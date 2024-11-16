-- Testbench for experiments with VHDL

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;

Entity testbench Is
End Entity testbench; 

Architecture tb Of testbench Is
    Signal clk_in : std_logic;
Begin
    -- Clock generator
    clk_driver : Entity work.clock_gen
        Generic Map(T => 2 ns, NUM_CLOCKS => 80)
        Port    Map(clk => clk_in);

    -- Clock dividers
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

    -- Instances of the tested components.
    dut_spi_max7219 : Entity work.test_spi_max7219
        Port Map(clk => clk_in);
    dut_spi_max7219_x2 : Entity work.test_spi_max7219_x2
        Port Map(clk => clk_in);
    dut_spi_max7219_synt : Entity work.test_spi_max7219_synt
        Port Map(clk => clk_in);

End Architecture tb;

