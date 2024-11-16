-- Implement the configurable clock divider.
--
-- IMPORTANT: Requirements for allowed range and values of the divider N:
--   1. the minimum value is 2
--   2. only the odd values are allowed (2, 4, 8, 16, etc.)
--   3. any other values would result in undefined behavior

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;
Use ieee.math_real.All;

Entity clock_div Is
    Generic (N : natural);
    Port (
        i_rst : In  std_logic;
        i_clk : In  std_logic;
        o_clk : Out std_logic
    );
End Entity clock_div;


Architecture Behavioral Of clock_div Is
    Signal clk   : std_logic := '0';
    Signal count : integer := 0;
Begin
    bcd_compute_process : Process (i_clk, i_rst) Is
    Begin
        If i_rst = '1' Then
            count <= 0;
        ElsIf rising_edge(i_clk) Then
            If count = N / 2 - 1 Then
                clk <= Not clk;
                count <= 0;
            Else
                count <= count + 1;
            End If;
        End If;
    End Process bcd_compute_process;
    o_clk <= clk;
End Architecture Behavioral;


