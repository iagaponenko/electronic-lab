`timescale 1 ns / 1 ps

module pulse_tb;

    reg         r_Rst;
    reg         r_Clk;
    reg         r_Data;
    reg         r_Pulse;

    // Make pulses on the falling edge of the clock.
    pulse pulse_0 (
        .i_Rst  (r_Rst),
        .i_Clk  (r_Clk),
        .i_Data (r_Data),
        .o_Data (r_Pulse)
    );

    reg         r_Pulse_P;

    // Make pulses on the rising edge of the clock by inverting the clock.
    pulse pulse_1 (
        .i_Rst  (r_Rst),
        .i_Clk  (~r_Clk),
        .i_Data (r_Data),
        .o_Data (r_Pulse_P)
    );

    // Make the half-period pulses. Note that this implementation doesn't guarantee that the
    // pulse will happen on a specific edge of the clock. It will happen on the edge of the delayed
    // pulse. See the simulation waveform for more details.
    wire r_Pulse_Half_Period = r_Pulse & r_Pulse_P;

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
        #200 $finish;
    end

    always begin
        forever #($urandom_range(10, 40) * 1ns) r_Data = ~r_Data;
    end

    always begin
        #1 r_Clk = ~r_Clk;
    end
    always begin
        forever #($urandom_range(15, 30) * 1ns) begin
            r_Rst = ~r_Rst;
        end
    end

endmodule
