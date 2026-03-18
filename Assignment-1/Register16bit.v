`timescale 1ns / 1ps
module Register16bit(
    input Clock,
    input E,
    input [1:0] FunSel,
    input [15:0] I,
    output reg [15:0] Q
);

    always @(posedge Clock) begin
        if(E) begin
            case (FunSel)
                2'b00: Q <= 0;
                2'b01: Q <= I;
                2'b10: Q <= Q + 1;
                2'b11: Q <= Q - 1;
                default: Q <= Q;
            endcase
        end
    end
endmodule