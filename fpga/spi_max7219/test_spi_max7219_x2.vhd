-- Testbench for testing an SPI-like serializer for MAX7219.
-- The correct implementation in which the SPI clock is divided by 2.


Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;
Use ieee.math_real.All;

Entity test_spi_max7219_x2 Is Port(clk : In std_logic);
End Entity test_spi_max7219_x2; 

Architecture tb Of test_spi_max7219_x2 Is

    Signal rst_in         : std_logic;
    Signal start_in       : std_logic;
    Signal data_in        : std_logic_vector(15 Downto 0);
    Signal busy_out       : std_logic;
    Signal spi_clk_out    : std_logic;
    Signal spi_load_out   : std_logic;
    Signal spi_din_out    : std_logic;
    Signal diag_state_out : std_logic_vector(1 Downto 0);

	Constant data_tested_1 : std_logic_vector(15 Downto 0) := "1010101010101010";
	Constant data_tested_2 : std_logic_vector(15 Downto 0) := "1001100110011001";

Begin
    dut : Entity work.spi_max7219_x2
        Port Map(rst        => rst_in,
                 clk        => clk,
                 start      => start_in,
                 data       => data_in,
                 busy       => busy_out,
                 spi_clk    => spi_clk_out,
                 spi_load   => spi_load_out,
                 spi_din    => spi_din_out,
                 diag_state => diag_state_out);

    stimulus_process : Process Is
    Begin

        -- Transaction: initial reset (half period)
        Wait Until falling_edge(clk);
        rst_in <= '1';
        Wait Until rising_edge(clk);
        rst_in <= '0';

        -- Transaction 1: make the request when not busy
        wait_while_busy_1 : While busy_out /= '0' Loop
            Wait Until rising_edge(clk);
        End Loop wait_while_busy_1;
        data_in <= data_tested_1;
        start_in <= '1';
        Wait Until rising_edge(clk);
        start_in <= '0';
        Wait Until rising_edge(clk);

        -- Transaction 2: make the request when not busy
        wait_while_busy_2 : While busy_out /= '0' Loop
            Wait Until rising_edge(clk);
        End Loop wait_while_busy_2;

        data_in <= data_tested_2;
        start_in <= '1';
        Wait Until rising_edge(clk);
        start_in <= '0';

        Wait;

    End Process stimulus_process;
End Architecture tb;

