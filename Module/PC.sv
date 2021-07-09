`timescale 1ns / 1ps

`include "../Include/Enum.sv"

import ClockEdge::*;
module PC #(
	parameter BitWidth = 32,
	parameter InstrWidth = 32,
	parameter `BIT(BitWidth) StartingAddress = 0,
	parameter ClockEdgeEnum Edge = ClockEdge::Rising
)(enable, reset, clock, goto, addr, pc);
	typedef `BIT(BitWidth) Address;
	input			enable;
	input			reset;
	input			clock;
	input			goto;
	input	Address	addr;
	output	Address pc = StartingAddress;

	if (Edge == ClockEdge::Rising) begin
		always_ff @(posedge clock or posedge reset)
			pc <= reset ? StartingAddress : ~enable ? pc
				: goto ? addr : pc + (InstrWidth >> 3);
	end
	else begin
		always_ff @(negedge clock or posedge reset)
			pc <= reset ? StartingAddress : ~enable ? pc
				: goto ? addr : pc + (InstrWidth >> 3);
	end
endmodule