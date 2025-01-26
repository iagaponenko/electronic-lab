`timescale 1 ns / 1 ps

// The top module for the design of the TM1638 driver.

module tm1638

    import tm1638_driver_types::*;
    import tm1638_types::*;
    import led7_types::*;

    #(
`ifdef SIMULATION
        parameter   STIMUL_CLK_CYCLES_DELAY = 0,
        parameter   SPI_CYCLES = 1,
        parameter   SPI_READ_DELAY_CYCLES = 1,  // The number of cycles to wait before reading the data from the SPI device
        parameter   SPI_READ_WIDTH = 8,         // The width of the data read from the SPI device (must be a power of 2)
        parameter   FIFO_DEPTH = 4,
        parameter   KEY_RESET_CYCLES = 0
`else
        // GOWIN Tang Nano 20K FPGA. 27 MHz clock.
        parameter   STIMUL_CLK_CYCLES_DELAY = 540_000,      // 27 MHz ->   50 Hz update frequency
        parameter   SPI_CYCLES = 200,                       // 27 MHz -> ~67 kHz SPI clock
        parameter   SPI_READ_DELAY_CYCLES = 200,            // The number of cycles to wait before reading the data from the SPI device (about 7.4 us for 27 MHz, or 2 us for 100 MHz)
        parameter   SPI_READ_WIDTH = 32,                    // The width of the data read from the SPI device (must be a power of 2)
        parameter   FIFO_DEPTH = 16,
        parameter   DEBOUNCE_CYCLES = 27_000,               // 27 MHz -> 1 kHz debounce frequency (1 ms)
        parameter   KEY_RESET_CYCLES = 27_000_000           // 27 MHz -> 1 Hz reset frequency (1 s)
`endif
    )(
        // Control signals
        input               i_Rst,
        input               i_Clk,
        input               i_Stimulus_Next,
        input               i_Encoder_Btn,      // Button signal from the rotary encoder
        input               i_Encoder_A,        // A signal from the rotary encoder
        input               i_Encoder_B,        // B signal from the rotary encoder
`ifndef SIMULATION
        output              o_Clk,        // Clock signal to the FPGa pin for debugging
`endif

        // Output SPI signals
        output reg          o_SPI_Stb,
        output reg          o_SPI_Clk,
`ifndef SIMULATION
        inout  reg          io_SPI_Dio
`else
        inout  reg          io_SPI_Dio,

        // Diagnostic signals (this module)
        output reg          o_Diag_Segments_Valid,
        output reg          o_Diag_SPI_FIFO_Full,
        output reg [17:0]   o_Diag_Data,
        output reg          o_Diag_Data_Valid,

        // Diagnostic signals
        output state_t      o_Diag_Driver_State,
        output grid_t       o_Diag_Driver_Grid,
        output segments_t   o_Diag_Driver_Segments,
        output leds_t       o_Diag_Driver_Leds
`endif
    );

`ifndef SIMULATION
    assign o_Clk = r_Out_Data[0];
`endif

    localparam S0 = 8'b00111111;
    localparam S1 = 8'b00000110;
    localparam S2 = 8'b01011011;
    localparam S3 = 8'b01001111;
    localparam S4 = 8'b01100110;
    localparam S5 = 8'b01101101;
    localparam S6 = 8'b01111101;
    localparam S7 = 8'b00000111;

    segments_t  r_Segments_0;
    leds_t      r_Leds_0;
    reg         r_Segments_Valid_0;
    tm1638_stimulus
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY)
        ) tm1638_stimulus_0 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),
            .o_Segments (r_Segments_0),
            .o_Leds     (r_Leds_0),
            .o_Valid    (r_Segments_Valid_0)
        );

    segments_t  r_Segments_1;
    leds_t      r_Leds_1;
    reg         r_Segments_Valid_1;
    tm1638_stimulus_fixed
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SEG                        (S0),
            .LEDS                       (8'b10000000)
        ) tm1638_stimulus_1 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),
            .o_Segments (r_Segments_1),
            .o_Leds     (r_Leds_1),
            .o_Valid    (r_Segments_Valid_1)
        );

    segments_t  r_Segments_2;
    leds_t      r_Leds_2;
    reg         r_Segments_Valid_2;
    tm1638_stimulus_fixed
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SEG                        (S1),
            .LEDS                       (8'b01000000)
        ) tm1638_stimulus_2 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),
            .o_Segments (r_Segments_2),
            .o_Leds     (r_Leds_2),
            .o_Valid    (r_Segments_Valid_2)
        );

    segments_t  r_Segments_3;
    leds_t      r_Leds_3;
    reg         r_Segments_Valid_3;
    tm1638_stimulus_fixed
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SEG                        (S2),
            .LEDS                       (8'b00100000)
        ) tm1638_stimulus_3 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),
            .o_Segments (r_Segments_3),
            .o_Leds     (r_Leds_3),
            .o_Valid    (r_Segments_Valid_3)
        );

    segments_t  r_Segments_4;
    leds_t      r_Leds_4;
    reg         r_Segments_Valid_4;
    tm1638_stimulus_fixed
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SEG                        (S3),
            .LEDS                       (8'b00010000)
        ) tm1638_stimulus_4 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),
            .o_Segments (r_Segments_4),
            .o_Leds     (r_Leds_4),
            .o_Valid    (r_Segments_Valid_4)
        );

    reg  [SPI_READ_WIDTH-1:0]   r_Out_Data;     // The input signal for keys pressed on the TM1638.
    wire [SPI_READ_WIDTH-1:0]   w_Out_Data;     // The pulses for keys pressed on the TM1638.
`ifdef SIMULATION
    // In simulation, the stimulus is controlled by the testbench. And the debouncing nodule is not used.
    // It's tested separately in the testbench.
    assign w_Out_Data = r_Out_Data;
`else
    reg  [SPI_READ_WIDTH-1:0]   r_Out_Data_debounced;
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_0 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY0]), .o_Data (r_Out_Data_debounced[KEY0]));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_1 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY1]), .o_Data (r_Out_Data_debounced[KEY1]));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_2 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY2]), .o_Data (r_Out_Data_debounced[KEY2]));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_3 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY3]), .o_Data (r_Out_Data_debounced[KEY3]));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_4 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY4]), .o_Data (r_Out_Data_debounced[KEY4]));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_5 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY5]), .o_Data (r_Out_Data_debounced[KEY5]));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_6 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY6]), .o_Data (r_Out_Data_debounced[KEY6]));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_7 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (r_Out_Data[KEY7]), .o_Data (r_Out_Data_debounced[KEY7]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_0 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY0]), .o_Data(w_Out_Data[KEY0]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_1 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY1]), .o_Data(w_Out_Data[KEY1]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_2 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY2]), .o_Data(w_Out_Data[KEY2]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_3 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY3]), .o_Data(w_Out_Data[KEY3]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_4 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY4]), .o_Data(w_Out_Data[KEY4]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_5 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY5]), .o_Data(w_Out_Data[KEY5]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_6 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY6]), .o_Data(w_Out_Data[KEY6]));
    pulse #(.RESET_CYCLES(KEY_RESET_CYCLES)) pulse_7 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Out_Data_debounced[KEY7]), .o_Data(w_Out_Data[KEY7]));
`endif

    wire    w_Encoder_Btn;     // The pulses for a button pressed on the encoder.
`ifdef SIMULATION
    // In simulation, the stimulus is controlled by the testbench. And the debouncing nodule is not used.
    // It's tested separately in the testbench.
    assign  w_Encoder_Btn = ~i_Encoder_Btn;
`else
    reg     r_Encoder_Btn_debounced;
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES))  debounce_encoder_btn (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(~i_Encoder_Btn),          .o_Data(r_Encoder_Btn_debounced));
    pulse    #(.RESET_CYCLES    (KEY_RESET_CYCLES)) pulse_encoder_btn    (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(r_Encoder_Btn_debounced), .o_Data(w_Encoder_Btn));
