-- The clock generator

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;

Entity clock_gen Is
    Generic(T          : time    := 2 ns;
            NUM_CLOCKS : integer := 50);
    Port(Signal clk : Out std_logic);
End Entity clock_gen;

Architecture Behavioral Of clock_gen Is
    Signal i : integer := 0;    -- Loop variable for generating the clock.
Begin
    -- Clock process: clock with 50% duty cycle is generated here.
    clk_process : Process Is
    Begin
        clk <= '0';
        Wait For T/2;
        clk <= '1';
        Wait For T/2;
        If i = NUM_CLOCKS Then
            Wait;
        Else
            i <= i + 1;
        End If;
    End Process clk_process;
End Architecture Behavioral;

