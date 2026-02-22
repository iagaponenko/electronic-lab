// Testbench for counter16

`timescale 1ns/1ps

module test;

  reg clk;
  reg rst;
  wire [15:0] count;

  counter16 counter16_0 (.clk(clk),
                         .rst(rst),
                         .count(count));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);

    clk = 1'b0;
    rst = 1'b1;

    #10 rst = 1'b0;

    #2000 $finish;
  end

  always #5 clk = ~clk;

  // Random reset.
  always begin
    #($urandom_range(60, 120) * 1ns) rst = 1'b1;
    #10 rst = 1'b0;
    assert(count == 16'h0000)
      else $error("%t: count(%h) != 0x0000 after reset", $time, count);
  end

endmodule
