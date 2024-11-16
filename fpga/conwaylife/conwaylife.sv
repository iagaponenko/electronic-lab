module conwaylife(
  input clk,
  input load,
  input [255:0] data,
  output reg [255:0] q,
  output int sum_out [255:0],
  output int i_out [255:0],
  output int i_N_out [255:0]); 

  genvar row, col;
  generate
    for (row = 0; row < 16; row = row + 1) begin: row_loop
      for (col = 0; col < 16; col = col + 1) begin: col_loop
        int i, i_N, i_NE, i_E, i_SE, i_S, i_SW, i_W, i_NW;
        assign i    = row * 16 + col;
        assign i_N  = (row == 15 ?  0 : row + 1) * 16 + col;
        assign i_NE = (row == 15 ?  0 : row + 1) * 16 + (col ==  0 ? 15 : col - 1);
        assign i_E  = row * 16                        + (col ==  0 ? 15 : col - 1);
        assign i_SE = (row ==  0 ? 15 : row - 1) * 16 + (col ==  0 ? 15 : col - 1);
        assign i_S  = (row ==  0 ? 15 : row - 1) * 16 + col;
        assign i_SW = (row ==  0 ? 15 : row - 1) * 16 + (col == 15 ?  0 : col + 1);
        assign i_W  = row * 16                        + (col == 15 ?  0 : col + 1);
        assign i_NW = (row == 15 ?  0 : row + 1) * 16 + (col == 15 ?  0 : col + 1);
        int sum;
        popcount8 sum_of_8_bits(.data({q[i_N],
                                       q[i_NE],
                                       q[i_E],
                                       q[i_SE],
                                       q[i_S],
                                       q[i_SW],
                                       q[i_W],
                                       q[i_NW]}),
                                .sum(sum));
        assign sum_out[row * 16 + col] = sum;
        assign i_out[row * 16 + col] = i;
        assign i_N_out[row * 16 + col] = i_N;
        always @(posedge clk) begin
          if (load) begin
            q[i] <= data[i];
          end else begin
            //sum_out[i] <= sum;
            case (sum_out[i])
              4'h2:    q[i] <= q[i];
              4'h3:    q[i] <= 1'b1;
              default: q[i] <= 1'b0;
            endcase
          end
        end
      end
    end
  endgenerate
endmodule

module popcount8(
    input [7:0] data,
    output int sum );
    integer i;
    always @(*) begin
        sum = 0;
	    for (i = 0; i < 8; i = i + 1) begin
            sum = sum + data[i];
    	end
    end
endmodule

