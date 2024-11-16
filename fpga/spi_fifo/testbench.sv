// Testbench
module test;

  reg clk;
  reg rst;
  reg write;
  reg [7:0] data;
  reg full;
  reg spi_stb;
  reg spi_clk;
  reg spi_dio;
  reg diag_fifo_read;
  reg [7:0] diag_fifo_rdata;
  reg diag_fifo_empty;
  reg diag_spi_data_rdy;
  reg diag_spi_busy;

  spi_fifo_diag #(.SPI_CYCLES(0), .FIFO_DEPTH(8))  spi_fifo_diag_0 (
    .clk(clk), .rst(rst),
    .write(write),
    .data(data),
    .full(full),
    .spi_stb(spi_stb),
    .spi_clk(spi_clk),
    .spi_dio(spi_dio),
    .diag_fifo_read(diag_fifo_read),
    .diag_fifo_rdata(diag_fifo_rdata),
    .diag_fifo_empty(diag_fifo_empty),
    .diag_spi_data_rdy(diag_spi_data_rdy),
    .diag_spi_busy(diag_spi_busy));

  function void init();
    $dumpfile("dump.vcd");
    $dumpvars(1);
    $monitor("%d: write=%b full=%b", $time, write, full);

    clk = 1'b0;
    rst = 1'b1;
    write = 1'b0;
    data = 8'b00000001;
  endfunction

  initial begin
    init();

    @(negedge clk) rst = 1'b0;

    repeat(80) begin
      @(negedge clk)
        if (~full) write = 1;
      @(negedge clk)
        if (write) begin
          write = 0;
          if (data == 8'b10000000) data = 8'b00000001;
          else data = {data[6:0],1'b0};
        end
    end

    repeat(100) @(negedge clk);

    $finish;

  end

  // Clock generator
  //
  always #5 clk = ~clk;

endmodule

