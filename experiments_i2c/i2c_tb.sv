`timescale 1ns/1ps

// Testbench for the i2c master module.
//
// A behavioural I2C slave model is included below.  It detects the START
// condition, receives the device address, ACKs it, then either receives a
// data byte (write) or drives a fixed read byte (read), and finally releases
// the bus for the master's STOP condition.
//
// Both write and read transactions are exercised, and the test checks that
// o_Done fires, o_Ack_Err stays clear, and (for reads) o_Data matches the
// expected byte.

module i2c_tb;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam [6:0] DEVICE_ADDR = 7'h50;
    localparam       CLK_DIV     = 4;
    localparam [7:0] WRITE_DATA  = 8'hA5;
    localparam [7:0] READ_BYTE   = 8'h3C;   // byte the slave returns on reads

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg        r_Clk;
    reg        r_Rst;
    reg        r_Start;
    reg        r_RW;
    reg  [7:0] r_Data;
    wire [7:0] w_Data;
    wire       w_Busy;
    wire       w_Ack_Err;
    wire       w_Done;
    wire       w_SCL;
    wire       w_SDA;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    i2c
        #(  .DEVICE_ADDR (DEVICE_ADDR),
            .CLK_DIV     (CLK_DIV)
        ) dut (
            .i_Clk      (r_Clk),
            .i_Rst      (r_Rst),
            .i_Start    (r_Start),
            .i_RW       (r_RW),
            .i_Data     (r_Data),
            .o_Data     (w_Data),
            .o_Busy     (w_Busy),
            .o_Ack_Err  (w_Ack_Err),
            .o_Done     (w_Done),
            .o_SCL      (w_SCL),
            .io_SDA     (w_SDA)
        );

    // -------------------------------------------------------------------------
    // Weak pull-up on SDA (simulates an external resistor)
    // -------------------------------------------------------------------------
    assign (weak1, highz0) w_SDA = 1'b1;

    // -------------------------------------------------------------------------
    // Clock generation (period = 2 ns → 500 MHz system clock)
    // -------------------------------------------------------------------------
    initial r_Clk = 1'b0;
    always  #1 r_Clk = ~r_Clk;

    // -------------------------------------------------------------------------
    // Global simulation timeout (guards against infinite loops)
    // -------------------------------------------------------------------------
    initial begin
        #200000;
        $error("%0t: Global simulation TIMEOUT", $time);
        $finish;
    end

    // -------------------------------------------------------------------------
    // Behavioural I2C slave
    //
    // Open-drain: r_Slave_Sda=1 drives SDA low; r_Slave_Sda=0 releases.
    // -------------------------------------------------------------------------
    reg       r_Slave_Sda;
    reg [7:0] slave_rx;

    assign w_SDA = r_Slave_Sda ? 1'b0 : 1'bz;

    // Receive one byte from the master (sample SDA on posedge SCL)
    task automatic slave_recv_byte(output reg [7:0] recv);
        integer b;
        recv = 8'h00;
        for (b = 7; b >= 0; b--) begin
            @(posedge w_SCL);
            recv[b] = w_SDA;
            @(negedge w_SCL);
        end
    endtask

    // Send one byte to the master (change SDA while SCL is low)
    task automatic slave_send_byte(input [7:0] send_val);
        integer b;
        for (b = 7; b >= 0; b--) begin
            // SCL is already low; drive or release SDA before SCL rises
            r_Slave_Sda = ~send_val[b];  // 1 → drive low (bit=0); 0 → release (bit=1)
            @(posedge w_SCL);
            @(negedge w_SCL);
        end
        r_Slave_Sda = 1'b0;  // release SDA after last bit
    endtask

    // Send ACK (drive SDA low for one SCL pulse)
    task automatic slave_send_ack;
        r_Slave_Sda = 1'b1;   // drive SDA low = ACK
        @(posedge w_SCL);
        @(negedge w_SCL);
        r_Slave_Sda = 1'b0;   // release SDA
    endtask

    // Slave main loop: detect START, handle one transaction, repeat.
    // START condition: SDA falls while SCL is high.
    initial r_Slave_Sda = 1'b0;

    always begin
        // Wait for a START condition: SDA falls while SCL is high.
        // Data-bit transitions happen only while SCL is low, so this
        // reliably distinguishes START from ordinary data changes.
        @(negedge w_SDA);
        if (w_SCL === 1'b1) begin
            // START detected
            @(negedge w_SCL);               // wait for first SCL low (addr clocking begins)
            slave_recv_byte(slave_rx);      // receive {DEVICE_ADDR, R/W}
            slave_send_ack;                 // ACK the address
            if (slave_rx[0] == 1'b0) begin
                // Write: receive one data byte then ACK
                slave_recv_byte(slave_rx);
                slave_send_ack;
            end else begin
                // Read: send READ_BYTE; master sends NACK at end
                slave_send_byte(READ_BYTE);
            end
        end
        // else: SDA fell while SCL was low (ordinary data bit); ignore and loop
    end

    // -------------------------------------------------------------------------
    // Test stimulus
    // -------------------------------------------------------------------------
    integer errors;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);

        errors  = 0;
        r_Rst   = 1'b1;
        r_Start = 1'b0;
        r_RW    = 1'b0;
        r_Data  = 8'h00;

        // Hold reset for a few cycles
        repeat (6) @(posedge r_Clk);
        r_Rst = 1'b0;
        @(posedge r_Clk);

        // =================================================================
        // Test 1: Write transaction
        // =================================================================
        $display("%0t: [TEST 1] Write (addr=0x%02h, data=0x%02h)",
                 $time, DEVICE_ADDR, WRITE_DATA);

        // Set up inputs on negedge so they are stable at the next posedge
        // when the master samples them (mirrors the SPI test pattern).
        @(negedge r_Clk);
        r_RW    = 1'b0;
        r_Data  = WRITE_DATA;
        r_Start = 1'b1;
        @(negedge r_Clk);
        r_Start = 1'b0;

        @(posedge w_Done);

        if (w_Ack_Err) begin
            $error("%0t: [TEST 1] Unexpected ACK error", $time);
            errors = errors + 1;
        end else begin
            $display("%0t: [TEST 1] PASSED", $time);
        end

        // Wait a few cycles between transactions
        repeat (16) @(posedge r_Clk);

        // =================================================================
        // Test 2: Read transaction
        // =================================================================
        $display("%0t: [TEST 2] Read (addr=0x%02h, expect data=0x%02h)",
                 $time, DEVICE_ADDR, READ_BYTE);

        @(negedge r_Clk);
        r_RW    = 1'b1;
        r_Data  = 8'h00;
        r_Start = 1'b1;
        @(negedge r_Clk);
        r_Start = 1'b0;

        @(posedge w_Done);

        if (w_Ack_Err) begin
            $error("%0t: [TEST 2] Unexpected ACK error", $time);
            errors = errors + 1;
        end else if (w_Data !== READ_BYTE) begin
            $error("%0t: [TEST 2] Data mismatch: got 0x%02h, expected 0x%02h",
                   $time, w_Data, READ_BYTE);
            errors = errors + 1;
        end else begin
            $display("%0t: [TEST 2] PASSED (received 0x%02h)", $time, w_Data);
        end

        // Final summary
        repeat (8) @(posedge r_Clk);
        if (errors == 0)
            $display("%0t: All tests PASSED", $time);
        else
            $display("%0t: %0d test(s) FAILED", $time, errors);

        $finish;
    end

endmodule
