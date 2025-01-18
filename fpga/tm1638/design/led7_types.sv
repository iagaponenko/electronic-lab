`timescale 1 ns / 1 ps

package led7_types;

function logic [7:0] bin2led7([7:0] bin);
    case (bin)
        8'h0:  return 8'b00111111;
        8'h1:  return 8'b00000110;
        8'h2:  return 8'b01011011;
        8'h3:  return 8'b01001111;
        8'h4:  return 8'b01100110;
        8'h5:  return 8'b01101101;
        8'h6:  return 8'b01111101;
        8'h7:  return 8'b00000111;
        8'h8:  return 8'b01111111;
        8'h9:  return 8'b01101111;
        8'hA:  return 8'b01110111;
        8'hB:  return 8'b01111100;
        8'hC:  return 8'b00111001;
        8'hD:  return 8'b01011110;
        8'hE:  return 8'b01111001;
        8'hF:  return 8'b01110001;
        default: return 8'b00000000;
    endcase
endfunction

endpackage
