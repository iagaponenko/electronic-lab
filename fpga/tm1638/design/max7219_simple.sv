`timescale 1 ns / 1 ps

// The top module for the MAX7219 driver.
//
// This module includes:
// - several stimulus modules to generate different patterns on the MAX7219 display
// - the MAX7219 driver module

module max7219

    import led7_types::*;

    (
        // Control signals
        input               i_Rst,
        input               i_Clk,
        input               i_Stimulus_Next,
        input               i_Encoder_Btn,      // Button signal from the rotary encoder
        input               i_Encoder_A,        // A signal from the rotary encoder
        input               i_Encoder_B,        // B signal from the rotary encoder
`ifndef __ICARUS__
        output              o_Clk,        // Clock signal to the FPGa pin for debugging
`endif

        // Output SPI signals (MAX7219)
        output reg          o_SPI_MAX7219_Stb,
        output reg          o_SPI_MAX7219_Clk,
`ifndef __ICARUS__
        output reg          o_SPI_MAX7219_Din
`else
        output reg          o_SPI_MAX7219_Din,

        // Diagnostic signals (this module)
        output reg          o_Diag_SPI_FIFO_Full,
        output reg [17:0]   o_Diag_Data,
        output reg          o_Diag_Data_Valid,

        // Diagnostic signals
        output state_t      o_Diag_Driver_State,
        output grid_t       o_Diag_Driver_Grid,
        output segments_t   o_Diag_Driver_Segments,
        output leds_t       o_Diag_Driver_Leds
`endif
    );

`ifndef __ICARUS__
    assign o_Clk = r_Out_Data[0];
`endif


`ifndef SIMPLE_MAX7219_DRIVER

    // The simple test for the MAX7219 driver.
    //
    // Coordinate system of a single 8x8 dot display:
    // 
    //       ROWS
    //
    //       7 |
    //       6 |
    //       5 |
    //       4 |
    //       3 |
    //       2 |
    //       1 |
    //       0 |              x
    //         +---------------
    //          0 1 2 3 4 5 6 7  COLUMNS
    //
    // The column numbers map to the bit numbers in the DATA as follows:
    // - the MSB 0 is the leftmost  pixel of the row (COLUMN=0)
    // - the MSB 7 is the rightmost pixel of the row (COLUMN=7)
    //
    // For example, a coordinate of the symbol 'x' is represented by ROW=0, DATA=8b'10000000
    //
`ifdef __ICARUS__
    localparam  MAX7219_SPI_CYCLES = 1;
    localparam  MAX7219_DATA_WIDTH = 16;
