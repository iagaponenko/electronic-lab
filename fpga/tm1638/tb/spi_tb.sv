`timescale 1 ns / 1 ps

module spi_tb;

    localparam  CYCLES = 4;

    reg         r_Rst;
    reg         r_Clk;

    reg         r_Busy;
    reg         r_Data_Ready;
    reg [17:0]  r_Data;

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

            .o_SPI_Stb      (r_SPI_Stb),
            .o_SPI_Clk      (r_SPI_Clk),
            .io_SPI_Dio     (r_SPI_Dio),

            .o_Diag_State   (r_Diag_State),
            .o_Diag_Data    (r_Diag_Data),
            .o_Diag_Addr    (r_Diag_Addr)
        );

    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(1);
        
        r_Rst = 1;
        r_Clk = 0;
        r_Data_Ready = 0;
        r_Data       = 17'b0_00000000_00000001;

        @(negedge r_Clk) r_Rst = 0;

        repeat (120) begin
        @(negedge r_Clk) begin
            if (~r_Busy) r_Data_Ready = 1;
        end
        @(negedge r_Clk)
            if (r_Data_Ready) begin
                r_Data_Ready = 0;
                r_Data       = {r_Data[15:0],r_Data[16]};
            end
        end

        @(negedge r_Clk) begin
            r_Data_Ready = 0;
            r_Data       = 17'b1_00000000_00000101;
        end
        repeat (120) begin
        @(negedge r_Clk) begin
            if (~r_Busy) r_Data_Ready = 1;
        end
        @(negedge r_Clk)
            if (r_Data_Ready) begin
                r_Data_Ready = 0;
                r_Data       = {r_Data[15:0],r_Data[16]};
            end
        end

        $finish;
    end

    always #5 r_Clk = ~r_Clk;

endmodule