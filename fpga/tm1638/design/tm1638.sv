`timescale 1 ns / 1 ps

// The top module for the design of the TM1638 driver.

module tm1638

    import tm1638_driver_types::*;
    import tm1638_types::*;

    #(
`ifdef SIMULATION
        parameter   STIMUL_CLK_CYCLES_DELAY = 0,
        parameter   SPI_CYCLES = 1,
        parameter   FIFO_DEPTH = 4
`else
        // GOWIN Tang Nano 20K FPGA. 27 MHz clock.
        parameter   STIMUL_CLK_CYCLES_DELAY = 540_000,  // 27 MHz -> 50 Hz update frequency
        parameter   SPI_CYCLES = 200,                   // 27 MHz -> ~67 kHz SPI clock
        parameter   FIFO_DEPTH = 16
`endif
    )(
        // Control signals
        input               i_Rst,
        input               i_Clk,
        input               i_Stimulus_Next,
`ifndef SIMULATION
        output              o_Clk,        // Clock signal to the FPGa pin for debugging
`endif

        // Output SPI signals
        output reg          o_SPI_Stb,
        output reg          o_SPI_Clk,
`ifndef SIMULATION
        output reg          o_SPI_Dio
`else
        output reg          o_SPI_Dio,

        // Diagnostic signals (this module)
        output reg          o_Diag_Segments_Valid,
        output reg          o_Diag_SPI_FIFO_Full,
        output reg [16:0]   o_Diag_Data,
        output reg          o_Diag_Data_Valid,

        // Diagnostic signals
        output state_t      o_Diag_Driver_State,
        output grid_t       o_Diag_Driver_Grid,
        output segments_t   o_Diag_Driver_Segments
`endif
    );

`ifndef SIMULATION
    assign o_Clk = i_Clk;
`endif

    segments_t  r_Segments_0;
    reg         r_Segments_Valid_0;
    tm1638_stimulus
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY)
        ) tm1638_stimulus_0 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),

            .o_Segments (r_Segments_0),
            .o_Valid    (r_Segments_Valid_0)
        );

    segments_t  r_Segments_1;
    reg         r_Segments_Valid_1;
    tm1638_stimulus_fixed
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SEG                        (8'h00)
        ) tm1638_stimulus_1 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),

            .o_Segments (r_Segments_1),
            .o_Valid    (r_Segments_Valid_1)
        );

    segments_t  r_Segments_2;
    reg         r_Segments_Valid_2;
    tm1638_stimulus_fixed
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SEG                        (8'ha0)
        ) tm1638_stimulus_2 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),

            .o_Segments (r_Segments_2),
            .o_Valid    (r_Segments_Valid_2)
        );

    segments_t  r_Segments_3;
    reg         r_Segments_Valid_3;
    tm1638_stimulus_fixed
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SEG                        (8'hff)
        ) tm1638_stimulus_3 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),

            .o_Segments (r_Segments_3),
            .o_Valid    (r_Segments_Valid_3)
        );

    reg [1:0] r_Stimulus_Sel;
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Stimulus_Sel <= 2'h0;
        end else if (i_Stimulus_Next) begin
            r_Stimulus_Sel <= r_Stimulus_Sel + 1'b1;
        end
    end

    segments_t  r_Segments;
    reg         r_Segments_Valid;
    always @(*) begin
        case (r_Stimulus_Sel)
            2'h0: begin
                r_Segments       = r_Segments_0;
                r_Segments_Valid = r_Segments_Valid_0;
            end
            2'h1: begin
                r_Segments       = r_Segments_1;
                r_Segments_Valid = r_Segments_Valid_1;
            end
            2'h2: begin
                r_Segments       = r_Segments_2;
                r_Segments_Valid = r_Segments_Valid_2;
            end
            2'h3: begin
                r_Segments       = r_Segments_3;
                r_Segments_Valid = r_Segments_Valid_3;
            end
            default: begin
                r_Segments       = '0;
                r_Segments_Valid = 0;
            end
        endcase
    end

    reg         r_SPI_FIFO_Full;
    reg [16:0]  r_Data;
    reg         r_Data_Valid;
    tm1638_driver
        tm1638_driver_0 (
            .i_Rst              (i_Rst),
            .i_Clk              (i_Clk),

            .i_Segments         (r_Segments),
            .i_Valid            (r_Segments_Valid),

            .i_SPI_FIFO_Full    (r_SPI_FIFO_Full),
            .o_Data             (r_Data),
`ifndef SIMULATION
            .o_Write            (r_Data_Valid)
`else
            .o_Write            (r_Data_Valid),

            .o_Diag_State       (o_Diag_Driver_State),
            .o_Diag_Grid        (o_Diag_Driver_Grid),
            .o_Diag_Segments    (o_Diag_Driver_Segments)
`endif
        );

    spi_fifo
        #(  .SPI_CYCLES (SPI_CYCLES),
            .FIFO_DEPTH (FIFO_DEPTH)
        ) spi_fifo_0 (
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),

            .o_FIFO_Full    (r_SPI_FIFO_Full),
            .i_Data_Valid   (r_Data_Valid),
            .i_Data         (r_Data),

            .o_SPI_Stb      (o_SPI_Stb),
            .o_SPI_Clk      (o_SPI_Clk),
            .o_SPI_Dio      (o_SPI_Dio)
        );

`ifdef SIMULATION
    assign o_Diag_Segments_Valid = r_Segments_Valid;
    assign o_Diag_SPI_FIFO_Full  = r_SPI_FIFO_Full;
    assign o_Diag_Data           = r_Data;
    assign o_Diag_Data_Valid     = r_Data_Valid;
`endif

endmodule
