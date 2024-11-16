// The expantion factor: <device-clock-period> := 2 * (SPI_CYCLES + 1) * <clock-period>
// Here are a few examples for various values of the parameter SPI_CYCLES:
//                      
//   SPI_CYCLES | expansion 
//      0       |     2     
//      1       |     4     
//      2       |     6     
//      3       |     8     
//      4       |    10     
//
// In the practical terms:
//
// Freq(clk) = 25 MHz
// SPI_CYCLES = 4
// Freq(dev_clk) = 2.5 MHz

module spi_fifo_diag

  #(parameter SPI_CYCLES = 1,
    parameter FIFO_DEPTH = 4)

  (input clk,
   input rst,
   input write,         // Latch the data (when the FIFO is not full)
   input [7:0] data,    // Data to be latched
   output reg full,     // When FIFO is full
   output reg spi_stb,
   output reg spi_clk,
   output reg spi_dio,
   output reg diag_fifo_read,
   output reg [7:0] diag_fifo_rdata,
   output reg diag_fifo_empty,
   output reg diag_spi_data_rdy,
   output reg diag_spi_busy);

  reg fifo_read;
  reg [7:0] fifo_rdata;
  reg fifo_empty;
  reg spi_data_rdy;
  reg spi_busy;

  fifo #(.DEPTH(FIFO_DEPTH)) fifo_0 (
    .clk(clk), .rst(rst),
    .write(write), .wdata(data), .read(fifo_read), .rdata(fifo_rdata),
    .empty(fifo_empty), .full(full));

  spi #(.CYCLES(SPI_CYCLES)) spi_0 (
    .clk(clk),
    .rst(rst),
    .data_rdy(spi_data_rdy), .data(fifo_rdata),
    .busy(spi_busy),
    .dev_stb(spi_stb), .dev_clk(spi_clk), .dev_dio(spi_dio));

  always @(negedge clk) begin
    if (rst) begin
      fifo_read <= 0;
      spi_data_rdy <= 0;
    end else begin
      if (spi_data_rdy) begin
        // Pop the data from the FIFO and clear the input data ready signal at SPI
        fifo_read <= 1;
        spi_data_rdy <= 0;
      end else if (fifo_read) begin
        // This is needed to avoid automatically poping the next data from the FIFO
        fifo_read <= 0;
      end else begin
        if (~fifo_empty & ~spi_busy) begin
          // Send the data from FIFO to SPI. This starts the 3-cycles transaction
          // on the negative edge of the clock.
          // 1) begin send data from FIFO to SPI
          // 2) end sending data to SPI, begin popping data from FIFO
          // 3) end popping data from FIFO
          spi_data_rdy <= 1;
        end
      end
    end
  end

  // Diagnostics
  assign diag_fifo_read = fifo_read;
  assign diag_fifo_rdata = fifo_rdata;
  assign diag_fifo_empty = fifo_empty;
  assign diag_spi_data_rdy = spi_data_rdy;
  assign diag_spi_busy = spi_busy;
endmodule

module spi_fifo

  #(parameter SPI_CYCLES = 1,
    parameter FIFO_DEPTH = 4)

  (input clk,
   input rst,
   input write,         // Latch the data (when the FIFO is not full)
   input [7:0] data,    // Data to be latched
   output reg full,     // When FIFO is full
   output reg spi_stb,
   output reg spi_clk,
   output reg spi_dio);

  reg diag_fifo_read;
  reg [7:0] diag_fifo_rdata;
  reg diag_fifo_empty;
  reg diag_spi_data_rdy;
  reg diag_spi_busy;

  spi_fifo_diag #(.SPI_CYCLES(SPI_CYCLES), .FIFO_DEPTH(FIFO_DEPTH)) spi_fifo_diag_0 (
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

endmodule

