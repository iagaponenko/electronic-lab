`timescale 1 ns / 1 ps

// The macro to get the MSB first representation of a bitsting
`define MSB_8(data) {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]}


// The top module for experimenting with an intermediate frame buffer synchronized
// wit the 32x40 display MAX7219 controlled via SPI. The content of the frame buffer
// is pushed to the display by a continiously run driver.
//
// Coordinate system of a single 8x8 dot display:
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
//          0 1 2 3 4 5 6 7
//
// For example, consider a pixel represented by the symbol 'x' at a position of the column=7
// in row=0. Since the data on the MAX7219 are organized in the MSB order, the bitstring that
// needs to be pushed to the matrix would be 8b'10000000.
//
// The complete display is assemped from 20 such 8x8 dot displays arranged in a grid of 4 columns
// and 5 rows.
//
//            DISP_COLUMNS=4
//         
//         -> [ ] [ ] [ ] [ ] -> END
//         -> [ ] [ ] [ ] [ ] ->
//         -> [ ] [ ] [ ] [ ] ->           DPSP_ROWS=5
//         -> [ ] [ ] [ ] [ ] ->
//  BEGIN  -> [ ] [ ] [ ] [ ] ->
//
// Note that the matrixes are connected sequentially. Therefore, the refresh of the complete
// ddisplay requires pushing 8 streams of 20 bytes (one byte per each 8x8 dot display)
// to the MAX7219 device. One such stream corresponds to one row of pixels across all 20 dot displays.
//
// Coordinate system of the full 32x40 framebuffer:
// 
//      [Y]
//
//      39
//      ..
//      31
//      ..
//      23      HEIGHT=40
//      ..      WIDTH=32
//      15.     [0:HEIGHT-1][0:WIDTH-1] FB
//      ..
//      07
//      ..
//      00
//         00 . 07 . 15 . 23 . 31  [X]
//
// Where each byte is represented in the MSB first order.     

module main

    (
        // 12 MHz
        input wire i_Clk,
        input wire [1:0] i_Button,

        // Output SPI signals (MAX7219)
        output reg o_SPI_MAX7219_Stb,
        output reg o_SPI_MAX7219_Clk,
        output reg o_SPI_MAX7219_Din

    );

    // Condition the reset button

    localparam BUTTON_DEBOUNCE_CYCLES = 120 * 1000;     // ~10 ms
    reg r_Rst;
    debounce
        #(  .DEBOUNCE_CYCLES (BUTTON_DEBOUNCE_CYCLES)
        ) debounce_0 (
            .i_Clk  (i_Clk),
            .i_Data (i_Button[1]),
            .o_Data (r_Rst)
        );

    // General configuration of the display and the SPI module.

    localparam  DISP_COLUMNS = 4;
    localparam  DISP_ROWS    = 5;
    localparam  MAX7219_DATA_WIDTH = DISP_COLUMNS * DISP_ROWS * 8 * 2; // 2 bytes per each row of the matrix display

    // The pattern generation algorithms

    wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] w_MAX7219_DataStream_rd;
    pattern_random
        #(  .DISP_ROWS      (DISP_ROWS),
            .DISP_COLUMNS   (DISP_COLUMNS),
            .CLK_FREQ_HZ    (12 * 1000 * 1000)  // 12 MHz
        ) pattern_random_0 (
            .i_Clk                  (i_Clk),
            .i_Rst                  (r_Rst),
            .o_MAX7219_DataStream   (w_MAX7219_DataStream_rd)
        );

    wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] w_MAX7219_DataStream_is;
    pattern_infinite_snake
        #(  .DISP_ROWS      (DISP_ROWS),
            .DISP_COLUMNS   (DISP_COLUMNS),
            .DELAY_CLOCKS   (60 * 1000)         // 5 ms at 12 MHz
        ) pattern_infinite_snake_0 (
            .i_Clk                  (i_Clk),
            .i_Rst                  (r_Rst),
            .o_MAX7219_DataStream   (w_MAX7219_DataStream_is)
        );

    wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] w_MAX7219_DataStream_fs;
    pattern_finite_snake
        #(  .DISP_ROWS      (DISP_ROWS),
            .DISP_COLUMNS   (DISP_COLUMNS),
            .DELAY_CLOCKS   (600 * 1000),       // 50 ms at 12 MHz
            .TAIL_LENGTH    (16)
        ) pattern_finite_snake_0 (
            .i_Clk                  (i_Clk),
            .i_Rst                  (r_Rst),
            .o_MAX7219_DataStream   (w_MAX7219_DataStream_fs)
        );

    wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] w_MAX7219_DataStream_ac;
    pattern_clock
        #(  .DISP_ROWS      (DISP_ROWS),
            .DISP_COLUMNS   (DISP_COLUMNS),
            .CLK_FREQ_HZ    (12 * 1000 * 1000)  // 12 MHz
        ) pattern_clock_0 (
            .i_Clk                  (i_Clk),
            .i_Rst                  (r_Rst),
            .o_MAX7219_DataStream   (w_MAX7219_DataStream_ac)
        );
    
    wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] w_MAX7219_DataStream_cs;
    pattern_circles
        #(  .DISP_ROWS      (DISP_ROWS),
            .DISP_COLUMNS   (DISP_COLUMNS),
            .CLK_FREQ_HZ    (12 * 1000 * 1000)  // 12 MHz
        ) pattern_circles_0 (
            .i_Clk                  (i_Clk),
            .i_Rst                  (r_Rst),
            .o_MAX7219_DataStream   (w_MAX7219_DataStream_cs)
        );

    // Algorithm selector switches between data streams based on the timing intervals

    reg [30:0] r_NumClocks = '0;
    always @(negedge i_Clk or posedge r_Rst) begin
        if (r_Rst) begin
            r_NumClocks <= '0;
        end else begin
            r_NumClocks <= r_NumClocks + 1;
        end
    end

    reg [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] r_MAX7219_DataStream;
    always_comb begin
        case (r_NumClocks[30:28])
            3'd0: r_MAX7219_DataStream = w_MAX7219_DataStream_rd;
            3'd1: r_MAX7219_DataStream = w_MAX7219_DataStream_is;
            3'd2: r_MAX7219_DataStream = w_MAX7219_DataStream_rd;
            3'd3: r_MAX7219_DataStream = w_MAX7219_DataStream_fs;
            3'd4: r_MAX7219_DataStream = w_MAX7219_DataStream_rd;
            3'd5: r_MAX7219_DataStream = w_MAX7219_DataStream_ac;
            3'd6: r_MAX7219_DataStream = w_MAX7219_DataStream_rd;
            3'd7: r_MAX7219_DataStream = w_MAX7219_DataStream_cs;
        endcase
    end

    // Push the current state of the data streams to the display.

    spi_max7219_driver
        #(  .MAX7219_SPI_CYCLES     (10),
            .MAX7219_DATA_WIDTH     (MAX7219_DATA_WIDTH),
            .REFRESH_DELAY_CLOCKS   (1200)  // ~100 us at 12 MHz
        ) spi_max7219_driver_0 (
            .i_Clk                      (i_Clk),
            .i_Rst                      (r_Rst),
            .i_MAX7219_DataStream       (r_MAX7219_DataStream),
            .o_SPI_MAX7219_Stb          (o_SPI_MAX7219_Stb),
            .o_SPI_MAX7219_Clk          (o_SPI_MAX7219_Clk),
            .o_SPI_MAX7219_Din          (o_SPI_MAX7219_Din)
        );

endmodule
