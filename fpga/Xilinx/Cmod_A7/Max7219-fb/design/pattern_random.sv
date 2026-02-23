`timescale 1 ns / 1 ps

// The generator for a random pattern using the random number generator.

module pattern_random

    import max7219_types::*;

    #(  parameter DISP_ROWS     = 1,
        parameter DISP_COLUMNS  = 1,
        parameter CLK_FREQ_HZ   = 1     // 1 Hz
    )(
        input  wire i_Clk,
        input  wire i_Rst,
        output wire [0:7][DISP_ROWS-1:0][DISP_COLUMNS-1:0][15:0] o_MAX7219_DataStream
    );

    // Data registers of the MAX7219 device are complied here for easier access.
    // Note that the function max7219_types::REG_ROW can't be used in the generated code below,
    // so we need to make the assignment here as an alternative solution.

    wire [7:0][3:0] w_REG_ROW = {
        REG_ROW_0, REG_ROW_1, REG_ROW_2, REG_ROW_3, REG_ROW_4, REG_ROW_5, REG_ROW_6, REG_ROW_7
    };

    // The framebuffer

    localparam  FB_WIDTH  = DISP_COLUMNS * 8;
    localparam  FB_HEIGHT = DISP_ROWS    * 8;

    reg fb [0:FB_HEIGHT-1][0:FB_WIDTH-1];

    task clear_fb;
        integer i, j;
        begin
            for (i = 0; i < FB_HEIGHT; i = i + 1) begin
                for (j = 0; j < FB_WIDTH; j = j + 1) begin
                    fb[i][j] <= 1'b0;
                end
            end
        end
    endtask

    task set_row (input integer y, input logic [0:FB_WIDTH-1] data);
        integer x;
        begin
            for (x = 0; x < FB_WIDTH; x = x + 1) begin
                fb[y][x] <= data[x];
            end
        end
    endtask

    // Streams of data to be pushed to the MAX7219 device. There are 8 such streams,
    // one per each row of the 8x8 dot displays.
    // We have to do the mapping it in this way using a generate statement since the streaming
    // concatenation operator {<<{data}} uswed by the macro `MSB is not supported in
    // the non-assignment context.

    generate
        genvar s, r, c;
        for (s = 0; s < 8; s = s + 1) begin : STREAM_GEN
            for (r = 0; r < DISP_ROWS; r = r + 1) begin : ROW_GEN
                for (c = 0; c < DISP_COLUMNS; c = c + 1) begin : COL_GEN
                    assign o_MAX7219_DataStream[7-s][r][c] = {
                        HDR, w_REG_ROW[s], {
                            fb[r*8+7-s][c*8+7], fb[r*8+7-s][c*8+6], fb[r*8+7-s][c*8+5], fb[r*8+7-s][c*8+4],
                            fb[r*8+7-s][c*8+3], fb[r*8+7-s][c*8+2], fb[r*8+7-s][c*8+1], fb[r*8+7-s][c*8+0]
                        }
                    };
                end
            end
        end
    endgenerate

    // The random number generator generates random bits to fill one row of the framebuffer.
    
    reg r_Enable = 1'b0;

    wire [0:FB_WIDTH-1] w_Random_Data;
    wire w_Random_Done;

    random
        #(  .NUM_BITS   (FB_WIDTH)
        ) rand_0 (
            .i_Clk          (i_Clk),
            .i_Enable       (r_Enable),
            .o_Random_Data  (w_Random_Data),
            .o_Random_Done  (w_Random_Done)
        );

    // The state machine runs on the negative edge of the clock

    localparam DELAY_LIMIT = CLK_FREQ_HZ / 4;

    int delay_clocks = 0;
    int y = 0;

    localparam STATE_IDLE = 0, STATE_INITIALIZED = 1, STATE_UPDATE_DISPLAY = 2, STATE_DELAY = 3;
    reg [1:0] r_State;
    reg [1:0] r_State_Next;

    always @(*) begin
        case (r_State)
            STATE_IDLE: begin
                if (i_Rst == 1'b0) begin
                    r_State_Next = STATE_INITIALIZED;
                end else begin
                    r_State_Next = STATE_IDLE;
                end
            end
            STATE_INITIALIZED: begin
                r_State_Next = STATE_UPDATE_DISPLAY;
            end
            STATE_UPDATE_DISPLAY: begin
                if (y < FB_HEIGHT) begin
                    r_State_Next = STATE_UPDATE_DISPLAY;
                end else begin
                    r_State_Next = STATE_DELAY;
                end
            end
            STATE_DELAY: begin
                if (delay_clocks < DELAY_LIMIT) begin
                    r_State_Next = STATE_DELAY;
                end else begin
                    r_State_Next = STATE_UPDATE_DISPLAY;
                end
            end
            default: begin
                r_State_Next = STATE_IDLE;
            end
        endcase
    end
    always @(negedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            r_State <= STATE_IDLE;
        end else begin
            r_State <= r_State_Next;
        end
    end
    always @(negedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            delay_clocks <= 0;
            y <= 0;
            r_Enable <= 1'b0;
        end else begin
            case (r_State)
                STATE_IDLE: begin
                    delay_clocks <= 0;
                    y <= 0;
                    r_Enable <= 1'b0;
                end
                STATE_INITIALIZED: begin
                    r_Enable <= 1'b1;
                    clear_fb();
                end
                STATE_UPDATE_DISPLAY: begin
                    if (y < FB_HEIGHT) begin
                        y <= y + 1;
                        set_row(y, w_Random_Data);
                    end else begin
                        y <= 0;
                        //r_Enable <= 1'b0;
                    end
                end
                STATE_DELAY: begin
                    if (delay_clocks < DELAY_LIMIT) begin
                        delay_clocks <= delay_clocks + 1;
                    end else begin
                        delay_clocks <= 0;
                        //r_Enable <= 1'b1;
                    end
                end
                default: begin
                    r_State_Next = STATE_IDLE;
                end
            endcase
        end
    end

endmodule
