-- This generic package encapculates data types and operations with displays made of
-- the sequentially connected rectangular LED matrixes such as MAX7219.
--
-- The LED matrixes are rectangular arrays of LEDs, where each [x] represents
-- an individual LED:
--                                   
--           ^                       
--    ROWS-1 | [x] [x] .  [x]        
--         . |  .   .  .   .         
--         1 | [x] [x] .  [x]        
--         0 | [x] [x] .  [x]        
--           +---------------------> 
--              0   1  .  COLUMNS-1  
--                                   
--
-- Displays are rectangular arrays of the LED matrixes, where each [m] represents
-- an individual LED matrix defined above:
--                                 
--           ^                     
--  HEIGHT-1 | [m] [m] .  [m]      
--         . |  .   .  .   .       
--         1 | [m] [m] .  [m]      
--         0 | [m] [m] .  [m]      
--           +-------------------> 
--              0   1  .  WIDTH-1  
--                                 
--
-- The following represents the combined (virtual) view on the display as it's seen
-- through the functions and procedures defined in the package, where each [x] represents
-- an individual LED:
--                                              
--                ^                             
--  HEIGHT*ROWS-1 | [x] [x] .  [x]              
--              . |  .   .  .   .               
--              1 | [x] [x] .  [x]              
--              0 | [x] [x] .  [x]              
--                +---------------------------> 
--                   0   1  .  WIDTH*COLUMNS-1  
--
-- An address of a pixel in most operations with the frame buffer (a display)
-- is specified by two parameters:
--
--   column : 0 .. WIDTH*COLUMNS-1
--      row : 0 .. HEIGHT*ROWS-1
--
-- The internal organizaton of the buffer is optimized for efficient extraction of
-- pixel streams sent to the physical devices via the serial protocol. The protocol
-- is expected to send the most significant bit of the stream first. The following
-- diagram illustrates an expected orgaization of the physical display made of
-- the sequantially connected individual matrixes. The arrows show a sample stream
-- of bits sent through matrixes when programming pixels of the same row of each matrix.
--
--            /       WIDTH        \
--           /COLUMNS               \
--          /        \               \
--         |  .  .  . |    |  .  .  . |          \       \
--    + -> | 12 13 14 | -> | 15 16 17 | [End]     ROWS    \
--    :    |  .  .  . |    |  .  .  . |          /         \
--    :                                                     \
--    + - - - - - - - - - - - - - - - - - -+                 \
--                                         :                  \
--         |  .  .  . |    |  .  .  . |    :                   \
--    + -> |  6  7  8 | -> |  9 10 11 | -> +                 HEIGHT
--    :    |  .  .  . |    |  .  .  . |                        /
--    :                                                       /
--    + - - - - - - - - - - - - - - - - - -+                 /
--                                         :                /
--         |  .  .  . |    |  .  .  . |    :               /
--    + -> |  0  1  2 | -> |  3  4  5 | -> +              /
--    :    |  .  .  . |    |  .  .  . |                  /
--    :                                      
--    + <- [Begin of stream for one row]     
--                                           
-- Where the stream index varies in a range of 0 to the number of rows in
-- each LED matrix (generic parameter ROWS):
--                          
--   positive (0 To ROWS-1) 
--                          
-- The most sigifgicant bit of the stream reaches the very last pixel (marked
-- as <End>) of the rightmost matrix in the top row of the display. The least
-- significant bit is displayed in the leftmost pixel of the leftmost matrix
-- at the very bottom row of the display.

Library ieee;
Use ieee.std_logic_1164.All;
Use ieee.numeric_std.All;

