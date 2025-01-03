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
// There are 17 bits in the input data, Where:
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

module spi

    #(
        parameter   CYCLES = 1
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
        output reg          o_Data_Valid,   // The data is ready to be read
        output reg [63:0]   o_Data,         // 4 bytes read from the SPI after the corresponding command is sent

        // Output SPI signals
        output reg          o_SPI_Stb,
        output reg          o_SPI_Clk,
`ifndef SIMULATION
        inout  reg          io_SPI_Dio
`else
        inout  reg          io_SPI_Dio,

        // Diagnostic signals
        output reg [2:0]    o_Diag_State,
        output reg [17:0]   o_Diag_Data,
        output reg [3:0]    o_Diag_Addr
`endif
    ); 

    localparam IDLE = 0, LOAD_DATA = 1, DATA_SET_ADDR = 2, DATA_TX = 3, PAUSE = 4; 
    reg [2:0] r_State;
    reg [2:0] r_State_Next;

    reg [15:0] r_Addr_Delay_Cycles;     // up to 64*1024
    reg [15:0] r_TX_Delay_Cycles;       // up to 64*1024
    reg [15:0] r_Busy_Delay_Cycles;     // up to 64*1024
    reg [3:0]  r_Addr;
    reg [3:0]  r_Addr_Max;              // The maximum address: 3'd7 if nod data is required by the command
                                        // or 3'd15 if the data is required by the command.

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
                                    next(r_Addr == r_Addr_Max, PAUSE, DATA_SET_ADDR),
                                    DATA_TX);
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
    assign o_Busy = (r_State == LOAD_DATA) || (r_State == DATA_SET_ADDR) || (r_State == DATA_TX) || (r_State == PAUSE);

    // --------------------------
    // Device clock delay control
    // --------------------------

    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Addr_Delay_Cycles <= 16'h0;
            r_TX_Delay_Cycles   <= 16'h0;
            r_Busy_Delay_Cycles <= 16'h0;
        end
        else begin
            case (r_State)
                LOAD_DATA: begin
                    r_Addr_Delay_Cycles <= 16'h0;
                    r_TX_Delay_Cycles   <= 16'h0;
                    r_Busy_Delay_Cycles <= 16'h0;
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

    // TODO: The data is not read from the SPI device yet. The data is just a placeholder.
    // In order to do so the current state machines need to be extended to read 4 bytes of
    // data from the SPI device after the command is sent. Note that each bit is read on
    // the rising edge of the SPI clock. The data validity signal o_Data_Valid should be set
    // to high for a duration of one clock on the rising edge of the clock when the data is
    // ready to be read.

    assign o_Data_Valid = 1'b0;
    assign o_Data = 32'h0;

    // -----------
    // SPI signals
    // -----------

    assign o_SPI_Stb = ~((r_State == DATA_SET_ADDR) || (r_State == DATA_TX));

    always @(*) begin
        case (r_State)
            DATA_SET_ADDR: o_SPI_Clk = 1'b0;
            default:       o_SPI_Clk = 1'b1;
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

`ifdef SIMULATION
    assign o_Diag_State = r_State;
    assign o_Diag_Data  = r_Data;
    assign o_Diag_Addr  = r_Addr;
`endif

endmodule
