`timescale 1 ns / 1 ps

// SPI module:
//
// ------------------------------------------------------------------------------------------
//
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
// Freq(i_Clk) = 25 MHz
// CYCLES = 4
// Freq(o_SPI_Clk) = 2.5 MHz
//
// --------------------------------------------------------------------------------------------
//
// There are 18 bits in the input data, Where:
//
//   [17]   the flag indicating if this is the write command (=1) or the read command (=0)
//   [16]   == 1'b1 if the command has data
//   [15:8] 8-bit data       (ignored if no data is sent after the command witing the same transaction)
//   [7:0]  8-bit command
//
// --------------------------------------------------------------------------------------------
//
// Input data is written to the SPI device on @posedge(i_Clk) when i_Data_Ready is high and
// o_Busy is low. The data needs to be set before i_Data_Ready is set and before the next
// @posedge(i_Clk). The best option is to set the data and i_Data_Ready to high on the previous
// @negedge(i_Clk) and set i_Data_Ready to low on the next @negedge(i_Clk).
//
// Here is an example of how to write data to the SPI device:
//                     ___     ___     ___     ___     ___
//   i_Clk:        ___|   |___|   |___|   |___|   |___|   |___
//                            :
//                         ___:___ 
//   i_Data_Ready:________|   :   |___________________________
//                            :
//   i_Data:                XXXXX
//
// Note that it makes no sense to write data to the SPI device every clock cycle because
// the device clock is at least 16 times slower (if CYCLES=0) than the input clock.
// Besides, the current design of the module doesn't have any buffering mechanism.
//
// ---------------------------------------------------------------------------------------------
//
// The signal o_Busy is set to high when the SPI device is busy and low otherwise. These changes
// are made on @posedge(i_Clk). Here is an extended examplke illustrating how to write data to
// the SPI device and check if it is busy:
//                     ___     ___     ___     ___     ___
//   i_Clk:        ___|   |___|   |___|   |___|   |___|   |___
//                            :
//                 ___        :_______________________________
//   o_Busy:          |_______|
//                         ___:___ 
//   i_Data_Ready:________|   :   |___________________________
//                            :
//   i_Data:                XXXXX
//
// The best way of initiating an SPI transaction is to wait for the o_Busy signal to be low
// on @negedge(i_Clk) and then set i_Data_Ready to high and set i_Data. Then remove i_Data_Ready
// on the next @negedge(i_Clk).
// Note how the o_Busy signal goes to high on the next @posedge(i_Clk) after the i_Data_Ready
// signal is set to high.
//
// ---------------------------------------------------------------------------------------------
//
// Regarding reading from the SPI device, a result the latest scan is being retained by the module.
// A state of the data can be sampled data on any edge of the clock. The defauls state of the data
// is '0'.
//
// ---------------------------------------------------------------------------------------------

module spi

    #(
        parameter   CYCLES = 1,
        parameter   READ_DELAY_CYCLES = 1,  // The number of cycles to wait before reading the data from the SPI device
        parameter   READ_WIDTH = 32         // The width of the data read from the SPI device (must be a power of 2)

    )(
        // Control signals
        input               i_Rst,
        input               i_Clk,

        // Input data for the SPI device
        output reg          o_Busy,
        input               i_Data_Ready,
        input [17:0]        i_Data,         // [17]   the flag indicating if this is the write command (=1) or the read command (=0)
                                            // [16]   the flag indicating if the data is required by the command
                                            // [15:8] 8-bit data (if required by the command)
                                            // [7:0]  8-bit command

        // Output data read from the SPI device
        output reg [READ_WIDTH-1:0] o_Data, // Data read from the SPI after the corresponding command is sent

        // Output SPI signals
        output reg          o_SPI_Stb,
        output reg          o_SPI_Clk,
`ifndef __ICARUS__
        inout  reg          io_SPI_Dio
