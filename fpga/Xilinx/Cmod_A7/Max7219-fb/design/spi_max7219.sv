`timescale 1 ns / 1 ps

// SPI module for the MAX7219 driver:
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
// the device clock is at least 2*DATA_WIDTH times slower (if CYCLES=0) than the input clock.
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

module spi_max7219

    #(
        parameter   CYCLES = 1,
        parameter   DATA_WIDTH = 16,
        parameter   ADDR_WIDTH = $clog2(DATA_WIDTH)
    )(
        // Control signals
        input       i_Rst,
        input       i_Clk,

        // Input data for the SPI device
        output reg              o_Busy,
        input                   i_Data_Ready,
        input [DATA_WIDTH-1:0]  i_Data,

        // Output SPI signals
        output reg      o_SPI_Stb,
        output reg      o_SPI_Clk,
        output reg      o_SPI_Din
    ); 

    typedef enum {
        IDLE            = 0,
        LOAD_DATA       = 1,
        DATA_SET_ADDR   = 2,
        DATA_TX         = 3,
        PAUSE           = 4
    } state_t;

    state_t r_State = IDLE;
    state_t r_State_Next;

    reg [16:0]              r_Addr_Delay_Cycles;    // up to 128*1024
    reg [16:0]              r_TX_Delay_Cycles;      // up to 128*1024
    reg [16:0]              r_Busy_Delay_Cycles;    // up to 128*1024
    reg [ADDR_WIDTH-1:0]    r_Addr;

    // ----------------------
    // State transition logic
    // ----------------------

    // Next state computation
    function state_t next(input cond, input state_t if_true, input state_t if_false);
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
                                    next(r_Addr == 0, PAUSE, DATA_SET_ADDR),
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
            r_Addr_Delay_Cycles <= 17'h0;
            r_TX_Delay_Cycles   <= 17'h0;
            r_Busy_Delay_Cycles <= 17'h0;
        end
        else begin
            case (r_State)
                LOAD_DATA: begin
                    r_Addr_Delay_Cycles <= 17'h0;
                    r_TX_Delay_Cycles   <= 17'h0;
                    r_Busy_Delay_Cycles <= 17'h0;
                end
                DATA_SET_ADDR:
                    if (r_Addr_Delay_Cycles == CYCLES)
                        r_TX_Delay_Cycles <= 17'h0;
                    else
                        r_Addr_Delay_Cycles <= r_Addr_Delay_Cycles + 1'b1;
                DATA_TX:
                    if (r_TX_Delay_Cycles == CYCLES)
                        r_Addr_Delay_Cycles <= 17'h0;
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

    reg [DATA_WIDTH-1:0] r_Data;
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Data <= '0;
            r_Addr <= DATA_WIDTH - 1;
        end
        else begin
            case (r_State)
                IDLE:
                    r_Data <= i_Data;
                LOAD_DATA: begin
                    r_Addr <= DATA_WIDTH - 1;
                end
                DATA_TX:
                    if (r_TX_Delay_Cycles == CYCLES) begin
                        r_Addr <= r_Addr - 1'b1;
                    end
            endcase
        end
    end

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

    always @(*) begin
        case (r_State)
            DATA_SET_ADDR: o_SPI_Din = r_Data[r_Addr];
            DATA_TX:       o_SPI_Din = r_Data[r_Addr];
            default:       o_SPI_Din = 1'b0;
        endcase
    end

endmodule
