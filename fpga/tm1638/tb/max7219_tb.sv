`timescale 1 ns / 1 ps

module max7219_tb;

    reg [2:0] r_Address;
    reg [7:0] r_Buf;

    max7219_write max7219_write_0 (r_Address, r_Buf);

    initial begin
        r_Address = 3'h0;
        $monitor("%t r_Address = %b r_Buf = %b", $time, r_Address, r_Buf);

        repeat (8) begin
            #1 r_Address = r_Address + 1;
        end
    end

endmodule