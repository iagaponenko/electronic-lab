// The DEPTH of the FIFO must be a power of 2, such as: 2, 4, 8, 16, etc.
//
module fifo_diag
  #(
    parameter DEPTH = 4,
    parameter ADDR_WIDTH = $clog2(DEPTH)
  )(
    input clk,
    input rst,
    input write,
    input [7:0] wdata,
    input read,
    output reg [7:0] rdata,
    output reg empty,
    output reg full,
    output reg [1:0] diag_state,
    output reg [ADDR_WIDTH-1:0] diag_waddr,
    output reg [ADDR_WIDTH-1:0] diag_raddr
  );

  localparam WRITE_ONLY = 0, READ_WRITE = 1, READ_ONLY = 2; 
  reg [1:0] state, next_state;
  reg [7:0] data [DEPTH-1:0];
  reg [ADDR_WIDTH-1:0] waddr, next_waddr;
  reg [ADDR_WIDTH-1:0] raddr, next_raddr;

  assign next_waddr = waddr + 1;
  assign next_raddr = raddr + 1;

  // State transition logic
  always @(*) begin
    case (state)
      WRITE_ONLY:
        if (write) begin
          next_state = READ_WRITE;
        end else begin
          next_state = WRITE_ONLY;
        end
      READ_WRITE :
        if (read ^ write) begin
        	if (read) begin
              if (next_raddr == waddr) begin
                next_state = WRITE_ONLY;
              end else begin
                next_state = READ_WRITE;
              end
	        end else begin
              if (next_waddr == raddr) begin
                next_state = READ_ONLY;
              end else begin
                next_state = READ_WRITE;
              end
            end
      	end else begin
          next_state = READ_WRITE;
        end
      READ_ONLY :
        if (read) begin
          next_state = READ_WRITE;
        end else begin
          next_state = READ_ONLY;
        end
      default:
        next_state = WRITE_ONLY;
    endcase
  end

  // State transition DFF
  always @(posedge clk) begin
    if (rst) begin
      state <= WRITE_ONLY;
    end else begin
      state <= next_state;
    end
  end

  // Read data path
  always @(posedge clk) begin
    if (rst) begin
      raddr <= 0;
    end else begin
      case (state)
        READ_WRITE:
          if (read) begin
            raddr <= next_raddr;
          end
        READ_ONLY:
          if (read) begin
            raddr <= next_raddr;
          end
        default: raddr <= raddr;
      endcase
    end
  end
  assign rdata = data[raddr];

  // Write data path
  always @(posedge clk) begin
    if (rst) begin
      waddr <= 0;
    end else begin
      case (state)
        WRITE_ONLY:
          if (write) begin
            data[waddr] <= wdata;
            waddr <= next_waddr;
          end
        READ_WRITE:
          if (write) begin
            data[waddr] <= wdata;
            waddr <= next_waddr;
          end
        default: waddr <= waddr;
      endcase
    end
  end

  assign empty = state == WRITE_ONLY;
  assign full  = state == READ_ONLY;

  // Diagnostic signals
  assign diag_state = state;
  assign diag_waddr = waddr;
  assign diag_raddr = raddr;
endmodule

// The frontend that has no diagnostic signals
//
module fifo
  #(
    parameter DEPTH = 4,
    parameter ADDR_WIDTH = $clog2(DEPTH)
  )(
    input clk,
    input rst,
    input write,
    input [7:0] wdata,
    input read,
    output reg [7:0] rdata,
    output reg empty,
    output reg full
  );

  reg [1:0] diag_state;
  reg [ADDR_WIDTH-1:0] diag_waddr;
  reg [ADDR_WIDTH-1:0] diag_raddr;

  fifo_diag #(.DEPTH(DEPTH)) fifo_0 (
    .clk(clk), .rst(rst),
    .write(write), .wdata(wdata), .read(read), .rdata(rdata),
    .empty(empty), .full(full),
    .diag_state(diag_state), .diag_waddr(diag_waddr), .diag_raddr(diag_raddr));

endmodule

