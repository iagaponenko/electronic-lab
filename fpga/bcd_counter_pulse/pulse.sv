// Make a pulse on the state transition of the input signal.
// The implementation compares the input signal with the previous state
// of the signal, and raises a pulse when the signal changed.
// Changes are checked and reported on the rising edge of the clock.
//
// Transitions of the input signal which are less than 1 period of the clock
// are ignored.

module pulse
  #(
    WIDTH = 8
  )(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    output reg x
  );

  reg [WIDTH-1:0] prev_a;
  always @(posedge clk) begin
    if (rst) begin
      prev_a <= a;
      x <= '0;
    end else begin
      prev_a <= a;
	  x <= prev_a != a;
    end
  end
endmodule