`else
    // GOWIN Tang Nano 20K FPGA. 27 MHz clock.
    localparam  MAX7219_SPI_CYCLES = 200; // 200;
    localparam  MAX7219_DATA_WIDTH = 20 * 16;
`endif
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
    wire [7:0][3:0]  REG_ROW = {
        REG_ROW_0, REG_ROW_1, REG_ROW_2, REG_ROW_3, REG_ROW_4, REG_ROW_5, REG_ROW_6, REG_ROW_7
    };
        
    localparam  DATA_ROW_0    = 8'b11000000;
    localparam  DATA_ROW_1    = 8'b01000000;
    localparam  DATA_ROW_2    = 8'b00100000;
    localparam  DATA_ROW_3    = 8'b00010000;
    localparam  DATA_ROW_4    = 8'b00001000;
    localparam  DATA_ROW_5    = 8'b00000100;
    localparam  DATA_ROW_6    = 8'b00000010;
    localparam  DATA_ROW_7    = 8'b00000001;
    wire [7:0][7:0]  DATA_ROW = {
        8'b11000000,
        8'b01000000,
        8'b00100000,
        8'b00010000,
        8'b00001000,
        8'b00000100,
        8'b00000010,
        8'b00000001
    };
    // localparam SYMB_0 = 64'hf88888888888f800;
    // localparam SYMB_1 = 64'h8080808080808000;
    // localparam SYMB_2 = 64'hf80808f88080f800;
    // localparam SYMB_3 = 64'hf88080f88080f800;
    // localparam SYMB_4 = 64'h808080f888888800;
    // localparam SYMB_5 = 64'hf88080f80808f800;
    // localparam SYMB_6 = 64'hf88888f80808f800;
    // localparam SYMB_7 = 64'h808080808080f800;
    // localparam SYMB_8 = 64'hf88888f88888f800;
    // localparam SYMB_9 = 64'hf88080f88888f800;

    // wire [7:0][7:0]  DATA_SYMBOLS [10] = {
    //     SYMB_0, SYMB_1, SYMB_2, SYMB_3, SYMB_4, SYMB_5, SYMB_6, SYMB_7, SYMB_8, SYMB_9
    // };

    // 5x7 left aligned font
    // wire [7:0][7:0]  DATA_SYMBOLS [10] = {
    //     64'h1010101010181000,
    //     64'h1f02040810110e00,
    //     64'h0e11100c10110e00,
    //     64'h10101f1214181000,
    //     64'h0e11100f01011f00,
    //     64'h0e11110f01110e00,
    //     64'h0202040810101f00,
    //     64'h0e11110e11110e00,
    //     64'h0e11101e11110e00,
    //     64'h0e11111111110e00
    // };

    // 4x7 right aligned font
    wire [9:0][7:0][7:0] DATA_SYMBOLS = {
        64'h6090909090906000,
        64'h8080808080c08000,
        64'hf010204080906000,
        64'h609080e080906000,
        64'h808080f090a0c000,
        64'he09080f01010f000,
        64'h6090907010906000,
        64'h101020408080f000,
        64'h609090f090906000,
        64'h609080e090906000
    };

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
    wire [0:15][7:0] DATA_INTENSITY = {
        8'b00000000, 8'b00000001, 8'b00000010, 8'b00000011, 8'b00000100, 8'b00000101, 8'b00000110, 8'b00000111,
        8'b00001000, 8'b00001001, 8'b00001010, 8'b00001011, 8'b00001100, 8'b00001101, 8'b00001110, 8'b00001111
    };

    localparam  REG_TEST            = 4'b1111;
    localparam  DATA_TEST           = 8'b00000001;
    localparam  DATA_NO_TEST        = 8'b00000000;


    // Set the data signal r_MAX7219_Data_Valid on the negative edge of the system clock
    // for one clock cycle only.
    reg                             r_MAX7219_SPI_Busy;
    reg                             r_MAX7219_Data_Valid = 1'b0;
    reg [MAX7219_DATA_WIDTH-1:0]    r_MAX7219_Data;

    int step = 0;
    int symbol = 0;
    int row = 0;

`ifdef __ICARUS__
    wire [MAX7219_DATA_WIDTH-1:0]   w_MAX7219_DataRowSymbol[10][8]; // [symbol][row]
    generate
        genvar  g_symbol;
        genvar  g_row;
        for (g_symbol = 0; g_symbol < 10; g_symbol = g_symbol + 1) begin : SYMBOL_GEN
            for (g_row = 0; g_row < 8; g_row = g_row + 1) begin : ROW_GEN
                assign w_MAX7219_DataRowSymbol[g_symbol][g_row] = {20{HDR, REG_ROW[g_row], DATA_SYMBOLS[g_symbol][7 - g_row]}};
            end
        end
    endgenerate
`endif
    reg [7:0] pattern1;
    reg [7:0] pattern2;
    reg [3:0] intensity_red = 4'h0;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_MAX7219_Data_Valid <= 1'b0;
            step <= 0;
            row <= 0;
            symbol <= 0;
            pattern1 <= 8'b10000001;
            pattern2 <= 8'b10000001;
            intensity_red <= 4'h0;
        end
        else begin
            if (r_MAX7219_Data_Valid) begin
                r_MAX7219_Data_Valid <= 1'b0;
            end
            else begin
                if (~r_MAX7219_SPI_Busy) begin
                    r_MAX7219_Data_Valid <= 1'b1;
