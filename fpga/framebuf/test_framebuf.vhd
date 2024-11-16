-- Test package framebuf.

-- Library ieee;
-- Use ieee.std_logic_1164.All;

Package display Is New work.framebuf
    Generic Map (WIDTH => 4, HEIGHT => 1, COLUMNS => 4, ROWS => 4);
Use work.display;

-- Redeclaration of the standard libraries is required after instantiating
-- the generic package. Otheriwise it would be shielded.

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.std_logic_unsigned.All;
Use ieee.numeric_std.All;
use std.textio.all;

Entity test_framebuf Is Port(clk : In std_logic);
End Entity test_framebuf; 

Architecture tb Of test_framebuf Is
    Signal fb : display.PixelBufType;
Begin
    stimulus_process : Process Is
    Begin
		Wait Until falling_edge(clk);
        display.clear(fb);
		Wait Until rising_edge(clk);
        report "after clear, fb = " & to_string(fb(3));
        report "                  " & to_string(fb(2));
        report "                  " & to_string(fb(1));
        report "                  " & to_string(fb(0));

        Wait Until falling_edge(clk);
        display.set(fb);
		Wait Until rising_edge(clk);
        report "after set, fb = " & to_string(fb(3));
        report "                " & to_string(fb(2));
        report "                " & to_string(fb(1));
        report "                " & to_string(fb(0));

        Wait Until falling_edge(clk);
        display.clear(fb);
        display.set(fb, 15, 2, '1');
		Wait Until rising_edge(clk);
        report "after set one pixel, fb = " & to_string(fb(3));
        report "                          " & to_string(fb(2));
        report "                          " & to_string(fb(1));
        report "                          " & to_string(fb(0));

        Wait;

    End Process stimulus_process;
End Architecture tb;

