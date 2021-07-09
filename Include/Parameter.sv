`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Function.sv"

`ifndef PARAMETER
`define PARAMETER

package Parameter;
	import ClockEdge::*;
	import Function::GetMinWidth;

	parameter DataWidth		= 32;
	parameter InstrWidth	= 32;
	parameter RegCount		= 32;
	parameter DataCapacity	= 128;
	parameter InstrCapacity	= 8192;
	parameter DataOffset	= 32'h10010000;
	parameter InstrOffset	= 32'h00400000;
	parameter ClockEdgeEnum PCEdge		= ClockEdge::Falling;
	parameter ClockEdgeEnum MemoryEdge	= ClockEdge::Rising;

	parameter RegAddrWidth	 = GetMinWidth(RegCount);
	parameter DataAddrWidth  = GetMinWidth(DataCapacity);
	parameter InstrAddrWidth = GetMinWidth(InstrCapacity);
	
	typedef `LOGIC(DataWidth)		Data;
	typedef `LOGIC(InstrWidth)		Instr;
	typedef `LOGIC(RegAddrWidth)	RegAddr;
	typedef `LOGIC(DataAddrWidth)	DataAddr;
	typedef `LOGIC(InstrAddrWidth)	InstrAddr;

	parameter Data ExceptionAddress = 32'h00000004;
endpackage

`endif