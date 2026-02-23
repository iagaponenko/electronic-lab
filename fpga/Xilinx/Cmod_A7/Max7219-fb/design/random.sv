`timescale 1 ns / 1 ps

// The random number generator based on a Linear Feedback Shift Register (LFSR).

module random

    #(  parameter NUM_BITS = 4  // The number of bits in the random number
    )(
        input   i_Clk,
        input   i_Enable,   // Set on the positive edge of the clock to run RNG
         
        output [NUM_BITS-1:0]   o_Random_Data,  // The current value of the random number
        output                  o_Random_Done
    );
 
    reg r_Seed_DV;
    reg [NUM_BITS-1:0] r_Seed_Data = {1'b1,{(NUM_BITS-1){1'b0}}};

    // The state machine is needed for the one time pulse of the Seed Data Valid (DV) signal
    // to the LFSR module. It's needed to load the seed value into the LFSR at the beginning
    // of operation.

    localparam STATE_IDLE        = 1'b0;
    localparam STATE_SEED_LOADED = 1'b1;
    reg r_State = STATE_IDLE;

    always @(negedge i_Clk) begin
        if (i_Enable == 1'b1) begin
            case (r_State)
                STATE_IDLE: begin
                    r_Seed_DV <= 1'b1;
                    r_State <= STATE_SEED_LOADED;
                end
                STATE_SEED_LOADED: begin
                    r_Seed_DV <= 1'b0;
                    r_State <= STATE_SEED_LOADED;
                end
            endcase
        end
    end

    lfsr
        #(  .NUM_BITS (NUM_BITS)
        ) lfsr_0 (
            .i_Clk      (i_Clk),
            .i_Enable   (i_Enable),
            .i_Seed_DV  (r_Seed_DV),
            .i_Seed_Data(r_Seed_Data),
            .o_LFSR_Data(o_Random_Data),
            .o_LFSR_Done(o_Random_Done)
        );

endmodule
