`timescale 1 ns / 1 ps

// The generator for expanding circles.

module pattern_circles

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

    // Tasks for drawing/erasing circles and digits

    task circle_00 (input reg val);
        begin
            fb[23][15] <= val;
        end
    endtask

    task circle_01 (input reg val);
        begin
            fb[24][15] <= 1'b1; fb[23][14] <= 1'b1; fb[23][16] <= 1'b1; fb[22][15] <= 1'b1;
        end
    endtask

    task circle_02 (input reg val);
        begin
            fb[25][14] <= 1'b1; fb[25][15] <= 1'b1; fb[25][16] <= 1'b1; fb[24][13] <= 1'b1; fb[24][17] <= 1'b1; fb[23][13] <= 1'b1; fb[23][17] <= 1'b1;
            fb[22][13] <= 1'b1; fb[22][17] <= 1'b1; fb[21][14] <= 1'b1; fb[21][15] <= 1'b1; fb[21][16] <= 1'b1;
        end
    endtask

    task circle_03 (input reg val);
        begin
            fb[26][15] <= 1'b1; fb[25][13] <= 1'b1; fb[25][17] <= 1'b1; fb[23][12] <= 1'b1; fb[23][18] <= 1'b1; fb[21][13] <= 1'b1; fb[21][17] <= 1'b1; fb[20][15] <= 1'b1;
        end
    endtask

    task circle_04 (input reg val);
        begin
            fb[27][15] <= 1'b1; fb[26][13] <= 1'b1; fb[26][17] <= 1'b1; fb[25][12] <= 1'b1; fb[25][18] <= 1'b1; fb[23][11] <= 1'b1; fb[23][19] <= 1'b1; fb[21][12] <= 1'b1;
            fb[21][18] <= 1'b1; fb[20][13] <= 1'b1; fb[20][17] <= 1'b1; fb[19][15] <= 1'b1;
        end
    endtask

    task circle_05 (input reg val);
        begin
            fb[28][14] <= 1'b1; fb[28][16] <= 1'b1; fb[27][12] <= 1'b1; fb[27][18] <= 1'b1; fb[26][11] <= 1'b1; fb[26][19] <= 1'b1; fb[24][10] <= 1'b1; fb[24][20] <= 1'b1;
            fb[22][10] <= 1'b1; fb[22][20] <= 1'b1; fb[20][11] <= 1'b1; fb[20][19] <= 1'b1; fb[19][12] <= 1'b1; fb[19][18] <= 1'b1; fb[18][14] <= 1'b1; fb[18][16] <= 1'b1;
        end
    endtask

    task circle_06 (input reg val);
        begin
            fb[29][14] <= 1'b1; fb[29][16] <= 1'b1; fb[28][12] <= 1'b1; fb[28][18] <= 1'b1; fb[26][10] <= 1'b1; fb[26][20] <= 1'b1; fb[24][9] <= 1'b1; fb[24][21] <= 1'b1;
            fb[22][9] <= 1'b1; fb[22][21] <= 1'b1; fb[20][10] <= 1'b1; fb[20][20] <= 1'b1; fb[18][12] <= 1'b1; fb[18][18] <= 1'b1; fb[17][14] <= 1'b1; fb[17][16] <= 1'b1;
        end
    endtask

    task circle_07 (input reg val);
        begin
            fb[30][14] <= 1'b1; fb[30][16] <= 1'b1; fb[29][12] <= 1'b1; fb[29][18] <= 1'b1; fb[28][10] <= 1'b1; fb[28][20] <= 1'b1; fb[26][9] <= 1'b1; fb[26][21] <= 1'b1;
            fb[24][8] <= 1'b1; fb[24][22] <= 1'b1; fb[22][8] <= 1'b1; fb[22][22] <= 1'b1; fb[20][9] <= 1'b1; fb[20][21] <= 1'b1; fb[18][10] <= 1'b1; fb[18][20] <= 1'b1;
            fb[17][12] <= 1'b1; fb[17][18] <= 1'b1; fb[16][14] <= 1'b1; fb[16][16] <= 1'b1;
        end
    endtask

    task circle_08 (input reg val);
        begin
            fb[31][14] <= 1'b1; fb[31][16] <= 1'b1; fb[30][12] <= 1'b1; fb[30][18] <= 1'b1; fb[29][10] <= 1'b1; fb[29][20] <= 1'b1; fb[28][9] <= 1'b1; fb[28][21] <= 1'b1;
            fb[26][8] <= 1'b1; fb[26][22] <= 1'b1; fb[24][7] <= 1'b1; fb[24][23] <= 1'b1; fb[22][7] <= 1'b1; fb[22][23] <= 1'b1; fb[20][8] <= 1'b1; fb[20][22] <= 1'b1;
            fb[18][9] <= 1'b1; fb[18][21] <= 1'b1; fb[17][10] <= 1'b1; fb[17][20] <= 1'b1; fb[16][12] <= 1'b1; fb[16][18] <= 1'b1; fb[15][14] <= 1'b1; fb[15][16] <= 1'b1;
        end
    endtask

    task circle_09 (input reg val);
        begin
            fb[32][14] <= 1'b1; fb[32][16] <= 1'b1; fb[31][11] <= 1'b1; fb[31][19] <= 1'b1; fb[30][9] <= 1'b1; fb[30][21] <= 1'b1; fb[29][8] <= 1'b1; fb[29][22] <= 1'b1;
            fb[27][7] <= 1'b1; fb[27][23] <= 1'b1; fb[24][6] <= 1'b1; fb[24][24] <= 1'b1; fb[22][6] <= 1'b1; fb[22][24] <= 1'b1; fb[19][7] <= 1'b1; fb[19][23] <= 1'b1;
            fb[17][8] <= 1'b1; fb[17][22] <= 1'b1; fb[16][9] <= 1'b1; fb[16][21] <= 1'b1; fb[15][11] <= 1'b1; fb[15][19] <= 1'b1; fb[14][14] <= 1'b1; fb[14][16] <= 1'b1;
        end
    endtask

    task circle_10 (input reg val);
        begin
            fb[33][14] <= 1'b1; fb[33][16] <= 1'b1; fb[32][11] <= 1'b1; fb[32][19] <= 1'b1; fb[31][9] <= 1'b1; fb[31][21] <= 1'b1; fb[30][8] <= 1'b1; fb[30][22] <= 1'b1;
            fb[29][7] <= 1'b1; fb[29][23] <= 1'b1; fb[27][6] <= 1'b1; fb[27][24] <= 1'b1; fb[24][5] <= 1'b1; fb[24][25] <= 1'b1; fb[22][5] <= 1'b1; fb[22][25] <= 1'b1;
            fb[19][6] <= 1'b1; fb[19][24] <= 1'b1; fb[17][7] <= 1'b1; fb[17][23] <= 1'b1; fb[16][8] <= 1'b1; fb[16][22] <= 1'b1; fb[15][9] <= 1'b1; fb[15][21] <= 1'b1;
            fb[14][11] <= 1'b1; fb[14][19] <= 1'b1; fb[13][14] <= 1'b1; fb[13][16] <= 1'b1;
        end
    endtask

    task circle_11 (input reg val);
        begin
            fb[34][13] <= 1'b1; fb[34][15] <= 1'b1; fb[34][17] <= 1'b1; fb[33][10] <= 1'b1; fb[33][20] <= 1'b1; fb[32][8] <= 1'b1; fb[32][22] <= 1'b1; fb[31][7] <= 1'b1;
            fb[31][23] <= 1'b1; fb[30][6] <= 1'b1; fb[30][24] <= 1'b1; fb[28][5] <= 1'b1; fb[28][25] <= 1'b1; fb[25][4] <= 1'b1; fb[25][26] <= 1'b1; fb[23][4] <= 1'b1;
            fb[23][26] <= 1'b1; fb[21][4] <= 1'b1; fb[21][26] <= 1'b1; fb[18][5] <= 1'b1; fb[18][25] <= 1'b1; fb[16][6] <= 1'b1; fb[16][24] <= 1'b1; fb[15][7] <= 1'b1;
            fb[15][23] <= 1'b1; fb[14][8] <= 1'b1; fb[14][22] <= 1'b1; fb[13][10] <= 1'b1; fb[13][20] <= 1'b1; fb[12][13] <= 1'b1; fb[12][15] <= 1'b1; fb[12][17] <= 1'b1;
        end
    endtask

    task circle_12 (input reg val);
        begin
            fb[35][13] <= 1'b1; fb[35][15] <= 1'b1; fb[35][17] <= 1'b1; fb[34][10] <= 1'b1; fb[34][20] <= 1'b1; fb[33][8] <= 1'b1; fb[33][22] <= 1'b1; fb[31][6] <= 1'b1;
            fb[31][24] <= 1'b1; fb[30][5] <= 1'b1; fb[30][25] <= 1'b1; fb[28][4] <= 1'b1; fb[28][26] <= 1'b1; fb[25][3] <= 1'b1; fb[25][27] <= 1'b1; fb[23][3] <= 1'b1;
            fb[23][27] <= 1'b1; fb[21][3] <= 1'b1; fb[21][27] <= 1'b1; fb[18][4] <= 1'b1; fb[18][26] <= 1'b1; fb[16][5] <= 1'b1; fb[16][25] <= 1'b1; fb[15][6] <= 1'b1;
            fb[15][24] <= 1'b1; fb[13][8] <= 1'b1; fb[13][22] <= 1'b1; fb[12][10] <= 1'b1; fb[12][20] <= 1'b1; fb[11][13] <= 1'b1; fb[11][15] <= 1'b1; fb[11][17] <= 1'b1;
        end
    endtask

    task circle_13 (input reg val);
        begin
            fb[36][13] <= 1'b1; fb[36][15] <= 1'b1; fb[36][17] <= 1'b1; fb[35][9] <= 1'b1; fb[35][21] <= 1'b1; fb[34][7] <= 1'b1; fb[34][23] <= 1'b1; fb[32][5] <= 1'b1;
            fb[32][25] <= 1'b1; fb[31][4] <= 1'b1; fb[31][26] <= 1'b1; fb[29][3] <= 1'b1; fb[29][27] <= 1'b1; fb[25][2] <= 1'b1; fb[25][28] <= 1'b1; fb[23][2] <= 1'b1;
            fb[23][28] <= 1'b1; fb[21][2] <= 1'b1; fb[21][28] <= 1'b1; fb[17][3] <= 1'b1; fb[17][27] <= 1'b1; fb[15][4] <= 1'b1; fb[15][26] <= 1'b1; fb[14][5] <= 1'b1;
            fb[14][25] <= 1'b1; fb[12][7] <= 1'b1; fb[12][23] <= 1'b1; fb[11][9] <= 1'b1; fb[11][21] <= 1'b1; fb[10][13] <= 1'b1; fb[10][15] <= 1'b1; fb[10][17] <= 1'b1;
        end
    endtask

    task circle_14 (input reg val);
        begin
            fb[37][13] <= 1'b1; fb[37][15] <= 1'b1; fb[37][17] <= 1'b1; fb[36][10] <= 1'b1; fb[36][20] <= 1'b1; fb[35][8] <= 1'b1; fb[35][22] <= 1'b1; fb[33][5] <= 1'b1;
            fb[33][25] <= 1'b1; fb[32][4] <= 1'b1; fb[32][26] <= 1'b1; fb[30][3] <= 1'b1; fb[30][27] <= 1'b1; fb[28][2] <= 1'b1; fb[28][28] <= 1'b1; fb[25][1] <= 1'b1;
            fb[25][29] <= 1'b1; fb[23][1] <= 1'b1; fb[23][29] <= 1'b1; fb[21][1] <= 1'b1; fb[21][29] <= 1'b1; fb[18][2] <= 1'b1; fb[18][28] <= 1'b1; fb[16][3] <= 1'b1;
            fb[16][27] <= 1'b1; fb[14][4] <= 1'b1; fb[14][26] <= 1'b1; fb[13][5] <= 1'b1; fb[13][25] <= 1'b1; fb[11][8] <= 1'b1; fb[11][22] <= 1'b1; fb[10][10] <= 1'b1;
            fb[10][20] <= 1'b1; fb[9][13] <= 1'b1; fb[9][15] <= 1'b1; fb[9][17] <= 1'b1;
        end
    endtask

    task circle_15 (input reg val);
        begin
            fb[38][13] <= 1'b1; fb[38][15] <= 1'b1; fb[38][17] <= 1'b1; fb[37][10] <= 1'b1; fb[37][20] <= 1'b1; fb[36][8] <= 1'b1; fb[36][22] <= 1'b1; fb[34][5] <= 1'b1;
            fb[34][25] <= 1'b1; fb[32][3] <= 1'b1; fb[32][27] <= 1'b1; fb[30][2] <= 1'b1; fb[30][28] <= 1'b1; fb[28][1] <= 1'b1; fb[28][29] <= 1'b1; fb[25][0] <= 1'b1;
            fb[25][30] <= 1'b1; fb[23][0] <= 1'b1; fb[23][30] <= 1'b1; fb[21][0] <= 1'b1; fb[21][30] <= 1'b1; fb[18][1] <= 1'b1; fb[18][29] <= 1'b1; fb[16][2] <= 1'b1;
            fb[16][28] <= 1'b1; fb[14][3] <= 1'b1; fb[14][27] <= 1'b1; fb[12][5] <= 1'b1; fb[12][25] <= 1'b1; fb[10][8] <= 1'b1; fb[10][22] <= 1'b1; fb[9][10] <= 1'b1;
            fb[9][20] <= 1'b1; fb[8][13] <= 1'b1; fb[8][15] <= 1'b1; fb[8][17] <= 1'b1;
        end
    endtask

    task circle_16 (input reg val);
        begin
            fb[39][12] <= 1'b1; fb[39][15] <= 1'b1; fb[39][18] <= 1'b1; fb[38][9] <= 1'b1; fb[38][21] <= 1'b1; fb[37][7] <= 1'b1; fb[37][23] <= 1'b1; fb[35][4] <= 1'b1;
            fb[35][26] <= 1'b1; fb[33][2] <= 1'b1; fb[33][28] <= 1'b1; fb[31][1] <= 1'b1; fb[31][29] <= 1'b1; fb[29][0] <= 1'b1; fb[29][30] <= 1'b1; fb[26][31] <= 1'b1;
            fb[23][31] <= 1'b1; fb[20][31] <= 1'b1; fb[17][0] <= 1'b1; fb[17][30] <= 1'b1; fb[15][1] <= 1'b1; fb[15][29] <= 1'b1; fb[13][2] <= 1'b1; fb[13][28] <= 1'b1;
            fb[11][4] <= 1'b1; fb[11][26] <= 1'b1; fb[9][7] <= 1'b1; fb[9][23] <= 1'b1; fb[8][9] <= 1'b1; fb[8][21] <= 1'b1;
        end
    endtask

    task digit_00 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][16] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][16] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][16] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][16] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_01 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][20] <= 1'b1;

        end
    endtask

    task digit_02 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][16] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][16] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_03 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_04 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][16] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][16] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_05 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][16] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][16] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_06 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][16] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][16] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][16] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][16] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_07 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_08 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][16] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][16] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][16] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][16] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_09 (input reg val);
        begin
            fb[6][10] <= 1'b1; fb[6][11] <= 1'b1; fb[6][12] <= 1'b1; fb[6][13] <= 1'b1; fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][10] <= 1'b1; fb[5][14] <= 1'b1; fb[5][16] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][10] <= 1'b1; fb[4][14] <= 1'b1; fb[4][16] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][10] <= 1'b1; fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][10] <= 1'b1; fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][10] <= 1'b1; fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][10] <= 1'b1; fb[0][11] <= 1'b1; fb[0][12] <= 1'b1; fb[0][13] <= 1'b1; fb[0][14] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_10 (input reg val);
        begin
            fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][14] <= 1'b1; fb[5][16] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][14] <= 1'b1; fb[4][16] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][14] <= 1'b1; fb[2][16] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][14] <= 1'b1; fb[1][16] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_11 (input reg val);
        begin
            fb[6][14] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][14] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][14] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][14] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][14] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_12 (input reg val);
        begin
            fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][14] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][14] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][14] <= 1'b1; fb[2][16] <= 1'b1;
            fb[1][14] <= 1'b1; fb[1][16] <= 1'b1;
            fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_13 (input reg val);
        begin
            fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][14] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][14] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_14 (input reg val);
        begin
            fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][14] <= 1'b1; fb[5][16] <= 1'b1; fb[5][20] <= 1'b1;
            fb[4][14] <= 1'b1; fb[4][16] <= 1'b1; fb[4][20] <= 1'b1;
            fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][14] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_15 (input reg val);
        begin
            fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][14] <= 1'b1; fb[5][16] <= 1'b1;
            fb[4][14] <= 1'b1; fb[4][16] <= 1'b1;
            fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][14] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][14] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    task digit_16 (input reg val);
        begin
            fb[6][14] <= 1'b1; fb[6][16] <= 1'b1; fb[6][17] <= 1'b1; fb[6][18] <= 1'b1; fb[6][19] <= 1'b1; fb[6][20] <= 1'b1;
            fb[5][14] <= 1'b1; fb[5][16] <= 1'b1;
            fb[4][14] <= 1'b1; fb[4][16] <= 1'b1;
            fb[3][14] <= 1'b1; fb[3][16] <= 1'b1; fb[3][17] <= 1'b1; fb[3][18] <= 1'b1; fb[3][19] <= 1'b1; fb[3][20] <= 1'b1;
            fb[2][14] <= 1'b1; fb[2][16] <= 1'b1; fb[2][20] <= 1'b1;
            fb[1][14] <= 1'b1; fb[1][16] <= 1'b1; fb[1][20] <= 1'b1;
            fb[0][14] <= 1'b1; fb[0][16] <= 1'b1; fb[0][17] <= 1'b1; fb[0][18] <= 1'b1; fb[0][19] <= 1'b1; fb[0][20] <= 1'b1;
        end
    endtask

    // The state machine runs on the negative edge of the clock

    int delay_clocks = 0;
    int circle = 0;
    reg outward = 1'b1;

    always @(negedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            delay_clocks <= 0;
            circle <= 0;
            outward <= 1'b1;
        end else begin
            if (delay_clocks < CLK_FREQ_HZ / 10) begin
                delay_clocks <= delay_clocks + 1;
            end else begin
                delay_clocks <= 0;
                if (outward) begin
                    if (circle < 16) begin
                        circle <= circle + 1;
                    end else begin
                        outward <= 1'b0;
                        circle <= 15;
                    end
                end else begin
                    if (circle > 0) begin
                        circle <= circle - 1;
                    end else begin
                        outward <= 1'b1;
                        circle <= 1;
                    end
                end
            end
        end
    end
    always @(negedge i_Clk) begin
        if (delay_clocks == 0) begin
            case (circle)
                0: begin
                    clear_fb();
                    circle_00(1'b1);
                    digit_00(1'b1);
                end
                1: begin
                    clear_fb();
                    circle_01(1'b1);
                    digit_01(1'b1);
                end
                2: begin
                    clear_fb();
                    circle_02(1'b1);
                    digit_02(1'b1);
                end
                3: begin
                    clear_fb();
                    circle_03(1'b1);
                    digit_03(1'b1);
                end
                4: begin
                    clear_fb();
                    circle_04(1'b1);
                    digit_04(1'b1);
                end
                5: begin
                    clear_fb();
                    circle_05(1'b1);
                    digit_05(1'b1);
                end
                6: begin
                    clear_fb();
                    circle_06(1'b1);
                    digit_06(1'b1);
                end
                7: begin
                    clear_fb();
                    circle_07(1'b1);
                    digit_07(1'b1);
                end
                8: begin
                    clear_fb();
                    circle_08(1'b1);
                    digit_08(1'b1);
                end
                9: begin
                    clear_fb();
                    circle_09(1'b1);
                    digit_09(1'b1);
                end
                10: begin
                    clear_fb();
                    circle_10(1'b1);
                    digit_10(1'b1);
                end
                11: begin
                    clear_fb();
                    circle_11(1'b1);
                    digit_11(1'b1);
                end
                12: begin
                    clear_fb();
                    circle_12(1'b1);
                    digit_12(1'b1);
                end
                13: begin
                    clear_fb();
                    circle_13(1'b1);
                    digit_13(1'b1);
                end
                14: begin
                    clear_fb();
                    circle_14(1'b1);
                    digit_14(1'b1);
                end
                15: begin
                    clear_fb();
                    circle_15(1'b1);
                    digit_15(1'b1);
                end
                16: begin
                    clear_fb();
                    circle_16(1'b1);
                    digit_16(1'b1);
                end
            endcase
        end
    end

endmodule