`endif

    wire    w_Encoder_A;
    wire    w_Encoder_B;
`ifdef SIMULATION
    // In simulation, the stimulus is controlled by the testbench. And the debouncing nodule is not used.
    // It's tested separately in the testbench.
    assign w_Encoder_A = i_Encoder_A;
    assign w_Encoder_B = i_Encoder_B;
`else
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_encoder_a (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (i_Encoder_A), .o_Data (w_Encoder_A));
    debounce #(.DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)) debounce_encoder_b (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data (i_Encoder_B), .o_Data (w_Encoder_B));
`endif

    reg r_Encoder_Left;
    reg r_Encoder_Right;
    encoder encoder_0 (
        .i_Rst      (i_Rst),
        .i_Clk      (i_Clk),
        .i_A        (w_Encoder_A),
        .i_B        (w_Encoder_B),
        .o_Left     (r_Encoder_Left),
        .o_Right    (r_Encoder_Right)
    );

    segments_t  r_Segments_5;
    leds_t      r_Leds_5;
    reg         r_Segments_Valid_5;
    tm1638_stimulus_encoder
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY)
        ) tm1638_stimulus_5 (
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),
            .i_Data_Pulse   (w_Out_Data),       // 1 clock cycle long pulses on keys pressed
            .i_Encoder_Btn  (w_Encoder_Btn),    // 1 clock cycle long pulses on keys pressed
            .i_Encoder_Left (r_Encoder_Left),
            .i_Encoder_Right(r_Encoder_Right),
            .o_Segments     (r_Segments_5),
            .o_Leds         (r_Leds_5),
            .o_Valid        (r_Segments_Valid_5)
        );

    segments_t  r_Segments_6;
    leds_t      r_Leds_6;
    reg         r_Segments_Valid_6;
    tm1638_stimulus_keys2cntr
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SPI_READ_WIDTH             (SPI_READ_WIDTH)
        ) tm1638_stimulus_6 (
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),
            .i_Data_Pulse   (w_Out_Data),   // 1 clock cycle long pulses on keys pressed
            .o_Segments     (r_Segments_6),
            .o_Leds         (r_Leds_6),
            .o_Valid        (r_Segments_Valid_6)
        );

    segments_t  r_Segments_7;
    leds_t      r_Leds_7;
    reg         r_Segments_Valid_7;
    tm1638_stimulus_keys
        #(  .STIMUL_CLK_CYCLES_DELAY    (STIMUL_CLK_CYCLES_DELAY),
            .SPI_READ_WIDTH             (SPI_READ_WIDTH)
        ) tm1638_stimulus_7 (
            .i_Rst      (i_Rst),
            .i_Clk      (i_Clk),
            .i_Data     (r_Out_Data),   // continuous data on keys pressed
            .o_Segments (r_Segments_7),
            .o_Leds     (r_Leds_7),
            .o_Valid    (r_Segments_Valid_7)
        );

    wire w_Stimulus_Next;
