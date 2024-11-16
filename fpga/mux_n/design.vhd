-- Multiplexor of the configurable order
--
-- This declaration is unused right now. Its only purpose is to prevent
-- the EDA Playground IDE choking on the empty file.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity mux_2 is
    port(a : in  STD_LOGIC_VECTOR (1 downto 0);
         s : in  STD_LOGIC;
         y : out STD_LOGIC);
end entity mux_2;

architecture Behavioral of mux_2 is

    component mux_n is
        generic(ORDER : integer);
        port(a : in  STD_LOGIC_VECTOR (2**ORDER-1 downto 0);
             s : in  STD_LOGIC_VECTOR (ORDER-1 downto 0);
             y : out STD_LOGIC);
    end component mux_n;

begin
    mux : mux_n generic map(1) port map(a, "" & s, y);
end architecture Behavioral;


