// Scoring support. Compiled FIRST -- the name begins with "aa" because the
// harness globs dut/*.sv in lexicographic order and a macro must be defined
// before the file that tests it is preprocessed.
//
// WHY: the anchor carries built-in protocol assertions. When a submission's
// stimulus slips -- dropping valid before ready, say -- they abort the
// simulation with $stop and print the ANCHOR'S FILENAME AND MODULE PATH to
// stdout. That is two problems in one: the run produces no RESULT line, so the
// submission fails on the GOLDEN and reads as "rejected correct hardware" when
// the real fault is its own stimulus; and the abort names the design the task
// is built on.
//
// The assertions check nothing this task's specification leaves to the design:
// input stability is an obligation on the SOURCE, which is the submission, and
// it is stated in the specification as such.
`define COMMON_CELLS_ASSERTS_OFF