`else
        inout  reg          io_SPI_Dio,

        // Diagnostic signals
        output reg [2:0]    o_Diag_State,
        output reg [17:0]   o_Diag_Data,
        output reg [3:0]    o_Diag_Addr
`endif
    ); 

    localparam  IDLE = 0,
                LOAD_DATA = 1,
                DATA_SET_ADDR = 2,
                DATA_TX = 3,
                PAUSE_BEFORE_READ = 4,
                DATA_SET_RX_ADDR = 5,
                DATA_RX = 6,
                PAUSE = 7;
    reg [2:0] r_State;
    reg [2:0] r_State_Next;

    reg [15:0] r_Addr_Delay_Cycles;     // up to 64*1024
    reg [15:0] r_TX_Delay_Cycles;       // up to 64*1024
    reg [3:0]  r_Addr;
    reg [3:0]  r_Addr_Max;              // The maximum address: 4'd7 if nod data is required by the command
                                        // or 4'd15 if the data is required by the command.

    localparam READ_ADDR_WIDTH = $clog2(READ_WIDTH);

    reg [15:0]                  r_Read_Delay_Cycles;    // up to 64*1024
    reg [15:0]                  r_RX_Addr_Delay_Cycles; // up to 64*1024
    reg [15:0]                  r_RX_Delay_Cycles;      // up to 64*1024
    reg [READ_ADDR_WIDTH-1:0]   r_RX_Addr;              // 0 .. READ_WIDTH-1

    reg [15:0] r_Busy_Delay_Cycles;     // up to 64*1024

    // ----------------------
    // State transition logic
    // ----------------------

    // Next state computation
    function [2:0] next(cond, [2:0] if_true, [2:0] if_false);
        if (cond) return if_true;
        else      return if_false;
    endfunction

    always @(*) begin
        case (r_State)
            IDLE:
                r_State_Next = next(i_Data_Ready, LOAD_DATA, IDLE);
            LOAD_DATA :
                r_State_Next = DATA_SET_ADDR;
            DATA_SET_ADDR:
                r_State_Next = next(r_Addr_Delay_Cycles == CYCLES, DATA_TX, DATA_SET_ADDR);
            DATA_TX:
                r_State_Next = next(r_TX_Delay_Cycles == CYCLES, 
                                    next(r_Addr == r_Addr_Max,
                                         next(r_Data[17],
                                              PAUSE_BEFORE_READ,
                                              PAUSE),
                                         DATA_SET_ADDR),
                                    DATA_TX);
            PAUSE_BEFORE_READ:
                r_State_Next = next(r_Read_Delay_Cycles == READ_DELAY_CYCLES, DATA_SET_RX_ADDR, PAUSE_BEFORE_READ);
            DATA_SET_RX_ADDR:
                r_State_Next = next(r_RX_Addr_Delay_Cycles == CYCLES, DATA_RX, DATA_SET_RX_ADDR);
            DATA_RX:
                r_State_Next = next(r_RX_Delay_Cycles == CYCLES, 
                                    next(r_RX_Addr == READ_WIDTH - 1, PAUSE, DATA_SET_RX_ADDR),
                                    DATA_RX);
            PAUSE:
                r_State_Next = next(r_Busy_Delay_Cycles == CYCLES, IDLE, PAUSE);
            default:
                r_State_Next = IDLE;
        endcase
    end

    // State transition DFF
    always @(posedge i_Clk) begin
        if (i_Rst) r_State <= IDLE;
        else       r_State <= r_State_Next;
    end

    // Busy signal is determined by the current state
    assign o_Busy = r_State != IDLE;

    // --------------------------
    // Device clock delay control
    // --------------------------

    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Addr_Delay_Cycles    <= 16'h0;
            r_TX_Delay_Cycles      <= 16'h0;
            r_Busy_Delay_Cycles    <= 16'h0;
            r_Read_Delay_Cycles    <= 16'h0;
            r_RX_Addr_Delay_Cycles <= 16'h0;
            r_RX_Delay_Cycles      <= 16'h0;
        end
        else begin
            case (r_State)
                LOAD_DATA: begin
                    r_Addr_Delay_Cycles    <= 16'h0;
                    r_TX_Delay_Cycles      <= 16'h0;
                    r_RX_Addr_Delay_Cycles <= 16'h0;
                    r_RX_Delay_Cycles      <= 16'h0;
                    r_Busy_Delay_Cycles    <= 16'h0;
                    r_Read_Delay_Cycles    <= 16'h0;
                end
                DATA_SET_ADDR:
                    if (r_Addr_Delay_Cycles == CYCLES)
                        r_TX_Delay_Cycles <= 16'h0;
                    else
                        r_Addr_Delay_Cycles <= r_Addr_Delay_Cycles + 1'b1;
                DATA_TX:
                    if (r_TX_Delay_Cycles == CYCLES)
                        r_Addr_Delay_Cycles <= 16'h0;
                    else
                        r_TX_Delay_Cycles <= r_TX_Delay_Cycles + 1'b1;
                PAUSE_BEFORE_READ:
                    r_Read_Delay_Cycles <= r_Read_Delay_Cycles + 1'b1;
                DATA_SET_RX_ADDR:
                    if (r_RX_Addr_Delay_Cycles == CYCLES)
                        r_RX_Addr_Delay_Cycles <= 16'h0;
                    else
                        r_RX_Addr_Delay_Cycles <= r_RX_Addr_Delay_Cycles + 1'b1;
                DATA_RX:
                    if (r_RX_Delay_Cycles == CYCLES)
                        r_RX_Delay_Cycles <= 16'h0;
                    else
                        r_RX_Delay_Cycles <= r_RX_Delay_Cycles + 1'b1;
                PAUSE:
                    r_Busy_Delay_Cycles <= r_Busy_Delay_Cycles + 1'b1;
            endcase
        end
    end

    // ---------------
    // Input data path
    // ---------------

    reg [17:0] r_Data;
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Addr <= 4'h0;
        end
        else begin
            case (r_State)
                IDLE:
                    r_Data <= i_Data;
                LOAD_DATA: begin
                    r_Addr <= 4'h0;
                    r_Addr_Max <= {r_Data[16], 3'h7};
                end
                DATA_TX:
                    if (r_TX_Delay_Cycles == CYCLES) begin
                        r_Addr <= r_Addr + 1'b1;
                    end
            endcase
        end
    end

    // ----------------
    // Output data path
    // ----------------

    always @(posedge i_Clk) begin
        if (i_Rst) begin
`ifndef __ICARUS__
            o_Data <= '0;
`else
            // Setting the output data to 'z in the simulation mode helps vizualizing the data
            // changes during the simulation.
            o_Data <= 'z;
`endif
            r_RX_Addr <= '0;
        end
        else begin
            case (r_State)
                LOAD_DATA: begin
                    r_RX_Addr <= '0;
                end
                DATA_SET_RX_ADDR: begin
                    if (r_RX_Addr_Delay_Cycles == CYCLES) begin
`ifndef __ICARUS__
                        // Sample the data signal from the SPI device
                        o_Data[r_RX_Addr] <= io_SPI_Dio;
`else
                        // Simulate reading the current state of the data signal from SPI device.
                        // The resulting signal will be a sequnce of 0s and 1s.
                        if (o_Data[r_RX_Addr] == 1'bz) begin
                            o_Data[r_RX_Addr] <= r_RX_Addr[0];
                        end
                        else begin
                            o_Data[r_RX_Addr] <= r_RX_Addr[1];
                        end
`endif
                    end
                end
                DATA_RX: begin
                    if (r_RX_Delay_Cycles == CYCLES) begin
                        r_RX_Addr <= r_RX_Addr + 1'b1;
                    end
                 end
            endcase
        end
    end


    // -----------
    // SPI signals
    // -----------

    assign o_SPI_Stb = ~((r_State == DATA_SET_ADDR) ||
                         (r_State == DATA_TX) ||
                         (r_State == PAUSE_BEFORE_READ) ||
                         (r_State == DATA_RX) ||
                         (r_State == DATA_SET_RX_ADDR));

    always @(*) begin
        case (r_State)
            DATA_SET_ADDR:    o_SPI_Clk = 1'b0;
            DATA_SET_RX_ADDR: o_SPI_Clk = 1'b0;
            default:          o_SPI_Clk = 1'b1;
        endcase
    end

    // always @(*) begin
    //     case (r_State)
    //         DATA_SET_ADDR: io_SPI_Dio = r_Data[r_Addr];
    //         DATA_TX:       io_SPI_Dio = r_Data[r_Addr];
    //         default:       io_SPI_Dio = 1'b0;
    //     endcase
    // end
    //
    // IMPORTANT: The procedural assignment code that is commented out above
    //            wouldn't work for driving the inout port. Hence the continuous
    //            assignment below is used instead. Note that the port is driven
    //            only when the SPI device is in the DATA_SET_ADDR or DATA_TX state.
    //
    assign io_SPI_Dio = (r_State == DATA_SET_ADDR) || (r_State == DATA_TX) ? r_Data[r_Addr] : 1'bz;

`ifdef __ICARUS__
    assign o_Diag_State = r_State;
    assign o_Diag_Data  = r_Data;
    assign o_Diag_Addr  = r_Addr;
`endif

endmodule
