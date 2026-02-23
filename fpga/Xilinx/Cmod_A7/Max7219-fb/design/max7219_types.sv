`timescale 1 ns / 1 ps

// The package provides data types and functions for generating
// the MAX7219 commands.
// See: https://www.analog.com/media/en/technical-documentation/data-sheets/max7219-max7221.pdf

package max7219_types;

    localparam  HDR = 4'b0000;

    localparam  REG_NOP     = 4'b0000;
    localparam  DATA_NOP    = 8'b00000000;

    localparam  REG_ROW_0   = 4'b0001;
    localparam  REG_ROW_1   = 4'b0010;
    localparam  REG_ROW_2   = 4'b0011;
    localparam  REG_ROW_3   = 4'b0100;
    localparam  REG_ROW_4   = 4'b0101;
    localparam  REG_ROW_5   = 4'b0110;
    localparam  REG_ROW_6   = 4'b0111;
    localparam  REG_ROW_7   = 4'b1000;

    function automatic [3:0] REG_ROW(input [2:0] row);
        case (row)
            3'd0: return REG_ROW_0;
            3'd1: return REG_ROW_1;
            3'd2: return REG_ROW_2;
            3'd3: return REG_ROW_3;
            3'd4: return REG_ROW_4;
            3'd5: return REG_ROW_5;
            3'd6: return REG_ROW_6;
            3'd7: return REG_ROW_7;
            default: return 4'b0000;
        endcase
    endfunction

    // Assignments are not allowed to be used within packages. The client modules need to make
    // such assignments from the package to their own code, or use functions as above.
    //
    // import max7219_types::*;
    // ...
    // wire [7:0][3:0] w_REG_ROW = {
    //     REG_ROW_0, REG_ROW_1, REG_ROW_2, REG_ROW_3, REG_ROW_4, REG_ROW_5, REG_ROW_6, REG_ROW_7
    // };

    localparam  REG_SHUT            = 4'b1100;
    localparam  DATA_SHUT_DOWN      = 8'b00000000;
    localparam  DATA_SHUT_NORMAL    = 8'b00000001;


    localparam  REG_SCAN            = 4'b1011;
    localparam  DATA_SCAN_0xxxxxxx  = 8'b00000000;
    localparam  DATA_SCAN_01xxxxxx  = 8'b00000001;
    localparam  DATA_SCAN_012xxxxx  = 8'b00000010;
    localparam  DATA_SCAN_0123xxxx  = 8'b00000011;
    localparam  DATA_SCAN_01234xxx  = 8'b00000100;
    localparam  DATA_SCAN_012345xx  = 8'b00000101;
    localparam  DATA_SCAN_0123456x  = 8'b00000110;
    localparam  DATA_SCAN_01234567  = 8'b00000111;

    localparam  REG_BCD_ENCODE          = 4'b1001;
    localparam  DATA_BCD_ENCODE_NONE    = 8'b00000000;

    localparam  REG_INTENSITY   = 4'b1010;

    function automatic [7:0] DATA_INTENSITY(input [3:0] intensity);
        return {4'b0000, intensity};
    endfunction

    // Assignments are not allowed to be used within packages. The client modules need to make
    // such assignments from the package to their own code, or use functions as above.
    //
    // import max7219_types::*;
    // ...
    // wire [0:15][7:0] w_DATA_INTENSITY = {
    //     8'b00000000, 8'b00000001, 8'b00000010, 8'b00000011, 8'b00000100, 8'b00000101, 8'b00000110, 8'b00000111,
    //     8'b00001000, 8'b00001001, 8'b00001010, 8'b00001011, 8'b00001100, 8'b00001101, 8'b00001110, 8'b00001111
    // };

    localparam  REG_TEST            = 4'b1111;
    localparam  DATA_TEST           = 8'b00000001;
    localparam  DATA_NO_TEST        = 8'b00000000;

endpackage : max7219_types
