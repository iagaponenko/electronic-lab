// Testbench

`timescale 1ns/1ps

module test;

  localparam WIDTH = 8;
  localparam CLOCKS_PER_INCREMENT = 1;
  localparam MIN_VALUE = 0;
  localparam MAX_VALUE = 5;
  reg clk;
  reg rst;
  reg [WIDTH-1:0] count;

  counter #(.WIDTH(WIDTH),
            .CLOCKS_PER_INCREMENT(CLOCKS_PER_INCREMENT),
            .MIN_VALUE(MIN_VALUE),
            .MAX_VALUE(MAX_VALUE)
           ) counter_0 (.clk(clk),
                        .rst(rst),
                        .count(count));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);

    clk = 1'b0;
    rst = 1'b1;

    #10 rst = 1'b0;

    #600 $finish;
  end
  
  always #5 clk = ~clk;

  // Random reset.
  always begin
    #($urandom_range(60, 120) * 1ns) rst = 1'b1;
    #10 rst = 1'b0;
    assert(count == MIN_VALUE)
      else $error("%t: count(%d) != MIN_VALUE(%d)", $time, count, MIN_VALUE);
  end

endmodule

