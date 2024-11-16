// Testbench
module test;

  localparam DEPTH = 4;
  localparam ADDR_WIDTH = $clog2(DEPTH);

  reg clk;
  reg rst;
  reg write;
  reg [7:0] wdata;
  reg read;
  reg [7:0] rdata;
  reg empty;
  reg full;
  reg [1:0] diag_state;
  reg [ADDR_WIDTH-1:0] diag_waddr;
  reg [ADDR_WIDTH-1:0] diag_raddr;

  fifo_diag #(.DEPTH(DEPTH)) fifo_0 (
    .clk(clk), .rst(rst),
    .write(write), .wdata(wdata), .read(read), .rdata(rdata),
    .empty(empty), .full(full),
    .diag_state(diag_state), .diag_waddr(diag_waddr), .diag_raddr(diag_raddr));

  function void init();
    $dumpfile("dump.vcd");
    $dumpvars(1);
    $monitor("%d: empty=%b full=%b", $time, empty, full);

    write = 0; wdata = 8'h0; read = 0;
  endfunction

  initial begin
    init();

    #10
    assert(empty == 1) 			else $error("empty=", empty);
    assert(full == 0)  			else $error("full=", full);
    assert(diag_state == 0) 	else $error("diag_state=", diag_state);
    assert(diag_waddr == 2'h0) 	else $error("diag_waddr=", diag_waddr);
    assert(diag_raddr == 2'h0) 	else $error("diag_raddr=", diag_raddr);

    #320
    $finish;

  end

  // Clock generator
  //
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Reset generator
  //
  task reset();
    rst = 1;
    #10 rst = 0;
  endtask

  initial begin
    #0   reset();
    #150 reset();
  end

  // The writing process wakes up on the negative edge of the clock and
  // writes the next byte into the buffer it it's not full.
  // 
  always begin
    #10
    if (write) begin
      write = 0;
    end else begin
      if (~full) begin
        wdata = wdata + 1;
        write = 1;
      end
    end
  end
  // The reading process wakes up on the negative edge of the clock and
  // reads the next byte if the buffer is not empty.
  // 
//   always begin
//     #10
//     if (read) begin
//         read = 0;
//     end else begin
//       if (~empty) begin
//         read = 1;
//       end
//     end
//   end
  always begin
    #90
    if (~empty) begin
      read = 1;
      #10
      read = 0;
    end
  end
endmodule

