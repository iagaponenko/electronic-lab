`timescale 1 ns / 1 ps

package tm1638_driver_types;

typedef enum {
    IDLE                      = 0,
    INPUT_LATCHED             = 1,
    CONTROL_COMMAND_SET       = 2,

    WAIT_KEY_READ_COMMAND_SET = 3,
    KEY_READ_COMMAND_SET      = 4,

    WAIT_SEG_DATA_COMMAND_SET = 5,
    SEG_DATA_COMMAND_SET      = 6,
    WAIT_SEG_ADDR_COMMAND_SET = 7,
    SEG_ADDR_COMMAND_SET      = 8,

    WAIT_LED_DATA_COMMAND_SET = 9,
    LED_DATA_COMMAND_SET      = 10,
    WAIT_LED_ADDR_COMMAND_SET = 11,
    LED_ADDR_COMMAND_SET      = 12

} state_t;

typedef logic [7:0][7:0] segments_t;  // [grid][segment]
typedef logic [7:0]      leds_t;      // [grid]

endpackage

