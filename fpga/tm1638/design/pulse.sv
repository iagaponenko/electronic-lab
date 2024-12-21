`timescale 1 ns / 1 ps

// Pulse module:
//
// ------------------------------------------------------------------------------------------
//
// The output is sent as a pulse which is high for one clock cycle when the input signal
// changes from low to high. The output is low otherwise. Changes are happening on the
// negative edge of the clock.
//
// ------------------------------------------------------------------------------------------

module pulse
    (
        input       i_Rst,
        input       i_Clk,
        input       i_Data,
        output reg  o_Data
    );

    reg r_Data_Prev;
    reg r_Data;
    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Data_Prev <= i_Data;
            r_Data <= 1'b0;
        end
        else begin
            r_Data_Prev <= i_Data;
            r_Data <= ~r_Data_Prev & i_Data;
        end
    end
    assign o_Data = r_Data;

endmodule
