# d_ca04 async_fifo_cdc timing constraints.
#
# TWO CLOCKS. This is the first two-clock SDC in the project and it is NOT the
# single-clock template with a second create_clock bolted on:
#
#   * the two clocks are declared ASYNCHRONOUS to each other, so STA does not
#     try to time paths between them. Without that, every pointer crossing is
#     reported as a huge violation and the numbers are meaningless.
#   * the pointer/data paths that do cross are bounded with set_max_delay
#     min(T_src, T_dst) and have their hold checks disabled, exactly as the
#     upstream module's own header prescribes. Leaving them unconstrained lets
#     the tool insert arbitrary delay on a Gray bit, which is the one thing
#     that breaks the "only one bit changes" guarantee in silicon.

current_design async_fifo_cdc

set wr_period 10.0
set rd_period 13.0
if {[info exists ::env(CLK_PERIOD_NS)]}    { set wr_period $::env(CLK_PERIOD_NS) }
if {[info exists ::env(RD_CLK_PERIOD_NS)]} { set rd_period $::env(RD_CLK_PERIOD_NS) }

create_clock -name wr_clock -period $wr_period [get_ports wr_clk]
create_clock -name rd_clock -period $rd_period [get_ports rd_clk]

# The whole point of the module: the domains are unrelated.
set_clock_groups -asynchronous -group {wr_clock} -group {rd_clock}

set_clock_latency 0.290 [get_clocks wr_clock]
set_clock_latency 0.290 [get_clocks rd_clock]

# IO delays are assigned PER DOMAIN by port name. `remove_from_collection` is a
# Synopsys DC command and OpenSTA does not implement it -- an earlier version
# used it and synthesis died at read_sdc. Listing the ports explicitly is also
# more accurate than lumping every input onto one clock, since rd_ready and
# rd_rst_n genuinely belong to the read domain.
set clk_io_pct 0.2

set_input_delay  [expr $wr_period * $clk_io_pct] -clock wr_clock \
    [get_ports {wr_rst_n wr_valid wr_data[*]}]
set_input_delay  [expr $rd_period * $clk_io_pct] -clock rd_clock \
    [get_ports {rd_rst_n rd_ready}]

set_output_delay [expr $wr_period * $clk_io_pct] -clock wr_clock \
    [get_ports {wr_ready}]
set_output_delay [expr $rd_period * $clk_io_pct] -clock rd_clock \
    [get_ports {rd_valid rd_data[*]}]

# Bound the crossing paths to the faster of the two periods and drop hold
# checks on them, per the upstream module's documented constraint recipe.
set cdc_max [expr {$wr_period < $rd_period ? $wr_period : $rd_period}]
set_max_delay $cdc_max -from [get_clocks wr_clock] -to [get_clocks rd_clock]
set_max_delay $cdc_max -from [get_clocks rd_clock] -to [get_clocks wr_clock]
set_false_path -hold -from [get_clocks wr_clock] -to [get_clocks rd_clock]
set_false_path -hold -from [get_clocks rd_clock] -to [get_clocks wr_clock]
