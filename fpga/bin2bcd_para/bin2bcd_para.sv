// Decode a number from the binary into the BCD representation based on
// the Double Dabble algorithm.
//
// The parametric (continous logic) implementaton of the decoder.
// The decoder requires many gates.

module bin2bcd_para
  #(
    BIN_WIDTH  = 8,
    BCD_DIGITS = $rtoi($ceil($log10(real'(2**BIN_WIDTH-1)))),
    BCD_WIDTH  = BCD_DIGITS*4
  )
  (
    input [BIN_WIDTH-1:0] bin,
    output reg [BCD_WIDTH-1:0] bcd
  );

  integer i,j;

  always @(*) begin
    bcd[BIN_WIDTH-1:0] = bin;
    for(i = BIN_WIDTH; i < BCD_WIDTH; i=i+1) begin
      bcd[i] = 0;
    end
    for(i = 0; i <= BIN_WIDTH-4; i=i+1) begin
      for(j = 0; j <= i/3; j = j+1) begin
        if (bcd[BIN_WIDTH-i+4*j-:4] > 4) begin
          bcd[BIN_WIDTH-i+4*j-:4] = bcd[BIN_WIDTH-i+4*j -:4] + 4'd3;
        end
      end
    end
  end
endmodule

