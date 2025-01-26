`timescale 1 ns / 1 ps

// Rotary encoder module:
//

module encoder
    (
        input       i_Rst,
        input       i_Clk,
        input       i_A,        // Debounced signal from the rotary encoder
        input       i_B,        // Debounced signal from the rotary encoder
        output reg  o_Left,     // Left rotation pulse (1 clock period, set on the positive edge of the clock)
        output reg  o_Right     // Right rotation pulse (1 clock period, set on the positive edge of the clock)
    );

    // Note that the pulses are generated on the negative edge of the clock,
    // and they last for exactly one clock cycle till the next negative edge of the clock.

    reg     r_A_Up;
    reg     r_A_Down;
    pulse                  pulse_0 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(i_A), .o_Data(r_A_Up));
    pulse   #(.ON_FALL(1)) pulse_1 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(i_A), .o_Data(r_A_Down));

    reg     r_B_Up;
    reg     r_B_Down;
    pulse                  pulse_2 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(i_B), .o_Data(r_B_Up));
    pulse   #(.ON_FALL(1)) pulse_3 (.i_Rst(i_Rst), .i_Clk(i_Clk), .i_Data(i_B), .o_Data(r_B_Down));

    typedef enum {
        IDLE    = 0,
        A_UP    = 1,
        A_DOWN  = 2,
        B_UP    = 3,
        B_DOWN  = 4,
        LEFT    = 5,
        RIGHT   = 6
    } state_t;

    state_t r_State = IDLE;
    state_t r_NextState;

    function state_t next(logic c1, state_t s1,
                          logic c2, state_t s2,
                          logic c3, state_t s3,
                          logic c4, state_t s4,
                                    state_t s5);
        if ( c1 & ~c2 & ~c3 & ~c4) return s1;
        if (~c1 &  c2 & ~c3 & ~c4) return s2;
        if (~c1 & ~c2 &  c3 & ~c4) return s3;
        if (~c1 & ~c2 & ~c3 &  c4) return s4;
        return s5;
    endfunction

    always_comb begin
        case (r_State)
            IDLE:
                r_NextState = next(
                    r_A_Up,     A_UP,
                    r_A_Down,   A_DOWN,
                    r_B_Up,     B_UP,
                    r_B_Down,   B_DOWN,
                                IDLE);
            A_UP:
                r_NextState = next(
                    r_A_Up,     IDLE,
                    r_A_Down,   IDLE,
                    r_B_Up,     RIGHT,
                    r_B_Down,   IDLE,
                                A_UP);
            A_DOWN:
                r_NextState = next(
                    r_A_Up,     IDLE,
                    r_A_Down,   IDLE,
                    r_B_Up,     IDLE,
                    r_B_Down,   RIGHT,
                                A_DOWN);
            B_UP:
                r_NextState = next(
                    r_A_Up,     LEFT,
                    r_A_Down,   IDLE,
                    r_B_Up,     IDLE,
                    r_B_Down,   IDLE,
                                B_UP);
            B_DOWN:
                r_NextState = next(
                    r_A_Up,     IDLE,
                    r_A_Down,   LEFT,
                    r_B_Up,     IDLE,
                    r_B_Down,   IDLE,
                                B_DOWN);
            LEFT:
                r_NextState = IDLE;
            RIGHT:
                r_NextState = IDLE;
            default:
                r_NextState = IDLE;
        endcase
    end

    always_ff @(posedge i_Clk) begin
        if (i_Rst) begin
            r_State <= IDLE;
        end
        else begin
            r_State <= r_NextState;
        end
    end

    assign o_Left  = r_State == LEFT;
    assign o_Right = r_State == RIGHT;

endmodule
