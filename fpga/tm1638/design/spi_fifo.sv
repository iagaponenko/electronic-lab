`timescale 1 ns / 1 ps

// SPI module:
//
// ------------------------------------------------------------------------------------------
//
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
// Freq(i_Clk) = 25 MHz
// SPI_CYCLES = 4
// Freq(o_SPI_Clk) = 2.5 MHz
//
// ------------------------------------------------------------------------------------------
//
// Requirements for the input signals to the module are the same as for the FIFO module.
// The ouput data are produced by the SPI module.
// See specifications of both modules for more details.
//
// ------------------------------------------------------------------------------------------
//
// The output data is captured in o_Data for 1 clock cycle after the o_Data_Valid is set to
// high. It's up to the user to read anbd buffer the data if needed.
//
// ------------------------------------------------------------------------------------------

module spi_fifo

    #(  parameter   SPI_CYCLES = 1,
        parameter   FIFO_DEPTH = 4
    )(
        // Control signals
        input               i_Rst,
        input               i_Clk,

        // Input FIFO signals
        output reg          o_FIFO_Full,    // When FIFO is full
        input               i_Data_Valid,   // Latch the data (when the FIFO is not full)
        input [17:0]        i_Data,         // Data to be latched

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
        output reg          o_Diag_FIFO_Read,
        output reg [17:0]   o_Diag_FIFO_RData,
        output reg          o_Diag_FIFO_Empty,
        output reg          o_Diag_SPI_Data_Rdy,
        output reg          o_Diag_SPI_Busy
`endif
    );

    reg         r_FIFO_Read;
    reg [17:0]  r_FIFO_RData;
    reg         r_FIFO_Empty;
    reg         r_SPI_Data_Rdy;
    reg         r_SPI_Busy;

    localparam  FIFO_DATA_WIDTH = 18;
    localparam  FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);

`ifdef SIMULATION
    reg [1:0]                   r_Diag_FIFO_State;
    reg [FIFO_ADDR_WIDTH-1:0]   r_Diag_FIFO_Buf_W_Addr;
    reg [FIFO_ADDR_WIDTH-1:0]   r_Diag_FIFO_Buf_R_Addr;
`endif
    fifo
        #(  .DEPTH      (FIFO_DEPTH),
            .DATA_WIDTH (FIFO_DATA_WIDTH)
        ) fifo_0 (
            .i_Rst              (i_Rst),
            .i_Clk              (i_Clk),

            .o_Full             (o_FIFO_Full),
            .i_Data_Valid       (i_Data_Valid),
            .i_Data             (i_Data),

            .o_Empty            (r_FIFO_Empty),
            .i_Read             (r_FIFO_Read),
`ifndef SIMULATION
            .o_Data             (r_FIFO_RData)
`else
            .o_Data             (r_FIFO_RData),
            .o_Diag_State       (r_Diag_FIFO_State),
            .o_Diag_Buf_W_Addr  (r_Diag_FIFO_Buf_W_Addr),
            .o_Diag_Buf_R_Addr  (r_Diag_FIFO_Buf_R_Addr)
`endif
        );

`ifdef SIMULATION
    reg [2:0]   r_Diag_SPI_State;
    reg [17:0]  r_Diag_SPI_Data;
    reg [3:0]   r_Diag_SPI_Addr;
`endif
    spi
        #(  .CYCLES (SPI_CYCLES)
        ) spi_0 (
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),

            .o_Busy         (r_SPI_Busy),
            .i_Data_Ready   (r_SPI_Data_Rdy),
            .i_Data         (r_FIFO_RData),

            .o_Data_Valid   (o_Data_Valid),
            .o_Data         (o_Data),

            .o_SPI_Stb      (o_SPI_Stb),
            .o_SPI_Clk      (o_SPI_Clk),
`ifndef SIMULATION
            .io_SPI_Dio     (io_SPI_Dio)
`else
            .io_SPI_Dio     (io_SPI_Dio),
            .o_Diag_State   (r_Diag_SPI_State),
            .o_Diag_Data    (r_Diag_SPI_Data),
            .o_Diag_Addr    (r_Diag_SPI_Addr)
`endif
        );

    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_FIFO_Read    <= 0;
            r_SPI_Data_Rdy <= 0;
        end
        else begin
            if (r_SPI_Data_Rdy) begin
                // Pop the data from the FIFO and clear the input data ready signal at SPI
                r_FIFO_Read    <= 1;
                r_SPI_Data_Rdy <= 0;
            end
            else if (r_FIFO_Read) begin
                // This is needed to avoid automatically poping the next data from the FIFO
                r_FIFO_Read <= 0;
            end
            else begin
                if (~r_FIFO_Empty & ~r_SPI_Busy) begin
                    // Send the data from FIFO to SPI. This starts the 3-cycles transaction
                    // on the negative edge of the clock.
                    // 1) begin send data from FIFO to SPI
                    // 2) end sending data to SPI, begin popping data from FIFO
                    // 3) end popping data from FIFO
                    r_SPI_Data_Rdy <= 1;
                end
            end
        end
    end

`ifdef SIMULATION
    assign o_Diag_FIFO_Read    = r_FIFO_Read;
    assign o_Diag_FIFO_RData   = r_FIFO_RData;
    assign o_Diag_FIFO_Empty   = r_FIFO_Empty;
    assign o_Diag_SPI_Data_Rdy = r_SPI_Data_Rdy;
    assign o_Diag_SPI_Busy     = r_SPI_Busy;
`endif

endmodule