`ifdef __ICARUS__
                    r_MAX7219_Data <= 16'b10000000_10000000;
`else
                    r_MAX7219_Data <= {20{HDR, REG_NOP, DATA_NOP}};
                    case (step)
                        0: begin
                            r_MAX7219_Data <= {20{HDR, REG_SHUT, DATA_SHUT_DOWN}};
                            step <= step + 1;
                        end
                        1: begin
                            r_MAX7219_Data <= {20{HDR, REG_SHUT, DATA_SHUT_NORMAL}};
                            step <= step + 1;
                        end
                        2: begin
                            r_MAX7219_Data <= {20{HDR, REG_BCD_ENCODE, DATA_BCD_ENCODE_NONE}};
                            step <= step + 1;
                        end
                        3: begin
                            r_MAX7219_Data <= {{16{HDR, REG_INTENSITY, DATA_INTENSITY[intensity_red]}}, {4{HDR, REG_INTENSITY, DATA_INTENSITY[intensity_red]}}};
                            step <= step + 1;
                        end
                        4: begin
                            r_MAX7219_Data <= {20{HDR, REG_SCAN, DATA_SCAN_01234567}};
                            step <= step + 1;
                        end
                        5: begin
                            r_MAX7219_Data <= {20{HDR, REG_TEST, DATA_TEST}};
                            step <= step + 1;
                        end
                        6: begin
                            r_MAX7219_Data <= {20{HDR, REG_TEST, DATA_NO_TEST}};
                            step <= step + 1;
                        end
                        7: begin
                            r_MAX7219_Data <= {
                                {4{HDR, REG_ROW[row], pattern1}},
                                {4{HDR, REG_ROW[row], pattern2}},
                                {4{HDR, REG_ROW[row], pattern1}},
                                {4{HDR, REG_ROW[row], pattern2}},
                                {4{HDR, REG_ROW[row], pattern1}}
                            };
                            pattern1 <= {pattern1[6:0], pattern1[7]}; // rotate the pattern left
                            pattern2 <= {pattern2[0], pattern2[7:1]}; // rotate the pattern right
                            //r_MAX7219_Data <= w_MAX7219_DataRowSymbol[symbol][row]; //{20{HDR, REG_ROW[row], DATA_SYMBOLS[symbol][7 - row]}};
                            //r_MAX7219_Data <= {20{HDR, REG_ROW[row], DATA_SYMBOLS[symbol][7 - row]}};
                            if (row == 7) begin
                                row <= 0;
                                if (symbol == 9) begin
                                    symbol <= 0;
                                end
                                else begin
                                    symbol <= symbol + 1;
                                end
                                step <= step + 1;   // delay before the next symbol
                            end
                            else begin
                                row <= row + 1;
                            end
                        end
                        default: begin
                            // Process delay before the next symbol
                            if (step == 200) begin
                                step <= 7;
                                pattern1 <= {pattern1[6:0], pattern1[7]}; // rotate the pattern left
                                pattern2 <= {pattern2[0], pattern2[7:1]}; // rotate the pattern right
                            end
                            else begin
                                step <= step + 1;
                                if (step == 199) begin
                                    step <= step + 1;
                                    r_MAX7219_Data <= {{16{HDR, REG_INTENSITY, DATA_INTENSITY[intensity_red]}}, {4{HDR, REG_INTENSITY, DATA_INTENSITY[intensity_red]}}};
                                    intensity_red <= intensity_red + 1'b1;
                                end
                            end
                        end
                    endcase
`endif
                end
            end
        end
    end

    spi_max7219
        #(  .CYCLES     (MAX7219_SPI_CYCLES),
            .DATA_WIDTH (MAX7219_DATA_WIDTH)
        ) spi_max7219_0 (
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),

            .o_Busy         (r_MAX7219_SPI_Busy),
            .i_Data_Ready   (r_MAX7219_Data_Valid),
            .i_Data         (r_MAX7219_Data),

            .o_SPI_Stb      (o_SPI_MAX7219_Stb),
            .o_SPI_Clk      (o_SPI_MAX7219_Clk),
            .o_SPI_Din      (o_SPI_MAX7219_Din)
        );

`else


    // The Frame buffer-based implementation of the MAX7219 driver.
`ifdef __ICARUS__
    localparam  MAX7219_SEG_ROWS                = 1;
    localparam  MAX7219_SEG_COLS                = 1;
    localparam  MAX7219_SPI_CYCLES              = 2;
    localparam  MAX7219_DISPLAY_UPDATE_CYCLES   = 1;
    localparam  MAX7219_FB_UPDATE_CYCLES        = 1;
`else
    // GOWIN Tang Nano 20K FPGA. 100 MHz clock.
    localparam  MAX7219_SEG_ROWS                = 5;
    localparam  MAX7219_SEG_COLS                = 4;
    localparam  MAX7219_SPI_CYCLES              =        100;
    localparam  MAX7219_DISPLAY_UPDATE_CYCLES   =      2_000;
    localparam  MAX7219_FB_UPDATE_CYCLES        =    200_000;
