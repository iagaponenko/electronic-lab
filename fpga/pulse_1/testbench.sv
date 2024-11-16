// Testbench

`timescale 1ns/1ps

module test;

  reg clk;
  reg rst;
  reg a;
  reg x;

  pulse pulse_0(.clk(clk), .rst(rst), .a(a), .x(x));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);

    clk = 1'b0;
    rst = 1'b1;
    a = 1'b0;

    #10 rst = 1'b0;

    repeat (25) begin
      #($urandom_range(0, 47) * 1ns) a = ~a;
    end
    repeat (25) begin
      #($urandom_range(10, 42) * 1ns) a = ~a;
    end

    #10 $finish;
  end
  
  always #5 clk = ~clk;

endmodule

