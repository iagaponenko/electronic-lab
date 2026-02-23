`timescale 1 ns / 1 ps

// The top module for the trivial led blinker.

module main

    (
        // 12 MHz
        input i_Clk,
        input reg [1:0] i_Button,

        output reg [2:0] o_Led_RGB,     // 2:blue 1:green 0:red
        output reg [1:0] o_Led_Green
    );

    typedef enum {RED = 0, GREEN = 1, BLUE = 2} rgb_channel_selectors;

    assign clk = i_Clk;
    assign rst = i_Button[0];

    // 32 million cycles, or 2.[6] (~2.67) seconds before overflow
    reg [24:0] counter = '0;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= '0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

    assign o_Led_RGB[RED]   =  counter[24];
    assign o_Led_RGB[GREEN] =  counter[23];
    assign o_Led_RGB[BLUE]  = ~counter[23];

    assign o_Led_Green[0] =  counter[24];
    assign o_Led_Green[1] = ~counter[24];

endmodule
