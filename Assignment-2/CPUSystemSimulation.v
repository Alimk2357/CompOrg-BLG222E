`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Engineer:
// Project Name: BLG222E Project 2 Simulation
//////////////////////////////////////////////////////////////////////////////////


module CPUSystemSimulation();
    wire [11:0] T;
    integer test_no;
    integer clock_count;
    wire clock;
    wire reset;
   
    wire[5:0] Opcode;
    wire[1:0] RegSel;
    wire[7:0] Address;
    wire[2:0] DestReg;
    wire[2:0] SrcReg1;
    wire[2:0] SrcReg2;

    CrystalOscillator clk();
    ResetGenerator rg();

    CPUSystem CPUSys(
        .Clock(clk.clock),
        .Reset(rg.reset),
        .T(T)
    );
    FileOperation F();
   
    assign clock = clk.clock;
    assign reset = rg.reset;
   
    task ClearRegisters;
        begin
            clock_count = 0;
            CPUSys.ALUSys.RF.R1.Q = 16'h0;
            CPUSys.ALUSys.RF.R2.Q = 16'h0;
            CPUSys.ALUSys.RF.R3.Q = 16'h0;
            CPUSys.ALUSys.RF.R4.Q = 16'h0;
            CPUSys.ALUSys.RF.S1.Q = 16'h0;
            CPUSys.ALUSys.RF.S2.Q = 16'h0;
            CPUSys.ALUSys.RF.S3.Q = 16'h0;
            CPUSys.ALUSys.RF.S4.Q = 16'h0;
            CPUSys.ALUSys.ARF.PC.Q = 16'h0;
            CPUSys.ALUSys.ARF.AR.Q = 16'h0;
            CPUSys.ALUSys.ARF.SP.Q = 16'h00FF;
            CPUSys.ALUSys.ALU.FlagsOut = 4'b0000;
            CPUSys.ALUSys.DMU.DR.DROut = 16'h0;
            CPUSys.ALUSys.IMU.IR.IROut = 16'h0;
        end
    endtask
       
    task SetRegisters;
        input [15:0] value;
        begin
            CPUSys.ALUSys.ARF.PC.Q = value;
            CPUSys.ALUSys.ARF.AR.Q = value;
            CPUSys.ALUSys.ARF.SP.Q = value;
            CPUSys.ALUSys.RF.R1.Q = value;
            CPUSys.ALUSys.RF.R2.Q = value;
            CPUSys.ALUSys.RF.R3.Q = value;
            CPUSys.ALUSys.RF.R4.Q = value;
            CPUSys.ALUSys.RF.S1.Q = value;
            CPUSys.ALUSys.RF.S2.Q = value;
            CPUSys.ALUSys.RF.S3.Q = value;
            CPUSys.ALUSys.RF.S4.Q = value;
            CPUSys.ALUSys.DMU.DR.DROut = 16'h0;
            CPUSys.ALUSys.IMU.IR.IROut = 16'h0;
        end
    endtask

    task SetALUFlags;
        input [3:0] value;
        begin
            CPUSys.ALUSys.ALU.FlagsOut = value;
        end
    endtask

    task SetRegistersRx;
        begin
            CPUSys.ALUSys.RF.R1.Q = 16'h2312;
            CPUSys.ALUSys.RF.R2.Q = 16'h6789;
            CPUSys.ALUSys.RF.R3.Q = 16'h8894;
            CPUSys.ALUSys.RF.R4.Q = 16'hF210;
        end
    endtask

    task DisableAll;
        begin
            CPUSys.RF_RegSel = 4'b1111;
            CPUSys.RF_ScrSel = 4'b1111;
            CPUSys.ARF_RegSel = 3'b111;
            CPUSys.ALU_WF = 0;
            CPUSys.IMU_CS = 0;
            CPUSys.DMU_CS = 0;
            CPUSys.T_Reset = 1;
        end
    endtask

    task ResetT;
        begin
            CPUSys.T_Reset = 1;
        end
    endtask


    task RunInstruction;
    begin
        clock_count = 0;
        CPUSys.T = 12'b0000_0000_0100; // Start at T2 (instruction already in IR)
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 20) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
    end
endtask
   
    assign Opcode = CPUSys.Opcode;
    assign RegSel = CPUSys.RegSel;
    assign Address = CPUSys.Address;
    assign DestReg = CPUSys.DestReg;
    assign SrcReg1 = CPUSys.SrcReg1;
    assign SrcReg2 = CPUSys.SrcReg2;
   
    initial begin
        F.SimulationName ="CPUSystem";
        F.InitializeSimulation(0);
        clk.clock = 0;
       
        //Test 1
        test_no = 1;
        clock_count = 0;
        DisableAll();
        ClearRegisters();
       
        SetRegisters(16'h7777);
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h7777, test_no, "R2");
        rg.ActivateReset();
        clk.Clock();
        rg.DeactivateReset();
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0000, test_no, "R2");
        CPUSys.ALUSys.ARF.PC.Q = 16'h0056;

        //Test 2 BGT 0x11
        test_no = 2;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1011;
                SetALUFlags(4'b0000);
        CPUSys.T = 12'b0000_0000_0100; // Set T to 4
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
                F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0011, test_no, "PC");

        //Test 3 DEC R1, R2
        test_no = 3;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'h0001;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h2250;
        CPUSys.T = 12'b0000_0000_0100; // Set T to 4
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0000, test_no, "R1");
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0001, test_no, "R2");
        F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z");

        //Test 4 LSL R2 R2
        test_no = 4;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'h0002;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h26D0;
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.OutA, 16'h0004, test_no, "OutA");
        F.CheckValues(CPUSys.ALUSys.ALUOut, 16'h0008, test_no, "ALUOut");
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0004, test_no, "R2");
       
        //Test 5 ADD PC AR SP
        test_no = 5;
        ClearRegisters();
        CPUSys.ALUSys.ARF.AR.Q = 16'h3550;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h4CA6;
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h364F, test_no, "PC");
       
        //Test 6 MOV AR, R4
        test_no = 6;
        ClearRegisters();
        SetRegistersRx();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h5970;               
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.RF.R4.Q, 16'hF210, test_no, "R4");
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'hF210, test_no, "AR");

        //Test 7 IMM R1, 0x01
        test_no = 7;
        ClearRegisters();
        SetRegistersRx();
        SetALUFlags(4'b1111);
        CPUSys.ALUSys.IMU.IR.IROut = 16'h5C01;
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0001, test_no, "R1");

        test_no = 8;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h00AB;
    SetALUFlags(4'b0000);
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h00AB, test_no, "PC");

    // ------------------------------------------------------------------
    // Test 9: BNE 0x55  (branch if Z==0, should branch)
    //   IR = {6'b000001, 2'b00, 8'h55} = 16'h0455
    //   Flags: Z=0 â†’ branch taken
    // ------------------------------------------------------------------
    test_no = 9;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h0455;
    SetALUFlags(4'b0000); // Z=0
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0055, test_no, "PC");

    // ------------------------------------------------------------------
    // Test 10: BNE 0x55  (Z==1, branch NOT taken â†’ PC unchanged)
    //   Flags: Z=1 â†’ fall through; PC stays at 0
    // ------------------------------------------------------------------
    test_no = 10;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h0455;
    SetALUFlags(4'b1000); // Z=1
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (no branch)");

    // ------------------------------------------------------------------
    // Test 11: BEQ 0x33  (branch if Z==1, should branch)
    //   IR = {6'b000010, 2'b00, 8'h33} = 16'h0833
    //   Flags: Z=1 â†’ branch taken
    // ------------------------------------------------------------------
    test_no = 11;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h0833;
    SetALUFlags(4'b1000); // Z=1
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0033, test_no, "PC");

    // ------------------------------------------------------------------
    // Test 12: BEQ 0x33  (Z==0, branch NOT taken)
    // ------------------------------------------------------------------
    test_no = 12;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h0833;
    SetALUFlags(4'b0000); // Z=0
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (no branch)");

    // ------------------------------------------------------------------
    // Test 13: BLT 0x22  (branch if N!=O, i.e. negative XOR overflow)
    //   Flags: N=1, O=0 â†’ N!=O â†’ branch taken
    //   IR = {6'b000011, 2'b00, 8'h22} = 16'h0C22
    // ------------------------------------------------------------------
    test_no = 13;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h0C22;
    SetALUFlags(4'b0010); // N=1, O=0
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0022, test_no, "PC");

    // ------------------------------------------------------------------
    // Test 14: BGE 0x44  (branch if N==O)
    //   Flags: N=0, O=0 â†’ branch taken
    //   IR = {6'b000110, 2'b00, 8'h44} = 16'h1844
    // ------------------------------------------------------------------
    test_no = 14;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h1844;
    SetALUFlags(4'b0000); // N=0, O=0
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0044, test_no, "PC");

    // ------------------------------------------------------------------
    // Test 15: BGE 0x44  (N!=O â†’ no branch)
    //   Flags: N=1, O=0
    // ------------------------------------------------------------------
    test_no = 15;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h1844;
    SetALUFlags(4'b0010); // N=1, O=0
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (no branch)");

    // ------------------------------------------------------------------
    // Test 16: BLE 0x77  (branch if N!=O OR Z==1)
    //   Flags: N=0, O=0, Z=1 â†’ condition true (Z==1)
    //   IR = {6'b000101, 2'b00, 8'h77} = 16'h1477
    // ------------------------------------------------------------------
    test_no = 16;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h1477;
    SetALUFlags(4'b1000); // Z=1
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0077, test_no, "PC");

// =====================================================================
// â”€â”€ 1-OPERAND ALU INSTRUCTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// =====================================================================

    // ------------------------------------------------------------------
    // Test 17: INC R1, R3  (R1 â† R3 + 1)
    //   DSTREG=R1=100, SREG1=R3=110
    //   IR = {6'b000111, 3'b100, 3'b110, 3'b000, 1'b0}
    //      = {6'h07, 4'b1001, 3'b100, 3'b00} â€¦
    //   Let's build it:
    //     bits[15:10]=000111, [9:7]=100, [6:4]=110, [3:1]=000, [0]=0
    //     = 0001_1110_0110_0000 = 16'h1E60
    // ------------------------------------------------------------------
    test_no = 17;
    ClearRegisters();
    CPUSys.ALUSys.RF.R3.Q = 16'h00FF;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h1E60;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0100, test_no, "R1 (INC R3)");

    // ------------------------------------------------------------------
    // Test 18: DEC R2, R2  (R2 â† R2 - 1, check zero flag)
    //   DSTREG=R2=101, SREG1=R2=101
    //   bits[15:10]=001000, [9:7]=101, [6:4]=101, [3:0]=0000
    //   = 0010_0010_1101_0000 = 16'h22D0
    //   (R2 starts at 0x0001 â†’ result 0x0000, Z should be set)
    // ------------------------------------------------------------------
    test_no = 18;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h0001;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h22D0;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0000, test_no, "R2 (DEC R2=1)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z flag");

    // ------------------------------------------------------------------
    // Test 19: LSR R1, R1  (R1 â† LSR R1, check carry with odd value)
    //   DSTREG=R1=100, SREG1=R1=100
    //   bits[15:10]=001010, [9:7]=100, [6:4]=100, [3:0]=0000
    //   = 0010_1010_0100_0000 = 16'h2A40
    //   R1 = 0x0003 â†’ result 0x0001, C=1 (LSB was 1)
    // ------------------------------------------------------------------
    test_no = 19;
    ClearRegisters();
    CPUSys.ALUSys.RF.R1.Q = 16'h0003;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h2A40;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0001, test_no, "R1 (LSR 0x0003)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 1, test_no, "C flag");

    // ------------------------------------------------------------------
    // Test 20: ASR R1, R1  (arithmetic right shift, sign extends)
    //   R1 = 0x8000 â†’ result 0xC000 (MSB stays 1)
    //   Same encoding as test 19 but OPCODE=0x0B
    //   bits[15:10]=001011, [9:7]=100, [6:4]=100, [3:0]=0000
    //   = 0010_1110_0100_0000 = 16'h2E40
    // ------------------------------------------------------------------
    test_no = 20;
    ClearRegisters();
    CPUSys.ALUSys.RF.R1.Q = 16'h8000;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h2E40;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hC000, test_no, "R1 (ASR 0x8000)");

    // ------------------------------------------------------------------
    // Test 21: CSL R3, R3  (circular left shift using carry)
    //   OPCODE=0x0C=001100, DSTREG=R3=110, SREG1=R3=110
    //   bits[15:10]=001100, [9:7]=110, [6:4]=110, [3:0]=0000
    //   = 0011_0011_0110_0000 = 16'h3360
    //   R3=0x8001, Carry=0 â†’ old MSB(1) becomes new carry, old carry(0) enters LSB
    //   result = 0x0002, new C=1
    // ------------------------------------------------------------------
    test_no = 21;
    ClearRegisters();
    CPUSys.ALUSys.RF.R3.Q = 16'h8001;
    SetALUFlags(4'b0000); // C=0
    CPUSys.ALUSys.IMU.IR.IROut = 16'h3360;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R3.Q, 16'h0002, test_no, "R3 (CSL 0x8001, C=0)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 1, test_no, "C flag after CSL");

    // ------------------------------------------------------------------
    // Test 22: NOT R4, R4  (R4 â† ~R4)
    //   OPCODE=0x0E=001110, DSTREG=R4=111, SREG1=R4=111
    //   bits[15:10]=001110, [9:7]=111, [6:4]=111, [3:0]=0000
    //   = 0011_1011_1111_0000 = 16'h3BF0
    //   R4=0xAA55 â†’ result 0x55AA
    // ------------------------------------------------------------------
    test_no = 22;
    ClearRegisters();
    CPUSys.ALUSys.RF.R4.Q = 16'hAA55;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h3BF0;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R4.Q, 16'h55AA, test_no, "R4 (NOT 0xAA55)");

// =====================================================================
// â”€â”€ 2-OPERAND ALU INSTRUCTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// =====================================================================

    // ------------------------------------------------------------------
    // Test 23: AND R1, R2, R3  (R1 â† R2 AND R3)
    //   OPCODE=0x0F=001111, DSTREG=R1=100, SREG1=R2=101, SREG2=R3=110
    //   bits[15:10]=001111, [9:7]=100, [6:4]=101, [3:1]=110, [0]=0
    //   = 0011_1110_0101_1100 = 16'h3E5C
    //   R2=0xFF0F, R3=0x0FF0 â†’ result 0x0F00
    // ------------------------------------------------------------------
    test_no = 23;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'hFF0F;
    CPUSys.ALUSys.RF.R3.Q = 16'h0FF0;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h3E5C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0F00, test_no, "R1 (AND R2,R3)");

    // ------------------------------------------------------------------
    // Test 24: ORR R1, R2, R3  (R1 â† R2 OR R3)
    //   OPCODE=0x10=010000, same DSTREG/SREG encoding as test 23
    //   bits[15:10]=010000, [9:7]=100, [6:4]=101, [3:1]=110, [0]=0
    //   = 0100_0010_0101_1100 = 16'h425C
    //   R2=0xF00F, R3=0x0FF0 â†’ result 0xFFFF
    // ------------------------------------------------------------------
    test_no = 24;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'hF00F;
    CPUSys.ALUSys.RF.R3.Q = 16'h0FF0;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h425C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hFFFF, test_no, "R1 (ORR R2,R3)");

    // ------------------------------------------------------------------
    // Test 25: XOR R1, R2, R3  (R1 â† R2 XOR R3)
    //   OPCODE=0x11=010001
    //   bits[15:10]=010001, [9:7]=100, [6:4]=101, [3:1]=110, [0]=0
    //   = 0100_0110_0101_1100 = 16'h465C
    //   R2=0xFFFF, R3=0x00FF â†’ result 0xFF00
    // ------------------------------------------------------------------
    test_no = 25;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'hFFFF;
    CPUSys.ALUSys.RF.R3.Q = 16'h00FF;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h465C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hFF00, test_no, "R1 (XOR R2,R3)");

    // ------------------------------------------------------------------
    // Test 26: NAND R1, R2, R3  (R1 â† ~(R2 AND R3))
    //   OPCODE=0x12=010010
    //   bits[15:10]=010010, [9:7]=100, [6:4]=101, [3:1]=110, [0]=0
    //   = 0100_1010_0101_1100 = 16'h4A5C
    //   R2=0xFFFF, R3=0xFFFF â†’ result 0x0000
    // ------------------------------------------------------------------
    test_no = 26;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'hFFFF;
    CPUSys.ALUSys.RF.R3.Q = 16'hFFFF;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h4A5C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0000, test_no, "R1 (NAND 0xFFFF,0xFFFF)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z flag");

    // ------------------------------------------------------------------
    // Test 27: ADD R1, R2, R3  (R1 â† R2 + R3, check carry)
    //   OPCODE=0x13=010011
    //   bits[15:10]=010011, [9:7]=100, [6:4]=101, [3:1]=110, [0]=0
    //   = 0100_1110_0101_1100 = 16'h4E5C
    //   R2=0xFFFF, R3=0x0001 â†’ result 0x0000, C=1, Z=1
    // ------------------------------------------------------------------
    test_no = 27;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'hFFFF;
    CPUSys.ALUSys.RF.R3.Q = 16'h0001;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h4E5C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0000, test_no, "R1 (ADD overflow)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 1, test_no, "C flag");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z flag");

    // ------------------------------------------------------------------
    // Test 28: ADD R1, R2, R3  (positive result, no carry)
    //   R2=0x1234, R3=0x0001 â†’ result 0x1235
    // ------------------------------------------------------------------
    test_no = 28;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h1234;
    CPUSys.ALUSys.RF.R3.Q = 16'h0001;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h4E5C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h1235, test_no, "R1 (ADD normal)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 0, test_no, "C=0");

    // ------------------------------------------------------------------
    // Test 29: ADC R1, R2, R3  (R1 â† R2 + R3 + Carry)
    //   OPCODE=0x14=010100
    //   bits[15:10]=010100, [9:7]=100, [6:4]=101, [3:1]=110, [0]=0
    //   = 0101_0010_0101_1100 = 16'h525C
    //   R2=0x0001, R3=0x0001, C=1 â†’ result 0x0003
    // ------------------------------------------------------------------
    test_no = 29;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h0001;
    CPUSys.ALUSys.RF.R3.Q = 16'h0001;
    SetALUFlags(4'b0100); // C=1
    CPUSys.ALUSys.IMU.IR.IROut = 16'h525C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0003, test_no, "R1 (ADC with C=1)");

    // ------------------------------------------------------------------
    // Test 30: SUB R1, R2, R3  (R1 â† R2 - R3)
    //   OPCODE=0x15=010101
    //   bits[15:10]=010101, [9:7]=100, [6:4]=101, [3:1]=110, [0]=0
    //   = 0101_0110_0101_1100 = 16'h565C
    //   R2=0x0005, R3=0x0003 â†’ result 0x0002
    // ------------------------------------------------------------------
    test_no = 30;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h0005;
    CPUSys.ALUSys.RF.R3.Q = 16'h0003;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h565C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0002, test_no, "R1 (SUB 5-3)");

    // ------------------------------------------------------------------
    // Test 31: SUB R1, R2, R2  (R2 - R2 = 0, Z flag set)
    //   DSTREG=R1=100, SREG1=R2=101, SREG2=R2=101
    //   bits[15:10]=010101, [9:7]=100, [6:4]=101, [3:1]=101, [0]=0
    //   = 0101_0110_0101_1010 = 16'h565A
    // ------------------------------------------------------------------
    test_no = 31;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'hABCD;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h565A;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0000, test_no, "R1 (SUB R2-R2)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z flag");

    // ------------------------------------------------------------------
    // Test 32: SUB negative result â†’ N flag set
    //   R2=0x0001, R3=0x0005 â†’ result = -4 = 0xFFFC, N=1
    // ------------------------------------------------------------------
    test_no = 32;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h0001;
    CPUSys.ALUSys.RF.R3.Q = 16'h0005;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h565C;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hFFFC, test_no, "R1 (SUB negative)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[1], 1, test_no, "N flag");

// =====================================================================
// â”€â”€ MOV / IMM DATA MOVE INSTRUCTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// =====================================================================

    // ------------------------------------------------------------------
    // Test 33: MOV R2, R4  (R2 â† R4)
    //   OPCODE=0x16=010110, DSTREG=R2=101, SREG1=R4=111
    //   bits[15:10]=010110, [9:7]=101, [6:4]=111, [3:0]=0000
    //   = 0101_1010_1111_0000 = 16'h5AF0
    // ------------------------------------------------------------------
    test_no = 33;
    ClearRegisters();
    SetRegistersRx();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h5AF0;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'hF210, test_no, "R2 (MOV R4 â†’ R2)");

    // ------------------------------------------------------------------
    // Test 34: IMM R3, 0xFF  (R3 â† 0x00FF)
    //   OPCODE=0x17=010111, RSEL=R3=10, ADDRESS=0xFF
    //   bits[15:10]=010111, [9:8]=10, [7:0]=11111111
    //   = 0101_1110_1111_1111 = 16'h5EFF
    // ------------------------------------------------------------------
    test_no = 34;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h5EFF;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R3.Q, 16'h00FF, test_no, "R3 (IMM 0xFF)");

    // ------------------------------------------------------------------
    // Test 35: IMM R4, 0x00  (load zero, verify Z flag NOT touched by IMM)
    //   OPCODE=0x17=010111, RSEL=R4=11, ADDRESS=0x00
    //   bits[15:10]=010111, [9:8]=11, [7:0]=00000000
    //   = 0101_1111_0000_0000 = 16'h5F00
    // ------------------------------------------------------------------
    test_no = 35;
    ClearRegisters();
    SetALUFlags(4'b0110); // pre-set some flags
    CPUSys.ALUSys.IMU.IR.IROut = 16'h5F00;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R4.Q, 16'h0000, test_no, "R4 (IMM 0x00)");
    // IMM should not modify flags
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut, 4'b0110, test_no, "Flags unchanged by IMM");

// =====================================================================
// â”€â”€ EDGE CASES & FLAG INTERACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// =====================================================================

    // ------------------------------------------------------------------
    // Test 36: LSL R1, R1  (shift out MSB â†’ carry, result zero â†’ Z)
    //   OPCODE=0x09=001001, DSTREG=R1=100, SREG1=R1=100
    //   bits[15:10]=001001, [9:7]=100, [6:4]=100, [3:0]=0000
    //   = 0010_0110_0100_0000 = 16'h2640
    //   R1=0x8000 â†’ LSL: result=0x0000, C=1, Z=1
    // ------------------------------------------------------------------
    test_no = 36;
    ClearRegisters();
    CPUSys.ALUSys.RF.R1.Q = 16'h8000;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h2640;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0000, test_no, "R1 (LSL 0x8000)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 1, test_no, "C=1 after LSL");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z=1 after LSL");

    // ------------------------------------------------------------------
    // Test 37: INC R1, R1  (overflow: 0x7FFF + 1 = 0x8000, overflow flag)
    //   OPCODE=0x07=000111, DSTREG=R1=100, SREG1=R1=100
    //   bits[15:10]=000111, [9:7]=100, [6:4]=100, [3:0]=0000
    //   = 0001_1110_0100_0000 = 16'h1E40
    //   0x7FFF + 1 = 0x8000, negative flag set, overflow flag set
    // ------------------------------------------------------------------
    test_no = 37;
    ClearRegisters();
    CPUSys.ALUSys.RF.R1.Q = 16'h7FFF;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h1E40;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h8000, test_no, "R1 (INC 0x7FFF)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[1], 1, test_no, "N flag");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[0], 1, test_no, "O flag");

    // ------------------------------------------------------------------
    // Test 38: BGT NOT taken when Z==1 (even if N==O)
    //   BGT condition: N==O AND Z==0
    //   Flags: N=0, O=0, Z=1 â†’ NOT taken
    //   IR = {6'b000100, 2'b00, 8'hFF} = 16'h10FF
    // ------------------------------------------------------------------
    test_no = 38;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h10FF;
    SetALUFlags(4'b1000); // Z=1, N=0, O=0
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (BGT no branch: Z=1)");

    // ------------------------------------------------------------------
    // Test 39: CSR R2, R2  (circular right shift)
    //   OPCODE=0x0D=001101, DSTREG=R2=101, SREG1=R2=101
    //   bits[15:10]=001101, [9:7]=101, [6:4]=101, [3:0]=0000
    //   = 0011_0110_1010_0000 = 16'h36A0 (wrong, recalculate)
    //   bits: 001101 | 101 | 101 | 000 | 0
    //   = 0011_0110_1101_0000 (hmm, let's be careful)
    //   b15-10: 001101
    //   b9-7:   101
    //   b6-4:   101
    //   b3-1:   000
    //   b0:     0
    //   = 00110110_10100000  wait:
    //     b15=0,b14=0,b13=1,b12=1,b11=0,b10=1 = 0x35 as upper
    //     b9=1,b8=0,b7=1 | b6=1,b5=0,b4=1 | b3=0,b2=0,b1=0 | b0=0
    //     lower byte: 10110100 wait again:
    //     b9-b8 = 10, b7 = 1, b6-b4=101, b3-b1=000, b0=0
    //     lower bits [9:0]: 10 1 101 000 0 = 10_1101_0000 = 0x2D0? no wait these are 10 bits
    //     Let me just spell it out bit by bit:
    //     [15:10] = 001101
    //     [9]     = 1
    //     [8]     = 0
    //     [7]     = 1
    //     [6]     = 1
    //     [5]     = 0
    //     [4]     = 1
    //     [3]     = 0
    //     [2]     = 0
    //     [1]     = 0
    //     [0]     = 0
    //     = 0011_0110_1101_0000 = 16'h36D0
    //   R2=0x0001, Carry=0 â†’ old LSB(1) becomes new carry, old carry(0) enters MSB
    //   result = 0x0000 (LSB out) | 0x0000 (C into MSB) = 0x0000? No:
    //   R2=0x0001=0000_0000_0000_0001, CSR: result=0x0000 with MSB=C=0 â†’ 0x0000, new C=1
    // ------------------------------------------------------------------
    test_no = 39;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h0001;
    SetALUFlags(4'b0000); // C=0
    CPUSys.ALUSys.IMU.IR.IROut = 16'h36D0;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0000, test_no, "R2 (CSR 0x0001, C=0)");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 1, test_no, "C=1 after CSR");

    // ------------------------------------------------------------------
    // Test 40: MOV R1, R1  (self-move, value preserved)
    //   OPCODE=0x16=010110, DSTREG=R1=100, SREG1=R1=100
    //   bits: 010110 | 100 | 100 | 000 | 0
    //   = 0101_1010_0100_0000 = 16'h5A40 (wait)
    //   b15-10=010110, b9-7=100, b6-4=100, b3-1=000, b0=0
    //   b15=0,14=1,13=0,12=1,11=1,10=0 | b9=1,8=0,7=0 | b6=1,5=0,4=0 | b3-1=000,b0=0
    //   = 0101_1010_0100_0000 = 16'h5A40
    // ------------------------------------------------------------------
    test_no = 40;
    ClearRegisters();
    CPUSys.ALUSys.RF.R1.Q = 16'hDEAD;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h5A40;
    RunInstruction();
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hDEAD, test_no, "R1 (MOV R1â†’R1 self-copy)");

        F.FinishSimulation();
    end

endmodule