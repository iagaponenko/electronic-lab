`timescale 1 ns / 1 ps

module encoder_tb;

    reg r_Rst;
    reg r_Clk;
    reg r_A;
    reg r_B;
    reg r_Left;
    reg r_Right;

    encoder encoder (
        .i_Rst  (r_Rst),
        .i_Clk  (r_Clk),
        .i_A    (r_A),
        .i_B    (r_B),
        .o_Left (r_Left),
        .o_Right(r_Right)
    );


    function void init();
        $dumpfile("encoder.vcd");
        $dumpvars(0);
        r_Rst = 1'b1;
        r_Clk = 1'b0;
        r_A = 1'b0;
        r_B = 1'b0;
    endfunction

    initial begin
        init();
        #1 r_Rst = 1'b0;
        #2000 $finish;
    end

    always begin
        forever #($urandom_range(10, 40) * 1ns) begin
            @ (negedge r_Clk);
            r_B = $urandom_range(0, 1);
            @ (negedge r_Clk);
            @ (negedge r_Clk);
            r_A = $urandom_range(0, 1);
        end
    end

    always begin
        #1 r_Clk = ~r_Clk;
    end
    always begin
        forever #($urandom_range(100, 200) * 1ns) begin
            r_Rst = 1'b1;
            #5 r_Rst = 1'b0;
        end
    end

endmodule
