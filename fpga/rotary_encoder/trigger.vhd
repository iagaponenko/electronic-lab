-- The triger sences pulses of the clock period length on when a button is pressed
-- or released. It also conditions the input signal using debouncer.

Library ieee;
Use ieee.std_logic_1164.All;

Entity trigger Is
    Generic (
        CLK_PERIODS : positive
    );
    Port (
        i_clk : In  std_logic;
        i_btn : In  std_logic;
        o_trg : Out std_logic
    );
End Entity trigger;

Architecture Rtl Of trigger Is
    Signal btn_deb        : std_logic;
    Signal btn_deb_invert : std_logic;
Begin
    btn_debouncer : Entity work.debouncer
        Generic Map(CLK_PERIODS => CLK_PERIODS)
        Port    Map(i_clk => i_clk,
                    i_btn => i_btn,
                    o_btn => btn_deb);

    btn_debouncer_invert : Entity work.debouncer
        Generic Map(CLK_PERIODS => CLK_PERIODS)
        Port    Map(i_clk => i_clk,
                    i_btn => Not i_btn,
                    o_btn => btn_deb_invert);

	o_trg <= btn_deb Or btn_deb_invert;

End Architecture Rtl;

