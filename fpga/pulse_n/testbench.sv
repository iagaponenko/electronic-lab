// Testbench

`timescale 1ns/1ps

module test;

  localparam WIDTH = 8;

  reg clk;
  reg rst;
  reg [WIDTH-1:0] a;
  reg x;

  pulse_n #(.WIDTH(WIDTH)
           ) pulse_n_0(.clk(clk),
                       .rst(rst),
                       .a(a),
                       .x(x));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);

    clk = 1'b0;
    rst = 1'b1;
    a = '0;

    #10 rst = 1'b0;

    repeat (25) begin
      #($urandom_range(0, 47) * 1ns) a = a + 1;
    end
    repeat (25) begin
      #($urandom_range(10, 42) * 1ns) a = a + 1;
    end

    #10 $finish;
  end
  
  always #5 clk = ~clk;

endmodule

