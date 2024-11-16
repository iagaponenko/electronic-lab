-- Test the meter that tracks the rotary encoder.

Library ieee;
Use ieee.std_logic_1164.All;

Entity test_meter Is Port(clk : In std_logic);
End Entity test_meter; 

Architecture tb Of test_meter Is
    Constant METER_WIDTH : positive := 4;
    Signal a_in      : std_logic;
    Signal b_in      : std_logic;
    Signal value_out : std_logic_vector(METER_WIDTH - 1 Downto 0);
Begin
    dut : Entity work.meter
        Generic Map(CLK_PERIODS => 5,
                    METER_WIDTH => METER_WIDTH)
        Port    Map(i_clk   => clk,
                    i_a     => a_in,
                    i_b     => b_in,
                    o_value => value_out);

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

