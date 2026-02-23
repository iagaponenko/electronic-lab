`timescale 1 ns / 1 ps

// The generator for a random pattern using the random number generator.
// The rules are explaind in https://en.wikipedia.org/wiki/Conway's_Game_of_Life
// Note that the framebiffer is treated as a torus, i.e., the top and bottom edges
// are connected, as well as the left and right edges.

module pattern_conwaylife

    import max7219_types::*;

    #(  parameter DISP_ROWS     = 1,
        parameter DISP_COLUMNS  = 1,
        parameter CLK_FREQ_HZ   = 1     // 1 Hz
    )(
        input  wire i_Clk,
        input  wire i_Rst,
        input  wire i_AliensArrived,
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

    reg fb [0:FB_HEIGHT-1][0:FB_WIDTH-1];   // [Y][X]

    task clear_fb;
        integer y, x;
        begin
            for (y = 0; y < FB_HEIGHT; y = y + 1) begin
                for (x = 0; x < FB_WIDTH; x = x + 1) begin
                    fb[y][x] <= 1'b0;
                end
            end
        end
    endtask

    task stimulate_life;
        begin
            fb[24][15] <= 1'b1;
            fb[23][12] <= 1'b1;
            fb[23][14] <= 1'b1;
            fb[23][16] <= 1'b1;
            fb[23][18] <= 1'b1;
            fb[22][13] <= 1'b1;
            fb[22][17] <= 1'b1;
            fb[21][12] <= 1'b1;
            fb[21][18] <= 1'b1;
            fb[20][11] <= 1'b1;
            fb[20][15] <= 1'b1;
            fb[20][19] <= 1'b1;
            fb[19][12] <= 1'b1;
            fb[19][18] <= 1'b1;
            fb[18][13] <= 1'b1;
            fb[18][17] <= 1'b1;
            fb[17][12] <= 1'b1;
            fb[17][14] <= 1'b1;
            fb[17][16] <= 1'b1;
            fb[17][18] <= 1'b1;
            fb[16][15] <= 1'b1;
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

    // The framebuffer update logic implementing the Conway's Game of Life rules.
    wire [3:0] sums [0:FB_HEIGHT-1][0:FB_WIDTH-1];   // [Y][X]

    generate
        genvar y, x;
        for (y = 0; y < FB_HEIGHT; y = y + 1) begin : SUM_ROW_GEN
            for (x = 0; x < FB_WIDTH; x = x + 1) begin : SUM_COL_GEN
                assign sums[y][x] = 
                    fb[(y-1+FB_HEIGHT)%FB_HEIGHT][(x-1+FB_WIDTH)%FB_WIDTH] +
                    fb[(y-1+FB_HEIGHT)%FB_HEIGHT][(x+0+FB_WIDTH)%FB_WIDTH] +
                    fb[(y-1+FB_HEIGHT)%FB_HEIGHT][(x+1+FB_WIDTH)%FB_WIDTH] +
                    fb[(y+0+FB_HEIGHT)%FB_HEIGHT][(x-1+FB_WIDTH)%FB_WIDTH] +
                    fb[(y+0+FB_HEIGHT)%FB_HEIGHT][(x+1+FB_WIDTH)%FB_WIDTH] +
                    fb[(y+1+FB_HEIGHT)%FB_HEIGHT][(x-1+FB_WIDTH)%FB_WIDTH] +
                    fb[(y+1+FB_HEIGHT)%FB_HEIGHT][(x+0+FB_WIDTH)%FB_WIDTH] +
                    fb[(y+1+FB_HEIGHT)%FB_HEIGHT][(x+1+FB_WIDTH)%FB_WIDTH];
            end
        end
    endgenerate

    // Rules:
    //   0-1  neighbours: Cell becomes 0 (underpopulation)
    //     2  neighbours: Cell state does not change
    //     3  neighbours: Cell becomes 1 (reproduction)
    //     4+ neighbours: Cell becomes 0 (overpopulation)

    task update_fb;
        integer y, x;
        begin
            for (y = 0; y < FB_HEIGHT; y = y + 1) begin
                for (x = 0; x < FB_WIDTH; x = x + 1) begin
                    fb[y][x] <= (fb[y][x] && (sums[y][x] == 2)) || (sums[y][x] == 3) ? 1'b1 : 1'b0;
                end
            end
        end
    endtask

    // The random number generator generates random bits to fill one row of the framebuffer.
    
    reg r_Enable = 1'b0;

    wire [3 + $clog2(FB_HEIGHT) + $clog2(FB_WIDTH)-1:0] w_Random_Data;
    wire w_Random_Done;

    random
        #(  .NUM_BITS   (3 + $clog2(FB_HEIGHT) + $clog2(FB_WIDTH))
        ) rand_0 (
            .i_Clk          (i_Clk),
            .i_Enable       (r_Enable),
            .o_Random_Data  (w_Random_Data),
            .o_Random_Done  (w_Random_Done)
        );

    // The state machine runs on the negative edge of the clock

    localparam DELAY_LIMIT = CLK_FREQ_HZ / 10;

    int delay_clocks = 0;
    int num_pixels_updated = 0;

    localparam  STATE_IDLE = 0,
                STATE_INITIALIZED = 1,
                STATE_SET_RANDOM_PATTERN = 2,
                STATE_UPDATE = 3,
                STATE_STIMULATE_LIFE = 4,
                STATE_DELAY = 5;
    reg [2:0] r_State;
    reg [2:0] r_State_Next;

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
                r_State_Next = STATE_SET_RANDOM_PATTERN;
            end
            STATE_SET_RANDOM_PATTERN: begin
                if (num_pixels_updated < FB_HEIGHT * FB_WIDTH) begin
                    r_State_Next = STATE_SET_RANDOM_PATTERN;
                end else begin
                    r_State_Next = STATE_UPDATE;
                end
            end
            STATE_UPDATE: begin
                if (i_AliensArrived == 1'b1) begin
                    r_State_Next = STATE_STIMULATE_LIFE;
                end else begin
                    r_State_Next = STATE_DELAY;
                end
            end
            STATE_STIMULATE_LIFE: begin
                r_State_Next = STATE_DELAY;
            end
            STATE_DELAY: begin
                if (delay_clocks < DELAY_LIMIT) begin
                    r_State_Next = STATE_DELAY;
                end else begin
                    r_State_Next = STATE_UPDATE;
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

    wire [$clog2(FB_HEIGHT)-1:0] current_y = w_Random_Data[$clog2(FB_HEIGHT) + $clog2(FB_WIDTH) -1 -: $clog2(FB_HEIGHT)];
    wire [$clog2(FB_WIDTH)-1:0] current_x = w_Random_Data[$clog2(FB_WIDTH)-1 : 0];

    always @(negedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            delay_clocks <= 0;
            num_pixels_updated <= 0;
            r_Enable <= 1'b0;
        end else begin
            case (r_State)
                STATE_IDLE: begin
                    delay_clocks <= 0;
                    num_pixels_updated <= 0;
                    r_Enable <= 1'b0;
                end
                STATE_INITIALIZED: begin
                    r_Enable <= 1'b1;
                    clear_fb();
                end
                STATE_SET_RANDOM_PATTERN: begin
                    if (num_pixels_updated < FB_HEIGHT * FB_WIDTH) begin
                        if (current_y < FB_HEIGHT && current_x < FB_WIDTH) begin
                            // fb[current_y][current_x] <= 1'b1;
                            fb[current_y][current_x] <= fb[current_y][current_x] ^ 1'b1;
                            num_pixels_updated <= num_pixels_updated + 1;
                        end
                    end else begin
                        num_pixels_updated <= 0;
                        r_Enable <= 1'b0;
                    end
                end
                STATE_UPDATE: begin
                    update_fb();
                end
                STATE_STIMULATE_LIFE: begin
                    stimulate_life();
                end
                STATE_DELAY: begin
                    if (delay_clocks < DELAY_LIMIT) begin
                        delay_clocks <= delay_clocks + 1;
                    end else begin
                        delay_clocks <= 0;
                    end
                end
                default: begin
                end
            endcase
        end
    end

endmodule