`ifdef SIMULATION
    // In simulation, the stimulus is controlled by the testbench. And the debouncing nodule is not used.
    // It's tested separately in the testbench.
    assign w_Stimulus_Next = i_Stimulus_Next;
`else
    reg r_Stimulus_Next;
    debounce
        #(  .DEBOUNCE_CYCLES (DEBOUNCE_CYCLES)
        ) debounce_stimulus (
        .i_Rst  (i_Rst),
        .i_Clk  (i_Clk),
        .i_Data (i_Stimulus_Next),
        .o_Data (r_Stimulus_Next)
    );
    pulse pulse_stimulus (
        .i_Rst  (i_Rst),
        .i_Clk  (i_Clk),
        .i_Data (r_Stimulus_Next),
        .o_Data (w_Stimulus_Next)
    );
`endif

    reg [2:0] r_Stimulus_Sel = 3'h5;
    always @(posedge i_Clk) begin
        if (i_Rst) begin
            r_Stimulus_Sel <= 3'h5;
        end
        else if (w_Stimulus_Next) begin
            r_Stimulus_Sel <= r_Stimulus_Sel + 1'b1;
        end
        else begin
            r_Stimulus_Sel <= r_Stimulus_Sel;
        end
    end

    segments_t  r_Segments;
    leds_t      r_Leds;
    reg         r_Segments_Valid;
    always @(*) begin
        case (r_Stimulus_Sel)
            3'h0: begin
                r_Segments       = r_Segments_0;
                r_Leds           = r_Leds_0;
                r_Segments_Valid = r_Segments_Valid_0;
            end
            3'h1: begin
                r_Segments       = r_Segments_1;
                r_Leds           = r_Leds_1;
                r_Segments_Valid = r_Segments_Valid_1;
            end
            3'h2: begin
                r_Segments       = r_Segments_2;
                r_Leds           = r_Leds_2;
                r_Segments_Valid = r_Segments_Valid_2;
            end
            3'h3: begin
                r_Segments       = r_Segments_3;
                r_Leds           = r_Leds_3;
                r_Segments_Valid = r_Segments_Valid_3;
            end
            3'h4: begin
                r_Segments       = r_Segments_4;
                r_Leds           = r_Leds_4;
                r_Segments_Valid = r_Segments_Valid_4;
            end
            3'h5: begin
                r_Segments       = r_Segments_5;
                r_Leds           = r_Leds_5;
                r_Segments_Valid = r_Segments_Valid_5;
            end
            3'h6: begin
                r_Segments       = r_Segments_6;
                r_Leds           = r_Leds_6;
                r_Segments_Valid = r_Segments_Valid_6;
            end
            3'h7: begin
                r_Segments       = r_Segments_7;
                r_Leds           = r_Leds_7;
                r_Segments_Valid = r_Segments_Valid_7;
            end
            default: begin
                r_Segments       = '0;
                r_Leds           = '0;
                r_Segments_Valid = 0;
            end
        endcase
    end

    reg         r_SPI_FIFO_Full;
    reg [17:0]  r_Data;
    reg         r_Data_Valid;
    tm1638_driver
        tm1638_driver_0 (
            .i_Rst              (i_Rst),
            .i_Clk              (i_Clk),

            .i_Segments         (r_Segments),
            .i_Leds             (r_Leds),
            .i_Valid            (r_Segments_Valid),

            .i_SPI_FIFO_Full    (r_SPI_FIFO_Full),
            .o_Data             (r_Data),
`ifndef SIMULATION
            .o_Write            (r_Data_Valid)
