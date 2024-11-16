-- Test button debouncer.

Library ieee;
Use ieee.std_logic_1164.All;

Entity test_debouncer Is Port(clk : In std_logic);
End Entity test_debouncer; 

Architecture tb Of test_debouncer Is
    Signal btn_in  : std_logic;
    Signal btn_out : std_logic;
Begin
    dut : Entity work.debouncer
        Generic Map(CLK_PERIODS => 5)
        Port    Map(i_clk => clk,
                    i_btn => btn_in,
                    o_btn => btn_out);

    stimulus_process : Process Is
    Begin
        Wait For 1 ns;
        btn_in <= '1';
        Wait For 2 ns;
        btn_in <= '0';
        Wait For 3 ns;
        btn_in <= '1';
        Wait For 1 ns;
        btn_in <= '0';
        Wait For 1 ns;
        btn_in <= '1';
        Wait For 5 ns;
        btn_in <= '0';
        Wait For 2 ns;
        btn_in <= '1';
        Wait For 70 ns;
        btn_in <= '0';

		Wait Until rising_edge(clk);

        Wait;

    End Process stimulus_process;
End Architecture tb;

