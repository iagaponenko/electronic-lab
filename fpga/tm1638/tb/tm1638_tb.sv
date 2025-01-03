`timescale 1 ns / 1 ps

module tm1638_tb;

    import tm1638_driver_types::*;
    import tm1638_types::*;

    localparam  STIMUL_CLK_CYCLES_DELAY = 10;
    localparam  SPI_CYCLES              = 1;
    localparam  SPI_READ_DELAY_CYCLES   = 1;
    localparam  SPI_READ_WIDTH          = 8;
    localparam  FIFO_DEPTH              = 2;

    reg         r_Rst;
    reg         r_Clk;
    reg         r_Stimulus_Next;

    reg         r_SPI_Stb;
    reg         r_SPI_Clk;
    reg         r_SPI_Dio;

    // Diagnostic signals (tm1638)
    reg         r_Diag_Segments_Valid;
    reg         r_Diag_SPI_FIFO_Full;
    reg [17:0]  r_Diag_Data;
    reg         r_Diag_Data_Valid;

    // Diagnostic signals (tm1638->driver)
    state_t     r_Diag_Driver_State;
    grid_t      r_Diag_Driver_Grid;
    segments_t  r_Diag_Driver_Segments;
    leds_t      r_Diag_Driver_Leds;

    tm1638
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SPI_CYCLES                 (SPI_CYCLES),
            .SPI_READ_DELAY_CYCLES      (SPI_READ_DELAY_CYCLES),
            .SPI_READ_WIDTH             (SPI_READ_WIDTH),
            .FIFO_DEPTH                 (FIFO_DEPTH)
        ) tm1638_0 (
            .i_Rst                  (r_Rst),
            .i_Clk                  (r_Clk),
            .i_Stimulus_Next        (r_Stimulus_Next),

            .o_SPI_Stb              (r_SPI_Stb),
            .o_SPI_Clk              (r_SPI_Clk),
            .io_SPI_Dio             (r_SPI_Dio),

            .o_Diag_Segments_Valid  (r_Diag_Segments_Valid),
            .o_Diag_SPI_FIFO_Full   (r_Diag_SPI_FIFO_Full),
            .o_Diag_Data            (r_Diag_Data),
            .o_Diag_Data_Valid      (r_Diag_Data_Valid),

            .o_Diag_Driver_State    (r_Diag_Driver_State),
            .o_Diag_Driver_Grid     (r_Diag_Driver_Grid),
            .o_Diag_Driver_Segments (r_Diag_Driver_Segments),
            .o_Diag_Driver_Leds     (r_Diag_Driver_Leds)
        );

    function void init();
        $dumpfile("tm1638.vcd");
        $dumpvars(0);
        $monitor("%d: r_Diag_Data: %b", $time, r_Diag_Data);
        r_Rst = 1'b1;
        r_Clk = 1'b0;
        r_Stimulus_Next = 1'b0;
    endfunction

    initial begin
        init();
        @(negedge r_Clk) r_Rst = 1'b0;
        repeat(10000) @(negedge r_Clk);
        $finish;
    end

    always @(posedge r_Clk) begin
        #($urandom_range(200, 400) * 1ns) begin
            @(posedge r_Clk) r_Stimulus_Next = 1'b1;
            @(posedge r_Clk) r_Stimulus_Next = 1'b0;
        end
    end

    always #5 r_Clk = ~r_Clk;

endmodule