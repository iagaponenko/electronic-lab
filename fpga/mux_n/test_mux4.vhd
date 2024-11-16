-- Testbench for testing the generated mux4.
--
-- Note: local packages needs to be included first before
--       the standard libraries.

library work;
package test_types_2 is new work.test_types generic map (ORDER => 2);
use work.test_types_2.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity test_mux4 is
    port(clk : in STD_LOGIC);
end entity test_mux4; 

architecture tb of test_mux4 is

    -- The DUT component.
    component mux_n is
        generic(ORDER : integer);
        port(a : in  STD_LOGIC_VECTOR (2**ORDER - 1 downto 0);
             s : in  STD_LOGIC_VECTOR (   ORDER - 1 downto 0);
             y : out STD_LOGIC);
    end component mux_n;

    signal a_in  : A_TYPE;
    signal s_in  : S_TYPE;
    signal y_out : STD_LOGIC;

    subtype TEST_COLLECTION_36 is TEST_COLLECTION (0 to 35);

    constant test_vector : TEST_COLLECTION_36 := (
        ("0000", "00", '0'),
        ("0000", "01", '0'),
        ("0000", "10", '0'),
        ("0000", "11", '0'),
        ("0001", "00", '1'),
        ("0001", "01", '0'),
        ("0001", "10", '0'),
        ("0001", "11", '0'),
        ("0010", "00", '0'),
        ("0010", "01", '1'),
        ("0010", "10", '0'),
        ("0010", "11", '0'),
        ("0011", "00", '1'),
        ("0011", "01", '1'),
        ("0011", "10", '0'),
        ("0011", "11", '0'),
        ("0100", "00", '0'),
        ("0100", "01", '0'),
        ("0100", "10", '1'),
        ("0100", "11", '0'),
        ("0101", "00", '1'),
        ("0101", "01", '0'),
        ("0101", "10", '1'),
        ("0101", "11", '0'),
        ("0110", "00", '0'),
        ("0110", "01", '1'),
        ("0110", "10", '1'),
        ("0110", "11", '0'),
        ("0111", "00", '1'),
        ("0111", "01", '1'),
        ("0111", "10", '1'),
        ("0111", "11", '0'),
        ("1000", "00", '0'),
        ("1000", "01", '0'),
        ("1000", "10", '0'),
        ("1000", "11", '1'));

begin
    -- An instance of the tested component.
    DUT : mux_n generic map(2) port map(a_in, s_in, y_out);

    -- Stimulus process
    stimulus_process : process is
        variable vectornum : integer := 0;
    begin
        wait until rising_edge(clk);
        a_in <= test_vector(vectornum).a;
        s_in <= test_vector(vectornum).s;
        wait until falling_edge(clk);
        if y_out /= test_vector(vectornum).y then
            report "The teest failed at " & integer'image(vectornum) & ":" &
                " y_in=" & STD_LOGIC'image(test_vector(vectornum).y) &
                " y_out=" & STD_LOGIC'image(y_out)
                severity warning;
        end if;
        vectornum := vectornum + 1;
        if vectornum = test_vector'length then
            wait;
        end if;
    end process stimulus_process;

end architecture tb;

