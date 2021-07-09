`timescale 1ns / 1ps

`include "../Include/Macro.sv"

`ifndef ENUM
`define ENUM

package ClockEdge;
	typedef enum bit{
		Rising	= '1,
		Falling	= '0
	} ClockEdgeEnum;
endpackage

package AluCode;
	typedef enum `LOGIC(4){
		ADDU = 4'h0,
		SUBU = 4'h1,
		ADD  = 4'h2,
		SUB  = 4'h3,
		AND  = 4'h4,
		OR   = 4'h5,
		XOR  = 4'h6,
		NOR  = 4'h7,
		LUI  = 4'h8,
		SLTU = 4'ha,
		SLT  = 4'hb,
		SRA  = 4'hc,
		SRL  = 4'hd,
		SLL  = 4'he,
		NONE = 4'hf
	} AluCodeEnum;
endpackage

package OpType;
	typedef enum `BIT(2){
		Register	= 2'b00,
		Immediate	= 2'b01,
		Jump		= 2'b10,
		Coprocessor	= 2'b11
	} OpTypeEnum;
endpackage

package OpCode;
	typedef enum `LOGIC(6){
		SPECIAL	= 6'b000000,	//OpType: Register
		SPECIAL2= 6'b011100,
		REGIMM	= 6'b000001,
		COP0	= 6'b010000,
		COP1	= 6'b010001,
		COP2	= 6'b010010,
		J		= 6'b000010,
		JAL		= 6'b000011,
		ADDI	= 6'b001000,
		ADDIU	= 6'b001001,
		ANDI	= 6'b001100,
		ORI		= 6'b001101,
		XORI	= 6'b001110,
		SLTI	= 6'b001010,
		SLTIU	= 6'b001011,
		LUI		= 6'b001111,
		LW		= 6'b100011,
		LH		= 6'b100001,
		LHU		= 6'b100101,
		LB		= 6'b100000,
		LBU		= 6'b100100,
		SW		= 6'b101011,
		SH		= 6'b101001,
		SB		= 6'b101000,
		BEQ		= 6'b000100,
		BNE		= 6'b000101,
		BLEZ	= 6'b000110,
		BGTZ	= 6'b000111,
		CACHE	= 6'b101111
	} OpCodeEnum;
endpackage

package SpecCode;	//OpCode = 000000
	typedef enum `LOGIC(6){
		NONE	= 6'b111111,
		ADD		= 6'b100000,
		ADDU	= 6'b100001,
		SUB		= 6'b100010,
		SUBU	= 6'b100011,
		AND		= 6'b100100,
		OR		= 6'b100101,
		XOR		= 6'b100110,
		NOR		= 6'b100111,
		SLT		= 6'b101010,
		SLTU	= 6'b101011,
		SLL		= 6'b000000,
		SRL		= 6'b000010,
		SRA		= 6'b000011,
		SLLV	= 6'b000100,
		SRLV	= 6'b000110,
		SRAV	= 6'b000111,
		JR		= 6'b001000,
		MULT	= 6'b011000,
		MULTU	= 6'b011001,
		DIV		= 6'b011010,
		DIVU	= 6'b011011,
		JALR	= 6'b001001,
		MFHI	= 6'b010000,
		MFLO	= 6'b010010,
		MTHI	= 6'b010001,
		MTLO	= 6'b010011,
		SYSCALL	= 6'b001100,
		BREAK	= 6'b001101,
		TEQ		= 6'b110100
	} SpecCodeEnum;
endpackage

package RegimmCode;
	typedef enum `LOGIC(5){
		NONE	= 5'b11111,
		BLTZ	= 5'b00000,
		BGEZ	= 5'b00001
	} RegimmCodeEnum;
endpackage

package Cop0Code;		//OpCode = 0100??
	typedef enum `LOGIC(6){
		NONE	= 6'b111111,
		MFC0	= 6'bz00000,
		MTC0	= 6'bz00100,
		ERET	= 6'b011000,
		DERET	= 6'b011111,
		TLBP	= 6'b001000,
		TLBR	= 6'b000001,
		TLBWI	= 6'b000010,
		TLBWR	= 6'b000110,
		WAIT	= 6'b100000
	} Cop0CodeEnum;
endpackage

package ExcCode;
	typedef enum `LOGIC(5){
		None	= 5'h1f,
		Int		= 5'h00,
		Mod		= 5'h01,
		TLBL	= 5'h02,
		TLBS	= 5'h03,
		AdEL	= 5'h04,
		AdES	= 5'h05,
		IBE		= 5'h06,
		DBE		= 5'h07,
		Sys		= 5'h08,
		Bp		= 5'h09,
		RI		= 5'h0a,
		CpU		= 5'h0b,
		Ov		= 5'h0c,
		Tr		= 5'h0d,
		FPE		= 5'h0f,
		C2E		= 5'h12,
		MDMX	= 5'h16,
		WATCH	= 5'h17,
		MCheck	= 5'h18,
		CacheErr= 5'h1e
	} ExcCodeEnum;
endpackage

package Spec2Code;	//OpCode = 011100
	typedef enum `LOGIC(6){
		NONE	= 6'b111111,
		CLZ		= 6'b100000,
		CLO		= 6'b100001,
		MUL		= 6'b000010
	} Spec2CodeEum;
endpackage

`endif