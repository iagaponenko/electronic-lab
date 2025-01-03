`timescale 1 ns / 1 ps

module spi_tb;

    localparam  CYCLES = 1;

    reg         r_Rst;
    reg         r_Clk;

    reg         r_Busy;
    reg         r_Data_Ready;
    reg [17:0]  r_Data;

    reg         r_Out_Data_Valid;
    reg [63:0]  r_Out_Data;

    reg         r_SPI_Stb;
    reg         r_SPI_Clk;
    reg         r_SPI_Dio;

    reg [2:0]   r_Diag_State;
    reg [17:0]  r_Diag_Data;
    reg [3:0]   r_Diag_Addr;

    spi
        #(  .CYCLES         (CYCLES)
        ) spi_0 (
            .i_Rst          (r_Rst),
            .i_Clk          (r_Clk),

            .o_Busy         (r_Busy),
            .i_Data_Ready   (r_Data_Ready),
            .i_Data         (r_Data),

            .o_Data_Valid   (r_Out_Data_Valid),
            .o_Data         (r_Out_Data),

            .o_SPI_Stb      (r_SPI_Stb),
            .o_SPI_Clk      (r_SPI_Clk),
            .io_SPI_Dio     (r_SPI_Dio),

            .o_Diag_State   (r_Diag_State),
            .o_Diag_Data    (r_Diag_Data),
            .o_Diag_Addr    (r_Diag_Addr)
        );

    task wait_for_busy;
        while (r_Busy) begin
            @(negedge r_Clk);
        end
    endtask

    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0);
        
        r_Rst = 1;
        r_Clk = 0;
        r_Data_Ready = 0;

        @(negedge r_Clk) r_Rst = 0;

        wait_for_busy;

        r_Data       = 18'b00_00000001_00000001;
        r_Data_Ready = 1;
        @(negedge r_Clk);
        r_Data_Ready = 0;

        wait_for_busy;

        r_Data       = 18'b01_10000000_10000000;
        r_Data_Ready = 1;
        @(negedge r_Clk);
        r_Data_Ready = 0;

        wait_for_busy;

        $finish;
    end

    always #1 r_Clk = ~r_Clk;

endmodule