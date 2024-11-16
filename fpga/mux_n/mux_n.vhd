-- Multiplexor of the configurable order
--
-- Note that ORDER must be 1 or bigger, where:
--   1 -> mux2
--   2 -> mux4
--   3 -> mux8
--   ...

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity mux_n is
    generic(ORDER : integer);
    port(a : in  STD_LOGIC_VECTOR (2**ORDER-1 downto 0);
         s : in  STD_LOGIC_VECTOR (ORDER-1 downto 0);
         y : out STD_LOGIC);
end entity mux_n;

architecture Behavioral of mux_n is
    -- Component declaration for the entity is still required by
    -- the VHDL compiler.
    component mux_n is
        generic(ORDER : integer);
        port(a : in  STD_LOGIC_VECTOR (2**ORDER-1 downto 0);
             s : in  STD_LOGIC_VECTOR (ORDER-1 downto 0);
             y : out STD_LOGIC);
    end component mux_n;

    alias a_upper_half is a(2**ORDER-1     downto 2**(ORDER-1));
    alias a_lower_half is a(2**(ORDER-1)-1 downto 0);
    alias s_down       is s((ORDER-1)-1 downto 0);
    alias s_merge      is s(ORDER-1     downto ORDER-1);

    signal y_merge : STD_LOGIC_VECTOR(1 downto 0);

begin
    mutex : if ORDER = 1 generate
        y <= a(1) when s(0) else a(0);
    else generate
        lower_mux : mux_n generic map(ORDER-1) port map(a_lower_half, s_down,  y_merge(0));
        upper_mux : mux_n generic map(ORDER-1) port map(a_upper_half, s_down,  y_merge(1));
        merge_mux : mux_n generic map(1)       port map(y_merge,      s_merge, y);
    end generate mutex;
end architecture Behavioral;

