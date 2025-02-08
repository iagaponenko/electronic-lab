`timescale 1 ns / 1 ps

module max7219_driver

    #(
        parameter   SEG_ROWS    = 1,
        parameter   SEG_COLS    = 1,
        parameter   SPI_CYCLES  = 1
    )(
        // Control signals
        input       i_Rst,
        input       i_Clk,

        input       [SEG_ROWS*8][SEG_COLS*8] i_FrameBuf,    // [y][x]

        // Output SPI signals
        output reg      o_SPI_Stb,
        output reg      o_SPI_Clk,
        output reg      o_SPI_Din
    );

    // SPI control signals
    reg r_SPI_Busy;
    reg r_Data_Ready;

    localparam  SPI_DATA_WIDTH  = 2 * 8 * SEG_ROWS * SEG_COLS;

    // Can't do this because the address width for 320 bits must be a power of 2. So using the next
    // number that is a power of 2.
    // localparam  MAX7219_ADDR_WIDTH = $clog2(MAX7219_DATA_WIDTH);
    localparam  MAX7219_ADDR_WIDTH = $clog2(512);

    wire [8][SPI_DATA_WIDTH]    r_Stripes;  // [stripe][pos]

    // max7219 registers and control commands

    localparam  HDR = 4'b0000;

    localparam  REG_NOP     = 4'b0000;
    localparam  DATA_NOP    = 8'b00000000;

    localparam  REG_SHUT            = 4'b1100;
    localparam  DATA_SHUT_DOWN      = 8'b00000000;
    localparam  DATA_SHUT_NORMAL    = 8'b00000001;

    localparam  REG_BCD_ENCODE          = 4'b1001;
    localparam  DATA_BCD_ENCODE_NONE    = 8'b00000000;

    localparam  REG_SCAN            = 4'b1011;
    localparam  DATA_SCAN_01234567  = 8'b00000111;

    localparam  REG_INTENSITY   = 4'b1010;
    wire [7:0]  DATA_INTENSITY [16] = {
        8'b00000000, 8'b00000001, 8'b00000010, 8'b00000011, 8'b00000100, 8'b00000101, 8'b00000110, 8'b00000111,
        8'b00001000, 8'b00001001, 8'b00001010, 8'b00001011, 8'b00001100, 8'b00001101, 8'b00001110, 8'b00001111
    };
    localparam  REG_ROW_0   = 4'b0001;
    localparam  REG_ROW_1   = 4'b0010;
    localparam  REG_ROW_2   = 4'b0011;
    localparam  REG_ROW_3   = 4'b0100;
    localparam  REG_ROW_4   = 4'b0101;
    localparam  REG_ROW_5   = 4'b0110;
    localparam  REG_ROW_6   = 4'b0111;
    localparam  REG_ROW_7   = 4'b1000;
    wire [3:0]  REG_ROW [8] = {
        REG_ROW_0, REG_ROW_1, REG_ROW_2, REG_ROW_3, REG_ROW_4, REG_ROW_5, REG_ROW_6, REG_ROW_7
    };

    spi_max7219
        #(  .CYCLES     (SPI_CYCLES),
            .DATA_WIDTH (SPI_DATA_WIDTH),
            .ADDR_WIDTH (MAX7219_ADDR_WIDTH)
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

endmodule
