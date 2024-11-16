-- Testbench for testing the configurable clock divider..

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;
Use ieee.math_real.All;

Entity test_clock_div Is
    Generic (N : natural := 2);
    Port    (clk : In std_logic);
End Entity test_clock_div; 

Architecture tb Of test_clock_div Is
    Signal rst_in   : std_logic;
    Signal clk_out  : std_logic;
Begin
    dut : Entity work.clock_div
        Generic Map(N => N)
        Port    Map(i_rst => rst_in,
                    i_clk => clk,
                    o_clk => clk_out);

    stimulus_process : Process Is
    Begin
        Wait;
    End Process stimulus_process;
End Architecture tb;

