// Testbench
module test;

  reg clk;
  reg load;
  reg [255:0] data;
  wire [255:0] q;
  int sum_out [255:0];
  int i_out [255:0];
  int i_N_out [255:0];
  
  conwaylife life(.clk(clk),
                  .load(load),
                  .data(data),
                  .q(q),
                  .sum_out(sum_out),
                  .i_out(i_out),
                  .i_N_out(i_N_out));
          
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);
    
    #0 clk = 0; data = 256'h7; load = 0;
    #1 clk = 1; data = 256'h7; load = 1;
    #1 clk = 0; data = 256'h0; load = 0;
    #1 clk = 1; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 0; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 1; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 0; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 1; data = 256'h3; load = 1; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 0; load = 0; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 1; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 0; $display(sum_out); $display(i_out); $display(i_N_out);
    #1 clk = 1; $display(sum_out); $display(i_out); $display(i_N_out);
  end
  

endmodule