Package framebuf Is
    -- Dimentions of the frame buffer are determined by these parameters.
    Generic(
        WIDTH   : positive := 1;  -- # matrixes in each row of a display
        HEIGHT  : positive := 1;  -- # rows of matrixes witin a display  
        COLUMNS : positive := 8;  -- # columns within each matrix
        ROWS    : positive := 8   -- # rows of pixels within each matrix
    );

    ------------------------------------
    -- FRAMEBUFFER (PHYSICAL STORAGE) --
    ------------------------------------

    -- The framebuffer type PixelBufType is an array of streams (of type StreamType),
    -- where each stream goes sequentially along the corresponding rows of all matrixes.
    -- The number of pixels in each stream is determined by the constant STREAM_SIZE.
    -- The number of streams is determined by the generic parameter ROWS.

    Constant STREAM_SIZE : positive := HEIGHT * WIDTH * COLUMNS;
    Subtype StreamType Is std_logic_vector(STREAM_SIZE - 1 Downto 0);
    Type PixelBufType Is array(0 To ROWS - 1) Of StreamType;

    -------------------------------------------------
    -- DISPLAY (VIRTUAL VIEW ONTO THE FRAMEBUFFER) --
    -------------------------------------------------

    -- Constants defining the dimention of the virtual display in pixels.
    Constant X_SIZE : natural := WIDTH  * COLUMNS;
    Constant Y_SIZE : natural := HEIGHT * ROWS;

    -- Types which define coordinates of pixels in the virtual display.
    Subtype XCoord Is natural Range 0 To X_SIZE - 1;
    Subtype YCoord Is natural Range 0 To Y_SIZE - 1;

    -- Clear all pixels in the buffer.
    Procedure clear(Signal buf : InOut PixelBufType);

    -- Set all pixels in the buffer.
    Procedure set(Signal buf : InOut PixelBufType);

    -- Set one pixel at the specified location
    Procedure set(Signal buf : InOut PixelBufType;
                  Constant x : In XCoord;
                  Constant y : In YCoord;
                  Constant value : In std_logic);

End Package framebuf;

Package Body framebuf Is

    -------------
    -- PRIVATE --
    -------------

    -- Private types PixelBufRowIdxType, StreamIdxType and PixeBufCoordType represent
    -- internal coordinates of pixels within the framebuffer.
    -- Private function buf_coord() computes internal coordinates of a pixel which is
    -- given by its address in the virtual (public) coordinate system of the display.

    Subtype PixelBufRowIdxType Is natural Range 0 To ROWS - 1;
    Subtype StreamIdxType      Is natural Range STREAM_SIZE - 1 Downto 0;

    Type PixeBufCoordType Is Record
        row        : PixelBufRowIdxType;
        stream_idx : StreamIdxType;
    End Record PixeBufCoordType;

    Function buf_coord(Constant x : In XCoord;
                       Constant y : In YCoord) Return PixeBufCoordType Is
        Constant matrix_row : natural := y  /  ROWS;
        Constant row        : natural := y Mod ROWS;
        Constant matrix_col : natural := x  /  COLUMNS;
        Constant col        : natural := x Mod COLUMNS;
        Constant stream_idx : natural := COLUMNS * (matrix_row * WIDTH + matrix_col) + col;
        Constant coord      : PixeBufCoordType := (row => row, stream_idx => stream_idx);
    Begin
        Return coord;
    End Function;

    -- Private function for setting all pixels of the display to the specified value.
    Procedure set(Signal     buf : InOut PixelBufType;
                  Constant value : In std_logic) Is
    Begin
        For row in 0 To ROWS - 1 Loop
            buf(row) <= (Others => value);
        End Loop;
    End Procedure;

    ------------
    -- PUBLIC --
    ------------

    Procedure clear(Signal buf : InOut PixelBufType) Is
    Begin
        set(buf, '0');
    End Procedure;

	Procedure set(Signal buf : InOut PixelBufType) Is
    Begin
        set(buf, '1');
    End Procedure;

    Procedure set(Signal buf : InOut PixelBufType;
                  Constant x : In XCoord;
                  Constant y : In YCoord;
                  Constant value : In std_logic) Is
        Constant coord : PixeBufCoordType := buf_coord(x, y);
    Begin
        buf(coord.row)(STREAM_SIZE - coord.stream_idx - 1) <= value;
    End Procedure;

End Package Body framebuf;

