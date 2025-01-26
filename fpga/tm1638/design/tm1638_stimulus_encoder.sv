`timescale 1 ns / 1 ps

// Segments and leds are updated on the negative edge of the clock when the encoder rotation is
// is detected.

module tm1638_stimulus_encoder

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

        // Encoder signals (1 clock cycle long pulses starting on the positive edge of the clock)
        input   i_Encoder_Btn,
        input   i_Encoder_Left,
        input   i_Encoder_Right,

        // Output data for the 7-segment display (8 digits, 8 segments) and LEDs above the digits
        output segments_t   o_Segments, // [grid][segment]
        output leds_t       o_Leds,     // [grid]
        output reg          o_Valid     // Data is valid and ready to be sent to TM1638
    );

    segments_t  r_Bin_Segments = 64'h0;
    tm1638_digit_pos_t r_Digit = DIGIT0;

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Bin_Segments <= 64'h0;
            r_Digit <= DIGIT0;
        end
        else begin
            if (i_Encoder_Btn) begin
                r_Bin_Segments[r_Digit] <= 8'h0;
            end
            else if (i_Encoder_Left) begin
                if (r_Bin_Segments[r_Digit] == 8'h0) begin
                    r_Bin_Segments[r_Digit] <= 8'hF;
                end
                else begin
                    r_Bin_Segments[r_Digit] <= r_Bin_Segments[r_Digit] - 1'b1;
                end
            end
            else if (i_Encoder_Right) begin
                if (r_Bin_Segments[r_Digit] == 8'hF) begin
                    r_Bin_Segments[r_Digit] <= 8'h0;
                end
                else begin
                    r_Bin_Segments[r_Digit] <= r_Bin_Segments[r_Digit] + 1'b1;
                end
            end
            else if (i_Data_Pulse[KEY0] == 1'b1) begin
                r_Digit <= DIGIT0;
            end
            else if (i_Data_Pulse[KEY1] == 1'b1) begin
                r_Digit <= DIGIT1;
            end
            else if (i_Data_Pulse[KEY2] == 1'b1) begin
                r_Digit <= DIGIT2;
            end
            else if (i_Data_Pulse[KEY3] == 1'b1) begin
                r_Digit <= DIGIT3;
            end
            else if (i_Data_Pulse[KEY4] == 1'b1) begin
                r_Digit <= DIGIT4;
            end
            else if (i_Data_Pulse[KEY5] == 1'b1) begin
                r_Digit <= DIGIT5;
            end
            else if (i_Data_Pulse[KEY6] == 1'b1) begin
                r_Digit <= DIGIT6;
            end
            else if (i_Data_Pulse[KEY7] == 1'b1) begin
                r_Digit <= DIGIT7;
            end
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
        {o_Leds[LED0],o_Leds[LED1],o_Leds[LED2],o_Leds[LED3],o_Leds[LED4],o_Leds[LED5],o_Leds[LED6],o_Leds[LED7]} = 8'h0;
        case (r_Digit)
            DIGIT0: o_Leds[LED0] = 1'b1;
            DIGIT1: o_Leds[LED1] = 1'b1;
            DIGIT2: o_Leds[LED2] = 1'b1;
            DIGIT3: o_Leds[LED3] = 1'b1;
            DIGIT4: o_Leds[LED4] = 1'b1;
            DIGIT5: o_Leds[LED5] = 1'b1;
            DIGIT6: o_Leds[LED6] = 1'b1;
            DIGIT7: o_Leds[LED7] = 1'b1;
        endcase
    end

    assign o_Valid = r_Valid;
endmodule
