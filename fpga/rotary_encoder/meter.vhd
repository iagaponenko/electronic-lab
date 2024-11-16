-- The meter uses the rotary encoder for setting up its value. Each time
-- the encoder's knob is turned one click right the value is incremented by one.
-- When the knob is turned left the value gets decremented. When the metered
-- value reaches 0 it stays at 0. When the value hits the maximum representation
-- of the metered value it stays there.

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.std_logic_unsigned.All;

Entity meter Is
    Generic (
        CLK_PERIODS : positive;
        METER_WIDTH : positive
    );
    Port (
        i_clk   : In  std_logic;
        i_a     : In  std_logic;
        i_b     : In  std_logic;
        o_value : Out std_logic_vector(METER_WIDTH - 1 Downto 0)
    );
End Entity meter;

Architecture Rtl Of meter Is
    Signal left  : std_logic;
    Signal right : std_logic;
    Constant min_value : std_logic_vector(METER_WIDTH - 1 Downto 0) := (Others => '0');
    Constant max_value : std_logic_vector(METER_WIDTH - 1 Downto 0) := (Others => '1');
    Signal       value : std_logic_vector(METER_WIDTH - 1 Downto 0) := min_value;
Begin
    value_encoder : Entity work.encoder
        Generic Map(CLK_PERIODS => CLK_PERIODS)
        Port    Map(i_clk   => i_clk,
                    i_a     => i_a,
                    i_b     => i_b,
                    o_left  => left,
                    o_right => right);

    metering_process : Process (i_clk) Is
    Begin
        If rising_edge(i_clk) Then
            If left Then
                If value /= min_value Then
                    value <= value - '1';
                End If;
            ElsIf right Then
                If value /= max_value Then
                    value <= value + '1';
                End If;
            End If;
        End If;
    End Process metering_process;

    o_value <= value;

End Architecture Rtl;

