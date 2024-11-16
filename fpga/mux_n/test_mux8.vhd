-- Testbench for testing the generated mux8.
--
-- Note: local packages needs to be included first before
--       the standard libraries.

library work;
package test_types_3 is new work.test_types generic map (ORDER => 3);
use work.test_types_3.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity test_mux8 is
    port(clk : in STD_LOGIC);
end entity test_mux8; 

architecture tb of test_mux8 is

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

    subtype TEST_COLLECTION_7 is TEST_COLLECTION (0 to 7);

    constant test_vector : TEST_COLLECTION_7 := (
        ("00000000", "000", '0'),
        ("00000001", "000", '1'),
        ("00000010", "000", '0'),
        ("00000010", "001", '1'),
        ("00000100", "001", '0'),
        ("00000100", "010", '1'),
        ("00001000", "010", '0'),
        ("00001000", "011", '1')
    );

begin
    -- An instance of the tested component.
    DUT : mux_n generic map(3) port map(a_in, s_in, y_out);

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

