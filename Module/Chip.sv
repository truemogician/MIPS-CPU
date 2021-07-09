`timescale 1ns / 1ps

`include "../Include/Parameter.sv"

import Parameter::*;
module Chip(enable, reset, clock);
	input enable;
	input reset;
	input clock;

	wire		write;
	InstrAddr	instrAddr;
	Instr		instr;
	DataAddr	dataAddr;
	Data		wData, rData;
	CPU cpu(
		.enable,
		.reset,
		.clock,
		.instrAddr,
		.instr,
		.write,
		.dataAddr,
		.wData,
		.rData
	);

	InstrMemory instrMemory(
		.addr(instrAddr),
		.instr
	);

	DataMemory #(DataWidth, DataCapacity, MemoryEdge) dataMemory(
		.enable,
		.reset,
		.clock,
		.write,
		.addr(dataAddr),
		.wData,
		.rData
	);
endmodule