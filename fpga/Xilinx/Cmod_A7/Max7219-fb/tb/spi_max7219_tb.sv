`timescale 1 ns / 1 ps

module spi_max7219_tb;

    localparam  CYCLES = 1;
    localparam  DATA_WIDTH = 16;

    reg         r_Rst;
    reg         r_Clk;

    reg                     r_Busy;
    reg                     r_Data_Ready;
    reg [DATA_WIDTH-1:0]    r_Data;

    reg         r_SPI_Stb;
    reg         r_SPI_Clk;
    reg         r_SPI_Din;

    spi_max7219
        #(  .CYCLES         (CYCLES),
            .DATA_WIDTH     (DATA_WIDTH)
        ) spi_0 (
            .i_Rst          (r_Rst),
            .i_Clk          (r_Clk),

            .o_Busy         (r_Busy),
            .i_Data_Ready   (r_Data_Ready),
            .i_Data         (r_Data),

            .o_SPI_Stb      (r_SPI_Stb),
            .o_SPI_Clk      (r_SPI_Clk),
            .o_SPI_Din      (r_SPI_Din)
        );

    task wait_for_busy;
        while (r_Busy) begin
            @(negedge r_Clk);
        end
    endtask

    initial begin
        $dumpfile("spi_max7219.vcd");
        $dumpvars(0);
        
        r_Rst = 1;
        r_Clk = 0;
        r_Data_Ready = 0;

        @(negedge r_Clk) r_Rst = 0;

        wait_for_busy;

        r_Data       = 16'b00000001_00000001;
        r_Data_Ready = 1;
        @(negedge r_Clk);
        r_Data_Ready = 0;

        wait_for_busy;

        r_Data       = 16'b10000000_10000000;
        r_Data_Ready = 1;
        @(negedge r_Clk);
        r_Data_Ready = 0;

        wait_for_busy;

        $finish;
    end

    always #1 r_Clk = ~r_Clk;


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
    //       0 |
    //         +---------------
    //          0 1 2 3 4 5 6 7  COLUMNS

    // Coordinate system of an array of 4 displays:
    //
    // 
    //
    //           ->   +----------+     +----------+
    //         /      |          |     |          |
    //        /   1   |          |     |          |
    //       /        |          |     |          |
    //      /         +----------+     +----------+
    //  SEG_ROWS 
    //      \         +----------+     +----------+
    //       \        |          |     |          |
    //        \   0   |          |     |          |
    //         \      |          |     |          |
    //           ->   +----------+     +----------+
    //
    //                ^     0                1    ^
    //                 \                         /
    //                  \                       /
    //                   \      SEG_COLS       /
    //
    // Note that stripes are generated from the 8-bit sequences of buffer pixels and
    // prepended by the 4-bit header and the 4-bit register address.

    localparam  SEG_ROWS = 3, SEG_COLS = 2;

    reg  [SEG_ROWS*8][SEG_COLS*8]   r_FrameBuf;     // [y][x]
    wire [8][2*SEG_ROWS*SEG_COLS*8] r_Stripes;      // [stripe][pos]

    wire [4] HDR = 4'bxxxx;
    wire [4] REG = 4'bzzzz;

    generate
        genvar  stripe;
        genvar  col;
        genvar  row;
        genvar  pix;
        for (stripe = 0; stripe < 8; stripe = stripe + 1) begin     : STRIPE_GEN
            for (row = 0; row < SEG_ROWS; row = row + 1) begin      : ROW_GEN
                for (col = 0; col < SEG_COLS; col = col + 1) begin  : COL_GEN
                    assign r_Stripes[stripe][2 * 8 * row * SEG_COLS + 2 * 8 * col +: 8] = {HDR,REG};
                    for (pix = 0; pix < 8; pix = pix + 1) begin     : PIX_GEN
                        assign r_Stripes[stripe][2 * 8 * row * SEG_COLS + 2 * 8 * col + 8 + pix] = r_FrameBuf[8 * row + stripe][8 * col + pix];
                    end
                end
            end
        end
    endgenerate

    function void print_fb();
        $display("\n");
        for (int y = SEG_ROWS*8 - 1; y >= 0; y = y - 1) begin
            $display("  [%02d] %b", y, r_FrameBuf[y]);
        end
    endfunction
    function void print_stripes();
        $display("\n");
        for (int stripe = 7; stripe >= 0; stripe = stripe - 1) begin
            $display("  [%02d] %b", stripe, r_Stripes[stripe]);
        end
    endfunction

    initial begin
        //$monitor("r_FrameBuf = %b\nr_Stripes  = %b", r_FrameBuf, r_Stripes);
        r_FrameBuf = '0;
        
        // Test for:SEG_ROWS = 2,  SEG_COLS = 2

        // r_FrameBuf[0][1] = 1;
        // r_FrameBuf[0][8] = 1;
        // r_FrameBuf[8][3] = 1;

        // r_FrameBuf[7][14] = 1;
        // r_FrameBuf[15][2] = 1;
        // r_FrameBuf[15][15] = 1;

        // Test for: SEG_ROWS = 1, SEG_COLS = 4

        // r_FrameBuf[0][1] = 1;
        // r_FrameBuf[0][8] = 1;
        // r_FrameBuf[0][15] = 1;
        // r_FrameBuf[0][29] = 1;

        // Test for:SEG_ROWS = 4, SEG_COLS = 1

        // r_FrameBuf[1][0] = 1;
        // r_FrameBuf[8][0] = 1;
        // r_FrameBuf[15][0] = 1;
        // r_FrameBuf[29][0] = 1;

        // Test for:SEG_ROWS = 3, SEG_COLS = 2

        r_FrameBuf[0][0] = 1;
        r_FrameBuf[1][1] = 1;
        r_FrameBuf[2][2] = 1;
        r_FrameBuf[3][3] = 1;
        r_FrameBuf[4][4] = 1;
        r_FrameBuf[5][5] = 1;
        r_FrameBuf[6][6] = 1;
        r_FrameBuf[7][7] = 1;
        r_FrameBuf[8][8] = 1;
        r_FrameBuf[9][9] = 1;
        r_FrameBuf[10][10] = 1;
        r_FrameBuf[11][11] = 1;
        r_FrameBuf[12][12] = 1;
        r_FrameBuf[13][13] = 1;
        r_FrameBuf[14][14] = 1;
        r_FrameBuf[15][15] = 1;
        r_FrameBuf[16][0] = 1;
        r_FrameBuf[17][1] = 1;
        r_FrameBuf[18][2] = 1;
        r_FrameBuf[19][3] = 1;
        r_FrameBuf[20][4] = 1;
        r_FrameBuf[21][5] = 1;
        r_FrameBuf[22][6] = 1;
        r_FrameBuf[23][7] = 1;

        #1 begin
            print_fb();
            print_stripes();
        end
    end

endmodule