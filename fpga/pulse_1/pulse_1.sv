// Make a pulse on the state transition of the input signal from 0 to 1.
// The implementation compares the input signal with the previous state
// of the signal, and raises a pulse when the signal changed from 0 to 1.
// Changes are checked and reported on the rising edge of the clock.
//
// Transitions of the input signal which are less than 1 period of the clock
// are ignored.

module pulse
  (
    input clk,
    input rst,
    input a,
    output reg x
  );

  reg prev_a;
  always @(posedge clk) begin
    if (rst) begin
      prev_a <= a;
      x <= 1'b0;
    end else begin
      prev_a <= a;
	  x <= ~prev_a & a;
    end
  end
endmodule

