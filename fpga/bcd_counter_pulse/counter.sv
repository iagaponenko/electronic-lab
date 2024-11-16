// The configurable binary counter

module counter
  #(
    WIDTH = 8,
    CLOCKS_PER_INCREMENT = 1, // Allowed range: 1 .. (2**31 - 1)
    MIN_VALUE = 0,
    MAX_VALUE = 1  // Must be equal to MIN_VALUE or higher
  )
  (
    input clk,
    input rst,
    output reg [WIDTH-1:0] count
  );

  integer clocks;
  always @(posedge clk) begin
    if (rst) begin
      count <= MIN_VALUE;
      clocks <= 0;
    end else begin
      if (clocks == CLOCKS_PER_INCREMENT - 1) begin
        clocks <= 0;
        if (count == MAX_VALUE) begin
          count <= MIN_VALUE;
        end else begin
          count <= count + 1;
        end
      end else begin
        clocks <= clocks + 1;
      end
    end
  end
endmodule

