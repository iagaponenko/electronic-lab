`timescale 1 ns / 1 ps

module debounce_tb;

    localparam  DEBOUNCE_CYCLES = 4;

    reg         r_Rst;
    reg         r_Clk;
    reg         r_Data;
    reg         r_Debounced_Data;

    debounce
        #(  .DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)
        ) debounce_0 (
            .i_Clk  (r_Clk),
            .i_Data (r_Data),
            .o_Data (r_Debounced_Data)
        );

    function void init();
        $dumpfile("debounce.vcd");
        $dumpvars(0);
        r_Rst = 1'b1;
        r_Clk = 1'b0;
        r_Data = 1'b0;
    endfunction

    initial begin
        init();
        #1 r_Rst = 1'b0;
        #2 r_Data <= ~r_Data;
        #3 r_Data <= ~r_Data;
        #7 r_Data <= ~r_Data;
        #3 r_Data <= ~r_Data;
        #30 r_Data <= ~r_Data;
        #50 r_Data <= ~r_Data;
        #200 $finish;
    end

    always begin
        #1 r_Clk = ~r_Clk;
    end

endmodule
