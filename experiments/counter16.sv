// A 16-bit counter module

module counter16
  (
    input  clk,
    input  rst,
    output reg [15:0] count
  );

  always @(posedge clk) begin
    if (rst) begin
      count <= 16'h0000;
    end else begin
      count <= count + 1'b1;
    end
  end

endmodule
