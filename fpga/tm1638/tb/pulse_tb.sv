`timescale 1 ns / 1 ps

module pulse_tb;

    parameter RESET_CYCLES = 2;

    reg r_Rst;
    reg r_Clk;
    reg r_Data;
    reg r_Pulse_Rise;
    reg r_Pulse_Rise_Series;
    reg r_Pulse_Fall;
    reg r_Pulse_Fall_Series;

    // Make pulses on the rising edge of the input signal.
    pulse
    pulse_rise (
        .i_Rst  (r_Rst),
        .i_Clk  (r_Clk),
        .i_Data (r_Data),
        .o_Data (r_Pulse_Rise)
    );


    // Make a series of pulses on the rising edge of the input signal.
    pulse #(
        .RESET_CYCLES(RESET_CYCLES))
    pulse_rise_series (
        .i_Rst  (r_Rst),
        .i_Clk  (r_Clk),
        .i_Data (r_Data),
        .o_Data (r_Pulse_Rise_Series)
    );

    // Make pulses on the falling edge of the input signal.
    pulse #(
        .ON_FALL(1))
    pulse_fall (
        .i_Rst  (r_Rst),
        .i_Clk  (r_Clk),
        .i_Data (r_Data),
        .o_Data (r_Pulse_Fall)
    );

    // Make a series of pulses on the falling edge of the input signal.
    pulse #(
        .RESET_CYCLES(RESET_CYCLES),
        .ON_FALL(1))
    pulse_fall_series (
        .i_Rst  (r_Rst),
        .i_Clk  (r_Clk),
        .i_Data (r_Data),
        .o_Data (r_Pulse_Fall_Series)
    );

    function void init();
        $dumpfile("pulse.vcd");
        $dumpvars(0);
        r_Rst = 1'b1;
        r_Clk = 1'b0;
        r_Data = 1'b0;
    endfunction

    initial begin
        init();
        #1 r_Rst = 1'b0;
        #400 $finish;
    end

    always begin
        forever #($urandom_range(10, 40) * 1ns) r_Data = ~r_Data;
    end

    always begin
        #1 r_Clk = ~r_Clk;
    end
    always begin
        forever #($urandom_range(30, 80) * 1ns) begin
            r_Rst = 1'b1;
            #5 r_Rst = 1'b0;
        end
    end

endmodule
