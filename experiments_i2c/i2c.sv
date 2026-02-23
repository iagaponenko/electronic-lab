`timescale 1ns/1ps

// I2C Master module
//
// Implements the I2C master protocol. The 7-bit device address is passed as
// the DEVICE_ADDR parameter.  CLK_DIV controls the number of system-clock
// cycles per I2C clock quarter-period, i.e. the SCL frequency is:
//
//   F_SCL = F_CLK / (4 * CLK_DIV)
//
// Usage
// -----
// Assert i_Start for one clock cycle to begin a transaction.
//   i_RW  = 0  → write: the byte on i_Data is sent after the address.
//   i_RW  = 1  → read:  one byte is received and presented on o_Data.
//
// o_Done is pulsed high for one clock cycle when the transaction finishes.
// o_Ack_Err is set if the slave did not acknowledge the address (or data
// byte in write mode) and remains set until the next transaction starts.
//
// The io_SDA port is open-drain: the master drives it low by enabling the
// output; it releases it (high-Z) to let the external pull-up assert high.
// The o_SCL output is driven directly by the master.

module i2c
    #(
        parameter [6:0] DEVICE_ADDR = 7'h50,
        parameter       CLK_DIV     = 4         // quarter-period in clock cycles
    )(
        input            i_Clk,
        input            i_Rst,

        // Control interface
        input            i_Start,               // pulse high for one cycle to start
        input            i_RW,                  // 0 = write, 1 = read
        input  [7:0]     i_Data,                // byte to write (sampled at i_Start)
        output reg [7:0] o_Data,                // byte read (valid after o_Done)
        output reg       o_Busy,
        output reg       o_Ack_Err,             // 1 = slave did not ACK
        output reg       o_Done,                // pulses high for one cycle on completion

        // I2C bus
        output reg       o_SCL,
        inout  wire      io_SDA
    );

    // --------------------------------------------------------------------------
    // Open-drain SDA driver: r_SDA=1 → release (pulled high); r_SDA=0 → drive low
    // --------------------------------------------------------------------------
    reg  r_SDA;
    assign io_SDA = r_SDA ? 1'bz : 1'b0;

    // SDA input (read back from bus)
    wire w_SDA_In = io_SDA;

    // --------------------------------------------------------------------------
    // State encoding
    // --------------------------------------------------------------------------
    localparam [2:0]
        IDLE     = 3'd0,
        START    = 3'd1,
        ADDR     = 3'd2,
        ADDR_ACK = 3'd3,
        DATA     = 3'd4,
        DATA_ACK = 3'd5,
        STOP     = 3'd6;

    reg [2:0]  r_State;

    // --------------------------------------------------------------------------
    // Timing / shift registers
    // --------------------------------------------------------------------------
    reg [15:0] r_Clk_Cnt;   // counts 0 .. CLK_DIV-1 inside each phase
    reg [1:0]  r_Phase;      // 4 phases per bit: 0, 1, 2, 3

    reg [7:0]  r_TX_Byte;   // byte currently being transmitted (shifted out MSB-first)
    reg [7:0]  r_RX_Byte;   // byte being received
    reg [7:0]  r_Data_Save; // copy of i_Data captured at i_Start
    reg [2:0]  r_Bit_Cnt;   // counts remaining bits (7 down to 0)
    reg        r_RW;         // stored R/W bit
    reg        r_Ack_Sample; // latched ACK sample (avoids reading o_Ack_Err one cycle late)

    // --------------------------------------------------------------------------
    // Main state machine
    // In IDLE:  i_Start is sampled every clock cycle (no divider latency).
    // Active:   state advances one step every CLK_DIV clock cycles.
    // --------------------------------------------------------------------------
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_State     <= IDLE;
            o_SCL       <= 1'b1;
            r_SDA       <= 1'b1;
            o_Busy      <= 1'b0;
            o_Ack_Err   <= 1'b0;
            o_Done      <= 1'b0;
            o_Data      <= 8'h00;
            r_Clk_Cnt   <= '0;
            r_Phase     <= '0;
            r_Bit_Cnt   <= '0;
            r_TX_Byte   <= '0;
            r_RX_Byte   <= '0;
            r_Data_Save <= '0;
            r_RW        <= 1'b0;
            r_Ack_Sample <= 1'b0;
        end else begin
            o_Done <= 1'b0;     // default: not done

            if (r_State == IDLE) begin
                // ---- IDLE: check i_Start every cycle ----
                o_SCL     <= 1'b1;
                r_SDA     <= 1'b1;
                r_Clk_Cnt <= '0;
                if (i_Start) begin
                    r_State     <= START;
                    o_Busy      <= 1'b1;
                    o_Ack_Err   <= 1'b0;
                    r_RW        <= i_RW;
                    r_Data_Save <= i_Data;
                    r_Phase     <= 2'd0;
                end
            end else begin
                // ---- Clock divider (active states only) ----
                if (r_Clk_Cnt < CLK_DIV - 1) begin
                    r_Clk_Cnt <= r_Clk_Cnt + 1'b1;
                end else begin
                    r_Clk_Cnt <= '0;

                    // ---- State machine (one step per CLK_DIV cycles) ----
                    case (r_State)

                        // ----------------------------------------------------
                        // START condition: SDA falls while SCL is high
                        // Phase 0: SDA=0 (START: SDA pulled low while SCL=1)
                        // Phase 1: SCL=0 (SCL pulled low to begin clocking)
                        // Phase 2: load address byte, go to ADDR
                        // ----------------------------------------------------
                        START: begin
                            case (r_Phase)
                                2'd0: begin
                                    r_SDA   <= 1'b0;
                                    r_Phase <= 2'd1;
                                end
                                2'd1: begin
                                    o_SCL   <= 1'b0;
                                    r_Phase <= 2'd2;
                                end
                                default: begin
                                    r_TX_Byte <= {DEVICE_ADDR, r_RW};
                                    r_Bit_Cnt <= 3'd7;
                                    r_State   <= ADDR;
                                    r_Phase   <= 2'd0;
                                end
                            endcase
                        end

                        // ----------------------------------------------------
                        // ADDR: send 8 bits (7-bit address + R/W), MSB first
                        // Phase 0: SCL=0, set SDA to current bit
                        // Phase 1: SCL=1  ← slave samples here
                        // Phase 2: SCL=0
                        // Phase 3: shift; if done → ADDR_ACK, else repeat
                        // ----------------------------------------------------
                        ADDR: begin
                            case (r_Phase)
                                2'd0: begin
                                    r_SDA   <= r_TX_Byte[7];
                                    r_Phase <= 2'd1;
                                end
                                2'd1: begin
                                    o_SCL   <= 1'b1;
                                    r_Phase <= 2'd2;
                                end
                                2'd2: begin
                                    o_SCL   <= 1'b0;
                                    r_Phase <= 2'd3;
                                end
                                default: begin
                                    r_TX_Byte <= {r_TX_Byte[6:0], 1'b0};
                                    if (r_Bit_Cnt == 3'd0) begin
                                        r_State <= ADDR_ACK;
                                        r_Phase <= 2'd0;
                                    end else begin
                                        r_Bit_Cnt <= r_Bit_Cnt - 1'b1;
                                        r_Phase   <= 2'd0;
                                    end
                                end
                            endcase
                        end

                        // ----------------------------------------------------
                        // ADDR_ACK: release SDA and sample slave ACK
                        // Phase 0: SCL=0, SDA=1 (released)
                        // Phase 1: SCL=1
                        // Phase 2: sample SDA (0=ACK, 1=NACK), SCL=0
                        // Phase 3: on NACK → STOP, on ACK → DATA
                        // ----------------------------------------------------
                        ADDR_ACK: begin
                            case (r_Phase)
                                2'd0: begin
                                    r_SDA   <= 1'b1;
                                    r_Phase <= 2'd1;
                                end
                                2'd1: begin
                                    o_SCL   <= 1'b1;
                                    r_Phase <= 2'd2;
                                end
                                2'd2: begin
                                    r_Ack_Sample <= w_SDA_In;   // latch: 0=ACK, 1=NACK
                                    o_SCL        <= 1'b0;
                                    r_Phase      <= 2'd3;
                                end
                                default: begin
                                    o_Ack_Err <= r_Ack_Sample;
                                    if (r_Ack_Sample) begin
                                        r_State <= STOP;
                                    end else begin
                                        r_TX_Byte <= r_Data_Save;
                                        r_RX_Byte <= '0;
                                        r_Bit_Cnt <= 3'd7;
                                        r_State   <= DATA;
                                    end
                                    r_Phase <= 2'd0;
                                end
                            endcase
                        end

                        // ----------------------------------------------------
                        // DATA: send (write) or receive (read) 8 bits, MSB first
                        // Phase 0: SCL=0, drive or release SDA
                        // Phase 1: SCL=1
                        // Phase 2: sample SDA (read mode), SCL=0
                        // Phase 3: shift; if done → DATA_ACK, else repeat
                        // ----------------------------------------------------
                        DATA: begin
                            case (r_Phase)
                                2'd0: begin
                                    r_SDA   <= r_RW ? 1'b1 : r_TX_Byte[7];
                                    r_Phase <= 2'd1;
                                end
                                2'd1: begin
                                    o_SCL   <= 1'b1;
                                    r_Phase <= 2'd2;
                                end
                                2'd2: begin
                                    if (r_RW) r_RX_Byte <= {r_RX_Byte[6:0], w_SDA_In};
                                    o_SCL   <= 1'b0;
                                    r_Phase <= 2'd3;
                                end
                                default: begin
                                    r_TX_Byte <= {r_TX_Byte[6:0], 1'b0};
                                    if (r_Bit_Cnt == 3'd0) begin
                                        if (r_RW) o_Data <= r_RX_Byte;
                                        r_State <= DATA_ACK;
                                        r_Phase <= 2'd0;
                                    end else begin
                                        r_Bit_Cnt <= r_Bit_Cnt - 1'b1;
                                        r_Phase   <= 2'd0;
                                    end
                                end
                            endcase
                        end

                        // ----------------------------------------------------
                        // DATA_ACK:
                        //   Write mode: release SDA, sample slave ACK
                        //   Read  mode: drive SDA=1 (NACK — no more bytes)
                        // Phase 0: SCL=0, set SDA
                        // Phase 1: SCL=1
                        // Phase 2: sample SDA (write only), SCL=0
                        // Phase 3: → STOP
                        // ----------------------------------------------------
                        DATA_ACK: begin
                            case (r_Phase)
                                2'd0: begin
                                    r_SDA   <= 1'b1;
                                    r_Phase <= 2'd1;
                                end
                                2'd1: begin
                                    o_SCL   <= 1'b1;
                                    r_Phase <= 2'd2;
                                end
                                2'd2: begin
                                    if (!r_RW) r_Ack_Sample <= w_SDA_In;
                                    o_SCL   <= 1'b0;
                                    r_Phase <= 2'd3;
                                end
                                default: begin
                                    if (!r_RW) o_Ack_Err <= r_Ack_Sample;
                                    r_State <= STOP;
                                    r_Phase <= 2'd0;
                                end
                            endcase
                        end

                        // ----------------------------------------------------
                        // STOP condition: SDA rises while SCL is high
                        // Phase 0: SCL=0, SDA=0
                        // Phase 1: SCL=1
                        // Phase 2: SDA=1  ← STOP
                        // Phase 3: back to IDLE, pulse o_Done
                        // ----------------------------------------------------
                        STOP: begin
                            case (r_Phase)
                                2'd0: begin
                                    r_SDA   <= 1'b0;
                                    r_Phase <= 2'd1;
                                end
                                2'd1: begin
                                    o_SCL   <= 1'b1;
                                    r_Phase <= 2'd2;
                                end
                                2'd2: begin
                                    r_SDA   <= 1'b1;
                                    r_Phase <= 2'd3;
                                end
                                default: begin
                                    r_State <= IDLE;
                                    o_Busy  <= 1'b0;
                                    o_Done  <= 1'b1;
                                end
                            endcase
                        end

                        default: r_State <= IDLE;
                    endcase
                end
            end
        end
    end

endmodule
