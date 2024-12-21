-- Implement an SPI-like serializer for MAX7219.
-- The correct implementation in which the SPI clock is divided by 2.
--
-- https://www.sparkfun.com/datasheets/Components/General/COM-09622-MAX7219-MAX7221.pdf

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;
Use ieee.math_real.All;

Entity spi_max7219_x2 Is
    Port (
        -- Management interface
        rst        : In  std_logic;
        clk        : In  std_logic;
        start      : In  std_logic;
        data       : In  std_logic_vector(15 Downto 0);
        busy       : Out std_logic;
        -- SPI signals generated by the entity
        spi_clk    : Out std_logic;
        spi_load   : Out std_logic;
        spi_din    : Out std_logic;
        -- Diagnostics
        diag_state : Out std_logic_vector(1 Downto 0)
    );
End Entity spi_max7219_x2;

Architecture Behavioral Of spi_max7219_x2 Is
    Type ProcessingState Is (IDLE, DATA_IN, LOAD);
    Signal state : ProcessingState := IDLE;
Begin
    bcd_compute_process : Process (clk, rst, start, state) Is
        Variable n : integer Range -1 To 15;
    Begin
        If rst Then
            state <= IDLE;
        ElsIf rising_edge(clk) Then
            Case state Is
                When IDLE =>
                    spi_clk  <= '0';
                    spi_load <= '0';
                    spi_din  <= 'X';
                    If start Then
                        n := 15;
                        state <= DATA_IN;
                    End If;
                When DATA_IN =>
                    spi_clk <= not spi_clk;
                When LOAD =>
                    spi_clk  <= '0';
                    spi_load <= '0';
                    state    <= IDLE;
                When Others =>
                    state <= IDLE;
            End Case;
        ElsIf falling_edge(clk) Then
            Case state Is
                When DATA_IN =>
                    If n = -1 Then
                        If spi_clk = '1' Then
                            spi_load <= '1';
                            state <= LOAD;
                        End If;
                    Else
                        If spi_clk = '0' Then
                            spi_din <= data(n);
                            n := n - 1;
                        End If;
                    End If;
                When Others =>
            End Case;
        End If;
    End Process bcd_compute_process;

    -- Device "busy" is set during when the last request is still being processed.
    -- The "start" command will be ignored in this state.
    busy <= '0' When state = IDLE    Else
            '1' When state = DATA_IN Else
            '1' When state = LOAD    Else
            'X';

    -- Diagnostic signals
    diag_state <= "00" When state = IDLE    Else
                  "01" When state = DATA_IN Else
                  "10" When state = LOAD    Else
                  "XX";

End Architecture Behavioral;
