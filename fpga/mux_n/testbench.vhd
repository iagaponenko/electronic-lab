-- Testbench for experiments with VHDL
-- The main goal is to learn how to generate multiplexors of various
-- orders in VHDL.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity testbench is
end entity testbench; 

architecture tb of testbench is

    -- The testbenches for multiplexors
    component test_mux2 is
        port(clk : in STD_LOGIC);
    end component test_mux2; 

    component test_mux4 is
        port(clk : in STD_LOGIC);
    end component test_mux4; 

    component test_mux8 is
        port(clk : in STD_LOGIC);
    end component test_mux8; 

    -- Clock generator
    component clock_gen is
        generic(T          : time    := 2 ns;
                NUM_CLOCKS : integer := 50);
        port(signal clk : out STD_LOGIC);
    end component clock_gen;

    signal clk_in : STD_LOGIC;

begin
    -- Clock generator
    clk_diver: clock_gen generic map(T => 2ns, NUM_CLOCKS => 50) port map (clk_in);

    -- Instances of the tested components.
    dut_test_mux2 : test_mux2 port map(clk_in);
    dut_test_mux4 : test_mux4 port map(clk_in);
    dut_test_mux8 : test_mux8 port map(clk_in);

end architecture tb;

