`timescale 1 ns / 1 ps

module max7219_driver_tb;

    localparam  SEG_ROWS                = 1;
    localparam  SEG_COLS                = 2;
    localparam  SPI_CYCLES              = 2;
    localparam  DISPLAY_UPDATE_CYCLES   = 1;
    localparam  YSIZE                   = SEG_ROWS * 8;
    localparam  XSIZE                   = SEG_COLS * 8;
    reg r_Rst;
    reg r_Clk;

    reg [0:YSIZE-1][0:XSIZE-1]              r_FrameBuf;     // [y][x]
    reg [SEG_ROWS-1:0][SEG_COLS-1:0][0:15]  r_Intensity;    // [row][col][level]

    reg r_SPI_Stb;
    reg r_SPI_Clk;
    reg r_SPI_Din;

    max7219_driver
    #(  .SEG_ROWS               (SEG_ROWS),
        .SEG_COLS               (SEG_COLS),
        .SPI_CYCLES             (SPI_CYCLES),
        .DISPLAY_UPDATE_CYCLES  (DISPLAY_UPDATE_CYCLES)
    ) max7219_driver_0 (
        .i_Rst          (r_Rst),
        .i_Clk          (r_Clk),

        .i_FrameBuf     (r_FrameBuf),
        .i_Intensity    (r_Intensity),

        .o_SPI_Stb      (r_SPI_Stb),
        .o_SPI_Clk      (r_SPI_Clk),
        .o_SPI_Din      (r_SPI_Din)
    );

    function void init();
        $dumpfile("max7219_driver.vcd");
        $dumpvars(0);
        r_Rst = 1'b1;
        r_Clk = 1'b0;
        r_FrameBuf = '0;
        r_Intensity = '0;
    endfunction

    initial begin
        init();
        #1 r_Rst = 1'b0;
        r_Intensity[0][0] = 4'b0011;
        r_FrameBuf[0][0] = 1'b1;
        r_FrameBuf[1][1] = 1'b1;
        r_FrameBuf[2][2] = 1'b1;
        r_FrameBuf[3][3] = 1'b1;
        r_FrameBuf[4][4] = 1'b1;
        r_FrameBuf[5][5] = 1'b1;
        r_FrameBuf[6][6] = 1'b1;
        r_FrameBuf[7][7] = 1'b1;
        #4000 $finish;
    end

    always begin
        #1 r_Clk = ~r_Clk;
    end

endmodule