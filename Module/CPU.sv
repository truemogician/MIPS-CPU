`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Parameter.sv"

import AluCode::*;
import InstrType::*;
import OpCode::*;
import SpecCode::*;
import Cop0Code::*;
import ExcCode::*;
import Spec2Code::*;
import RegimmCode::*;
import Function::GetMsb;
import Parameter::*;
import DataLength::*;
module CPU(enable, reset, clock, instrAddr, instr, write, dataAddr, wData, wDataMask, rData);
	input				enable;
	input				reset;
	input				clock;
	output	InstrAddr	instrAddr;
	input	Instr		instr;
	output				write;
	output	DataAddr	dataAddr;
	output	Data		wData;
	output	Data		wDataMask;
	input	Data		rData;

	`LOGIC(26)		immediate;
	InstrTypeEnum	instrType;
	OpCodeEnum		opCode;
	SpecCodeEnum	specCode;
	RegimmCodeEnum	regimmCode;
	Cop0CodeEnum	cop0Code;
	Spec2CodeEum	spec2Code;
	AluCodeEnum		aluCode;
	DataLengthEnum	lsLength;
	NullableRegAddr	wRegAddr, rRegAddr[2];
	logic			shamt, sext, jump, branch, load, store, mult, div, jal, trap, isUnsigned;
	Controller controller(
		.instr,
		.instrType,
		.opCode,
		.specCode,
		.regimmCode,
		.cop0Code,
		.spec2Code,
		.aluCode,
		.wAddr(wRegAddr),
		.rAddr1(rRegAddr[0]),
		.rAddr2(rRegAddr[1]),
		.immediate,
		.shamt,
		.sext,
		.jump,
		.branch,
		.load,
		.store,
		.lsLength,
		.isUnsigned,
		.mult,
		.div,
		.jal,
		.trap
	);

	Data a, b, c, wRegData, rRegData[2];
	Data pc, high, low, cp0;
	Data remainder, quotient;
	`LOGIC(DataWidth << 1) product;
	always_comb begin
		if (jal)
			wRegData = pc + 4;
		else if (load) begin
			case ({isUnsigned, lsLength}) inside
				{1'b?, DataLength::Word}:		wRegData = rData;
				{1'b0, DataLength::HalfWord}:	wRegData = `SEXT(rData[(DataWidth >> 1) - 1 : 0], DataWidth);
				{1'b1, DataLength::HalfWord}:	wRegData = `EXT(rData[(DataWidth >> 1) - 1 : 0], DataWidth);
				{1'b0, DataLength::Byte}:		wRegData = `SEXT(rData[(DataWidth >> 2) - 1 : 0], DataWidth);
				{1'b1, DataLength::Byte}:		wRegData = `EXT(rData[(DataWidth >> 2) - 1 : 0], DataWidth);
				default:	wRegData = 'z;
			endcase
		end
		else if (specCode == SpecCode::MFHI)
			wRegData = high;
		else if (specCode == SpecCode::MFLO)
			wRegData = low;
		else if (spec2Code == Spec2Code::MUL)
			wRegData = `LOW(product, DataWidth << 1);
		else if (spec2Code ==? 6'b10000?)	//CLZ, CLO
			wRegData = DataWidth - GetMsb(spec2Code[0] ? ~rRegData[0] : rRegData[0]) - 1;
		else if (cop0Code == Cop0Code::MFC0)
			wRegData = cp0;
		else
			wRegData = c;
	end
	RegFile #(DataWidth, RegCount, MemoryEdge) regFile(
		.enable,
		.reset,
		.clock,
		.write(jal | (wRegAddr.hasValue & wRegAddr.value != '0)),
		.wAddr(opCode == OpCode::JAL ? `EXT(31, RegAddrWidth) : wRegAddr.value),
		.rAddr1(rRegAddr[0].value),
		.rAddr2(rRegAddr[1].value),
		.wData(wRegData),
		.rData1(rRegData[0]),
		.rData2(rRegData[1])
	);

	Data rRegCache[2];
	if (MemoryEdge == ClockEdge::Rising)
		always_ff @(posedge clock or posedge reset) begin
			rRegCache[0] <= reset ? '0 : rRegData[0];
			rRegCache[1] <= reset ? '0 : rRegData[1];
		end
	else
		always_ff @(negedge clock or posedge reset) begin
			rRegCache[0] <= reset ? '0 : rRegData[0];
			rRegCache[1] <= reset ? '0 : rRegData[1];
		end

	wire zero, carry, negative, overflow;
	assign a = shamt ? `EXT(immediate, DataWidth) : rRegData[0];
	assign b = jump ? 'z : store | ~rRegAddr[1].hasValue
		? sext ? `SEXT(immediate, DataWidth) : `EXT(immediate, DataWidth)
		: rRegData[1];
	ALU #(DataWidth) alu(
		.a,
		.b,
		.control(aluCode),
		.c,
		.zero,
		.carry,
		.negative,
		.overflow
	);

	Multiplier #(DataWidth) multiplier(
		.enable(enable & (mult | spec2Code == Spec2Code::MUL)),
		.isUnsigned,
		.multiplicand(rRegData[0]),
		.multiplier(rRegData[1]),
		.product
	);
	Divider #(DataWidth) divider(
		.enable(enable & div),
		.isUnsigned,
		.dividend(rRegData[0]),
		.divisor(rRegData[1]),
		.quotient,
		.remainder
	);

	Register #(DataWidth, 0, MemoryEdge) highRegister(
		.enable,
		.reset,
		.clock,
		.write(mult | div | spec2Code == Spec2Code::MUL | specCode == SpecCode::MTHI),
		.wData(mult | spec2Code == Spec2Code::MUL ? `HIGH(product, DataWidth << 1) : div ? remainder : rRegData[0]),
		.rData(high)
	);
	Register #(DataWidth, 0, MemoryEdge) lowRegister(
		.enable,
		.reset,
		.clock,
		.write(mult | div | specCode == SpecCode::MTLO),
		.wData(mult ? `LOW(product, DataWidth << 1) : div ? quotient : rRegData[0]),
		.rData(low)
	);

	NullableData gotoAddr, epc;
	always_comb begin
		if (jump | epc.hasValue)
			gotoAddr.hasValue = '1;
		else if (opCode == OpCode::REGIMM) begin
			case (regimmCode)
				RegimmCode::BLTZ:	gotoAddr.hasValue = rRegData[0][DataWidth - 1];
				RegimmCode::BGEZ:	gotoAddr.hasValue = ~rRegData[0][DataWidth - 1];
				default:			gotoAddr.hasValue = '0;
			endcase
		end
		else begin
			case (opCode)
				OpCode::BEQ:	gotoAddr.hasValue = zero;
				OpCode::BNE:	gotoAddr.hasValue = ~zero;
				OpCode::BLEZ:	gotoAddr.hasValue = rRegData[0][DataWidth - 1] | zero;
				OpCode::BGTZ:	gotoAddr.hasValue = ~rRegData[0][DataWidth - 1] & ~zero;
				default:		gotoAddr.hasValue = '0;
			endcase
		end
	end
	assign gotoAddr.value = ~gotoAddr.hasValue ? 'z
		: epc.hasValue ? epc.value
			: instrType == InstrType::Register 
			? rRegCache[0] : branch 
				? pc + 4 + `SEXT(immediate[15 : 0] << 2, DataWidth)
				: {pc[31 : 28], immediate << 2};
	PC #(DataWidth, InstrWidth, InstrOffset, PCEdge) programCounter(
		.enable,
		.reset,
		.clock,
		.goto(gotoAddr.hasValue),
		.addr(gotoAddr.value),
		.pc
	);

	logic trapped;
	ExcCodeEnum excCode;
	always_comb begin
		if (trap) begin
			unique case({specCode, regimmCode}) inside
				{SpecCode::TEQ,	RegimmCode::NONE}, {SpecCode::NONE,	RegimmCode::TEQI }: trapped = zero;
				{SpecCode::TNE,	RegimmCode::NONE}, {SpecCode::NONE,	RegimmCode::TNEI }: trapped = ~zero;
				{SpecCode::TLT,	RegimmCode::NONE}, {SpecCode::NONE,	RegimmCode::TLTI }: trapped = negative;
				{SpecCode::TLTU,RegimmCode::NONE}, {SpecCode::NONE,	RegimmCode::TLTIU}: trapped = carry;
				{SpecCode::TGE,	RegimmCode::NONE}, {SpecCode::NONE,	RegimmCode::TGEI }: trapped = ~negative;
				{SpecCode::TGEU,RegimmCode::NONE}, {SpecCode::NONE,	RegimmCode::TGEIU}: trapped = ~carry;
				default: trapped = '0;
			endcase
			excCode = trapped ? ExcCode::Tr : ExcCode::None;
		end
		else if (opCode == OpCode::SPECIAL)
			unique case(specCode)
				SpecCode::SYSCALL:	excCode = ExcCode::Sys;
				SpecCode::BREAK:	excCode = ExcCode::Bp;
				default: 			excCode = ExcCode::None;
			endcase
		else
			excCode = ExcCode::None;
	end
	CP0 coprocessor0(
		.enable,
		.reset,
		.clock,
		.opCode(cop0Code),
		.excCode,
		.pc,
		.addr(instr[15 : 11]),
		.wData(rRegData[1]),
		.rData(cp0),
		.epc
	);

	assign instrAddr = `EXT(pc - InstrOffset, InstrAddrWidth);

	assign write = store;
	assign dataAddr	= store | load ? c - DataOffset : 'z;
	always_comb begin
		wData = rRegData[1];
		case (lsLength)
			DataLength::Word:		wDataMask = '1;
			DataLength::HalfWord:	wDataMask = `EXT(`ONE(DataWidth >> 1), DataWidth);
			DataLength::Byte:		wDataMask = `EXT(`ONE(DataWidth >> 2), DataWidth);
			default:				wDataMask = '0;
		endcase
	end
endmodule