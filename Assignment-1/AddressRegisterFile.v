`timescale 1ns / 1ps

module AddressRegisterFile(
    input Clock, 
    input [15:0] I, 
    input [2:0] RegSel,
    input [1:0] FunSel, 
    input [1:0] OutCSel, 
    input OutDSel, 
    output reg [15:0] OutC, 
    output [15:0] OutD, 
    output [15:0] OutE
);
    reg EPC, ESP, EAR;
    wire [15:0] QPC, QSP, QAR;
    
    always @(*) begin
       EPC = 0;
       ESP = 0;
       EAR = 0;
       case(RegSel)
          3'b000: begin
             EPC = 1;
             ESP = 1;
             EAR = 1;
          end
          3'b001: begin
             EPC = 1;
             ESP = 1;
          end
          3'b010: begin
             EPC = 1;
             EAR = 1;
          end
          3'b011: begin
             EPC = 1;
          end
          3'b100: begin
             ESP = 1;
             EAR = 1;
          end
          3'b101: begin
             ESP = 1;
          end
          3'b110: begin
             EAR = 1;
          end
          3'b111: begin
          end
          default: begin
             ESP = 0;
             EPC = 0;
             EAR = 0;
          end
       endcase
    end
    
    Register16bit PC(.I(I), .Clock(Clock), .FunSel(FunSel),.E(EPC), .Q(QPC));
    Register16bit SP(.I(I), .Clock(Clock), .FunSel(FunSel),.E(ESP), .Q(QSP));
    Register16bit AR(.I(I), .Clock(Clock), .FunSel(FunSel),.E(EAR), .Q(QAR));
    
    always @(*) begin
        case(OutCSel) 
            2'b00, 2'b01: OutC = QPC;
            2'b10: OutC = QAR;
            2'b11: OutC = QSP;
        endcase
    end

    assign OutD = (OutDSel) ? QSP : QAR;
    assign OutE = QPC;

endmodule