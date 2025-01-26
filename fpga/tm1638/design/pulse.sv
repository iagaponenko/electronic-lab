`timescale 1 ns / 1 ps

// Pulse module:
//
// -------------------------------------------------------------------------------------------------
//
// The output is sent as a series of pulses which are high for one clock cycle when the input signal
// changes as specified by the optional parameter ON_FALL. The output is low otherwise. If RESET_CYCLES
// is not 0 then pulses are emitted every RESET_CYCLES clock cycles when the high input is detected.
// Otheriwse a single pulse is emitted. Changes are happening on the negative edge of the clock.
//
// -------------------------------------------------------------------------------------------------

module pulse
    #(
        parameter   RESET_CYCLES    = 0,    // Number of clock cycles between pulses
        parameter   ON_FALL         = 0     // Pulse is emitted on the falling edge of the input signal
    )(
        input       i_Rst,
        input       i_Clk,
        input       i_Data,
        output reg  o_Data
    );

    integer r_Reset_Cycles;

    reg r_Data_Prev;
    reg r_Data;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Reset_Cycles <= 0;
            r_Data_Prev <= i_Data;
            r_Data <= 1'b0;
        end
        else begin
            if (RESET_CYCLES == 0) begin
                r_Data_Prev <= i_Data;
            end
            else begin
                if (r_Reset_Cycles == RESET_CYCLES) begin
                    r_Reset_Cycles <= 0;
                    r_Data_Prev <= ON_FALL ? 1'b1 : 1'b0;
                end
                else begin
                    if (i_Data == ON_FALL ? 1'b1 : 1'b0) begin
                        r_Reset_Cycles <= 0;
                    end
                    else begin
                        r_Reset_Cycles <= r_Reset_Cycles + 1;
                    end
                    r_Data_Prev <= i_Data;
                end
            end
            r_Data <= ON_FALL ? r_Data_Prev & ~i_Data : ~r_Data_Prev & i_Data;
        end
    end
    assign o_Data = r_Data;

endmodule
