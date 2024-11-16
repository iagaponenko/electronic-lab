// Testbench
module test;

  reg clk;
  reg rst;
  reg data_rdy;
  reg [7:0] data;
  reg busy, dev_stb, dev_clk, dev_dio;
  reg [1:0] diag_state;
  reg [7:0] diag_dev_data;
  reg [2:0] diag_addr;

  spi_diag #(.CYCLES(0)) spi_diag_0 (
    .clk(clk),
    .rst(rst),
    .data_rdy(data_rdy),
    .data(data),
    .busy(busy),
    .dev_stb(dev_stb),
    .dev_clk(dev_clk),
    .dev_dio(dev_dio),
    .diag_state(diag_state),
    .diag_dev_data(diag_dev_data),
    .diag_addr(diag_addr));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);
    
    clk = 0; rst = 1; data_rdy = 0; data = 8'b00000001;
    
	@(negedge clk) rst = 0;

    repeat (60) begin
      @(negedge clk) begin
        if (~busy) data_rdy = 1;
      end
      @(negedge clk)
        if (data_rdy) begin
          data_rdy = 0;
          data = {data[6:0],1'b0};
        end
    end

    $finish;

  end

  always #5 clk = ~clk;

endmodule

