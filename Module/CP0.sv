`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Parameter.sv"

import Cop0Code::*;
import ExcCode::*;
import Parameter::*;
module CP0(enable, reset, clock, opCode, excCode, pc, addr, wData, rData, eJump, epc);
	typedef `LOGIC(5) Address;
	input	wire			enable;
	input	wire			reset;
	input	wire			clock;
	input	Cop0CodeEnum	opCode;
	input	ExcCodeEnum		excCode;
	input	Data			pc;
	input	Address			addr;
	input	Data			wData;
	output	Data			rData;
	output	logic			eJump;
	output	Data			epc;

	Data[31 : 0] registers;
	localparam Address Status = 5'd12;
	localparam Address Cause = 5'd13;
	localparam Address EPC = 5'd14;
	always_comb begin
		if (opCode == Cop0Code::ERET)
			eJump = '1;
		else if (opCode != Cop0Code::NONE || excCode == ExcCode::None || ~registers[Status][0])
			eJump = '0;
		//Interupt mask should be 1 to enable relative interupt according to MIPS specification
		//but the requirement of the assigmnent violate the standard
		else case ({excCode, registers[Status][15 : 8]}) inside
			{ExcCode::Sys,	8'b???????0}: eJump = '1;
			{ExcCode::Bp,	8'b??????0?}: eJump = '1;
			{ExcCode::Tr,	8'b?????0??}: eJump = '1;
			default: eJump = '0;
		endcase
	end
	Data statusCache;
	always_ff @(posedge clock or posedge reset) begin
		if (reset) begin
			for (int i = 0; i < 32; ++i)
				if (i != Status)
					registers[i] <= '0;
			registers[Status] <= 32'h0000ff01;
			statusCache <= '0;
		end
		else if (enable) begin
			case(opCode) inside
				Cop0Code::MTC0:	registers[addr] <= wData;
				Cop0Code::ERET: registers[Status] <= statusCache;
				Cop0Code::NONE:
					if (eJump) begin
						statusCache <= registers[Status];
						registers[Status][0] <= '0;
						registers[Cause][6 : 2] <= excCode;
						registers[EPC] <= pc;
					end
			endcase
		end
	end
	assign epc = ~enable | reset ? 'z
		: opCode == Cop0Code::ERET ? registers[EPC] + (InstrWidth >> 3)
			: eJump ? ExceptionAddress + InstrOffset : 'z;
	assign rData = enable & ~reset & opCode == Cop0Code::MFC0 ? registers[addr] : 'z;
endmodule