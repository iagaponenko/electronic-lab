`timescale 1 ns / 1 ps

module main_tb ();
 
    localparam NUM_BITS = 4;
    
    reg r_Clk = 1'b0;
    
    wire [NUM_BITS-1:0] w_LFSR_Data;
    wire w_LFSR_Done;
    
    lfsr
        #(  .NUM_BITS(NUM_BITS)
        ) lfsr_0 (
            .i_Clk(r_Clk),
            .i_Enable(1'b1),
            .i_Seed_DV(1'b0),
            .i_Seed_Data({NUM_BITS{1'b0}}),
            .o_LFSR_Data(w_LFSR_Data),
            .o_LFSR_Done(w_LFSR_Done)
        );
  
    always @(*) begin
        #10 r_Clk <= ~r_Clk;
    end

endmodule
