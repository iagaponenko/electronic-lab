`timescale 1 ns / 1 ps

// This version of the driver is a simple state machine that sends the data to the TM1638
// In this version the following sequence is implemented:
//
// - Input the segment data (8 digits of 8 segments each)
// - Sends the control command to the TM1638
// - Loop over the 8 digits:
//   * Send the read-data/fixed address configuration command to the TM1638
//   * Send the address command for the digit to the TM1638
//   * Send the segment data to the TM1638
//

module tm1638_driver

    import tm1638_types::*;
    import tm1638_driver_types::*;

    (
        // Control signals
        input               i_Rst,
        input               i_Clk,

        // Input data for the 7-segment display (8 digits, 8 segments)
        input segments_t    i_Segments,         // [grid][segment]
        input               i_Valid,            // Data is valid and ready to be sent to TM1638

        // Output data to be sent to TM1638 over SPI
        input               i_SPI_FIFO_Full,    // SPI FIFO full flag (not ready to accept data)
        output reg [16:0]   o_Data,             // Data to be sent to TM1638
`ifndef SIMULATION
        output reg          o_Write             // Write pulse to indicate the data is ready
`else
        output reg          o_Write,            // Write pulse to indicate the data is ready

        // Diagnostic signals
        output state_t      o_Diag_State,
        output grid_t       o_Diag_Grid,
        output segments_t   o_Diag_Segments
`endif
    );

    state_t     r_State;
    state_t     r_State_Next;
    segments_t  r_Segments;
    grid_t      r_Grid;

    // Next state computation logic
    function state_t next(cond, state_t if_true, state_t if_false);
        if (cond) return if_true;
        else      return if_false;
    endfunction

    always @(*) begin
        case (r_State)
            IDLE:                   r_State_Next = next(i_Valid,         SEGMENTES_LATCHED,     IDLE);
            SEGMENTES_LATCHED:      r_State_Next = next(i_SPI_FIFO_Full, SEGMENTES_LATCHED,     CONTROL_COMMAND_SET);       
            CONTROL_COMMAND_SET:    r_State_Next = next(i_SPI_FIFO_Full, WAIT_DATA_COMMAND_SET, DATA_COMMAND_SET);
            WAIT_DATA_COMMAND_SET:  r_State_Next = next(i_SPI_FIFO_Full, WAIT_DATA_COMMAND_SET, DATA_COMMAND_SET);
            DATA_COMMAND_SET:       r_State_Next = next(i_SPI_FIFO_Full, WAIT_ADDR_COMMAND_SET, ADDR_COMMAND_SET);
            WAIT_ADDR_COMMAND_SET:  r_State_Next = next(i_SPI_FIFO_Full, WAIT_ADDR_COMMAND_SET, ADDR_COMMAND_SET);
            ADDR_COMMAND_SET:
                // Check if the grid counter rotated after 8 iterations
                if (r_Grid == 3'h0) r_State_Next = IDLE;
                else                r_State_Next = next(i_SPI_FIFO_Full, WAIT_DATA_COMMAND_SET, DATA_COMMAND_SET);
            default:
                                    r_State_Next = IDLE;
        endcase
    end

    // State transition DFF
    always @(negedge i_Clk) begin
        if (i_Rst) r_State <= IDLE;
        else       r_State <= r_State_Next;
    end

    // Output data computation logic
    always @(negedge i_Clk) begin
        if (i_Rst) begin
            r_Segments <= 64'h0;
            r_Grid  <= 3'd0;
            o_Data  <= 17'h0;
        end
        else begin
            case (r_State)

                IDLE: begin
                    r_Segments <= i_Segments;
                end

                SEGMENTES_LATCHED: begin
                    o_Data <= make_control_command();
                    r_Grid <= 3'd0;
                end

                CONTROL_COMMAND_SET: begin
                    o_Data <= make_data_command();
                end

                DATA_COMMAND_SET: begin
                    o_Data <= make_addr_command_and_data(r_Grid, r_Segments[r_Grid]);
                    r_Grid <= r_Grid + 1'b1;
                end

                ADDR_COMMAND_SET: begin
                    o_Data <= r_Segments[r_Grid];
                    // Ignore the rotated grid counter
                    if (r_Grid != 3'h0) begin
                        o_Data <= make_data_command();
                    end
                end

            endcase
        end
    end

    assign o_Write = (r_State == CONTROL_COMMAND_SET) ||
                     (r_State == DATA_COMMAND_SET)    ||
                     (r_State == ADDR_COMMAND_SET);

`ifdef SIMULATION
    assign o_Diag_State    = r_State;
    assign o_Diag_Grid     = r_Grid;
    assign o_Diag_Segments = r_Segments;
`endif

endmodule

