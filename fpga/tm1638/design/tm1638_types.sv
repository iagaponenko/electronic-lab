`timescale 1 ns / 1 ps

// The package provides data types and functions for generating
// the tm1638 commands.
// See:
// https://mikesmodz.wordpress.com/2015/11/25/tm1638-seven-segment-display-driver-with-key-scan-interface/
// https://www.makerhero.com/img/files/download/TM1638-Datasheet.pdf
package tm1638_types;

typedef enum reg [1:0] {
    COMMAND_DATA    = 2'b01,
    COMMAND_CONTROL = 2'b10,
    COMMAND_ADDR    = 2'b11
} command_t;

typedef enum reg { SHOW_ON = 1'b1, SHOW_OFF = 1'b0} show_t;

typedef reg [2:0] brightness_t;
localparam BRIGHTNESS_MIN = 3'h0;
localparam BRIGHTNESS_MAX = 3'h7;

function reg [16:0] make_control_command
    (   show_t       show = SHOW_ON,
        brightness_t brightness = BRIGHTNESS_MIN
    );
    return {1'b0, 8'h0, COMMAND_CONTROL, 2'b00, show, brightness};
endfunction 

typedef enum reg {
    DATA_MODE_NORMAL = 1'b0,
    DATA_MODE_TEST   = 1'b1
} data_mode_t;

typedef enum reg {
    ADDR_MODE_AUTO  = 1'b0,
    ADDR_MODE_FIXED = 1'b1
} addr_mode_t;

typedef enum reg {
    DATA_DIR_WRITE = 1'b0,
    DATA_DIR_READ  = 1'b1
} data_dir_t;

function reg [16:0] make_data_command
    (   data_dir_t  data_dir  = DATA_DIR_WRITE,
        addr_mode_t addr_mode = ADDR_MODE_FIXED,
        data_mode_t data_mode = DATA_MODE_NORMAL
    );
    return {1'b0, 8'h0, COMMAND_DATA, 2'b00, data_mode, addr_mode, data_dir, 1'b0};
 endfunction 

typedef reg [2:0] grid_t;

typedef enum reg {
    SEG07 = 1'b0,
    SEG89 = 1'b1
} segment_t;


typedef enum reg [3:0] {
    GRID0_SEG07 = 4'h0, GRID0_SEG89 = 4'h1,
    GRID1_SEG07 = 4'h2, GRID1_SEG89 = 4'h3,
    GRID2_SEG07 = 4'h4, GRID2_SEG89 = 4'h5,
    GRID3_SEG07 = 4'h6, GRID3_SEG89 = 4'h7,
    GRID4_SEG07 = 4'h8, GRID4_SEG89 = 4'h9,
    GRID5_SEG07 = 4'ha, GRID5_SEG89 = 4'hb,
    GRID6_SEG07 = 4'hc, GRID6_SEG89 = 4'hd,
    GRID7_SEG07 = 4'he, GRID7_SEG89 = 4'hf
} register_t;

function reg [16:0] make_addr_command_and_data
    (   grid_t grid,
        [7:0] data,
        segment_t segment = SEG07
    );
    return {1'b1, data, COMMAND_ADDR, 2'b00, grid, segment};
endfunction 

endpackage
