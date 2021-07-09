`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Function.sv"

import ClockEdge::*;
import Function::GetMinWidth;
module DataMemory #(
	parameter BitWidth = 32,	//unit: bit
	parameter Capacity = 128,	//unit: byte
	parameter ClockEdgeEnum Edge = ClockEdge::Rising
)(enable, reset, clock, write, addr, wData, wDataMask, rData);
	localparam AddrWidth = GetMinWidth(Capacity);
	typedef `LOGIC(BitWidth) Data;
	typedef `BIT(AddrWidth) Address;
	input	wire	enable;
	input	wire	reset;
	input	wire	clock;
	input	wire	write;
	input 	Address	addr;
	input	Data	wData;
	input	Data	wDataMask;
	output	Data	rData;

	`BIT(Capacity << 3) data;
	`WIRE(AddrWidth + 3) bitAddr = `EXT(addr, AddrWidth + 3) << 3;
	assign rData = ~enable | write ? 'z : data[bitAddr +: BitWidth];
	if (Edge == ClockEdge::Rising) begin
		always_ff @(posedge clock or posedge reset) begin
			if (reset)
				data <= '0;
			else if (enable & write)
				for (int i = 0; i < BitWidth; ++i) begin
					if (wDataMask[i])
						data[bitAddr + i] <= wData[i];
				end
		end
	end
	else begin
		always_ff @(negedge clock or posedge reset) begin
			if (reset)
				data <= '0;
			else if (enable & write)
				for (int i = 0; i < BitWidth; ++i) begin
					if (wDataMask[i])
						data[bitAddr + i] <= wData[i];
				end
		end
	end
endmodule