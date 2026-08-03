# =============================================================================
# synth_and_time.tcl -- parameterized single-module synthesis + STA flow.
# =============================================================================
#
# Usage:
#   yosys -c synth_and_time.tcl -- <module> <target_period_ns>
#   e.g.  yosys -c synth_and_time.tcl -- fifo 5.0
#
# Processes exactly ONE module per invocation. All paths are derived from the
# repo layout relative to this script:
#
#   candidates/<module>.sv         input  (the implementation to synthesize)
#   candidates/<module>_synth.v    output (gate-level netlist)
#   candidates/<module>_stat.txt   output (yosys stat log)
#   candidates/<module>_sta.tcl    output (generated OpenSTA script)
#   candidates/<module>_sta.log    output (raw OpenSTA output)
#   candidates/<module>_result.json output (the JSON result line)
#
# NOTE ON INVOCATION MODE: `yosys -c` runs a REAL Tcl interpreter, so every
# Yosys command must be prefixed with `yosys` (e.g. `yosys read_verilog`).
# Bare `read_verilog` fails with "invalid command name". The `yosys` prefix is
# used throughout below; that is deliberate, not redundant.
#
# TIMING CAVEAT: the numbers this emits are SYNTHESIS-STAGE estimates. There is
# no placement, no routing, and no extracted parasitics -- interconnect is
# whatever wireload/ideal-net assumption the tools default to. These are useful
# as a relative signal for comparing implementations; they are NOT signoff
# timing and must never be reported as such.
# =============================================================================

set LIBERTY_DEFAULT /home/jack/tools/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
set STA_BIN_DEFAULT /home/jack/tools/OpenSTA/build/sta

# Both overridable from the environment so this is not welded to one machine.
set LIBERTY [expr {[info exists ::env(SKY130_LIB)] ? $::env(SKY130_LIB) : $LIBERTY_DEFAULT}]
set STA_BIN [expr {[info exists ::env(STA_BIN)]    ? $::env(STA_BIN)    : $STA_BIN_DEFAULT}]

# Cell-name prefix that proves the Liberty mapping actually took effect.
set LIB_CELL_PREFIX "sky130_fd_sc_hd__"

# -----------------------------------------------------------------------------
# helpers
# -----------------------------------------------------------------------------

# Every failure path comes through here: message on stderr, non-zero exit.
# Nothing downstream should ever have to guess whether a run was clean.
proc die {msg} {
    puts stderr "ERROR\[synth_and_time\]: $msg"
    flush stderr
    exit 1
}

# Pull "<label> max <value>" out of an OpenSTA report_wns/report_tns/
# report_worst_slack line. Returns "" if the line is absent.
proc parse_sta_metric {text label} {
    foreach line [split $text "\n"] {
        if {[regexp "^\\s*$label\\s+\\S+\\s+(-?\[0-9.eE+-\]+)\\s*$" $line -> value]} {
            return $value
        }
    }
    return ""
}

proc json_escape {s} {
    string map {\\ \\\\ \" \\\" \n \\n \r \\r \t \\t} $s
}

# -----------------------------------------------------------------------------
# argument handling
# -----------------------------------------------------------------------------
if {![info exists argv] || [llength $argv] != 2} {
    die "usage: yosys -c synth_and_time.tcl -- <module> <target_period_ns>"
}

set module        [lindex $argv 0]
set target_period [lindex $argv 1]

if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $module]} {
    die "'$module' is not a legal module identifier"
}
if {![string is double -strict $target_period] || $target_period <= 0} {
    die "target clock period must be a positive number in ns, got '$target_period'"
}

set repo_root  [file dirname [file normalize [info script]]]
set cand_dir   [file join $repo_root candidates]
set src        [file join $cand_dir $module.sv]
set netlist    [file join $cand_dir ${module}_synth.v]
set stat_file  [file join $cand_dir ${module}_stat.txt]
set sta_script [file join $cand_dir ${module}_sta.tcl]
set sta_log    [file join $cand_dir ${module}_sta.log]
set json_file  [file join $cand_dir ${module}_result.json]

# -----------------------------------------------------------------------------
# preflight -- fail before doing any work rather than emitting a garbage report
# -----------------------------------------------------------------------------
if {![file isfile $src]} {
    die "candidate source not found: $src"
}
if {![file isfile $LIBERTY]} {
    die "Liberty file does not resolve: $LIBERTY (override with \$SKY130_LIB)"
}
if {![file executable $STA_BIN]} {
    die "OpenSTA binary not found or not executable: $STA_BIN (override with \$STA_BIN)"
}

puts "\[synth_and_time\] module=$module period=${target_period}ns"
puts "\[synth_and_time\] source=$src"
puts "\[synth_and_time\] liberty=$LIBERTY"

# -----------------------------------------------------------------------------
# 1. SYNTHESIS (Yosys, Tcl mode -- note the mandatory `yosys` prefix)
# -----------------------------------------------------------------------------
if {[catch {
    yosys read_verilog -sv $src
    yosys synth -top $module
    yosys dfflibmap -liberty $LIBERTY
    yosys abc -liberty $LIBERTY
    yosys write_verilog $netlist
    yosys tee -q -o $stat_file stat
} err]} {
    die "synthesis failed for '$module': $err"
}

if {![file isfile $netlist]} {
    die "synthesis produced no netlist at $netlist"
}

# --- read back the stat report -----------------------------------------------
set fh [open $stat_file r]
set stat_txt [read $fh]
close $fh

