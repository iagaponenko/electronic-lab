`ifndef SIMPLE_MAX7219_DRIVER

`timescale 1 ns / 1 ps

// NOTE: state transitions on the negative edge of i_Clk. This is because the SPI interface
//      latches input signals on the posedge of i_Clk.

module max7219_driver

    #(
        parameter   SEG_ROWS                = 1,
        parameter   SEG_COLS                = 1,
        parameter   SPI_CYCLES              = 1,
        parameter   DISPLAY_UPDATE_CYCLES   = 1,
        parameter   FB_YSIZE                = SEG_ROWS * 8,
        parameter   FB_XSIZE                = SEG_COLS * 8
    )(
        // Control signals
        input reg   i_Rst,
        input reg   i_Clk,

        input reg   [0:FB_YSIZE-1][0:FB_XSIZE-1]        i_FrameBuf,     // [y][x]
        input reg   [SEG_ROWS-1:0][SEG_COLS-1:0][0:15]  i_Intensity,    // [row][col][level]

        // Output SPI signals
        output reg      o_SPI_Stb,
        output reg      o_SPI_Clk,
        output reg      o_SPI_Din
    );

    // max7219 registers and control commands

    localparam  HDR = 4'b0000;

    localparam  REG_NOP     = 4'b0000;
    localparam  DATA_NOP    = 8'b00000000;

    localparam  REG_SHUT            = 4'b1100;
    localparam  DATA_SHUT_DOWN      = 8'b00000000;
    localparam  DATA_SHUT_NORMAL    = 8'b00000001;

    localparam  REG_BCD_ENCODE          = 4'b1001;
    localparam  DATA_BCD_ENCODE_NONE    = 8'b00000000;

    localparam  REG_SCAN            = 4'b1011;
    localparam  DATA_SCAN_01234567  = 8'b00000111;

    localparam  REG_TEST            = 4'b1111;
    localparam  DATA_TEST           = 8'b00000001;
    localparam  DATA_NO_TEST        = 8'b00000000;

    localparam  REG_INTENSITY   = 4'b1010;
    wire [0:15][7:0]  DATA_INTENSITY = {
        8'b00000000, 8'b00000001, 8'b00000010, 8'b00000011, 8'b00000100, 8'b00000101, 8'b00000110, 8'b00000111,
        8'b00001000, 8'b00001001, 8'b00001010, 8'b00001011, 8'b00001100, 8'b00001101, 8'b00001110, 8'b00001111
    };
`ifdef __ICARUS__
    initial begin
        $display("max7219_driver: DATA_INTENSITY[ 0] %b", DATA_INTENSITY[ 0]);
        $display("max7219_driver: DATA_INTENSITY[ 1] %b", DATA_INTENSITY[ 1]);
        $display("max7219_driver: DATA_INTENSITY[ 2] %b", DATA_INTENSITY[ 2]);
        $display("max7219_driver: DATA_INTENSITY[ 3] %b", DATA_INTENSITY[ 3]);
        $display("max7219_driver: DATA_INTENSITY[ 4] %b", DATA_INTENSITY[ 4]);
        $display("max7219_driver: DATA_INTENSITY[ 5] %b", DATA_INTENSITY[ 5]);
        $display("max7219_driver: DATA_INTENSITY[ 6] %b", DATA_INTENSITY[ 6]);
        $display("max7219_driver: DATA_INTENSITY[ 7] %b", DATA_INTENSITY[ 7]);
        $display("max7219_driver: DATA_INTENSITY[ 8] %b", DATA_INTENSITY[ 8]);
        $display("max7219_driver: DATA_INTENSITY[ 9] %b", DATA_INTENSITY[ 9]);
        $display("max7219_driver: DATA_INTENSITY[10] %b", DATA_INTENSITY[10]);
        $display("max7219_driver: DATA_INTENSITY[11] %b", DATA_INTENSITY[11]);
        $display("max7219_driver: DATA_INTENSITY[12] %b", DATA_INTENSITY[12]);
        $display("max7219_driver: DATA_INTENSITY[13] %b", DATA_INTENSITY[13]);
        $display("max7219_driver: DATA_INTENSITY[14] %b", DATA_INTENSITY[14]);
        $display("max7219_driver: DATA_INTENSITY[15] %b", DATA_INTENSITY[15]);
    end
`endif

    // The 8-bit register address is used to select the corresponding 8-bit row of the 8x8 dot display.
    // [row][register]
    wire [7:0][3:0]  REG_ROW = {
        4'b00000001, 4'b00000010, 4'b00000011, 4'b00000100, 4'b00000101, 4'b00000111, 4'b00000111, 4'b00001000
    };
