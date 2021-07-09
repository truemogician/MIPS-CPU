`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Function.sv"

import ClockEdge::*;
import Function::GetMinWidth;
module RegFile #(
	parameter BitWidth = 32,
	parameter RegCount = 32,
	parameter ClockEdgeEnum Edge = ClockEdge::Rising
)(enable, reset, clock, write, wAddr, rAddr1, rAddr2, wData, rData1, rData2);
	typedef `BIT(GetMinWidth(RegCount)) Address;
	typedef `BIT(BitWidth) Data;
	input			enable;
	input			reset;
	input			clock;
	input			write;
	input	Address	wAddr;
	input	Address	rAddr1;
	input	Address	rAddr2;
	input	Data	wData;
	output	Data	rData1;
	output	Data	rData2;

	Data[RegCount - 1 : 0] registers;
	if (Edge == ClockEdge::Rising) begin
		always_ff @(posedge clock or posedge reset) begin
			if (reset)
				for (int i = 0; i < RegCount; ++i)
					registers[i] <= '0;
			else if (enable && write == '1)
				registers[wAddr] <= wData;
		end
	end
	else begin
		always_ff @(negedge clock or posedge reset) begin
			if (reset)
				for (int i = 0; i < RegCount; ++i)
					registers[i] <= '0;
			else if (enable && write == '1)
				registers[wAddr] <= wData;
		end
	end
	assign rData1 = ~enable ? 'z : registers[rAddr1];
	assign rData2 = ~enable ? 'z : registers[rAddr2];
endmodule