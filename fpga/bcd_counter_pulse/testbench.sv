// Testbench

`timescale 1ns/1ps

module test;

  localparam WIDTH = 8;
  localparam CLOCKS_PER_INCREMENT = 3;
  localparam MIN_VALUE = 0;
  localparam MAX_VALUE = 12;
  localparam BCD_DIGITS = $rtoi($ceil($log10(real'(2**WIDTH-1))));
  localparam BCD_WIDTH = BCD_DIGITS*4;

  reg clk;
  reg rst;
  reg [BCD_WIDTH-1:0] bcd;
  reg updated;

  bcd_counter_pulse #(.WIDTH(WIDTH),
            .CLOCKS_PER_INCREMENT(CLOCKS_PER_INCREMENT),
            .MIN_VALUE(MIN_VALUE),
            .MAX_VALUE(MAX_VALUE)
           ) bcd_counter_pulse_0 (.clk(clk),
                                  .rst(rst),
                                  .bcd(bcd),
                                  .updated(updated));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);

    clk = 1'b0;
    rst = 1'b1;

    #10 rst = 1'b0;

    #1200 $finish;
  end
  
  always #5 clk = ~clk;

  // Random reset.
  always begin
    #($urandom_range(60, 620) * 1ns) rst = 1'b1;
    #10 rst = 1'b0;
  end

endmodule

