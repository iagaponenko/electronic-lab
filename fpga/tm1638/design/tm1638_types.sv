`timescale 1 ns / 1 ps

// The package provides data types and functions for generating
// the tm1638 commands.
// See:
// https://mikesmodz.wordpress.com/2015/11/25/tm1638-seven-segment-display-driver-with-key-scan-interface/
// https://www.makerhero.com/img/files/download/TM1638-Datasheet.pdf
package tm1638_types;

typedef enum logic {
    COMMAND_NO_DATA  = 1'b0,
    COMMAND_AND_DATA = 1'b1
} command_data_t;

typedef enum logic [1:0] {
    COMMAND_DATA    = 2'b01,
    COMMAND_CONTROL = 2'b10,
    COMMAND_ADDR    = 2'b11
} command_t;

typedef enum logic { SHOW_ON = 1'b1, SHOW_OFF = 1'b0} show_t;

typedef logic [2:0] brightness_t;
localparam BRIGHTNESS_MIN = 3'h0;
localparam BRIGHTNESS_MAX = 3'h7;

function logic [17:0] make_control_command
    (   show_t       show = SHOW_ON,
        brightness_t brightness = BRIGHTNESS_MIN
    );
    return _make_command(DATA_DIR_WRITE, COMMAND_NO_DATA, COMMAND_CONTROL, {2'b00, show, brightness});
endfunction 

typedef enum logic {
    DATA_MODE_NORMAL = 1'b0,
    DATA_MODE_TEST   = 1'b1
} data_mode_t;

typedef enum logic {
    ADDR_MODE_AUTO  = 1'b0,
    ADDR_MODE_FIXED = 1'b1
} addr_mode_t;

typedef enum logic {
    DATA_DIR_WRITE = 1'b0,
    DATA_DIR_READ  = 1'b1
} data_dir_t;

function logic [17:0] make_write_data_command
    (   addr_mode_t addr_mode = ADDR_MODE_FIXED,
        data_mode_t data_mode = DATA_MODE_NORMAL
    );
    return _data_command(DATA_DIR_WRITE, addr_mode, data_mode);
endfunction 

function logic [17:0] make_read_data_command(); return _data_command(DATA_DIR_READ); endfunction 

function logic [17:0] _data_command
    (   data_dir_t  data_dir,
        addr_mode_t addr_mode = ADDR_MODE_FIXED,
        data_mode_t data_mode = DATA_MODE_NORMAL
    );
    return _make_command(data_dir, COMMAND_NO_DATA, COMMAND_DATA, {2'b00, data_mode, addr_mode, data_dir, 1'b0});
endfunction 

typedef logic [2:0] grid_t;

typedef enum logic {
    SEG07 = 1'b0,
    SEG89 = 1'b1
} segment_t;


typedef enum logic [3:0] {
    GRID0_SEG07 = 4'h0, GRID0_SEG89 = 4'h1,
    GRID1_SEG07 = 4'h2, GRID1_SEG89 = 4'h3,
    GRID2_SEG07 = 4'h4, GRID2_SEG89 = 4'h5,
    GRID3_SEG07 = 4'h6, GRID3_SEG89 = 4'h7,
    GRID4_SEG07 = 4'h8, GRID4_SEG89 = 4'h9,
    GRID5_SEG07 = 4'ha, GRID5_SEG89 = 4'hb,
    GRID6_SEG07 = 4'hc, GRID6_SEG89 = 4'hd,
    GRID7_SEG07 = 4'he, GRID7_SEG89 = 4'hf
} register_t;

typedef logic [7:0] data_t;
localparam EMPTY_DATA = 8'h0;

function logic [17:0] make_addr_command_and_data
    (   grid_t    grid,
        data_t    data,
        segment_t segment = SEG07
    );
    return _make_command(DATA_DIR_WRITE, COMMAND_AND_DATA, COMMAND_ADDR, {2'b00, grid, segment}, data);
endfunction 

function logic [17:0] _make_command
    (   data_dir_t     data_dir,
        command_data_t command_data_type,
        command_t      command_type,
        [5:0]          command_arguments,
        data_t         data = EMPTY_DATA
    );
    return {data_dir, command_data_type, data, command_type, command_arguments};
endfunction 

// The definitions for positions of leds, digits and keys on the TM1638 arranged from the left
// to the right.
typedef enum logic [2:0] {
    LED0 = 3'd7,
    LED1 = 3'd6,
    LED2 = 3'd5,
    LED3 = 3'd4,
    LED4 = 3'd3,
    LED5 = 3'd2,
    LED6 = 3'd1,
    LED7 = 3'd0
} tm1638_led_pos_t;

typedef enum logic [2:0] {
    DIGIT0 = 3'd7,
    DIGIT1 = 3'd6,
    DIGIT2 = 3'd5,
    DIGIT3 = 3'd4,
    DIGIT4 = 3'd3,
    DIGIT5 = 3'd2,
    DIGIT6 = 3'd1,
    DIGIT7 = 3'd0
} tm1638_digit_pos_t;

typedef enum logic [4:0] {
    KEY0 = 5'd28,
    KEY1 = 5'd20,
    KEY2 = 5'd12,
    KEY3 = 5'd04,
    KEY4 = 5'd24,
    KEY5 = 5'd16,
    KEY6 = 5'd08,
    KEY7 = 5'd00
} tm1638_key_pos_t;


endpackage
