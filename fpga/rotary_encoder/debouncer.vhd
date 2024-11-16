-- The button's or encoder's signal debouncer.

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;
Use ieee.math_real.All;

Entity debouncer Is
    Generic (
        CLK_PERIODS : positive
    );
    Port (
        i_clk : In  std_logic;
        i_btn : In  std_logic;
        o_btn : Out std_logic
    );
End Entity debouncer;

Architecture Rtl Of debouncer Is

    -- Registered (clocked) state of the input button.
    Signal btn_reg1 : std_logic;  

    -- Registered state of the previuous signal delayed by 1 clock.
    Signal btn_reg2 : std_logic;

    -- State machine of the debouncer.
    Type DebouncerState Is (IDLE, COUNTING, DONE);
    Signal state : DebouncerState;

Begin
    btn_reg1_process : Process (i_clk) Is
    Begin
        If rising_edge(i_clk) Then
            btn_reg1 <= i_btn;
        End If;
    End Process btn_reg1_process;

    btn_reg2_process : Process (i_clk) Is
    Begin
        If rising_edge(i_clk) Then
            btn_reg2 <= btn_reg1;
        End If;
    End Process btn_reg2_process;

    counter_process : Process (i_clk) Is
        -- The number of periods to count while the butten is in the stable HIGH state.
        Variable counter  : positive Range 1 To CLK_PERIODS;
    Begin
        If rising_edge(i_clk) Then
            Case state Is
                When IDLE =>
                    If btn_reg1 And Not btn_reg2 Then
                        counter := 1;
                        state <= COUNTING;
                    End If;
                When COUNTING =>
                    If btn_reg1 And btn_reg2 Then
                        If counter = CLK_PERIODS Then
                            state <= DONE;
                        Else
                            counter := counter + 1;
                        End If;
                    Else
                        state <= IDLE;
                    End If;
                When DONE =>
                    state <= IDLE;
                When Others =>
                    state <= IDLE;
            End Case;
        End If;
    End Process counter_process;

    o_btn <= '1' When state = DONE Else '0';
End Architecture Rtl;

