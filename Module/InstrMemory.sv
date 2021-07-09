`timescale 1ns / 1ps

`include "../Include/Parameter.sv"

import Parameter::*;
module InstrMemory(addr, instr);
	input	InstrAddr	addr;
	output	Instr		instr;
	MemoryCore memoryCore(
		.a(`EXT(addr >> 2, 11)),
		.spo(instr)
	);
endmodule