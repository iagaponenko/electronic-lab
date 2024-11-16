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

    dut_framebuf: Entity work.test_framebuf
        Port Map(clk => clk_in);

End Architecture tb;

