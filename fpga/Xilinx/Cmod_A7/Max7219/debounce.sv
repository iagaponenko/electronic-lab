`timescale 1 ns / 1 ps

// Debounce module:
//
// ------------------------------------------------------------------------------------------
//
// The input data is debounced. The output data is high when the input data is high for
// DEBOUNCE_CYCLES clock cycles. The output data is low when the input data is low.
//
// ------------------------------------------------------------------------------------------

module debounce
    #(  parameter   DEBOUNCE_CYCLES = 4
    )(
        input       i_Clk,
        input       i_Data,
        output reg  o_Data
    );

    integer     r_Cycles = 0;
    reg         r_Data = 0;

    always @(posedge i_Clk) begin
        if (i_Data) begin
            if (r_Cycles == DEBOUNCE_CYCLES) begin
                r_Cycles <= 0;
                r_Data   <= 1;
            end
            else begin
                r_Cycles <= r_Cycles + 1;
            end
        end
        else begin
            r_Cycles <= 0;
            r_Data   <= 0;
        end
    end

    assign o_Data = r_Data;

endmodule