`else
            .o_Write            (r_Data_Valid),

            .o_Diag_State       (o_Diag_Driver_State),
            .o_Diag_Grid        (o_Diag_Driver_Grid),
            .o_Diag_Segments    (o_Diag_Driver_Segments),
            .o_Diag_Leds        (o_Diag_Driver_Leds)
`endif
        );

    spi_fifo
        #(  .SPI_CYCLES             (SPI_CYCLES),
            .SPI_READ_DELAY_CYCLES  (SPI_READ_DELAY_CYCLES),
            .SPI_READ_WIDTH         (SPI_READ_WIDTH),
            .FIFO_DEPTH (FIFO_DEPTH)
        ) spi_fifo_0 (
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),

            .o_FIFO_Full    (r_SPI_FIFO_Full),
            .i_Data_Valid   (r_Data_Valid),
            .i_Data         (r_Data),

            .o_Data         (r_Out_Data),

            .o_SPI_Stb      (o_SPI_Stb),
            .o_SPI_Clk      (o_SPI_Clk),
            .io_SPI_Dio     (io_SPI_Dio)
        );

`ifdef SIMULATION
    assign o_Diag_Segments_Valid = r_Segments_Valid;
    assign o_Diag_SPI_FIFO_Full  = r_SPI_FIFO_Full;
    assign o_Diag_Data           = r_Data;
    assign o_Diag_Data_Valid     = r_Data_Valid;
`endif

endmodule
