`timescale 1 ns / 1 ps

// FIFO module:
//
// ------------------------------------------------------------------------------------------
//
// Input data is written to the FIFO on @posedge(clk) when i_Data_Valid is high and o_Full is
// low. The data needs to be set before i_Data_Valid is set and before the next @posedge(clk).
// The best option is to set the data and i_Data_Valid to high on the previous @negedge(clk)
// and set i_Data_Valid to low on the next @negedge(clk).
//
// Here is an example of how to write data to the FIFO every other clock cycle:
//                     ___     ___     ___     ___     ___ 
//   i_Clk:        ___|   |___|   |___|   |___|   |___|   |___
//                            :               :
//                         ___:___         ___:___        
//   i_Data_Valid:________|   :   |_______|   :   |_______
//                            :               :
//   i_Data:                XXXXX           YYYYY 
//
// Another example of how to write data to the FIFO every clock cycle:
//                     ___     ___     ___     ___     ___ 
//   i_Clk:        ___|   |___|   |___|   |___|   |___|   |___
//                            :       :       :
//                         ___:___ ___:___ ___:___ ___:___        
//   i_Data_Valid:________|   :       :       :       :   |_______
//                            :       :       :       :
//   i_Data:                XXXXX   YYYYY   ZZZZZ   WWWWW
//
// ------------------------------------------------------------------------------------------
//
// The data is valid on the next @negedge(clk) when o_Empty is low.
// The data is removed from the FIFO on @posedge(clk) when i_Read is high and o_Empty is low.
//
// Here is an example of how to read data from the FIFO every other clock cycle:
//                     ___     ___     ___     ___     ___
//   i_Clk:        ___|   |___|   |___|   |___|   |___|   |___
//                        :               :
//                        :_______        :_______
//   i_Read:       _______|       |_______|       |___________
//                        :               :
//   o_Data:       XXXXXXXXXX           YYYYY   ZZZZZZZZZZZZZZ
//
//                     ___     ___     ___     ___     ___
//   i_Clk:        ___|   |___|   |___|   |___|   |___|   |___
//                        :       :       :       :       :
//                        :_______:_______:_______:_______:
//   i_Read:       _______|       :       :       :       |___
//                        :       :       :       :       :
//   o_Data:       XXXXXXXXXX   YYYYY   ZZZZZ   WWWWW   NNNNNN
//
// Note that the data is guaranteeded to be the same for as long as no i_Read is asserted.
// For example:
//                     ___     ___     ___     ___     ___
//   i_Clk:        ___|   |___|   |___|   |___|   |___|   |___
//                                        :       :
//                                        :_______:
//   i_Read:       _______________________|       |___________
//                                        :       :
//   o_Data:       XXXXXXXXXXXXXXXXXXXXXXXXXX   YYYYYYYYYYYYYY
//
// -------------------------------------------------------------------------------------------
//
// Signals o_Full and o_Empty are used to indicate the state of the FIFO. They are reevaluated
// on every @posedge(clk).
//
// -------------------------------------------------------------------------------------------

module fifo

    #(
        // The DEPTH of the FIFO must be a power of 2, such as: 2, 4, 8, 16, etc.
        parameter   DEPTH      = 4,
        parameter   DATA_WIDTH = 18,
        parameter   ADDR_WIDTH = $clog2(DEPTH)
    )(
        // Control signals
        input                       i_Rst,  // FPGA Reset
        input                       i_Clk,  // FPGA Clock

        // Input data path signals
        output reg                  o_Full,         // Full flag (no space in the FIFO)
        input                       i_Data_Valid,   // Data Valid Pulse with i_Data
        input [DATA_WIDTH-1:0]      i_Data,         // Data to receive and store in the FIFO

        // Output data path signals
        output reg                  o_Empty,        // Empty flag (no data in the FIFO)
        input                       i_Read,         // Read Pulse to indicate the data is read
`ifndef SIMULATION
        output reg [DATA_WIDTH-1:0] o_Data          // Data read from the FIFO
