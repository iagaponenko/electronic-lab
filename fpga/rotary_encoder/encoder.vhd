-- The rotary encoder processes two unconditioned inputs (AKA "buttons"), debounces those
-- and produces two output signals. One makes period length pulse on each turn of
-- the encoder to the right, and the other one - to the left.
--
-- Notes:
--   * This versin of the encoder ignores incomplete patterns (skipped 'a'a or 'b' signals)
--
-- State machine:
--
--    IDLE
--      a_up   -> A_UP
--      a_down -> A_DOWN
--      b_up   -> B_UP
--      b_down -> B_DOWN
--    A_UP
--      a_up   -> IDLE
--      a_down -> IDLE
--      b_up   -> LEFT
--      b_down -> IDLE
--    A_DOWN
--      b_up   -> IDLE
--      b_down -> LEFT
--      a_up   -> IDLE
--      a_down -> IDLE
--    B_UP
--      a_up   -> RIGHT
--      b_down -> IDLE
--      a_up   -> IDLE
--      a_down -> IDLE
--    B_DOWN
--      a_up   -> IDLE
--      b_down -> RIGHT
--      a_up   -> IDLE
--      a_down -> IDLE
--    LEFT
--      *      -> IDLE
--    RIGHT
--      *      -> IDLE
--      

Library ieee;
Use ieee.std_logic_1164.All;

Entity encoder Is
    Generic (
        CLK_PERIODS : positive
    );
    Port (
        i_clk   : In  std_logic;
        i_a     : In  std_logic;
        i_b     : In  std_logic;
        o_left  : Out std_logic;
        o_right : Out std_logic
    );
End Entity encoder;

Architecture Rtl Of encoder Is
    Signal a_up   : std_logic := '0';
    Signal a_down : std_logic := '0';
    Signal b_up   : std_logic := '0';
    Signal b_down : std_logic := '0';
    Type EncoderState Is (
        STATE_IDLE,
        STATE_A_UP,
        STATE_A_DOWN,
        STATE_B_UP,
        STATE_B_DOWN,
        STATE_LEFT,
        STATE_RIGHT
    );
    Signal state : EncoderState := STATE_IDLE;
Begin
    a_up_debouncer : Entity work.debouncer
        Generic Map(CLK_PERIODS => CLK_PERIODS)
        Port    Map(i_clk => i_clk,
                    i_btn => i_a,
                    o_btn => a_up);
    a_down_debouncer : Entity work.debouncer
    Generic Map(CLK_PERIODS => CLK_PERIODS)
    Port    Map(i_clk => i_clk,
                i_btn => Not i_a,
                o_btn => a_down);
            
    b_up_debouncer : Entity work.debouncer
        Generic Map(CLK_PERIODS => CLK_PERIODS)
        Port    Map(i_clk => i_clk,
                    i_btn => i_b,
                    o_btn => b_up);

    b_down_debouncer : Entity work.debouncer
    Generic Map(CLK_PERIODS => CLK_PERIODS)
    Port    Map(i_clk => i_clk,
                i_btn => Not i_b,
                o_btn => b_down);
            
    encoder_process : Process (i_clk) Is
    Begin
        If rising_edge(i_clk) Then
            Case state Is
                When STATE_IDLE =>
                    If    a_up   Then state <= STATE_A_UP;
                    ElsIf a_down Then state <= STATE_A_DOWN;
                    ElsIf b_up   Then state <= STATE_B_UP;
                    ElsIf b_down Then state <= STATE_B_DOWN;
                    End If;
                When STATE_A_UP =>
                    If    a_up   Then state <= STATE_IDLE;
                    ElsIf a_down Then state <= STATE_IDLE;
                    ElsIf b_up   Then state <= STATE_LEFT;
                    ElsIf b_down Then state <= STATE_IDLE;
                    End If;
                When STATE_A_DOWN =>
                    If    a_up   Then state <= STATE_IDLE;
                    ElsIf a_down Then state <= STATE_IDLE;
                    ElsIf b_up   Then state <= STATE_IDLE;
                    ElsIf b_down Then state <= STATE_LEFT;
                    End If;
                When STATE_B_UP =>
                    If    a_up   Then state <= STATE_RIGHT;
                    ElsIf a_down Then state <= STATE_IDLE;
                    ElsIf b_up   Then state <= STATE_IDLE;
                    ElsIf b_down Then state <= STATE_IDLE;
                    End If;
                When STATE_B_DOWN =>
                    If    a_up   Then state <= STATE_IDLE;
                    ElsIf a_down Then state <= STATE_RIGHT;
                    ElsIf b_up   Then state <= STATE_IDLE;
                    ElsIf b_down Then state <= STATE_IDLE;
                    End If;
                When STATE_LEFT =>
                    state <= STATE_IDLE;
                When STATE_RIGHT =>
                    state <= STATE_IDLE;
                When Others =>
                    state <= STATE_IDLE;
            End Case;
        End If;
    End Process encoder_process;

    o_left  <= '1' When state = STATE_LEFT  Else '0';
    o_right <= '1' When state = STATE_RIGHT Else '0';

End Architecture Rtl;