`endif
    localparam  MAX7219_YSIZE   = MAX7219_SEG_ROWS*8;
    localparam  MAX7219_XSIZE   = MAX7219_SEG_COLS*8;
    localparam  MAX7219_YSIZE_ADDR_WIDTH = $clog2(MAX7219_YSIZE);
    localparam  MAX7219_XSIZE_ADDR_WIDTH = $clog2(MAX7219_XSIZE);

    // [y][x]
    reg [0:MAX7219_YSIZE-1][0:MAX7219_XSIZE-1]  r_MAX7219_FrameBuf;

    // Up to 16 levels of intensity for each display.
    // [row][col][level]
    reg [MAX7219_SEG_ROWS-1:0][MAX7219_SEG_COLS-1:0][0:15]  r_MAX7219_Intensity;

    max7219_driver
    #(  .SEG_ROWS               (MAX7219_SEG_ROWS),
        .SEG_COLS               (MAX7219_SEG_COLS),
        .SPI_CYCLES             (MAX7219_SPI_CYCLES),
        .DISPLAY_UPDATE_CYCLES  (MAX7219_DISPLAY_UPDATE_CYCLES)
    ) max7219_driver_0 (
        .i_Rst          (i_Rst),
        .i_Clk          (i_Clk),

        .i_FrameBuf     (r_MAX7219_FrameBuf),
        .i_Intensity    (r_MAX7219_Intensity),

        .o_SPI_Stb      (o_SPI_MAX7219_Stb),
        .o_SPI_Clk      (o_SPI_MAX7219_Clk),
        .o_SPI_Din      (o_SPI_MAX7219_Din)
    );

    // Populate the frame buffer and the intensity map with the test data.

    reg [31:0]                  r_MAX7219_FrameBuf_Update_Counter = 32'h0;
    reg [0:MAX7219_YSIZE_ADDR_WIDTH-1]     r_Y = '0;
    reg [0:MAX7219_XSIZE_ADDR_WIDTH-1]     r_X = '0;
    reg r_Val = 1'b0;

    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_MAX7219_FrameBuf_Update_Counter <= 32'h0;
            r_Y <= '0;
            r_X <= '0;
            r_MAX7219_FrameBuf <= '0;
            r_Val <= 1'b0;
`ifdef __ICARUS__
                r_MAX7219_Intensity[0][0] <= 4'h4;
`else
                r_MAX7219_Intensity[0][0] <= 4'h0;
                r_MAX7219_Intensity[0][1] <= 4'h1;
                r_MAX7219_Intensity[0][2] <= 4'h2;
                r_MAX7219_Intensity[0][3] <= 4'h3;
                r_MAX7219_Intensity[1][0] <= 4'h3;
                r_MAX7219_Intensity[1][1] <= 4'h7;
                r_MAX7219_Intensity[1][2] <= 4'hB;
                r_MAX7219_Intensity[1][3] <= 4'hF;
                r_MAX7219_Intensity[2][0] <= 4'h3;
                r_MAX7219_Intensity[2][1] <= 4'h7;
                r_MAX7219_Intensity[2][2] <= 4'hB;
                r_MAX7219_Intensity[2][3] <= 4'hF;
                r_MAX7219_Intensity[3][0] <= 4'h3;
                r_MAX7219_Intensity[3][1] <= 4'h7;
                r_MAX7219_Intensity[3][2] <= 4'hB;
                r_MAX7219_Intensity[3][3] <= 4'hF;
                r_MAX7219_Intensity[4][0] <= 4'h3;
                r_MAX7219_Intensity[4][1] <= 4'h7;
                r_MAX7219_Intensity[4][2] <= 4'hB;
                r_MAX7219_Intensity[4][3] <= 4'hF;
`endif
        end
        else begin
            if (r_MAX7219_FrameBuf_Update_Counter == MAX7219_FB_UPDATE_CYCLES) begin
                r_MAX7219_FrameBuf_Update_Counter <= 32'h0;
`ifdef __ICARUS__
                r_MAX7219_FrameBuf[1][1] <= 1'b1;
`else
                if (r_X == MAX7219_XSIZE - 1) begin
                    r_X <= '0;
                    if (r_Y == MAX7219_YSIZE - 1) begin
                        r_Y <= '0;
                        r_MAX7219_FrameBuf <= '0;
                        r_Val <= 1'b0;
                    end
                    else begin
                        r_Y <= r_Y + 1'b1;
                        r_Val <= ~r_Val;
                    end
                end
                else begin
                    r_X <= r_X + 1'b1;
                    r_Val <= ~r_Val;
                end
                r_MAX7219_FrameBuf[r_Y][r_X] <= 1'b1 ^ r_MAX7219_FrameBuf[r_Y][r_X];
                //r_MAX7219_FrameBuf[r_Y][r_X] <= r_Val ^ r_MAX7219_FrameBuf[r_Y][r_X];
`endif
            end
            else begin
                r_MAX7219_FrameBuf_Update_Counter <= r_MAX7219_FrameBuf_Update_Counter + 1'b1;
            end
        end
    end
`endif

endmodule