`ifdef __ICARUS__
    initial begin
        $display("max7219_driver: REG_ROW[0] %b", REG_ROW[0]);
        $display("max7219_driver: REG_ROW[1] %b", REG_ROW[1]);
        $display("max7219_driver: REG_ROW[2] %b", REG_ROW[2]);
        $display("max7219_driver: REG_ROW[3] %b", REG_ROW[3]);
        $display("max7219_driver: REG_ROW[4] %b", REG_ROW[4]);
        $display("max7219_driver: REG_ROW[5] %b", REG_ROW[5]);
        $display("max7219_driver: REG_ROW[6] %b", REG_ROW[6]);
        $display("max7219_driver: REG_ROW[7] %b", REG_ROW[7]);
    end
`endif

    // The stripes are sequences of bits sent along the corresponidng 8-bit rows of
    // the connected 8x8 dot displays. The stripes are generated from the 8-bit sequnces of
    // buffer pixels prepended by the 4-bit header and the 4-bit regsiter address.

    localparam  SPI_DATA_WIDTH  = 2 * 8 * SEG_ROWS * SEG_COLS;

    reg [0:FB_YSIZE-1][0:FB_XSIZE-1]    r_FrameBuf;         // [y][x]
    wire    [7:0][SPI_DATA_WIDTH-1:0]   w_Pixel_Stripes;    // [pos][stripe]
    wire    [SPI_DATA_WIDTH-1:0]        w_Nop_Stripe;
    wire    [SPI_DATA_WIDTH-1:0]        w_Shut_Down_Stripe;
    wire    [SPI_DATA_WIDTH-1:0]        w_Shut_Normal_Stripe;
    wire    [SPI_DATA_WIDTH-1:0]        w_Test_Stripe;
    wire    [SPI_DATA_WIDTH-1:0]        w_No_Test_Stripe;
    wire    [SPI_DATA_WIDTH-1:0]        w_Bcd_Encode_None_Stripe;
    wire    [SPI_DATA_WIDTH-1:0]        w_Scan_Stripe;
    wire    [SPI_DATA_WIDTH-1:0]        w_Intensity_Stripe;

    generate
        genvar  stripe;
        genvar  col;
        genvar  row;
        genvar  pix;
        for (stripe = 0; stripe < 8; stripe = stripe + 1) begin     : STRIPE_GEN
            for (row = 0; row < SEG_ROWS; row = row + 1) begin      : ROW_GEN
                for (col = 0; col < SEG_COLS; col = col + 1) begin  : COL_GEN
                    // assign w_Pixel_Stripes[stripe][2 * 8 * (SEG_ROWS - 1 - row) * SEG_COLS + 2 * 8 * (SEG_COLS - 1 - col) + 15 -: 8] = {HDR, REG_ROW[stripe]};
                    // for (pix = 0; pix < 8; pix = pix + 1) begin     : PIX_GEN
                    //     assign w_Pixel_Stripes[stripe][2 * 8 * (SEG_ROWS - 1 - row) * SEG_COLS + 2 * 8 * (SEG_COLS - 1 - col) + 7 - pix] = i_FrameBuf[8 * row + stripe][8 * col + pix];
                    // end
                    assign w_Pixel_Stripes[stripe][2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 8] = {HDR, REG_ROW[7 - stripe]};
                    for (pix = 0; pix < 8; pix = pix + 1) begin     : PIX_GEN
                        assign w_Pixel_Stripes[stripe][2 * 8 * row * SEG_COLS + 2 * 8 * col + 7 - pix] = r_FrameBuf[8 * row + stripe][8 * col + pix];
                    end
                end
            end
        end
        for (row = 0; row < SEG_ROWS; row = row + 1) begin      : ROW_GEN
            for (col = 0; col < SEG_COLS; col = col + 1) begin  : COL_GEN
                assign w_Nop_Stripe             [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_NOP,        DATA_NOP};
                assign w_Shut_Down_Stripe       [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_SHUT,       DATA_SHUT_DOWN};
                assign w_Shut_Normal_Stripe     [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_SHUT,       DATA_SHUT_NORMAL};
                assign w_Test_Stripe            [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_TEST,       DATA_TEST};
                assign w_No_Test_Stripe         [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_TEST,       DATA_NO_TEST};
                assign w_Bcd_Encode_None_Stripe [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_BCD_ENCODE, DATA_BCD_ENCODE_NONE};
                assign w_Scan_Stripe            [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_SCAN,       DATA_SCAN_01234567};
                assign w_Intensity_Stripe       [2 * 8 * row * SEG_COLS + 2 * 8 * col + 15 -: 16] = {HDR, REG_INTENSITY,  DATA_INTENSITY[i_Intensity[row][col]]};
            end
        end
    endgenerate

