`timescale 1ns / 1ps

module RegisterFile(
    input Clock,
    input [15:0] I,
    input [2:0] OutASel,
    input [2:0] OutBSel,
    input [1:0] FunSel,
    input [3:0] RegSel,
    input [3:0] ScrSel,
    output reg [15:0] OutA,
    output reg [15:0] OutB
);

    wire [15:0] QR1, QR2, QR3, QR4;
    wire [15:0] QS1, QS2, QS3, QS4;

    reg ER1,ER2,ER3,ER4;
    reg ES1,ES2,ES3,ES4;

    // eğer Clock kullansaydık enable değişimleri
    // registerlara ulaşsa bile clock vuruşu sebebiyle
    // registerlar önceki enable değerini işler
    // bu sebeple veri işlenmesi 1 clock cycle gecikir
    always @(*) begin
        ER1 = 0;
        ER2 = 0;
        ER3 = 0;
        ER4 = 0;
        case(RegSel)
            4'b0000: begin
                ER1 = 1;
                ER2 = 1;
                ER3 = 1;
                ER4 = 1;
            end
            4'b0001: begin
                ER1 = 1;
                ER2 = 1;
                ER3 = 1;
            end
            4'b0010: begin
                ER1 = 1;
                ER2 = 1;
                ER4 = 1;
            end
            4'b0011: begin
                ER1 = 1;
                ER2 = 1;
            end
            4'b0100: begin
                ER1 = 1;
                ER3 = 1;
                ER4 = 1;
            end   
            4'b0101: begin
                ER1 = 1;
                ER3 = 1;
            end
            4'b0110: begin
                ER1 = 1;
                ER4 = 1;
            end
            4'b0111: begin
                ER1 = 1;
            end
            4'b1000: begin
                ER2 = 1;
                ER3 = 1;
                ER4 = 1;
            end
            4'b1001: begin
                ER2 = 1;
                ER3 = 1;
            end
            4'b1010: begin
                ER2 = 1;
                ER4 = 1;
            end
            4'b1011: begin
                ER2 = 1;
            end
            4'b1100: begin
                ER3 = 1;
                ER4 = 1;
            end
            4'b1101: begin
                ER3 = 1;
            end
            4'b1110: begin
                ER4 = 1;
            end
            4'b1111: begin
            end
            default: begin
                ER1 = 0;
                ER2 = 0;
                ER3 = 0;
                ER4 = 0;
            end
        endcase
    end

    always @(*) begin
        ES1 = 0;
        ES2 = 0;
        ES3 = 0;
        ES4 = 0;
        case(ScrSel)
            4'b0000: begin
                ES1 = 1;
                ES2 = 1;
                ES3 = 1;
                ES4 = 1;
            end
            4'b0001: begin
                ES1 = 1;
                ES2 = 1;
                ES3 = 1;
            end
            4'b0010: begin
                ES1 = 1;
                ES2 = 1;
                ES4 = 1;
            end
            4'b0011: begin
                ES1 = 1;
                ES2 = 1;
            end
            4'b0100: begin
                ES1 = 1;
                ES3 = 1;
                ES4 = 1;
            end   
            4'b0101: begin
                ES1 = 1;
                ES3 = 1;
            end
            4'b0110: begin
                ES1 = 1;
                ES4 = 1;
            end
            4'b0111: begin
                ES1 = 1;
            end
            4'b1000: begin
                ES2 = 1;
                ES3 = 1;
                ES4 = 1;
            end
            4'b1001: begin
                ES2 = 1;
                ES3 = 1;
            end
            4'b1010: begin
                ES2 = 1;
                ES4 = 1;
            end
            4'b1011: begin
                ES2 = 1;
            end
            4'b1100: begin
                ES3 = 1;
                ES4 = 1;
            end
            4'b1101: begin
                ES3 = 1;
            end
            4'b1110: begin
                ES4 = 1;
            end
            4'b1111: begin
            end
            default: begin
                ES1 = 0;
                ES2 = 0;
                ES3 = 0;
                ES4 = 0;
            end
        endcase
    end

    Register16bit R1(.E(ER1), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QR1));
    Register16bit R2(.E(ER2), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QR2));
    Register16bit R3(.E(ER3), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QR3));
    Register16bit R4(.E(ER4), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QR4));
    Register16bit S1(.E(ES1), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QS1));
    Register16bit S2(.E(ES2), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QS2));
    Register16bit S3(.E(ES3), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QS3));
    Register16bit S4(.E(ES4), .Clock(Clock), .FunSel(FunSel), .I(I), .Q(QS4));

    // bu devre de combinational olmalı çünkü register zaten
    // clock cycle'a göre değişiklik yapar. Bu, sadece output seçme
    // işlemidir, bunun için clock cycle beklemek gecikme yaratır
    // buradaki devre bir MUX gibi davranmalıdır.
    always @(*) begin
        case (OutASel)
            3'b000: OutA = QR1;
            3'b001: OutA = QR2;
            3'b010: OutA = QR3;
            3'b011: OutA = QR4;
            3'b100: OutA = QS1;
            3'b101: OutA = QS2;
            3'b110: OutA = QS3;
            3'b111: OutA = QS4;
            default: OutA = 0;
        endcase
    end

    always @(*) begin
        case (OutBSel)
            3'b000: OutB = QR1;
            3'b001: OutB = QR2;
            3'b010: OutB = QR3;
            3'b011: OutB = QR4;
            3'b100: OutB = QS1;
            3'b101: OutB = QS2;
            3'b110: OutB = QS3;
            3'b111: OutB = QS4;
            default: OutB = 0;
        endcase
    end
endmodule