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

endmodule