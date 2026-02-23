`timescale 1 ns / 1 ps

module lfsr_tb ();
 
    localparam NUM_BITS = 4;
    
    reg r_Clk;
    reg r_Enable;
    reg r_Seed_DV;
    reg [NUM_BITS-1:0] r_Seed_Data = {1'b1,{(NUM_BITS-1){1'b0}}};

    wire [NUM_BITS-1:0] w_LFSR_Data;
    wire w_LFSR_Done;
    
    lfsr
        #(  .NUM_BITS(NUM_BITS)
        ) lfsr_0 (
            .i_Clk(r_Clk),
            .i_Enable(r_Enable),
            .i_Seed_DV(r_Seed_DV),
            .i_Seed_Data(r_Seed_Data),
            .o_LFSR_Data(w_LFSR_Data),
            .o_LFSR_Done(w_LFSR_Done)
        );
  
    initial begin
        $dumpfile("lfsr.vcd");
        $dumpvars(0);
        r_Clk = 1'b0;
        r_Enable = 1'b1;
        r_Seed_DV = 1'b1;
        #2 r_Seed_DV = ~r_Seed_DV;
        #62 $finish;
    end

    always @(*) begin
        #1 r_Clk <= ~r_Clk;
    end
   
endmodule
