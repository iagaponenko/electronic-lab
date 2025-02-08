`timescale 1 ns / 1 ps

module max7219_write (
    input       [2:0]   i_Address,
    output reg  [7:0]   io_Buf
);

logic [7:0][0:7] r_Letter = {8'h7E, 8'h30, 8'h6D, 8'h79, 8'h33, 8'h5B, 8'h5F, 8'h70};

always_comb begin 
    io_Buf = r_Letter[i_Address];
end

endmodule
