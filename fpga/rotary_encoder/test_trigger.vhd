-- Test trigger.

Library ieee;
Use ieee.std_logic_1164.All;

Entity test_trigger Is Port(clk : In std_logic);
End Entity test_trigger; 

Architecture tb Of test_trigger Is
    Signal btn_in  : std_logic;
    Signal btn_trg : std_logic;
Begin
    dut : Entity work.trigger
        Generic Map(CLK_PERIODS => 5)
        Port    Map(i_clk => clk,
                    i_btn => btn_in,
                    o_trg => btn_trg);

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

