module spi_diag

  // The expantion factor: <device-clock-period> := 2 * (CYCLES + 1) * <clock-period>
  // Here are a few examples for various values of the parameter CYCLES:
  //                      
  //   CYCLES | expansion 
  //      0   |     2     
  //      1   |     4     
  //      2   |     6     
  //      3   |     8     
  //      4   |    10     
  //
  // In the practical terms:
  //
  // Freq(clk) = 25 MHz
  // CYCLES = 4
  // Freq(dev_clk) = 2.5 MHz

  #(parameter CYCLES = 1)

  (	input clk,
    input rst,
    input data_rdy,
    input [7:0] data,
    output reg busy,
    output reg dev_stb,
    output reg dev_clk,
    output reg dev_dio,
    output reg [1:0] diag_state,
    output reg [7:0] diag_dev_data,
    output reg [2:0] diag_addr); 

  localparam IDLE = 0, LOAD_DATA = 1, DATA_SET_ADDR = 2, DATA_TX = 3; 
  reg [1:0] state, next_state;

  reg [7:0] addr_delay_cycles, tx_delay_cycles;  // up to 256
  reg [2:0] dev_data_addr;

  // State transition logic
  always @(*) begin
    case (state)
      IDLE:
        next_state = data_rdy ? LOAD_DATA : IDLE;
      LOAD_DATA :
        next_state = DATA_SET_ADDR;
      DATA_SET_ADDR:
        if (addr_delay_cycles == CYCLES) begin
	        next_state = DATA_TX;
        end else begin
            next_state = DATA_SET_ADDR;
        end
      DATA_TX:
        if (tx_delay_cycles == CYCLES) begin
          next_state = (dev_data_addr == 3'h7) ? IDLE : DATA_SET_ADDR;
        end else begin
	       next_state = DATA_TX;
        end
      default:
        next_state = IDLE;
    endcase
  end

  // State transition DFF
  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end
  assign busy = (state == LOAD_DATA) || (state == DATA_SET_ADDR) || (state == DATA_TX);

  // Strobe (enable) signal
  assign dev_stb = ~((state == DATA_SET_ADDR) || (state == DATA_TX));

  // Device clock
  always @(*) begin
    case (state)
      DATA_SET_ADDR: dev_clk = 1'b0;
      default:       dev_clk = 1'b1;
    endcase
  end

  // Device clock delay control
  always @(posedge clk) begin
    if (rst) begin
      addr_delay_cycles <= 8'h0;
      tx_delay_cycles <= 8'h0;
    end else begin
      case (state)
        LOAD_DATA: begin
          addr_delay_cycles <= 8'h0;
	      tx_delay_cycles <= 8'h0;
        end
        DATA_SET_ADDR: begin
          if (addr_delay_cycles == CYCLES) begin
            tx_delay_cycles <= 8'h0;
          end else begin
            addr_delay_cycles <= addr_delay_cycles + 1'b1;
          end
        end
        DATA_TX: begin
          if (tx_delay_cycles == CYCLES) begin
            addr_delay_cycles <= 8'h0;
          end else begin
            tx_delay_cycles <= tx_delay_cycles + 1'b1;
          end
        end
      endcase
    end
  end

  // Data path
  reg [7:0] dev_data;
  always @(posedge clk) begin
    if (rst) begin
      dev_data <= 7'h0;
      dev_data_addr <= 3'h0;
    end else begin
      case (state)
        IDLE:      dev_data <= data;
        LOAD_DATA: dev_data_addr <= 3'h0;
        DATA_TX:   if (tx_delay_cycles == CYCLES) dev_data_addr <= dev_data_addr + 1;
      endcase
    end
  end
  always @(*) begin
    case (state)
      DATA_SET_ADDR: dev_dio = dev_data[dev_data_addr];
  	  DATA_TX:       dev_dio = dev_data[dev_data_addr];
      default:       dev_dio = 1'b0;
    endcase
  end

  assign diag_state = state;
  assign diag_dev_data = dev_data;
  assign diag_addr = dev_data_addr;
endmodule

module spi

  #(parameter CYCLES = 1)

  (	input clk,
    input rst,
    input data_rdy,
    input [7:0] data,
    output reg busy,
    output reg dev_stb,
    output reg dev_clk,
    output reg dev_dio); 

  reg [1:0] diag_state;
  reg [7:0] diag_dev_data;
  reg [2:0] diag_addr;

  spi_diag #(.CYCLES(CYCLES)) spi_diag_0 (
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

endmodule

