`timescale 1 ns / 1 ps

module pattern_conwaylife_tb ();
 
    localparam DISP_ROWS     = 1;
    localparam DISP_COLUMNS  = 1;
    localparam CLK_FREQ_HZ   = 8;  // 8 Hz
    reg r_Clk;
    reg r_Rst;
    reg r_AliensArrived;
    wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] w_MAX7219_DataStream;

    
    pattern_conwaylife
        #(  .DISP_ROWS      (DISP_ROWS),
            .DISP_COLUMNS   (DISP_COLUMNS),
            .CLK_FREQ_HZ    (CLK_FREQ_HZ)
        ) pattern_conwaylife_0 (
            .i_Clk                  (r_Clk),
            .i_Rst                  (r_Rst),
            .i_AliensArrived        (r_AliensArrived),
            .o_MAX7219_DataStream   (w_MAX7219_DataStream)
        ); 
  
    initial begin
        $dumpfile("pattern_conwaylife.vcd");
        $dumpvars(0);
        r_Clk = 1'b0;
        r_Rst = 1'b0;
        r_AliensArrived = 1'b0;
        #1000 $finish;
    end

    always @(*) begin
        #1 r_Clk <= ~r_Clk;
    end
   
endmodule