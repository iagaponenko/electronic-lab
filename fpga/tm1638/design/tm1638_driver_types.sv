`timescale 1 ns / 1 ps

package tm1638_driver_types;

typedef enum {
  IDLE                  = 0,
  SEGMENTES_LATCHED     = 1,
  CONTROL_COMMAND_SET   = 2,
  WAIT_DATA_COMMAND_SET = 3,
  DATA_COMMAND_SET      = 4,
  WAIT_ADDR_COMMAND_SET = 5,
  ADDR_COMMAND_SET      = 6
} state_t;

typedef reg [7:0][7:0] segments_t;  // [grid][segment]

endpackage

