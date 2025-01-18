`timescale 1 ns / 1 ps

module spi_tb;

    localparam  CYCLES = 1;
    localparam  READ_DELAY_CYCLES = 1;
    localparam  READ_WIDTH = 32;

    reg         r_Rst;
    reg         r_Clk;

    reg         r_Busy;
    reg         r_Data_Ready;
    reg [17:0]  r_Data;

    reg [READ_WIDTH-1:0]    r_Out_Data;

    reg         r_SPI_Stb;
    reg         r_SPI_Clk;
    reg         r_SPI_Dio;

    reg [2:0]   r_Diag_State;
    reg [17:0]  r_Diag_Data;
    reg [3:0]   r_Diag_Addr;

    spi
        #(  .CYCLES             (CYCLES),
            .READ_DELAY_CYCLES  (READ_DELAY_CYCLES),
            .READ_WIDTH         (READ_WIDTH)
        ) spi_0 (
            .i_Rst          (r_Rst),
            .i_Clk          (r_Clk),

            .o_Busy         (r_Busy),
            .i_Data_Ready   (r_Data_Ready),
            .i_Data         (r_Data),

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

    task send_data (input [17:0] data);
        wait_for_busy;
        r_Data       = data;
        r_Data_Ready = 1;
        @(negedge r_Clk);
        r_Data_Ready = 0;
    endtask

    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0);
        
        r_Rst = 1;
        r_Clk = 0;
        r_Data_Ready = 0;

        @(negedge r_Clk) r_Rst = 0;

        send_data(18'b00_00000000_00000001);
        send_data(18'b01_10000000_00000010);
        send_data(18'b10_00000010_00000010);    // read 32 bit data after sending the 8-bit command
        send_data(18'b01_10000000_00000100);
        send_data(18'b10_00000010_00001000);    // read 32 bit data after sending the 8-bit command

        wait_for_busy;
        repeat (200) @(negedge r_Clk);

        $finish;
    end

    always #1 r_Clk = ~r_Clk;

endmodule