`timescale 1 ns / 1 ps

module tm1638_driver_tb;

    import tm1638_types::*;
    import tm1638_driver_types::*;

    parameter   STIMUL_CLK_CYCLES_DELAY = 10;

    reg         r_Rst;
    reg         r_Clk;

    segments_t  r_Segments;
    leds_t      r_Leds;
    reg         r_Segments_Valid;

    reg         r_SPI_FIFO_Full;
    reg [16:0]  r_Data;
    reg         r_Write;

    state_t     r_Diag_State;
    grid_t      r_Diag_Grid;
    segments_t  r_Diag_Segments;
    leds_t      r_Diag_Leds;

    tm1638_driver
        tm1638_driver_diag_0 (
            .i_Rst          (r_Rst),
            .i_Clk          (r_Clk),

            .i_Segments     (r_Segments),
            .i_Leds         (r_Leds),
            .i_Valid        (r_Segments_Valid),

            .i_SPI_FIFO_Full(r_SPI_FIFO_Full),
            .o_Data         (r_Data),
            .o_Write        (r_Write),

            .o_Diag_State   (r_Diag_State),
            .o_Diag_Grid    (r_Diag_Grid),
            .o_Diag_Segments(r_Diag_Segments),
            .o_Diag_Leds    (r_Diag_Leds)
        );

    tm1638_stimulus
        #(  .STIMUL_CLK_CYCLES_DELAY (STIMUL_CLK_CYCLES_DELAY)
        ) tm1638_stimulus_0 (
            .i_Rst      (r_Rst),
            .i_Clk      (r_Clk),

            .o_Segments (r_Segments),
            .o_Leds     (r_Leds),
            .o_Valid    (r_Segments_Valid)
        );

    function void init();
        $dumpfile("tm1638_driver.vcd");
        $dumpvars(2);
        $monitor("%d: r_Segments: %b r_Leds: %b", $time, r_Segments, r_Leds);
        r_Rst           = 1'b1;
        r_Clk           = 1'b0;
        r_SPI_FIFO_Full = 1'b0;
    endfunction

    initial begin
        init();
        @(negedge r_Clk) r_Rst = 1'b0;
        repeat(2000) @(negedge r_Clk);
        $finish;
    end

    // Simulate random fullness of the SPI FIFO
    always begin
        #($urandom_range(20, 120) * 1ns) begin
            @(posedge r_Clk) r_SPI_FIFO_Full = ~r_SPI_FIFO_Full;
        end
    end

    always #5 r_Clk = ~r_Clk;

endmodule

