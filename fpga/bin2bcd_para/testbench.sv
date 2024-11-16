// Testbench
module test;

  localparam BIN_WIDTH = 10;
  localparam BCD_DIGITS = $rtoi($ceil($log10(real'(2**BIN_WIDTH-1))));
  localparam BCD_WIDTH = BCD_DIGITS*4;

  reg [BIN_WIDTH-1:0] bin;
  reg [BCD_WIDTH-1:0] bcd;
  
  wire [3:0] bcd_hundreds = bcd[11:8];
  wire [3:0] bcd_tens     = bcd[ 7:4];
  wire [3:0] bcd_ones     = bcd[ 3:0];

  bin2bcd_para #(.BIN_WIDTH(BIN_WIDTH)) bin2bcd_para_0(
    .bin(bin),
    .bcd(bcd));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);
    $display("BIN_WIDTH:  %d", BIN_WIDTH);
    $display("BCD_DIGITS: %d", BCD_DIGITS);
    $display("BCD_WIDTH:  %d", BCD_WIDTH);

    bin = '0;
    repeat(16) begin
      #1
      $display("%d: %b", bin, bcd);
      bin = bin + 1;
    end
    repeat(2**BIN_WIDTH-2*16) begin
      #1
      bin = bin + 1;
    end
    repeat(16) begin
      #1
      $display("%d: %b", bin, bcd);
      bin = bin + 1;
    end

    for (integer hundreds = 0; hundreds < 10; hundreds = hundreds + 1) begin
      for (integer tens = 0; tens < 10; tens = tens + 1) begin
        for (integer ones = 0; ones < 10; ones = ones + 1) begin
          bin = 100 * hundreds + 10 * tens + ones;
          #1
	      $display("%d: %b", bin, bcd);
          assert((hundreds == bcd_hundreds) &
                 (tens     == bcd_tens) &
                 (ones     == bcd_ones))
            else $error("%d != %d%d%d", bin, bcd_hundreds, bcd_tens, bcd_ones);
        end
      end
    end

    $finish;
  end

endmodule

