`timescale 1 ns / 1 ps

// Segments and leds are updated on the negative edge of the clock when changes in the input keys
// are detected.

module tm1638_stimulus_keys2cntr

    import tm1638_types::*;
    import tm1638_driver_types::*;
    import led7_types::*;

    #(
        parameter   STIMUL_CLK_CYCLES_DELAY = 0,
        parameter   SPI_READ_WIDTH          = 32    // The width of the data read from the SPI device (must be a power of 2)
    )(
        // Control signals
        input   i_Rst,
        input   i_Clk,

        // Input data (values of keys) read from the SPI device
        input reg [SPI_READ_WIDTH-1:0]  i_Data_Pulse,   // 1 clock cycle long pulses on keys scanned from the SPI device

        // Output data for the 7-segment display (8 digits, 8 segments) and LEDs above the digits
        output segments_t   o_Segments, // [grid][segment]
        output leds_t       o_Leds,     // [grid]
        output reg          o_Valid     // Data is valid and ready to be sent to TM1638
    );

    segments_t  r_Bin_Segments = 64'h0;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Bin_Segments <= 64'h0;
        end
        else begin
            r_Bin_Segments[DIGIT0] <= r_Bin_Segments[DIGIT0] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT0] + i_Data_Pulse[KEY0];
            r_Bin_Segments[DIGIT1] <= r_Bin_Segments[DIGIT1] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT1] + i_Data_Pulse[KEY1];
            r_Bin_Segments[DIGIT2] <= r_Bin_Segments[DIGIT2] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT2] + i_Data_Pulse[KEY2];
            r_Bin_Segments[DIGIT3] <= r_Bin_Segments[DIGIT3] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT3] + i_Data_Pulse[KEY3];
            r_Bin_Segments[DIGIT4] <= r_Bin_Segments[DIGIT4] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT4] + i_Data_Pulse[KEY4];
            r_Bin_Segments[DIGIT5] <= r_Bin_Segments[DIGIT5] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT5] + i_Data_Pulse[KEY5];
            r_Bin_Segments[DIGIT6] <= r_Bin_Segments[DIGIT6] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT6] + i_Data_Pulse[KEY6];
            r_Bin_Segments[DIGIT7] <= r_Bin_Segments[DIGIT7] == 8'hF ? 8'h0 : r_Bin_Segments[DIGIT7] + i_Data_Pulse[KEY7];
        end
    end


    integer     r_Cycles;
    reg         r_Valid;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Cycles   <= 0;
            r_Valid    <= 1'b0;
        end
        else begin
            if (r_Valid) begin
                r_Valid <= 0;
            end
            else begin
                if (r_Cycles == STIMUL_CLK_CYCLES_DELAY) begin
                    r_Cycles <= 0;
                    r_Valid  <= 1'b1;
                end
                else begin
                    r_Cycles <= r_Cycles + 1;
                end
            end
        end
    end
    always_comb begin
        for (int i = 0; i < 8; i++) begin
            o_Segments[i] = bin2led7(r_Bin_Segments[i]);
        end
    end

    assign o_Leds[LED0] = r_Bin_Segments[DIGIT0] != 8'h0;
    assign o_Leds[LED1] = r_Bin_Segments[DIGIT1] != 8'h0;
    assign o_Leds[LED2] = r_Bin_Segments[DIGIT2] != 8'h0;
    assign o_Leds[LED3] = r_Bin_Segments[DIGIT3] != 8'h0;
    assign o_Leds[LED4] = r_Bin_Segments[DIGIT4] != 8'h0;
    assign o_Leds[LED5] = r_Bin_Segments[DIGIT5] != 8'h0;
    assign o_Leds[LED6] = r_Bin_Segments[DIGIT6] != 8'h0;
    assign o_Leds[LED7] = r_Bin_Segments[DIGIT7] != 8'h0;

    assign o_Valid = r_Valid;
endmodule
