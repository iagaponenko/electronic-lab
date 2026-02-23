`timescale 1 ns / 1 ps

// The top module for generating simple patterns on the 32x40 display
// MAX7219 controlled via SPI.
//
// The simple test for the MAX7219 driver.
//
// Coordinate system of a single 8x8 dot display:
// 
//       ROWS
//
//       7 |
//       6 |
//       5 |
//       4 |
//       3 |
//       2 |
//       1 |
//       0 |              x
//         +---------------
//          0 1 2 3 4 5 6 7  COLUMNS
//
// The column numbers map to the bit numbers in the DATA as follows:
// - the MSB 0 is the leftmost  pixel of the row (COLUMN=0)
// - the MSB 7 is the rightmost pixel of the row (COLUMN=7)
//
// For example, a coordinate of the symbol 'x' is represented by ROW=0, DATA=8b'10000000

module main

    (
        // 12 MHz
        input i_Clk,
        input reg [1:0] i_Button,

        // Output SPI signals (MAX7219)
        output reg o_SPI_MAX7219_Stb,
        output reg o_SPI_MAX7219_Clk,
        output reg o_SPI_MAX7219_Din

    );

    // Condition the reset button
    localparam BUTTON_DEBOUNCE_CYCLES = 120 * 1000;     // ~10 ms
    reg rst1;
    debounce
        #(  .DEBOUNCE_CYCLES (BUTTON_DEBOUNCE_CYCLES)
        ) debounce_0 (
            .i_Clk  (i_Clk),
            .i_Data (i_Button[1]),
            .o_Data (rst1)
        );

    assign rst = i_Button[0];

    // General configuration of the SPI module

    localparam  MAX7219_SPI_CYCLES = 10;
    localparam  MAX7219_DATA_WIDTH = 20 * 16;

    // Registers of the MAX7219 device

    localparam  HDR = 4'b0000;

    localparam  REG_NOP     = 4'b0000;
    localparam  DATA_NOP    = 8'b00000000;

    localparam  REG_ROW_0   = 4'b0001;
    localparam  REG_ROW_1   = 4'b0010;
    localparam  REG_ROW_2   = 4'b0011;
    localparam  REG_ROW_3   = 4'b0100;
    localparam  REG_ROW_4   = 4'b0101;
    localparam  REG_ROW_5   = 4'b0110;
    localparam  REG_ROW_6   = 4'b0111;
    localparam  REG_ROW_7   = 4'b1000;
    wire [7:0][3:0]  REG_ROW = {
        REG_ROW_0, REG_ROW_1, REG_ROW_2, REG_ROW_3, REG_ROW_4, REG_ROW_5, REG_ROW_6, REG_ROW_7
    };

    localparam  REG_SHUT            = 4'b1100;
    localparam  DATA_SHUT_DOWN      = 8'b00000000;
    localparam  DATA_SHUT_NORMAL    = 8'b00000001;


    localparam  REG_SCAN            = 4'b1011;
    localparam  DATA_SCAN_0xxxxxxx  = 8'b00000000;
    localparam  DATA_SCAN_01xxxxxx  = 8'b00000001;
    localparam  DATA_SCAN_012xxxxx  = 8'b00000010;
    localparam  DATA_SCAN_0123xxxx  = 8'b00000011;
    localparam  DATA_SCAN_01234xxx  = 8'b00000100;
    localparam  DATA_SCAN_012345xx  = 8'b00000101;
    localparam  DATA_SCAN_0123456x  = 8'b00000110;
    localparam  DATA_SCAN_01234567  = 8'b00000111;

    localparam  REG_BCD_ENCODE          = 4'b1001;
    localparam  DATA_BCD_ENCODE_NONE    = 8'b00000000;

    localparam  REG_INTENSITY   = 4'b1010;
    wire [0:15][7:0] DATA_INTENSITY = {
        8'b00000000, 8'b00000001, 8'b00000010, 8'b00000011, 8'b00000100, 8'b00000101, 8'b00000110, 8'b00000111,
        8'b00001000, 8'b00001001, 8'b00001010, 8'b00001011, 8'b00001100, 8'b00001101, 8'b00001110, 8'b00001111
    };

    localparam  REG_TEST            = 4'b1111;
    localparam  DATA_TEST           = 8'b00000001;
    localparam  DATA_NO_TEST        = 8'b00000000;

    // Set the data signal r_MAX7219_Data_Valid on the negative edge of the system clock
    // for one clock cycle only.
    reg                             r_MAX7219_SPI_Busy;
    reg                             r_MAX7219_Data_Valid = 1'b0;
    reg [MAX7219_DATA_WIDTH-1:0]    r_MAX7219_Data;

    int step = 0;
    int row = 0;
    reg [7:0] pattern1 = 8'b10000001;
    reg [7:0] pattern2 = 8'b10000001;
    reg [3:0] intensity = 4'h0;
    reg intensity_down = 1'b0;

    always @(negedge i_Clk or posedge rst1) begin
        if (rst1) begin
            r_MAX7219_Data_Valid <= 1'b0;
            step <= 0;
            row <= 0;
            pattern1 <= 8'b10000001;
            pattern2 <= 8'b10000001;
            intensity <= 4'h0;
            intensity_down <= 1'b0;
        end else begin
            if (r_MAX7219_Data_Valid) begin
                r_MAX7219_Data_Valid <= 1'b0;
            end else begin
                if (~r_MAX7219_SPI_Busy) begin
                    case (step)

                        // The reset cycle starts from here
                        0: begin
                            r_MAX7219_Data <= {20{HDR, REG_SHUT, DATA_SHUT_DOWN}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end
                        1: begin
                            r_MAX7219_Data <= {20{HDR, REG_TEST, DATA_TEST}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end

                        // Normal display refresh cycle starts from here
                        2: begin
                            r_MAX7219_Data <= {20{HDR, REG_SHUT, DATA_SHUT_NORMAL}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end
                        3: begin
                            r_MAX7219_Data <= {20{HDR, REG_BCD_ENCODE, DATA_BCD_ENCODE_NONE}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end
                        4: begin
                            r_MAX7219_Data <= {20{HDR, REG_SCAN, DATA_SCAN_01234567}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end
                        5: begin
                            r_MAX7219_Data <= {20{HDR, REG_TEST, DATA_NO_TEST}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end
                        6: begin
                            r_MAX7219_Data <= {{16{HDR, REG_INTENSITY, DATA_INTENSITY[intensity]}}, {4{HDR, REG_INTENSITY, DATA_INTENSITY[intensity]}}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end
                        7: begin
                            r_MAX7219_Data <= {
                                {4{HDR, REG_ROW[row], pattern1}},
                                {4{HDR, REG_ROW[row], pattern2}},
                                {4{HDR, REG_ROW[row], pattern1}},
                                {4{HDR, REG_ROW[row], pattern2}},
                                {4{HDR, REG_ROW[row], pattern1}}
                            };
                            r_MAX7219_Data_Valid <= 1'b1;

                            if (row == 7) begin
                                row <= 0;

                                // Shift the pattern by 2 pixels after updating all rows
                                // to allow the "moving" effect. Otheriwse the picture will stay still
                                // since there are 8 bits in the pattern and there are 8 rows in total.
                                pattern1 <= {pattern1[5:0], pattern1[7:6]};     // rotate the pattern left
                                pattern2 <= {pattern2[1:0], pattern2[7:2]};     // rotate the pattern right

                                // Change the intensity after refreshing all rows.
                                if (intensity == 4'b1111) begin
                                    intensity_down <= 1'b1;
                                    intensity <= intensity - 1'b1;
                                end else if (intensity == 4'b0000) begin
                                    intensity_down <= 1'b0;
                                    intensity <= intensity + 1'b1;
                                end else begin
                                    if (intensity_down) begin
                                        intensity <= intensity - 1'b1;
                                    end else begin
                                        intensity <= intensity + 1'b1;
                                    end
                                end

                                // Delay before refreshing the display
                                step <= step + 1;

                            end else begin
                                row <= row + 1;

                                // Shift the pattern by 1 pixel on each row to allow th ediagonal pattern.
                                pattern1 <= {pattern1[6:0], pattern1[7]};   // rotate the pattern left
                                pattern2 <= {pattern2[0],   pattern2[7:1]}; // rotate the pattern right
                            end

                        end
                        default: begin
                            // Process delay before refreshing the current pattern on the display.
                            if (step == 4 * 1000 * 1000) begin
                                // Resume with the normal refresh cycle
                                step <= 2;
                            end else begin
                                step <= step + 1;
                            end
                        end
                    endcase
                end
            end
        end
    end

    spi_max7219
        #(  .CYCLES     (MAX7219_SPI_CYCLES),
            .DATA_WIDTH (MAX7219_DATA_WIDTH)
        ) spi_max7219_0 (
            .i_Rst          (rst),
            .i_Clk          (i_Clk),

            .o_Busy         (r_MAX7219_SPI_Busy),
            .i_Data_Ready   (r_MAX7219_Data_Valid),
            .i_Data         (r_MAX7219_Data),

            .o_SPI_Stb      (o_SPI_MAX7219_Stb),
            .o_SPI_Clk      (o_SPI_MAX7219_Clk),
            .o_SPI_Din      (o_SPI_MAX7219_Din)
        );

endmodule