# Sum the per-module "N cells" lines. SCOPE is one module per invocation and
# these candidates are flat, so this is an exact instance count; for a
# hierarchical design it would be the sum of local counts.
set cell_count 0
foreach line [split $stat_txt "\n"] {
    if {[regexp {^\s+([0-9]+) cells\s*$} $line -> n]} {
        incr cell_count $n
    }
}

# Collect the mapped standard-cell types. If dfflibmap/abc had silently not
# taken, the netlist would still be full of $_AND_ / $_DFF_P_ style internal
# cells and this list would come back empty -- which is the real check, not
# "yosys exited 0".
set mapped_cells {}
foreach line [split $stat_txt "\n"] {
    if {[regexp "^\\s+\[0-9\]+\\s+($LIB_CELL_PREFIX\\S+)\\s*$" $line -> cell]} {
        lappend mapped_cells $cell
    }
}

if {$cell_count <= 0} {
    die "synthesis produced zero cells for '$module' -- nothing to time"
}
if {[llength $mapped_cells] == 0} {
    die "no $LIB_CELL_PREFIX cells in the netlist -- Liberty mapping did not take effect"
}

puts "\[synth_and_time\] synthesis ok: $cell_count cells, [llength $mapped_cells] distinct\
mapped cell types (e.g. [lindex $mapped_cells 0])"

# -----------------------------------------------------------------------------
# 2. STATIC TIMING ANALYSIS (OpenSTA, run as a child process)
# -----------------------------------------------------------------------------
# Delimiters are emitted around each metric so the parse below keys off our own
# markers rather than guessing at report formatting.
#
# On the input-delay constraint: the clock port must be excluded. Applying
# set_input_delay to clk relative to the clock defined on clk itself trips
# OpenSTA warning 441. `[all_inputs -no_clocks]` is how this OpenSTA build
# spells that exclusion -- it has no `remove_from_list` command (that is a
# PrimeTime-ism; verified absent in OpenSTA 3.1.0).
set fh [open $sta_script w]
puts $fh "# generated by synth_and_time.tcl -- do not edit by hand"
puts $fh "read_liberty [list $LIBERTY]"
puts $fh "read_verilog [list $netlist]"
puts $fh "link_design $module"
puts $fh ""
puts $fh "create_clock -name clk -period $target_period \[get_ports clk\]"
puts $fh "set_input_delay 0.5 -clock clk \[all_inputs -no_clocks\]"
puts $fh "set_output_delay 0.5 -clock clk \[all_outputs\]"
puts $fh ""
puts $fh "puts \"===REPORT_CHECKS===\""
puts $fh "report_checks -path_delay max"
puts $fh "report_checks -path_delay min"
puts $fh "puts \"===WNS===\""
puts $fh "report_wns"
puts $fh "puts \"===TNS===\""
puts $fh "report_tns"
puts $fh "puts \"===WORST_SLACK===\""
puts $fh "report_worst_slack"
puts $fh "puts \"===DONE===\""
close $fh

set sta_rc 0
if {[catch {exec $STA_BIN -no_init -exit $sta_script 2>@1} sta_out]} {
    # exec throws on non-zero exit; $sta_out still holds the merged output.
    set sta_rc 1
}

set fh [open $sta_log w]
puts $fh $sta_out
close $fh

if {![string match *===DONE===* $sta_out]} {
    puts stderr $sta_out
    die "OpenSTA did not run to completion (see $sta_log)"
}
if {[regexp -line {^Error:} $sta_out]} {
    puts stderr $sta_out
    die "OpenSTA reported an error (see $sta_log)"
}
if {$sta_rc} {
    die "OpenSTA exited non-zero (see $sta_log)"
}

set wns         [parse_sta_metric $sta_out "wns"]
set tns         [parse_sta_metric $sta_out "tns"]
set worst_slack [parse_sta_metric $sta_out "worst slack"]

foreach {name val} [list wns $wns tns $tns worst_slack $worst_slack] {
    if {$val eq "" || ![string is double -strict $val]} {
        die "could not parse $name from OpenSTA output (see $sta_log)"
    }
}

puts "\[synth_and_time\] sta ok: wns=$wns tns=$tns worst_slack=$worst_slack"

# -----------------------------------------------------------------------------
# 3. STRUCTURED RESULT
# -----------------------------------------------------------------------------
# report_wns clamps at 0 when every path meets, so WNS is min(0, worst_slack):
# it answers "how badly did we miss" and never goes positive. worst_slack is
# carried alongside it as the actual worst path slack, which is the number you
# want when comparing two implementations that both close.
set timing_met [expr {$wns >= 0 ? "true" : "false"}]

set note "SYNTHESIS-STAGE timing only: post-synthesis netlist with\
wireload/ideal-net interconnect estimates, no placement, routing, or extracted\
parasitics. Relative signal for comparing implementations -- NOT post-route,\
NOT signoff quality. Do not report or log as signoff timing."

set json [format {{"module":"%s","target_period_ns":%s,"wns_ns":%s,"tns_ns":%s,"worst_slack_ns":%s,"cell_count":%d,"timing_met":%s,"stage":"synthesis","signoff_quality":false,"liberty":"%s","note":"%s"}} \
    [json_escape $module] \
    [format %.4f $target_period] \
    [format %.4f $wns] \
    [format %.4f $tns] \
    [format %.4f $worst_slack] \
    $cell_count \
    $timing_met \
    [json_escape [file tail $LIBERTY]] \
    [json_escape $note]]

set fh [open $json_file w]
puts $fh $json
close $fh

puts $json
flush stdout

exit 0
