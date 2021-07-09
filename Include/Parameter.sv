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

	`define DECLARE_TYPE(typeName) typedef `LOGIC(typeName``Width) typeName
	`define DECLARE_NULLABLE(typeName, hasValueName = hasValue, valueName = value)\
	typedef struct packed{\
		logic hasValue;\
		typename value;\
	} Nullable``typeName

	`DECLARE_TYPE(Data);
	`DECLARE_TYPE(Instr);
	`DECLARE_TYPE(RegAddr);
	`DECLARE_TYPE(DataAddr);
	`DECLARE_TYPE(InstrAddr);
	`DECLARE_NULLABLE(RegAddr);
	`DECLARE_NULLABLE(DataAddr);
	`DECLARE_NULLABLE(InstrAddr);

	parameter Data ExceptionAddress = 32'h00000004;
endpackage

`endif