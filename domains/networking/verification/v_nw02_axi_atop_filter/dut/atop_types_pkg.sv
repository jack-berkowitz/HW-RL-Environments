// Scoring support. Structural AXI channel types at the pinned configuration.
//
// These mirror the anchor's `AXI_TYPEDEF_ALL macro expansion field for field.
// Declared here rather than included from the macro header because that header
// carries no include guard: the golden and a mutant land in ONE compilation, so
// including it from both redefines every macro. Deliberately free of any
// package dependency, so the harness's alphabetical file glob cannot order it
// ahead of something it needs.
package atop_types_pkg;
  parameter int unsigned ID_W = 4, ADDR_W = 32, DATA_W = 32, USER_W = 1;

  typedef logic [ID_W-1:0]     id_t;
  typedef logic [ADDR_W-1:0]   addr_t;
  typedef logic [DATA_W-1:0]   data_t;
  typedef logic [DATA_W/8-1:0] strb_t;
  typedef logic [USER_W-1:0]   user_t;

  typedef struct packed {
    id_t id; addr_t addr; logic [7:0] len; logic [2:0] size; logic [1:0] burst;
    logic lock; logic [3:0] cache; logic [2:0] prot; logic [3:0] qos;
    logic [3:0] region; logic [5:0] atop; user_t user;
  } aw_t;
  typedef struct packed { data_t data; strb_t strb; logic last; user_t user; } w_t;
  typedef struct packed { id_t id; logic [1:0] resp; user_t user; } b_t;
  typedef struct packed {
    id_t id; addr_t addr; logic [7:0] len; logic [2:0] size; logic [1:0] burst;
    logic lock; logic [3:0] cache; logic [2:0] prot; logic [3:0] qos;
    logic [3:0] region; user_t user;
  } ar_t;
  typedef struct packed { id_t id; data_t data; logic [1:0] resp; logic last; user_t user; } r_t;

  typedef struct packed {
    aw_t aw; logic aw_valid; w_t w; logic w_valid; logic b_ready;
    ar_t ar; logic ar_valid; logic r_ready;
  } req_t;
  typedef struct packed {
    logic aw_ready; logic ar_ready; logic w_ready; logic b_valid; b_t b;
    logic r_valid; r_t r;
  } resp_t;
endpackage