`else
        output reg [DATA_WIDTH-1:0] o_Data,         // Data read from the FIFO

        // Diagnostic signals
        output reg [1:0]            o_Diag_State,       // State of the FSM
        output reg [ADDR_WIDTH-1:0] o_Diag_Buf_W_Addr,  // Write address
        output reg [ADDR_WIDTH-1:0] o_Diag_Buf_R_Addr   // Read address
`endif
    );

    localparam WRITE_ONLY = 0, READ_WRITE = 1, READ_ONLY = 2; 
    reg [1:0] r_State;
    reg [1:0] r_State_Next;

    reg [DATA_WIDTH-1:0] r_Buf [DEPTH-1:0];    // The FIFO buffer
    reg [ADDR_WIDTH-1:0] r_Buf_W_Addr;
    reg [ADDR_WIDTH-1:0] r_Buf_W_Addr_Next;
    reg [ADDR_WIDTH-1:0] r_Buf_R_Addr;
    reg [ADDR_WIDTH-1:0] r_Buf_R_Addr_Next;

    assign r_Buf_W_Addr_Next = r_Buf_W_Addr + 1'b1;
    assign r_Buf_R_Addr_Next = r_Buf_R_Addr + 1'b1;

    // Next state computation logic
    always @(*) begin
        case (r_State)
            WRITE_ONLY:
                r_State_Next = i_Data_Valid ? READ_WRITE : WRITE_ONLY;
            READ_WRITE:
                if (i_Read ^ i_Data_Valid) begin
                    if (i_Read) begin
                        r_State_Next = r_Buf_R_Addr_Next == r_Buf_W_Addr ? WRITE_ONLY : READ_WRITE;
                    end
                    else begin
                        r_State_Next = r_Buf_W_Addr_Next == r_Buf_R_Addr ? READ_ONLY : READ_WRITE;
                    end
                end
                else begin
                    r_State_Next = READ_WRITE;
                end 
            READ_ONLY:
                r_State_Next = i_Read ? READ_WRITE : READ_ONLY;
            default:
                r_State_Next = WRITE_ONLY;
        endcase
    end

    // State transition DFF
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_State <= WRITE_ONLY;
        end
        else begin
            r_State <= r_State_Next;
        end
    end

    // Read data path
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Buf_R_Addr <= 0;
        end
        else begin
            case (r_State)
                READ_WRITE: if (i_Read) r_Buf_R_Addr <= r_Buf_R_Addr_Next;
                READ_ONLY:  if (i_Read) r_Buf_R_Addr <= r_Buf_R_Addr_Next;
                default:    r_Buf_R_Addr <= r_Buf_R_Addr;
            endcase
        end
    end
    assign o_Data = r_Buf[r_Buf_R_Addr];

    // Write data path
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Buf_W_Addr <= 0;
        end
        else begin
            case (r_State)
                WRITE_ONLY:
                    if (i_Data_Valid) begin
                        r_Buf[r_Buf_W_Addr] <= i_Data;
                        r_Buf_W_Addr <= r_Buf_W_Addr_Next;
                    end
                READ_WRITE:
                    if (i_Data_Valid) begin
                        r_Buf[r_Buf_W_Addr] <= i_Data;
                        r_Buf_W_Addr <= r_Buf_W_Addr_Next;
                    end
                default:
                    r_Buf_W_Addr <= r_Buf_W_Addr;
            endcase
        end
    end
    assign o_Empty = (r_State == WRITE_ONLY);
    assign o_Full  = (r_State == READ_ONLY);

`ifdef SIMULATION
    assign o_Diag_State      = r_State;
    assign o_Diag_Buf_W_Addr = r_Buf_W_Addr;
    assign o_Diag_Buf_R_Addr = r_Buf_R_Addr;
`endif

endmodule
