`timescale 1 ns / 1 ps

module random_tb ();
 
    localparam NUM_BITS = 4;
    
    reg r_Clk;
    reg r_Enable;

    wire [NUM_BITS-1:0] w_Random_Data;
    wire w_Random_Done;
    
    random
        #(  .NUM_BITS   (NUM_BITS)
        ) rand_0 (
            .i_Clk          (r_Clk),
            .i_Enable       (r_Enable),
            .o_Random_Data  (w_Random_Data),
            .o_Random_Done  (w_Random_Done)
        );
  
    initial begin
        $dumpfile("random.vcd");
        $dumpvars(0);
        r_Clk = 1'b0;
        @(negedge r_Clk); r_Enable = 1'b1;
        @(negedge r_Clk); r_Enable = 1'b0;
        #5;
        @(negedge r_Clk); r_Enable = 1'b1;
        #64 $finish;
    end

    always @(*) begin
        #1 r_Clk <= ~r_Clk;
    end
   
endmodule
