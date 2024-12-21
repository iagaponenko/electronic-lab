`timescale 1 ns / 1 ps

// Segments are updated on the negative edge of the clock every STIMUL_CLK_CYCLES_DELAY + 1 cycles.
// The segments are have fixed values.

module tm1638_stimulus_fixed

    import tm1638_types::*;
    import tm1638_driver_types::*;

    #(
        parameter   STIMUL_CLK_CYCLES_DELAY = 0,
        parameter   SEG = 8'h00
    )(
        // Control signals
        input               i_Rst,
        input               i_Clk,

        // Output data for the 7-segment display (8 digits, 8 segments)
        output segments_t   o_Segments, // [grid][segment]
        output reg          o_Valid     // Data is valid and ready to be sent to TM1638
    );

    integer     r_Cycles;
    reg         r_Valid;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Cycles   <=  0;
            o_Segments <= '0;
            r_Valid    <=  0;
        end
        else begin
            if (r_Valid) begin
                r_Valid <= 0;
            end
            else begin
                if (r_Cycles == STIMUL_CLK_CYCLES_DELAY) begin
                    r_Cycles <= 0;
                    o_Segments <= {SEG, SEG, SEG, SEG, SEG, SEG, SEG, SEG};
                    r_Valid <= 1;
                end
                else begin
                    r_Cycles <= r_Cycles + 1;
                end
            end
        end
    end
    assign o_Valid = r_Valid;
endmodule
