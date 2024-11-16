-- Test rotary encoder.

Library ieee;
Use ieee.std_logic_1164.All;

Entity test_encoder Is Port(clk : In std_logic);
End Entity test_encoder; 

Architecture tb Of test_encoder Is
    Signal a_in      : std_logic;
    Signal b_in      : std_logic;
    Signal left_out  : std_logic;
    Signal right_out : std_logic;
Begin
    dut : Entity work.encoder
        Generic Map(CLK_PERIODS => 5)
        Port    Map(i_clk   => clk,
                    i_a     => a_in,
                    i_b     => b_in,
                    o_left  => left_out,
                    o_right => right_out);

    a_stimulus_process : Process Is
    Begin
        -- Simulate two clicks: up and down
        Wait For 1 ns;
        a_in <= '1';
        Wait For 2 ns;
        a_in <= '0';
        Wait For 3 ns;
        a_in <= '1';
        Wait For 1 ns;
        a_in <= '0';
        Wait For 1 ns;
        a_in <= '1';
        Wait For 5 ns;
        a_in <= '0';
        Wait For 2 ns;
        a_in <= '1';
        Wait For 30 ns;
        a_in <= '0';

        -- Wait for some time before rotating the encoder
        Wait For 45 ns;

        -- Delay 'a' for a few periods
        Wait For 10 ns;

        -- Simulate another set of two clicks: up and down
        Wait For 1 ns;
        a_in <= '1';
        Wait For 2 ns;
        a_in <= '0';
        Wait For 3 ns;
        a_in <= '1';
        Wait For 1 ns;
        a_in <= '0';
        Wait For 1 ns;
        a_in <= '1';
        Wait For 5 ns;
        a_in <= '0';
        Wait For 2 ns;
        a_in <= '1';
        Wait For 30 ns;
        a_in <= '0';

        -- Wait for some time before rotating the encoder
        Wait For 30 ns;

        -- Simulate another set of two clicks: up and down
        a_in <= '1';
        Wait For 30 ns;
        a_in <= '0';

        -- Simulate another set of two clicks: up and down
        Wait For 30 ns;
        a_in <= '1';
        Wait For 30 ns;
        a_in <= '0';

		Wait Until rising_edge(clk);
        Wait;

    End Process a_stimulus_process;

    b_stimulus_process : Process Is
    Begin
        -- Delay 'b' for a few periods
        -- After that generate the same sequence as for 'a'
        Wait For 10 ns;
        
        -- Simulate two clicks: up and down
        Wait For 1 ns;
        b_in <= '1';
        Wait For 2 ns;
        b_in <= '0';
        Wait For 3 ns;
        b_in <= '1';
        Wait For 1 ns;
        b_in <= '0';
        Wait For 1 ns;
        b_in <= '1';
        Wait For 5 ns;
        b_in <= '0';
        Wait For 2 ns;
        b_in <= '1';
        Wait For 30 ns;
        b_in <= '0';

        -- Wait for some time before rotating the encoder
        Wait For 30 ns;

        -- Simulate another set of two clicks: up and down
        Wait For 1 ns;
        b_in <= '1';
        Wait For 2 ns;
        b_in <= '0';
        Wait For 3 ns;
        b_in <= '1';
        Wait For 1 ns;
        b_in <= '0';
        Wait For 1 ns;
        b_in <= '1';
        Wait For 5 ns;
        b_in <= '0';
        Wait For 2 ns;
        b_in <= '1';
        Wait For 30 ns;
        b_in <= '0';

        -- Wait for some time before rotating the encoder
        Wait For 40 ns;

        -- Simulate another set of two clicks: up and down
        b_in <= '1';
        Wait For 40 ns;
        b_in <= '0';

		Wait Until rising_edge(clk);
        Wait;

    End Process b_stimulus_process;

End Architecture tb;

