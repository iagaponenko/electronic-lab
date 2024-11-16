// The configurable BCD counter with a pulse generator when the lowest
// digit gets incremented

module bcd_counter_pulse
  #(
    WIDTH = 8,
    CLOCKS_PER_INCREMENT = 1, // Allowed range: 1 .. (2**31 - 1)
    MIN_VALUE = 0,
    MAX_VALUE = 1, // Must be equal to MIN_VALUE or higher
    BCD_DIGITS = $rtoi($ceil($log10(real'(2**WIDTH-1)))),
    BCD_WIDTH = BCD_DIGITS*4
  )
  (
    input clk,
    input rst,
    output reg [BCD_WIDTH-1:0] bcd,
    output reg updated
  );

  reg [WIDTH-1:0] count;

  counter #(.WIDTH(WIDTH),
            .CLOCKS_PER_INCREMENT(CLOCKS_PER_INCREMENT),
            .MIN_VALUE(MIN_VALUE),
            .MAX_VALUE(MAX_VALUE)
           ) counter_0 (.clk(clk),
                        .rst(rst),
                        .count(count));
 
  bin2bcd_para #(.BIN_WIDTH(WIDTH),
                 .BCD_DIGITS(BCD_DIGITS),
                 .BCD_WIDTH(BCD_WIDTH)
                ) bin2bcd_para_0 (.bin(count),
                                  .bcd(bcd));

  pulse #(.WIDTH(4)
         ) pulse_0 (.clk(clk),
                    .rst(rst),
                    .a(bcd[3:0]),
                    .x(updated));

endmodule

