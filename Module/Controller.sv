`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Parameter.sv"

import AluCode::*;
import InstrType::*;
import OpCode::*;
import SpecCode::*;
import RegimmCode::*;
import Cop0Code::*;
import ExcCode::*;
import Spec2Code::*;
import Parameter::*;
import DataLength::*;
module Controller(instr,
	instrType, opCode, specCode, regimmCode, cop0Code, spec2Code, aluCode,
	wAddr, rAddr1, rAddr2, immediate,
	shamt, sext, jump, branch, load, store, lsLength, isUnsigned, mult, div, jal, trap);
	input	Instr instr;
	output	InstrTypeEnum instrType;
	output	OpCodeEnum opCode;
	output	SpecCodeEnum specCode;
	output	RegimmCodeEnum regimmCode;
	output	Cop0CodeEnum cop0Code;
	output	Spec2CodeEum spec2Code;
	output	AluCodeEnum aluCode;
	output	NullableRegAddr wAddr;
	output	NullableRegAddr rAddr1;
	output 	NullableRegAddr rAddr2;
	output	`LOGIC(26) immediate;
	output	wire shamt;
	output	wire sext;
	output	wire jump;
	output	wire branch;
	output	wire load;
	output	wire store;
	output	DataLengthEnum lsLength;
	output 	wire isUnsigned;
	output	wire mult;
	output	wire div;
	output	wire jal;
	output	wire trap;

	assign opCode = OpCodeEnum'(instr[31 : 26]);
	assign specCode = opCode != OpCode::SPECIAL ? SpecCode::NONE : SpecCodeEnum'(instr[5 : 0]);
	assign regimmCode = opCode != OpCode::REGIMM ? RegimmCode::NONE : RegimmCodeEnum'(instr[20 : 16]);
	assign cop0Code = opCode != OpCode::COP0 ? Cop0Code::NONE : Cop0CodeEnum'(instr[25] ? instr[5 : 0] : {1'b0, instr[25 : 21]});
	assign spec2Code = opCode != OpCode::SPECIAL2 ? Spec2Code::NONE : Spec2CodeEum'(instr[5 : 0]);
	always_comb begin
		unique case(opCode) inside
			OpCode::SPECIAL, OpCode::SPECIAL2: begin
				instrType = InstrType::Register;
				immediate = shamt ? `EXT(instr[10 : 6], 26) : 'z;
			end
			OpCode::J, OpCode::JAL: begin
				instrType = InstrType::Jump;
				immediate = instr[25 : 0];
			end
			6'b0100??: begin
				instrType = InstrType::Coprocessor;
				immediate = 'z;
			end
			default: begin
				instrType = InstrType::Immediate;
				immediate = sext ? `SEXT(instr[15 : 0], 26) : `EXT(instr[15 : 0], 26);
			end
		endcase
	end
	RegAddr rsAddr, rtAddr, rdAddr;
	assign {rsAddr, rtAddr} = instrType == InstrType::Jump ? 'z : instr[25 : 16];
	assign rdAddr = opCode == OpCode::SPECIAL || opCode == OpCode::SPECIAL2 ? instr[15 : 11] : 'z;
	
	assign shamt = specCode ==? 6'b0000??;	//SLL, SRL, SRA
	assign sext = opCode ==? 6'b0010?? | (opCode == OpCode::REGIMM & trap);	//ADDI, ADDIU, SLTI, SLTIU
	assign jump = instrType == InstrType::Jump | specCode ==? 6'b00100?; 	//JR, JALR
	assign branch = opCode ==? 6'b0001?? | regimmCode ==? 5'b0000?;
	assign load = opCode ==? 6'b100???;						//LW, LH, LHU, LB, LBU
	assign store = opCode inside {[6'b101000 : 6'b101110]};	//SW, SH, SB
	assign mult = specCode ==? 6'b01100?;	//MULT, MULTU
	assign div = specCode ==? 6'b01101?;	//DIV, DIVU
	assign isUnsigned = (load & opCode[2]) | ((mult | div) & specCode[0]);	//LHU, LBU
	wire fromHilo, toHilo, exception;
	assign fromHilo = specCode ==? 6'b100?0;
	assign toHilo = specCode ==? 6'b0100?1;
	assign lsLength = load | store ? DataLengthEnum'(opCode[1 : 0]) : DataLength::None;
	assign jal = opCode == OpCode::JAL || specCode == SpecCode::JALR;
	assign trap = specCode ==? 6'b110??? | regimmCode ==? 5'b01???;
	assign exception = trap | specCode ==? 6'b00110?;
	assign wAddr.hasValue = ~(store | mult | div | toHilo | branch | exception | (jump & specCode != SpecCode::JALR) | (instrType == InstrType::Coprocessor & instr[25 : 21] != '0));
	assign wAddr.value =  wAddr.hasValue ? instrType == InstrType::Register | spec2Code ==? 6'b10000? ? rdAddr : rtAddr : '0;
	assign rAddr1.hasValue = ~(shamt | fromHilo | instrType == InstrType::Jump | opCode == OpCode::LUI | (exception & ~trap));
	assign rAddr1.value = rAddr1.hasValue ? rsAddr : '0;
	assign rAddr2.hasValue = opCode != OpCode::REGIMM & (store | branch | (instrType == InstrType::Register & ~jump) | (instrType == InstrType::Coprocessor & instr[25 : 21] == 5'b00100));
	assign rAddr2.value = rAddr2.hasValue ? rtAddr : '0;

	always_comb begin : GenerateAluCode
		if (trap || (branch && opCode != OpCode::REGIMM))
			aluCode = AluCode::SUBU;
		else if (load || store)
			aluCode = AluCode::ADDU;
		else if (opCode == OpCode::SPECIAL) begin
			unique case (specCode) inside
				SpecCode::ADD:	aluCode = AluCode::ADD;
				SpecCode::ADDU:	aluCode = AluCode::ADDU;
				SpecCode::SUB:	aluCode = AluCode::SUB;
				SpecCode::SUBU:	aluCode = AluCode::SUBU;
				SpecCode::AND:	aluCode = AluCode::AND;
				SpecCode::OR:	aluCode = AluCode::OR;
				SpecCode::XOR:	aluCode = AluCode::XOR;
				SpecCode::SLT:	aluCode = AluCode::SLT;
				SpecCode::SLTU:	aluCode = AluCode::SLTU;
				SpecCode::NOR:	aluCode = AluCode::NOR;
				SpecCode::SLL, SpecCode::SLLV:	aluCode = AluCode::SLL;
				SpecCode::SRL, SpecCode::SRLV:	aluCode = AluCode::SRL;
				SpecCode::SRA, SpecCode::SRAV:	aluCode = AluCode::SRA;
				default:	aluCode = AluCode::NONE;
			endcase
		end
		else begin
			unique case (opCode) inside
				OpCode::ADDI:	aluCode = AluCode::ADD;
				OpCode::ADDIU:	aluCode = AluCode::ADDU;
				OpCode::ANDI:	aluCode = AluCode::AND;
				OpCode::ORI:	aluCode = AluCode::OR;
				OpCode::XORI:	aluCode = AluCode::XOR;
				OpCode::SLTI:	aluCode = AluCode::SLT;
				OpCode::SLTIU:	aluCode = AluCode::SLTU;
				OpCode::LUI:	aluCode = AluCode::LUI;
				default:		aluCode = AluCode::NONE;
			endcase
		end
	end
endmodule