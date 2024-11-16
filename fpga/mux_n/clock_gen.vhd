-- The clock generator

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity clock_gen is
    generic(T          : time    := 2 ns;
            NUM_CLOCKS : integer := 50);
    port(signal clk : out STD_LOGIC);
end entity clock_gen;

architecture Behavioral of clock_gen is
    signal i : integer := 0;    -- Loop variable for generating the clock.
begin
    -- Clock process: clock with 50% duty cycle is generated here.
    clk_process : process is begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
        if i = NUM_CLOCKS then
            wait;
        else
            i <= i + 1;
        end if;
    end process clk_process;
end architecture Behavioral;

