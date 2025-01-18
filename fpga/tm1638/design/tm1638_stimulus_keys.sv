`timescale 1 ns / 1 ps

// Segments and leds are updated on the negative edge of the clock when changes in the input keys
// are detected.

module tm1638_stimulus_keys

    import tm1638_types::*;
    import tm1638_driver_types::*;

    #(
        parameter   STIMUL_CLK_CYCLES_DELAY = 0,
        parameter   SPI_READ_WIDTH          = 32    // The width of the data read from the SPI device (must be a power of 2)
    )(
        // Control signals
        input   i_Rst,
        input   i_Clk,

        // Input data (values of keys) read from the SPI device
        input reg [SPI_READ_WIDTH-1:0]  i_Data, // Data read from the SPI after the corresponding command is sent

        // Output data for the 7-segment display (8 digits, 8 segments) and LEDs above the digits
        output segments_t   o_Segments, // [grid][segment]
        output leds_t       o_Leds,     // [grid]
        output reg          o_Valid     // Data is valid and ready to be sent to TM1638
    );

    integer     r_Cycles;
    reg         r_Valid;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Cycles   <= 0;
            o_Segments <= 64'h0;
            o_Leds     <= 8'h0;
            r_Valid    <= 1'b0;
        end
        else begin
            if (r_Valid) begin
                r_Valid <= 0;
            end
            else begin
                if (r_Cycles == STIMUL_CLK_CYCLES_DELAY) begin
                    r_Cycles   <= 0;
                    o_Segments <= {i_Data,i_Data};
                    o_Leds     <= {i_Data[0],i_Data[4],i_Data[8],i_Data[12],i_Data[16],i_Data[20],i_Data[24],i_Data[28]};
                    r_Valid    <= 1'b1;
                end
                else begin
                    r_Cycles <= r_Cycles + 1;
                end
            end
        end
    end
    assign o_Valid = r_Valid;
endmodule
