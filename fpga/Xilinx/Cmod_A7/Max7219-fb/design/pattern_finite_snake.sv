`timescale 1 ns / 1 ps

// The generator for an finite snake pattern. The "snake" moves diagonally
// across the display, bouncing off the edges. When it steps on its own body,
// the corresponding pixel is turned off. The snake has the limited length.

module pattern_finite_snake

    import max7219_types::*;

    #(  parameter DISP_ROWS     = 1,
        parameter DISP_COLUMNS  = 1,
        parameter DELAY_CLOCKS  = 60 * 1000,    // 5 ms at 12 MHz
        parameter TAIL_LENGTH   = 1
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

    localparam  X_ADDR_WIDTH = $clog2(FB_WIDTH);
    localparam  Y_ADDR_WIDTH = $clog2(FB_HEIGHT);

    reg [X_ADDR_WIDTH-1:0] x = '0;
    reg [Y_ADDR_WIDTH-1:0] y = '0;
    reg [TAIL_LENGTH:0][X_ADDR_WIDTH-1:0] prev_x = '0;
    reg [TAIL_LENGTH:0][Y_ADDR_WIDTH-1:0] prev_y = '0;
    reg x_right = 1'b1;
    reg y_up  = 1'b1;
    int delay_clocks = 0;
    reg face_initialized = 1'b0;

    always @(negedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            x <= '0;
            y <= '0;
            prev_x <= '0;
            prev_y <= '0;
            x_right <= 1'b1;
            y_up <= 1'b1;
            delay_clocks <= 0;
            face_initialized <= 1'b0;
        end else begin
            if (delay_clocks < DELAY_CLOCKS) begin
                delay_clocks <= delay_clocks + 1;
            end else begin
                delay_clocks <= 0;

                if (~face_initialized) begin
                    face_initialized <= 1'b1;
                    clear_fb();
                end

                // Plot the head
                fb[y][x] <= 1'b1;

                // Cut the tail
                fb[prev_y[TAIL_LENGTH]][prev_x[TAIL_LENGTH]] <= 1'b0;

                prev_x <= {prev_x[TAIL_LENGTH-1:0], x};
                prev_y <= {prev_y[TAIL_LENGTH-1:0], y};

                // Move the head of the snake
                if (x == FB_WIDTH - 1) begin
                    x_right <= 1'b0;
                    x <= x - 1;
                end else if (x == 0) begin
                    x_right <= 1'b1;
                    x <= x + 1;
                end else begin
                    x <= x_right ? x + 1 : x - 1;
                end
                if (y == FB_HEIGHT - 1) begin
                    y_up <= 1'b0;
                    y <= y - 1;
                    prev_y[0] <= y;
                end else if (y == 0) begin
                    y_up <= 1'b1;
                    y <= 1;
                    prev_y[0] <= y;
                end else begin
                    y <= y_up ? y + 1 : y - 1;
                    prev_y[0] <= y;
                end
            end
        end
    end

endmodule
