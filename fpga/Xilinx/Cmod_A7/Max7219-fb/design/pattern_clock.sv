`timescale 1 ns / 1 ps

// The generator for an analog clock.

module pattern_clock

    import max7219_types::*;

    #(  parameter DISP_ROWS     = 1,
        parameter DISP_COLUMNS  = 1,
        parameter CLK_FREQ_HZ   = 1    // 1 Hz
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

    // The state machine runs on the negative edge of the clock

    localparam CENTER_X = 15;
    localparam CENTER_Y = 23;

    int x = 0;
    int y = 0;
    int prev_x = 0;
    int prev_y = 0;

    int delay_clocks = 0;
    reg [5:0] seconds = 0;
    reg [5:0] minutes = 0;
    reg [4:0] hours = 0;

    reg face_initialized = 1'b0;

    always @(negedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            delay_clocks <= 0;
            seconds <= 0;
            minutes <= 0;
            hours <= 0;
            x <= 0;
            y <= 0;
            prev_x <= 0;
            prev_y <= 0;
            face_initialized <= 1'b0;
        end else begin
            if (delay_clocks < CLK_FREQ_HZ) begin
                delay_clocks <= delay_clocks + 1;
            end else begin
                delay_clocks <= 0;
                if (~face_initialized) begin
                    face_initialized <= 1'b1;
                    clear_fb();
                end

                // Center
                fb[CENTER_Y  ][CENTER_X  ] <= 1'b1;
                fb[CENTER_Y+1][CENTER_X+1] <= 1'b1;
                fb[CENTER_Y+1][CENTER_X-1] <= 1'b1;
                fb[CENTER_Y-1][CENTER_X+1] <= 1'b1;
                fb[CENTER_Y-1][CENTER_X-1] <= 1'b1;

                // Hour marks
                fb[CENTER_Y+14][CENTER_X   ] <= 1'b1;     // 12:00
                fb[CENTER_Y+11][CENTER_X+ 8] <= 1'b1;    //  1:00
                fb[CENTER_Y+ 6][CENTER_X+13] <= 1'b1;    //  2:00
                fb[CENTER_Y   ][CENTER_X+14] <= 1'b1;    //  3:00
                fb[CENTER_Y- 6][CENTER_X+13] <= 1'b1;    //  4:00
                fb[CENTER_Y-11][CENTER_X+ 8] <= 1'b1;    //  5:00
                fb[CENTER_Y-14][CENTER_X   ] <= 1'b1;    //  6:00
                fb[CENTER_Y-11][CENTER_X- 8] <= 1'b1;    //  7:00
                fb[CENTER_Y- 6][CENTER_X-13] <= 1'b1;    //  8:00
                fb[CENTER_Y   ][CENTER_X-14] <= 1'b1;    //  9:00
                fb[CENTER_Y+ 6][CENTER_X-13] <= 1'b1;    // 10:00
                fb[CENTER_Y+11][CENTER_X- 8] <= 1'b1;    // 11:00
            end
            if (seconds < 59) begin
                seconds <= seconds + 1;
            end else begin
                seconds <= 0;
                if (minutes < 59) begin
                    minutes <= minutes + 1;
                end else begin
                    minutes <= 0;
                    if (hours < 23) begin
                        hours <= hours + 1;
                    end else begin
                        hours <= 0;
                    end
                end
            end

            fb[prev_y][prev_x] <= 1'b0;
            fb[y][x] <= 1'b1;

            prev_x <= x;
            prev_y <= y;

            if (seconds < 15) begin
                // upper right quadrant
                x <= CENTER_X + seconds;
                y <= CENTER_Y + 15 - seconds;
            end else if (seconds < 30) begin
                // lower right quadrant
                x <= CENTER_X + 30 - seconds;
                y <= CENTER_Y + 15 - seconds;
            end else if (seconds < 45) begin
                // lower left quadrant
                x <= CENTER_X + 30 - seconds;
                y <= CENTER_Y - 45 + seconds;
            end else begin
                // upper left quadrant
                x <= CENTER_X - 60 + seconds;
                y <= CENTER_Y - 45 + seconds;
            end
        end
    end

endmodule
