`timescale 1 ns / 1 ps

// Segments are updated on the negative edge of the clock every STIMUL_CLK_CYCLES_DELAY + 1 cycles.
// The segments are updated in a round-robin fashion.

module tm1638_stimulus

    import tm1638_types::*;
    import tm1638_driver_types::*;

    #(
        parameter   STIMUL_CLK_CYCLES_DELAY = 0
    )(
        // Control signals
        input               i_Rst,
        input               i_Clk,

        // Output data for the 7-segment display (8 digits, 8 segments) and LEDs above the digits
        output segments_t   o_Segments, // [grid][segment]
        output leds_t       o_Leds,     // [grid]
        output reg          o_Valid     // Data is valid and ready to be sent to TM1638
    );

    integer     r_Cycles;
    grid_t      r_Grid;
    reg [7:0]   r_Segment;
    reg [7:0]   r_Leds;
    reg         r_Valid;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Cycles   <=  0;
            r_Grid     <= '0;
            r_Segment  <= 8'h0;
            r_Leds     <= 8'h0;
            o_Segments <= '0;
            o_Leds     <= '0;
            r_Valid    <=  1'b0;
        end
        else begin
            if (r_Valid) begin
                r_Valid <= 0;
            end
            else begin
                if (r_Cycles == STIMUL_CLK_CYCLES_DELAY) begin
                    r_Cycles           <= 0;
                    o_Segments[r_Grid] <= r_Segment;
                    o_Leds             <= r_Leds;
                    r_Valid            <= 1'b1;
                    if (r_Grid == 3'h7) begin
                        r_Grid <= '0;
                        if (r_Segment == 8'hff) begin
                            r_Segment <= '0;
                        end
                        else begin
                            r_Segment <= r_Segment + 1'b1;
                        end
                    end
                    else begin
                        r_Grid <= r_Grid + 1'b1;
                    end
                    r_Leds <= r_Leds + 1'b1;
                end
                else begin
                    r_Cycles <= r_Cycles + 1;
                end
            end
        end
    end
    assign o_Valid = r_Valid;
endmodule
