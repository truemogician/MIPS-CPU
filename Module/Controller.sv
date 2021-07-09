`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Parameter.sv"

import AluCode::*;
import OpType::*;
import OpCode::*;
import SpecCode::*;
import RegimmCode::*;
import Cop0Code::*;
import ExcCode::*;
import Spec2Code::*;
import Parameter::Instr;
import Parameter::InstrAddr;
import Parameter::RegAddr;
module Controller(instr,
	opType, opCode, specCode, regimmCode, cop0Code, excCode, spec2Code, aluCode,
	hasWriteAddr, wAddr, rAddr1, rAddr2, immediate,
	shamt, sext, jump, branch, load, store, lsLength, isUnsigned, mult, div, jal);
	input	Instr instr;
	output	OpTypeEnum opType;
	output	OpCodeEnum opCode;
	output	SpecCodeEnum specCode;
	output	RegimmCodeEnum regimmCode;
	output	Cop0CodeEnum cop0Code;
	output	ExcCodeEnum excCode;
	output	Spec2CodeEum spec2Code;
	output	AluCodeEnum aluCode;
	output	wire hasWriteAddr;
	output	RegAddr wAddr;
	output	RegAddr rAddr1;
	output 	RegAddr rAddr2;
	output	`LOGIC(26) immediate;
	output	wire shamt;
	output	wire sext;
	output	wire jump;
	output	wire branch;
	output	wire load;
	output	wire store;
	output	`WIRE(2) lsLength;
	output 	wire isUnsigned;
	output	wire mult;
	output	wire div;
	output	wire jal;

	assign opCode = OpCodeEnum'(instr[31 : 26]);
	assign specCode = opCode != OpCode::SPECIAL ? SpecCode::NONE : SpecCodeEnum'(instr[5 : 0]);
	assign regimmCode = opCode != OpCode::REGIMM ? RegimmCode::NONE : RegimmCodeEnum'(instr[20 : 16]);
	assign cop0Code = opCode != OpCode::COP0 ? Cop0Code::NONE : Cop0CodeEnum'(instr[25] ? instr[5 : 0] : {1'bz, instr[25 : 21]});
	assign spec2Code = opCode != OpCode::SPECIAL2 ? Spec2Code::NONE : Spec2CodeEum'(instr[5 : 0]);
	always_comb begin
		unique case(opCode) inside
			OpCode::SPECIAL, OpCode::SPECIAL2: opType = OpType::Register;
			OpCode::J, OpCode::JAL: opType = OpType::Jump;
			6'b0100??: opType = OpType::Coprocessor;
			default: opType = OpType::Immediate;
		endcase
		unique case(specCode) inside
			SpecCode::SYSCALL: excCode = ExcCode::Sys;
			SpecCode::BREAK: excCode = ExcCode::Bp;
			SpecCode::TEQ: excCode = ExcCode::Tr;
			default: excCode = ExcCode::None;
		endcase
	end
	RegAddr rsAddr, rtAddr, rdAddr;
	assign {rsAddr, rtAddr} = opType == OpType::Jump ? 'z : instr[25 : 16];
	assign rdAddr = opCode == OpCode::SPECIAL || opCode == OpCode::SPECIAL2 ? instr[15 : 11] : 'z;
	
	assign shamt = specCode =?= 6'b0000?? === '1;	//SLL, SRL, SRA
	assign sext = opCode =?= 6'b0010?? === '1;		//ADDI, ADDIU, SLTI, SLTIU
	assign immediate = shamt ? `EXT(instr[10 : 6], 26)
		: opType == OpType::Register || opType == OpType::Coprocessor ? 'z
			: opType == OpType::Jump ? instr[25 : 0]
				: sext ? `SEXT(instr[15 : 0], 26) : `EXT(instr[15 : 0], 26);
	assign jump = opType == OpType::Jump | specCode =?= 6'b00100? === '1; //JR, JALR
	assign branch = opCode =?= 6'b0001?? === '1 | regimmCode =?= 5'b0000? === '1;
	assign load = opCode =?= 6'b100??? === '1;		//LW, LH, LHU, LB, LBU
	assign store = opCode =?= 6'b101??? === '1;		//SW, SH, SB
	assign mult = specCode =?= 6'b01100? === '1;	//MULT, MULTU
	assign div = specCode =?= 6'b01101? === '1;		//DIV, DIVU
	assign isUnsigned = (load & opCode[2]) | ((mult | div) & specCode[0]);	//LHU, LBU
	wire fromHilo, toHilo;
	assign fromHilo = specCode =?= 6'b100?0 === '1;
	assign toHilo = specCode =?= 6'b0100?1 === '1;
	assign lsLength = load | store ? opCode[1 : 0] : 'z;	//Word:11, Halfword:01, Byte: 00
	assign exception = opCode =?= 6'b110??? | specCode =?= 6'b00110? === '1;	//TRAP, SYSCALL, BREAK
	assign jal = opCode == OpCode::JAL || specCode === SpecCode::JALR;
	assign hasWriteAddr = ~(store | mult | div | toHilo | branch | (jump & specCode !== SpecCode::JALR) | (opType == OpType::Coprocessor & instr[25 : 21] != '0));
	assign wAddr =  hasWriteAddr ? opType == OpType::Register | spec2Code =?= 6'b10000? === '1 ? rdAddr : rtAddr : 'z;
	assign rAddr1 = shamt | fromHilo | opType == OpType::Jump | opCode == OpCode::LUI ? 'z : rsAddr;
	assign rAddr2 = store | (branch & opCode != OpCode::REGIMM) | (opType == OpType::Register & ~jump) | (opType == OpType::Coprocessor & instr[25 : 21] == 5'b00100) ? rtAddr : 'z;

	always_comb begin : GenerateAluCode
		priority case ({opCode, specCode}) inside
			{OpCode::SPECIAL, SpecCode::ADD	}, {OpCode::ADDI,	SpecCode::NONE}:	aluCode = AluCode::ADD;
			{OpCode::SPECIAL, SpecCode::ADDU}, {OpCode::ADDIU,	SpecCode::NONE}:	aluCode = AluCode::ADDU;
			{OpCode::SPECIAL, SpecCode::SUB	}, {6'b0001??,		SpecCode::NONE}:	aluCode = AluCode::SUB;
			{OpCode::SPECIAL, SpecCode::AND	}, {OpCode::ANDI,	SpecCode::NONE}:	aluCode = AluCode::AND;
			{OpCode::SPECIAL, SpecCode::OR	}, {OpCode::ORI,	SpecCode::NONE}:	aluCode = AluCode::OR;
			{OpCode::SPECIAL, SpecCode::XOR	}, {OpCode::XORI,	SpecCode::NONE}:	aluCode = AluCode::XOR;
			{OpCode::SPECIAL, SpecCode::SLL	}, {OpCode::SPECIAL,SpecCode::SLLV}:	aluCode = AluCode::SLL;
			{OpCode::SPECIAL, SpecCode::SRL	}, {OpCode::SPECIAL,SpecCode::SRLV}:	aluCode = AluCode::SRL;
			{OpCode::SPECIAL, SpecCode::SRA	}, {OpCode::SPECIAL,SpecCode::SRAV}:	aluCode = AluCode::SRA;
			{OpCode::SPECIAL, SpecCode::SLT	}, {OpCode::SLTI,	SpecCode::NONE}:	aluCode = AluCode::SLT;
			{OpCode::SPECIAL, SpecCode::SLTU}, {OpCode::SLTIU,	SpecCode::NONE}:	aluCode = AluCode::SLTU;
			{OpCode::SPECIAL, SpecCode::SUBU}:	aluCode = AluCode::SUBU;
			{OpCode::SPECIAL, SpecCode::NOR	}:	aluCode = AluCode::NOR;
			{OpCode::LUI,     SpecCode::NONE}:	aluCode = AluCode::LUI;
			{6'b10????, 	  SpecCode::NONE}:	if (opCode != OpCode::CACHE) aluCode = AluCode::ADD;
			default:	aluCode = AluCode::NONE;
		endcase
	end
endmodule