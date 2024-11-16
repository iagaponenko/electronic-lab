-- Testbench for experiments with VHDL

Library ieee;
Use ieee.std_logic_1164.All;

Entity testbench Is
End Entity testbench; 

Architecture tb Of testbench Is
    Signal clk_in : std_logic;
Begin
    clk_driver : Entity work.clock_gen
        Generic Map(T => 2 ns, NUM_CLOCKS => 300)
        Port    Map(clk => clk_in);

    clk_divider_2 : Entity work.test_clock_div
        Generic Map (N => 2)
        Port    Map (clk => clk_in);
    clk_divider_4 : Entity work.test_clock_div
        Generic Map (N => 4)
        Port    Map (clk => clk_in);
    clk_divider_8 : Entity work.test_clock_div
        Generic Map (N => 8)
        Port    Map (clk => clk_in);
    clk_divider_16 : Entity work.test_clock_div
        Generic Map (N => 16)
        Port    Map (clk => clk_in);
    clk_divider_32 : Entity work.test_clock_div
        Generic Map (N => 32)
        Port    Map (clk => clk_in);

    dut_debouncer: Entity work.test_debouncer
        Port Map(clk => clk_in);
    dut_trigger:  Entity work.test_trigger
        Port Map(clk => clk_in);
    dut_encoder: Entity work.test_encoder
        Port Map(clk => clk_in);
    dut_meter: Entity work.test_meter
        Port Map(clk => clk_in);

End Architecture tb;

