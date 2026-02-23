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

module main1

    (
        // 12 MHz
        input wire i_Clk,
        input wire [1:0] i_Button,

        // Output SPI signals (MAX7219)
        output reg o_SPI_MAX7219_Stb,
        output reg o_SPI_MAX7219_Clk,
        output reg o_SPI_MAX7219_Din

    );

    // Condition the buttons

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

    localparam  CLK_FREQ_HZ  = 12 * 1000 * 1000;    // 12 MHz
    localparam  DISP_COLUMNS = 4;
    localparam  DISP_ROWS    = 5;
    localparam  MAX7219_DATA_WIDTH = DISP_COLUMNS * DISP_ROWS * 8 * 2; // 2 bytes per each row of the matrix display

    // Send periodic stimuluses to refresh the scenery.
    // The ~1 second length pulses (set/reset on the rising clock) are sent roughly each 2 seconds.
    // The implementation is based on overflowing a counter of clocks, in which one extra upper
    // bit represents the overflow.

    localparam CLOCK_COUNTER_WIDTH = $clog2(CLK_FREQ_HZ);
    reg [CLOCK_COUNTER_WIDTH:0] r_Clocks = '0;
    wire r_AliensArrived = r_Clocks[CLOCK_COUNTER_WIDTH];

    always @(posedge i_Clk or posedge r_Rst) begin
        if (r_Rst == 1'b1) begin
            r_Clocks <= '0;
        end else begin
            r_Clocks <= r_Clocks + 1'b1;
        end
    end

    // The pattern generation algorithms

    wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] w_MAX7219_DataStream;
    pattern_conwaylife
        #(  .DISP_ROWS      (DISP_ROWS),
            .DISP_COLUMNS   (DISP_COLUMNS),
            .CLK_FREQ_HZ    (CLK_FREQ_HZ)
        ) pattern_conwaylife_0 (
            .i_Clk                  (i_Clk),
            .i_Rst                  (r_Rst),
            .i_AliensArrived        (r_AliensArrived),
            .o_MAX7219_DataStream   (w_MAX7219_DataStream)
        );

    // Push the current state of the data streams to the display.

    spi_max7219_driver
        #(  .MAX7219_SPI_CYCLES     (10),
            .MAX7219_DATA_WIDTH     (MAX7219_DATA_WIDTH),
            .REFRESH_DELAY_CLOCKS   (1200)  // ~100 us at 12 MHz
        ) spi_max7219_driver_0 (
            .i_Clk                      (i_Clk),
            .i_Rst                      (r_Rst),
            .i_MAX7219_DataStream       (w_MAX7219_DataStream),
            .o_SPI_MAX7219_Stb          (o_SPI_MAX7219_Stb),
            .o_SPI_MAX7219_Clk          (o_SPI_MAX7219_Clk),
            .o_SPI_MAX7219_Din          (o_SPI_MAX7219_Din)
        );

endmodule
