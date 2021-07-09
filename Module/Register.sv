`timescale 1ns / 1ps

`include "../Include/Enum.sv"

import ClockEdge::*;
module Register #(
	parameter BitWidth = 32,
	parameter `LOGIC(BitWidth) InitialValue = 0,
	parameter ClockEdgeEnum Edge = ClockEdge::Rising
)(enable, reset, clock, write, wData, rData);
	typedef `LOGIC(BitWidth) T;
	input	wire	enable;
	input	wire	reset;
	input	wire	clock;
	input	wire	write;
	input	T		wData;
	output	T		rData;

	T data;
	if (Edge == ClockEdge::Rising) begin
		always_ff @(posedge clock or posedge reset)
			data <= reset ? InitialValue : write ? wData : data;
	end
	else begin
		always_ff @(negedge clock or posedge reset)
			data <= reset ? InitialValue : write ? wData : data;
	end
	assign rData = enable & ~write ? data : 'z;
endmodule