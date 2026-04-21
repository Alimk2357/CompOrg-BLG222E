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
        // ------------------------------------------------------------------
        test_no = 9;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h0455;
        SetALUFlags(4'b0000); // Z=0
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0055, test_no, "PC");

        // ------------------------------------------------------------------
        // Test 10: BNE 0x55  (Z==1, branch NOT taken)
        // ------------------------------------------------------------------
        test_no = 10;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h0455;
        SetALUFlags(4'b1000); // Z=1
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (no branch)");

        // ------------------------------------------------------------------
        // Test 11: BEQ 0x33  (branch if Z==1, should branch)
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
        // Test 13: BLT 0x22  (branch if N!=O, taken)
        // ------------------------------------------------------------------
        test_no = 13;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h0C22;
        SetALUFlags(4'b0010); // N=1, O=0
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0022, test_no, "PC");

        // ------------------------------------------------------------------
        // Test 14: BGE 0x44  (branch if N==O, taken)
        // ------------------------------------------------------------------
        test_no = 14;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1844;
        SetALUFlags(4'b0000); // N=0, O=0
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0044, test_no, "PC");

        // ------------------------------------------------------------------
        // Test 15: BGE 0x44  (N!=O â†’ no branch)
        // ------------------------------------------------------------------
        test_no = 15;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1844;
        SetALUFlags(4'b0010); // N=1, O=0
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (no branch)");

        // ------------------------------------------------------------------
        // Test 16: BLE 0x77  (branch if N!=O OR Z==1)
        // ------------------------------------------------------------------
        test_no = 16;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1477;
        SetALUFlags(4'b1000); // Z=1
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0077, test_no, "PC");

        // ------------------------------------------------------------------
        // Test 17: INC R1, R3  (R1 â†  R3 + 1)
        // ------------------------------------------------------------------
        test_no = 17;
        ClearRegisters();
        CPUSys.ALUSys.RF.R3.Q = 16'h00FF;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1E60;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0100, test_no, "R1 (INC R3)");

        // ------------------------------------------------------------------
        // Test 18: DEC R2, R2  (R2 â†  R2 - 1, check zero flag)
        // ------------------------------------------------------------------
        test_no = 18;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'h0001;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h22D0;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0000, test_no, "R2 (DEC R2=1)");
        F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z flag");

        // ------------------------------------------------------------------
        // Test 19: LSR R1, R1  (R1 â†  LSR R1)
        // ------------------------------------------------------------------
        test_no = 19;
        ClearRegisters();
        CPUSys.ALUSys.RF.R1.Q = 16'h0003;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h2A40;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0001, test_no, "R1 (LSR 0x0003)");
        F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 1, test_no, "C flag");

        // ------------------------------------------------------------------
        // Test 20: ASR R1, R1  (arithmetic right shift)
        // ------------------------------------------------------------------
        test_no = 20;
        ClearRegisters();
        CPUSys.ALUSys.RF.R1.Q = 16'h8000;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h2E40;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hC000, test_no, "R1 (ASR 0x8000)");

        // ------------------------------------------------------------------
        // Test 21: CSL R3, R3  (circular left shift)
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
        // Test 22: NOT R4, R4  (R4 â†  ~R4)
        // ------------------------------------------------------------------
        test_no = 22;
        ClearRegisters();
        CPUSys.ALUSys.RF.R4.Q = 16'hAA55;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h3BF0;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R4.Q, 16'h55AA, test_no, "R4 (NOT 0xAA55)");

        // ------------------------------------------------------------------
        // Test 23: AND R1, R2, R3
        // ------------------------------------------------------------------
        test_no = 23;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'hFF0F;
        CPUSys.ALUSys.RF.R3.Q = 16'h0FF0;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h3E5C;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0F00, test_no, "R1 (AND R2,R3)");

        // ------------------------------------------------------------------
        // Test 24: ORR R1, R2, R3
        // ------------------------------------------------------------------
        test_no = 24;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'hF00F;
        CPUSys.ALUSys.RF.R3.Q = 16'h0FF0;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h425C;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hFFFF, test_no, "R1 (ORR R2,R3)");

        // ------------------------------------------------------------------
        // Test 25: XOR R1, R2, R3
        // ------------------------------------------------------------------
        test_no = 25;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'hFFFF;
        CPUSys.ALUSys.RF.R3.Q = 16'h00FF;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h465C;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hFF00, test_no, "R1 (XOR R2,R3)");

        // ------------------------------------------------------------------
        // Test 26: NAND R1, R2, R3
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
        // Test 27: ADD R1, R2, R3 (overflow)
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
        // Test 28: ADD R1, R2, R3 (normal)
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
        // Test 29: ADC R1, R2, R3
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
        // Test 30: SUB R1, R2, R3
        // ------------------------------------------------------------------
        test_no = 30;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'h0005;
        CPUSys.ALUSys.RF.R3.Q = 16'h0003;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h565C;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0002, test_no, "R1 (SUB 5-3)");

        // ------------------------------------------------------------------
        // Test 31: SUB R1, R2, R2 (Z flag)
        // ------------------------------------------------------------------
        test_no = 31;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'hABCD;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h565A;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0000, test_no, "R1 (SUB R2-R2)");
        F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z flag");

        // ------------------------------------------------------------------
        // Test 32: SUB negative N flag
        // ------------------------------------------------------------------
        test_no = 32;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'h0001;
        CPUSys.ALUSys.RF.R3.Q = 16'h0005;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h565C;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hFFFC, test_no, "R1 (SUB negative)");
        F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[1], 1, test_no, "N flag");

        // ------------------------------------------------------------------
        // Test 33: MOV R2, R4
        // ------------------------------------------------------------------
        test_no = 33;
        ClearRegisters();
        SetRegistersRx();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h5AF0;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'hF210, test_no, "R2 (MOV R4 â†’ R2)");

        // ------------------------------------------------------------------
        // Test 34: IMM R3, 0xFF
        // ------------------------------------------------------------------
        test_no = 34;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h5EFF;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R3.Q, 16'h00FF, test_no, "R3 (IMM 0xFF)");

        // ------------------------------------------------------------------
        // Test 35: IMM R4, 0x00
        // ------------------------------------------------------------------
        test_no = 35;
        ClearRegisters();
        SetALUFlags(4'b0110); 
        CPUSys.ALUSys.IMU.IR.IROut = 16'h5F00;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R4.Q, 16'h0000, test_no, "R4 (IMM 0x00)");
        F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut, 4'b0110, test_no, "Flags unchanged by IMM");

        // ------------------------------------------------------------------
        // Test 36: LSL R1, R1 
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
        // Test 37: INC R1, R1 (overflow)
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
        // Test 38: BGT NOT taken when Z==1
        // ------------------------------------------------------------------
        test_no = 38;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h10FF;
        SetALUFlags(4'b1000); 
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (BGT no branch: Z=1)");

        // ------------------------------------------------------------------
        // Test 39: CSR R2, R2 
        // ------------------------------------------------------------------
        test_no = 39;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'h0001;
        SetALUFlags(4'b0000); 
        CPUSys.ALUSys.IMU.IR.IROut = 16'h36D0;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0000, test_no, "R2 (CSR 0x0001, C=0)");
        F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[2], 1, test_no, "C=1 after CSR");

        // ------------------------------------------------------------------
        // Test 40: MOV R1, R1 (self-copy)
        // ------------------------------------------------------------------
        test_no = 40;
        ClearRegisters();
        CPUSys.ALUSys.RF.R1.Q = 16'hDEAD;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h5A40;
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'hDEAD, test_no, "R1 (MOV R1â†’R1 self-copy)");

        // =====================================================================
        // ── EXTENDED TEST CASES (41 - 61) ──
        // =====================================================================

        // ------------------------------------------------------------------
        // Test 41: BLT 0x33 (N==O, branch NOT taken)
        // ------------------------------------------------------------------
        test_no = 41;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h0C33;
        SetALUFlags(4'b0000); // N=0, O=0
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (BLT no branch: N==O)");

        // ------------------------------------------------------------------
        // Test 42: BLT 0x33 (N=1, O=1, branch NOT taken)
        // ------------------------------------------------------------------
        test_no = 42;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h0C33;
        SetALUFlags(4'b0011); // N=1, O=1
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (BLT no branch: N==O)");

        // ------------------------------------------------------------------
        // Test 43: BLE 0x44 (N==O and Z==0, branch NOT taken)
        // ------------------------------------------------------------------
        test_no = 43;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1444;
        SetALUFlags(4'b0000); // Z=0, N=0, O=0
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0000, test_no, "PC (BLE no branch)");

        // ------------------------------------------------------------------
        // Test 44: BLE 0x44 (N!=O and Z==0, branch taken)
        // ------------------------------------------------------------------
        test_no = 44;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1444;
        SetALUFlags(4'b0010); // Z=0, N=1, O=0
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0044, test_no, "PC (BLE branch taken)");

 // ------------------------------------------------------------------
        // Test 45: INC SP, SP (ARF usage)
        // ------------------------------------------------------------------
        test_no = 45;
        ClearRegisters();
        CPUSys.ALUSys.ARF.SP.Q = 16'h00FF;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h1DB0; // Düzeltildi (Eski: 1D60)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h0100, test_no, "SP (INC SP)");

        // ------------------------------------------------------------------
        // Test 46: DEC AR, AR (ARF usage)
        // ------------------------------------------------------------------
        test_no = 46;
        ClearRegisters();
        CPUSys.ALUSys.ARF.AR.Q = 16'h1000;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h2120; // Düzeltildi (Eski: 2140)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h0FFF, test_no, "AR (DEC AR)");

        // ------------------------------------------------------------------
        // Test 48: SUB SP, SP, R3 (Mixed ARF/RF usage)
        // ------------------------------------------------------------------
        test_no = 48;
        ClearRegisters();
        CPUSys.ALUSys.ARF.SP.Q = 16'h0100;
        CPUSys.ALUSys.RF.R3.Q = 16'h0002;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h55BC; // Düzeltildi (Eski: 5578)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h00FE, test_no, "SP (SUB SP, SP, R3)");

        // ------------------------------------------------------------------
        // Test 49: MOV SP, R4 (RF to ARF)
        // ------------------------------------------------------------------
        test_no = 49;
        ClearRegisters();
        CPUSys.ALUSys.RF.R4.Q = 16'hABCD;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h59F0; // Düzeltildi (Eski: 59E0)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'hABCD, test_no, "SP (MOV SP, R4)");

        // ------------------------------------------------------------------
        // Test 51: ORR R2, R2, R2 (Self ORR)
        // ------------------------------------------------------------------
        test_no = 51;
        ClearRegisters();
        CPUSys.ALUSys.RF.R2.Q = 16'hAAAA;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h42DA; // Düzeltildi (Eski: 42AA)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'hAAAA, test_no, "R2 (ORR R2, R2, R2)");

        // ------------------------------------------------------------------
        // Test 55: LSL SP, AR (ARF to ARF shift)
        // ------------------------------------------------------------------
        test_no = 55;
        ClearRegisters();
        CPUSys.ALUSys.ARF.AR.Q = 16'h000F;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h25A0; // Düzeltildi (Eski: 2540)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h001E, test_no, "SP (LSL SP, AR)");

        // ------------------------------------------------------------------
        // Test 56: LSR AR, SP (ARF to ARF shift)
        // ------------------------------------------------------------------
        test_no = 56;
        ClearRegisters();
        CPUSys.ALUSys.ARF.SP.Q = 16'h000F;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h2930; // Düzeltildi (Eski: 2960)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h0007, test_no, "AR (LSR AR, SP)");

        // ------------------------------------------------------------------
        // Test 57: ASR PC, R1 (Sign extension into PC)
        // ------------------------------------------------------------------
        test_no = 57;
        ClearRegisters();
        CPUSys.ALUSys.RF.R1.Q = 16'h8000;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h2CC0; // Düzeltildi (Eski: 2C80)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'hC000, test_no, "PC (ASR PC, R1)");

        // ------------------------------------------------------------------
        // Test 58: CSL R1, SP (ARF source for CSL)
        // ------------------------------------------------------------------
        test_no = 58;
        ClearRegisters();
        CPUSys.ALUSys.ARF.SP.Q = 16'h8001;
        SetALUFlags(4'b0100); // C=1
        CPUSys.ALUSys.IMU.IR.IROut = 16'h3230; // Düzeltildi (Eski: 3260)
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0003, test_no, "R1 (CSL R1, SP with C=1)");
        // ------------------------------------------------------------------
        // Test 59: CSR R2, AR (ARF source for CSR)
        // ------------------------------------------------------------------
        test_no = 59;
        ClearRegisters();
        CPUSys.ALUSys.ARF.AR.Q = 16'h0001;
        SetALUFlags(4'b0100); // C=1
        CPUSys.ALUSys.IMU.IR.IROut = 16'h36A0; 
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h8000, test_no, "R2 (CSR R2, AR with C=1)");

        // ------------------------------------------------------------------
        // Test 60: NOT PC, PC
        // ------------------------------------------------------------------
        test_no = 60;
        ClearRegisters();
        CPUSys.ALUSys.ARF.PC.Q = 16'h0000;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h3800; 
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'hFFFF, test_no, "PC (NOT PC, PC)");

        // ------------------------------------------------------------------
        // Test 61: IMM R2, 0xAA
        // ------------------------------------------------------------------
        test_no = 61;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h5DAA; 
        RunInstruction();
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h00AA, test_no, "R2 (IMM 0xAA)");

        F.FinishSimulation();
    end
endmodule