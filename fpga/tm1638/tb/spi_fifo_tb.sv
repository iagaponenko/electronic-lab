`timescale 1 ns / 1 ps

module spi_fifo_tb;

    localparam  SPI_CYCLES = 0;
    localparam  SPI_READ_DELAY_CYCLES = 0;
    localparam  SPI_READ_WIDTH = 32;
    localparam  FIFO_DEPTH = 2;

    reg         r_Rst;
    reg         r_Clk;

    reg         r_FIFO_Full;
    reg         r_Data_Valid;
    reg [17:0]  r_Data;

    reg [SPI_READ_WIDTH-1:0]    r_Out_Data;

    reg         r_SPI_Stb;
    reg         r_SPI_Clk;
    reg         r_SPI_Dio;

    reg         r_Diag_FIFO_Read;
    reg [17:0]  r_Diag_FIFO_RData;
    reg         r_Diag_FIFO_Empty;
    reg         r_Diag_SPI_Data_Rdy;
    reg         r_Diag_SPI_Busy;

    spi_fifo
        #(  .SPI_CYCLES             (SPI_CYCLES),
            .SPI_READ_DELAY_CYCLES  (SPI_READ_DELAY_CYCLES),
            .SPI_READ_WIDTH         (SPI_READ_WIDTH),
            .FIFO_DEPTH             (FIFO_DEPTH)
        ) spi_fifo_0 (
            .i_Rst              (r_Rst),
            .i_Clk              (r_Clk),

            .o_FIFO_Full        (r_FIFO_Full),
            .i_Data_Valid       (r_Data_Valid),
            .i_Data             (r_Data),

            .o_Data             (r_Out_Data),

            .o_SPI_Stb          (r_SPI_Stb),
            .o_SPI_Clk          (r_SPI_Clk),
            .io_SPI_Dio         (r_SPI_Dio),

            .o_Diag_FIFO_Read   (r_Diag_FIFO_Read),
            .o_Diag_FIFO_RData  (r_Diag_FIFO_RData),
            .o_Diag_FIFO_Empty  (r_Diag_FIFO_Empty),
            .o_Diag_SPI_Data_Rdy(r_Diag_SPI_Data_Rdy),
            .o_Diag_SPI_Busy    (r_Diag_SPI_Busy)
        );

    function void init();
        $dumpfile("spi_fifo.vcd");
        $dumpvars(2);
        $monitor("%d: r_Data_Valid=%b r_FIFO_Full=%b", $time, r_Data_Valid, r_FIFO_Full);

        r_Rst = 1'b1;
        r_Clk = 1'b0;
        r_Data_Valid = 0;
        r_Data       = 17'b0_00000000_00000001;
    endfunction

    initial begin
        init();

        @(negedge r_Clk) r_Rst = 1'b0;

        repeat(80) begin
            @(negedge r_Clk)
                if (~r_FIFO_Full) r_Data_Valid = 1;
            @(negedge r_Clk)
                if (r_Data_Valid) begin
                    r_Data_Valid = 0;
                    if (r_Data == 17'b1_00000000_0000000) r_Data = 17'b0_00000000_00000001;
                    else                                  r_Data = {r_Data[15:0],1'b0};
                end
        end

        repeat(100) @(negedge r_Clk);

        $finish;

    end

    // Clock generator
    always #5 r_Clk = ~r_Clk;

endmodule