`ifdef __ICARUS__
    initial begin
        #2;
        $display("max7219_driver: w_Nop_Stripe             %b", w_Nop_Stripe);
        $display("max7219_driver: w_Shut_Down_Stripe       %b", w_Shut_Down_Stripe);
        $display("max7219_driver: w_Shut_Normal_Stripe     %b", w_Shut_Normal_Stripe);
        $display("max7219_driver: w_No_Test_Stripe         %b", w_No_Test_Stripe);
        $display("max7219_driver: w_Bcd_Encode_None_Stripe %b", w_Bcd_Encode_None_Stripe);
        $display("max7219_driver: w_Scan_Stripe            %b", w_Scan_Stripe);
        $display("max7219_driver: w_Intensity_Stripe       %b", w_Intensity_Stripe);
        $display("max7219_driver:");
        for (int stripe = 7; stripe >= 0; stripe = stripe - 1) begin
            $display("max7219_driver: w_Pixel_Stripes[%1d]       %b", stripe, w_Pixel_Stripes[stripe]);
        end
        $display("max7219_driver:");
        for (int row = FB_YSIZE - 1; row >= 0; row = row - 1) begin
            $display("max7219_driver: i_FrameBuf[%3d]       %b", row, i_FrameBuf[row]);
        end
    end
`endif

    // SPI control signals
    reg                         r_SPI_Busy;
    reg                         r_Data_Valid    = 1'b0;
    reg [SPI_DATA_WIDTH-1:0]    r_Data          = w_Nop_Stripe;

    spi_max7219
        #(  .CYCLES     (SPI_CYCLES),
            .DATA_WIDTH (SPI_DATA_WIDTH)
        ) spi_max7219_0 (
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),

            .o_Busy         (r_SPI_Busy),
            .i_Data_Ready   (r_Data_Valid),
            .i_Data         (r_Data),

            .o_SPI_Stb      (o_SPI_Stb),
            .o_SPI_Clk      (o_SPI_Clk),
            .o_SPI_Din      (o_SPI_Din)
        );

    reg [2:0]   r_Pixel_Stripe          = 3'h0;
    reg [31:0]  r_Display_Update_Cycles = '0;   // up to 4 billion cycles

    // State transition logic
    typedef enum {
        IDLE                    = 0,
        WAIT_SET_SHUT_DOWN      = 1,
        SET_SHUT_DOWN           = 2,
        WAIT_SET_SHUT_NORMAL    = 3,
        SET_SHUT_NORMAL         = 4,
        WAIT_SET_NO_TEST        = 5,
        SET_NO_TEST             = 6,
        WAIT_SET_BCD_NO_ENCODE  = 7,
        SET_BCD_NO_ENCODE       = 8,
        WAIT_SET_SCAN           = 9,
        SET_SCAN                = 10,
        WAIT_SET_INTENSITY      = 11,
        SET_INTENSITY           = 12,
        WAIT_SET_PIXELS         = 13,
        SET_PIXELS              = 14,
        DISPLAY_UPDATE_PAUSE    = 15
    } state_t;

    state_t r_State = IDLE;
    state_t r_State_Next;

    // ----------------------
    // State transition logic
    // ----------------------
    //
    // NOTE: state transitions to the next state always go via the corresponding WAIT_ state
    //       to allow the SPI interface to accept the next data. This will ad 1 more clock cycle.
    //       Otherwise the data will be overwritten by the next state transition.

    // Next state computation
    function state_t next(input cond, input state_t if_true, input state_t if_false);
        if (cond) return if_true;
        else      return if_false;
    endfunction

    always @(*) begin
        case (r_State)
            IDLE:
                r_State_Next = WAIT_SET_SHUT_DOWN;
            WAIT_SET_SHUT_DOWN :
                r_State_Next = next(r_SPI_Busy,
                                    WAIT_SET_SHUT_DOWN,
                                    SET_SHUT_DOWN);
            SET_SHUT_DOWN:
                r_State_Next = WAIT_SET_SHUT_NORMAL;
            WAIT_SET_SHUT_NORMAL :
                r_State_Next = next(r_SPI_Busy,
                                    WAIT_SET_SHUT_NORMAL,
                                    SET_SHUT_NORMAL);
            SET_SHUT_NORMAL:
                r_State_Next = WAIT_SET_NO_TEST;
            WAIT_SET_NO_TEST :
                r_State_Next = next(r_SPI_Busy,
                                    WAIT_SET_NO_TEST,
                                    SET_NO_TEST);
            SET_NO_TEST:
                r_State_Next = WAIT_SET_BCD_NO_ENCODE;
            WAIT_SET_BCD_NO_ENCODE:
                r_State_Next = next(r_SPI_Busy,
                                    WAIT_SET_BCD_NO_ENCODE,
                                    SET_BCD_NO_ENCODE);
            SET_BCD_NO_ENCODE:
                r_State_Next = WAIT_SET_SCAN;
            WAIT_SET_SCAN:
                r_State_Next = next(r_SPI_Busy,
                                    WAIT_SET_SCAN,
                                    SET_SCAN);
            SET_SCAN:
                r_State_Next = WAIT_SET_INTENSITY;
            WAIT_SET_INTENSITY:
                r_State_Next = next(r_SPI_Busy,
                                    WAIT_SET_INTENSITY,
                                    SET_INTENSITY);
            SET_INTENSITY:
                r_State_Next = WAIT_SET_PIXELS;
            WAIT_SET_PIXELS:
                r_State_Next = next(r_SPI_Busy,
                                    WAIT_SET_PIXELS,
                                    SET_PIXELS);
            SET_PIXELS:
                r_State_Next = next(r_Pixel_Stripe == 3'h7,
                                    DISPLAY_UPDATE_PAUSE,
                                    WAIT_SET_PIXELS);
            DISPLAY_UPDATE_PAUSE:
                r_State_Next = next(r_Display_Update_Cycles == DISPLAY_UPDATE_CYCLES,
                                    IDLE, // WAIT_SET_PIXELS,
                                    DISPLAY_UPDATE_PAUSE);
            default:
                r_State_Next = IDLE;
        endcase
    end

    // State transition DFF
    always @(negedge i_Clk) begin
        if (i_Rst) r_State <= IDLE;
        else       r_State <= r_State_Next;
    end

    // Stripe feader logic
    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_FrameBuf              <= '0;
            r_Data_Valid            <= 1'b0;
            r_Pixel_Stripe          <= 3'h0;
            r_Display_Update_Cycles <= '0;
        end
        else begin
            r_Data_Valid <= 1'b0;
            if (r_Data_Valid) begin
                r_Data_Valid <= 1'b0;
            end
            else begin
                case (r_State)
                    SET_SHUT_DOWN: begin
                        r_Data <= w_Shut_Down_Stripe;
                        r_Data_Valid <= 1'b1;
                    end
                    SET_SHUT_NORMAL: begin
                        r_Data <= w_Shut_Normal_Stripe;
                        r_Data_Valid <= 1'b1;
                    end
                    SET_NO_TEST: begin
                        r_Data <= w_No_Test_Stripe;
                        r_Data_Valid <= 1'b1;
                    end
                    SET_BCD_NO_ENCODE: begin
                        r_Data  <= w_Bcd_Encode_None_Stripe;
                        r_Data_Valid <= 1'b1;
                    end
                    SET_INTENSITY: begin
                        r_Data  <= w_Intensity_Stripe;
                        r_Data_Valid <= 1'b1;
                    end
                    SET_SCAN: begin
                        r_Data  <= w_Scan_Stripe;
                        r_Pixel_Stripe  <= 3'h0;
                        r_Data_Valid <= 1'b1;
                        r_FrameBuf <= i_FrameBuf;
                    end
                    SET_PIXELS: begin
                        r_Data <= w_Pixel_Stripes[r_Pixel_Stripe];
                        // r_Data <= {
                        //     HDR, 4'b0001, 8'b00000001,
                        //     HDR, 4'b0010, 8'b00000010,
                        //     HDR, 4'b0011, 8'b00000100,
                        //     HDR, 4'b0100, 8'b00001000,
                        //     HDR, 4'b0101, 8'b00010000,
                        //     HDR, 4'b0110, 8'b00100000,
                        //     HDR, 4'b0111, 8'b01000000,
                        //     HDR, 4'b1000, 8'b10000000,
                        //     HDR, 4'b0001, 8'b00000001,
                        //     HDR, 4'b0010, 8'b00000010,
                        //     HDR, 4'b0011, 8'b00000100,
                        //     HDR, 4'b0100, 8'b00001000,
                        //     HDR, 4'b0101, 8'b00010000,
                        //     HDR, 4'b0110, 8'b00100000,
                        //     HDR, 4'b0111, 8'b01000000,
                        //     HDR, 4'b1000, 8'b10000000,
                        //     HDR, 4'b0001, 8'b00000001,
                        //     HDR, 4'b0010, 8'b00000010,
                        //     HDR, 4'b0011, 8'b00000100,
                        //     HDR, 4'b0100, 8'b00001000
                        // };
                        if (r_Pixel_Stripe == 3'h7) begin
                            r_Pixel_Stripe  <= 3'h0;
                            r_Display_Update_Cycles <= '0;
                        end
                        else begin
                            r_Pixel_Stripe <= r_Pixel_Stripe + 1'b1;
                        end
                        r_Data_Valid <= 1'b1;
                    end
                    DISPLAY_UPDATE_PAUSE: begin
                        r_Display_Update_Cycles <= r_Display_Update_Cycles + 1'b1;
                        r_Data <= w_Nop_Stripe;
                        r_Data_Valid <= 1'b1;
                    end
                    default: begin
                        r_Data_Valid <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule

`endif
