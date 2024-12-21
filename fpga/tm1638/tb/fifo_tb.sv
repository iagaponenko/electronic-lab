`timescale 1 ns / 1 ps

module fifo_tb;

    localparam  DEPTH      = 4;
    localparam  DATA_WIDTH = 17;
    localparam  ADDR_WIDTH = $clog2(DEPTH);

    // Control signals
    reg                     r_Rst;
    reg                     r_Clk;

    // Data path to write data to the FIFO
    reg                     r_Full;
    reg                     r_Data_Valid;
    reg [DATA_WIDTH-1:0]    r_W_Data;

    // Data path to read data from the FIFO
    reg                     r_Empty;
    reg                     r_Read;
    reg [DATA_WIDTH-1:0]    r_R_Data;

    // Diagnostic signals
    reg [1:0]               r_Diag_State;
    reg [ADDR_WIDTH-1:0]    r_Diag_Buf_W_Addr;
    reg [ADDR_WIDTH-1:0]    r_Diag_Buf_R_Addr;

    fifo
    #(  .DEPTH      (DEPTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) fifo_0 (

        .i_Rst              (r_Rst),
        .i_Clk              (r_Clk),

        .o_Full             (r_Full),
        .i_Data_Valid       (r_Data_Valid),
        .i_Data             (r_W_Data),

        .o_Empty            (r_Empty),
        .i_Read             (r_Read),
        .o_Data             (r_R_Data),

        .o_Diag_State       (r_Diag_State),
        .o_Diag_Buf_W_Addr  (r_Diag_Buf_W_Addr),
        .o_Diag_Buf_R_Addr  (r_Diag_Buf_R_Addr)
    );

    function void init();
        $dumpfile("fifo.vcd");
        $dumpvars(0);
        $monitor("%d: r_Empty=%b r_Full=%b", $time, r_Empty, r_Full);
        r_Data_Valid = 0;
        r_W_Data = 8'h0;
        r_Read = 0;
    endfunction

    initial begin
        init();

        @(negedge r_Clk);
        @(negedge r_Clk);

        // Make sure the FIFO is empty after the initial reset
        assert(r_Empty == 1) 			    else $error("r_Empty=", r_Empty);
        assert(r_Full == 0)  			    else $error("r_Full=", r_Full);
        assert(r_Diag_State == 0)           else $error("r_Diag_State=", r_Diag_State);
        assert(r_Diag_Buf_W_Addr == 2'h0)   else $error("r_Diag_Buf_W_Addr=", r_Diag_Buf_W_Addr);
        assert(r_Diag_Buf_R_Addr == 2'h0)   else $error("r_Diag_Buf_R_Addr=", r_Diag_Buf_R_Addr);

        #2000
        $finish;

    end

    // Clock generator
    initial begin
        r_Clk = 1'b0;
        forever #5 r_Clk = ~r_Clk;
    end

    // Simulate the initial reset
    initial begin
        r_Rst = 1;
        @(negedge r_Clk) r_Rst = 0;
    end

    // // Simulate the initial reset and then random resets
    // always begin
    //     r_Rst = 1;
    //     @(negedge r_Clk) r_Rst = 0;
    //     forever #($urandom_range(10, 240) * 1ns) begin
    //         @(negedge r_Clk) r_Rst = 1;
    //         @(negedge r_Clk) r_Rst = 0;
    //     end
    // end

    // initial begin
    //     repeat (10) begin
    //         @(negedge r_Clk);
    //         if (~r_Full) begin
    //             r_W_Data = r_W_Data + 1;
    //             r_Data_Valid = 1;
    //             @(negedge r_Clk);
    //             r_Data_Valid = 0;
    //             @(negedge r_Clk);
    //             @(negedge r_Clk);
    //         end
    //         // else begin
    //         //     r_Data_Valid = 0;
    //         // end
    //     end
    // end
    always begin
        forever #($urandom_range(5, 35) * 1ns) begin
            @(negedge r_Clk) begin
                if (~r_Full) begin
                    r_W_Data = r_W_Data + 1;
                    r_Data_Valid = 1;
                    @(negedge r_Clk);
                    r_Data_Valid = 0;
                end
            end
        end
    end
    // initial begin
    //     repeat (20) begin
    //         @(negedge r_Clk);
    //         if (~r_Empty) begin
    //             r_Read = 1;
    //             @(negedge r_Clk);
    //             r_Read = 0;
    //         end
    //         // else begin
    //         //     r_Read = 0;
    //         // end
    //     end
    // end
    reg [DATA_WIDTH-1:0] r_R_Data_expected;
    reg r_R_Data_match;
    initial begin
        r_R_Data_expected = 8'h1;
        r_R_Data_match = 1;
    end
    always begin
        forever #($urandom_range(10, 40) * 1ns) begin
            @(negedge r_Clk) begin
                if (~r_Empty) begin
                    r_R_Data_match = r_R_Data == r_R_Data_expected;
                    assert(r_R_Data_match) else $error("r_R_Data=", r_R_Data, " r_R_Data_expected=", r_R_Data_expected);
                    r_R_Data_expected = r_R_Data_expected + 1;
                    r_Read = 1;
                    @(negedge r_Clk);
                    r_Read = 0;
                end
            end
        end
    end
endmodule
