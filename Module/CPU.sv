`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Parameter.sv"

import AluCode::*;
import OpType::*;
import OpCode::*;
import SpecCode::*;
import Cop0Code::*;
import ExcCode::*;
import Spec2Code::*;
import RegimmCode::*;
import Function::GetMsb;
import Parameter::*;
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
	OpTypeEnum		opType;
	OpCodeEnum		opCode;
	SpecCodeEnum	specCode;
	RegimmCodeEnum	regimmCode;
	Cop0CodeEnum	cop0Code;
	ExcCodeEnum		excCode;
	Spec2CodeEum	spec2Code;
	AluCodeEnum		aluCode;
	RegAddr			wRegAddr, rRegAddr1, rRegAddr2;
	logic			hasWriteAddr, shamt, sext, jump, branch, load, store, mult, div, jal, isUnsigned;
	`LOGIC(2)		lsLength;
	Controller controller(
		.instr,
		.opType,
		.opCode,
		.specCode,
		.regimmCode,
		.cop0Code,
		.excCode,
		.spec2Code,
		.aluCode,
		.hasWriteAddr,
		.wAddr(wRegAddr),
		.rAddr1(rRegAddr1),
		.rAddr2(rRegAddr2),
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
		.jal
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
				3'b?11:		wRegData = rData;
				3'b001:		wRegData = `SEXT(rData[(DataWidth >> 1) - 1 : 0], DataWidth);
				3'b101:		wRegData = `EXT(rData[(DataWidth >> 1) - 1 : 0], DataWidth);
				3'b000:		wRegData = `SEXT(rData[(DataWidth >> 2) - 1 : 0], DataWidth);
				3'b100:		wRegData = `EXT(rData[(DataWidth >> 2) - 1 : 0], DataWidth);
				default:	wRegData = 'z;
			endcase
		end
		else if (specCode == SpecCode::MFHI)
			wRegData = high;
		else if (specCode == SpecCode::MFLO)
			wRegData = low;
		else if (spec2Code === Spec2Code::MUL)
			wRegData = `LOWW(product, DataWidth << 1);
		else if (spec2Code =?= 6'b10000? === '1)	//CLZ, CLO
			wRegData = DataWidth - GetMsb(spec2Code[0] ? ~rRegData[0] : rRegData[0]) - 1;
		else if (cop0Code === Cop0Code::MFC0)
			wRegData = cp0;
		else
			wRegData = c;
	end
	RegFile #(DataWidth, RegCount, MemoryEdge) regFile(
		.enable,
		.reset,
		.clock,
		.write((jal | hasWriteAddr) & wRegAddr !== '0),
		.wAddr(opCode === OpCode::JAL ? `EXT(31, RegAddrWidth) : wRegAddr),
		.rAddr1(rRegAddr1),
		.rAddr2(rRegAddr2),
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
	assign b = jump ? 'z : store | rRegAddr2 === 'z
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
		.enable(enable & (mult | spec2Code === Spec2Code::MUL)),
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
		.write(mult | div | spec2Code === Spec2Code::MUL | specCode === SpecCode::MTHI),
		.wData(mult | spec2Code === Spec2Code::MUL ? `HIGHW(product, DataWidth << 1) : div ? remainder : rRegData[0]),
		.rData(high)
	);
	Register #(DataWidth, 0, MemoryEdge) lowRegister(
		.enable,
		.reset,
		.clock,
		.write(mult | div | specCode === SpecCode::MTLO),
		.wData(mult ? `LOWW(product, DataWidth << 1) : div ? quotient : rRegData[0]),
		.rData(low)
	);

	logic goto;
	Data gotoAddr, epc;
	always_comb begin
		if (jump | epc !== 'z)
			goto = '1;
		else if (opCode == OpCode::REGIMM) begin
			case (regimmCode)
				RegimmCode::BLTZ:	goto = rRegData[0][DataWidth - 1];
				RegimmCode::BGEZ:	goto = ~rRegData[0][DataWidth - 1];
				default:			goto = '0;
			endcase
		end
		else begin
			case (opCode)
				OpCode::BEQ:	goto = zero;
				OpCode::BNE:	goto = ~zero;
				OpCode::BLEZ:	goto = rRegData[0][DataWidth - 1] | zero;
				OpCode::BGTZ:	goto = ~rRegData[0][DataWidth - 1] & ~zero;
				default:		goto = '0;
			endcase
		end
	end
	assign gotoAddr = ~goto ? 'z : epc !== 'z ? epc
		: opType == OpType::Register 
		? rRegCache[0] : branch 
			? pc + 4 + `SEXT(immediate[15 : 0] << 2, DataWidth)
			: {pc[31 : 28], immediate << 2};
	PC #(DataWidth, InstrWidth, InstrOffset, PCEdge) programCounter(
		.enable,
		.reset,
		.clock,
		.goto,
		.addr(gotoAddr),
		.pc
	);

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
		wData = rRegData[0];
		case (lsLength)
			2'b11:		wDataMask = '1;
			2'b01:		wDataMask = `EXT(`ONE(DataWidth >> 1), DataWidth);
			2'b00:		wDataMask = `EXT(`ONE(DataWidth >> 2), DataWidth);
			default:	wDataMask = '0;
		endcase
	end
endmodule