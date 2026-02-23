`timescale 1 ns / 1 ps

// The driver for the MAX7219 device.

module spi_max7219_driver

    import max7219_types::*;

    #(  parameter MAX7219_SPI_CYCLES    = 1,            // See the documentation of the spi_max7219 module
        parameter MAX7219_DATA_WIDTH    = 4 + 4 + 8,    // 4 bits of header + 4 bits of register + 8 bits of data
        parameter REFRESH_DELAY_CLOCKS  = 1200          // ~100 us at 12 MHz
    )(
        input  wire                                 i_Clk,
        input  wire                                 i_Rst,
        input  wire [0:7][MAX7219_DATA_WIDTH-1:0]   i_MAX7219_DataStream,
        output wire                                 o_SPI_MAX7219_Stb,
        output wire                                 o_SPI_MAX7219_Clk,
        output wire                                 o_SPI_MAX7219_Din
    );

    // Set the data signal r_MAX7219_Data_Valid on the negative edge of the system clock
    // for one clock cycle only.
    reg                             r_MAX7219_SPI_Busy;
    reg                             r_MAX7219_Data_Valid = 1'b0;
    reg [MAX7219_DATA_WIDTH-1:0]    r_MAX7219_Data;

    // State machine to push data to the MAX7219 device

    int step = 0;
    int row = 0;

    reg [3:0] intensity = 4'ha; // 4'h0;
    // reg intensity_down = 1'b0;

    always @(negedge i_Clk or posedge i_Rst) begin
        if (i_Rst) begin
            r_MAX7219_Data_Valid <= 1'b0;
            step <= 0;
            row <= 0;
            // intensity <= 4'h0;
            // intensity_down <= 1'b0;
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
                            r_MAX7219_Data <= {{16{HDR, REG_INTENSITY, DATA_INTENSITY(intensity)}}, {4{HDR, REG_INTENSITY, DATA_INTENSITY(intensity)}}};
                            r_MAX7219_Data_Valid <= 1'b1;
                            step <= step + 1;
                        end
                        7: begin
                            r_MAX7219_Data <= i_MAX7219_DataStream[row];
                            r_MAX7219_Data_Valid <= 1'b1;

                            if (row == 7) begin
                                row <= 0;

                                // // Change the intensity after refreshing all rows.
                                // if (intensity == 4'b1111) begin
                                //     intensity_down <= 1'b1;
                                //     intensity <= intensity - 1'b1;
                                // end else if (intensity == 4'b0000) begin
                                //     intensity_down <= 1'b0;
                                //     intensity <= intensity + 1'b1;
                                // end else begin
                                //     if (intensity_down) begin
                                //         intensity <= intensity - 1'b1;
                                //     end else begin
                                //         intensity <= intensity + 1'b1;
                                //     end
                                // end

                                // Delay before refreshing the display
                                step <= step + 1;

                            end else begin
                                row <= row + 1;
                            end

                        end
                        default: begin
                            // Delay before refreshing the display
                            if (step == REFRESH_DELAY_CLOCKS) begin
                                // Proceed to the normal refresh cycle
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
            .i_Rst          (i_Rst),
            .i_Clk          (i_Clk),

            .o_Busy         (r_MAX7219_SPI_Busy),
            .i_Data_Ready   (r_MAX7219_Data_Valid),
            .i_Data         (r_MAX7219_Data),

            .o_SPI_Stb      (o_SPI_MAX7219_Stb),
            .o_SPI_Clk      (o_SPI_MAX7219_Clk),
            .o_SPI_Din      (o_SPI_MAX7219_Din)
        );

endmodule
