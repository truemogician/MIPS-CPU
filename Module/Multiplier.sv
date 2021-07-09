`timescale 1ns / 1ps

`include "../Include/Macro.sv"

module Multiplier #(
	parameter BitWidth = 32
)(enable, isUnsigned, multiplicand, multiplier, product);
	typedef `LOGIC(BitWidth) TIn;
	typedef `LOGIC(BitWidth << 1) TOut;
	input	wire enable;
	input	wire isUnsigned;
	input	TIn multiplicand;
	input	TIn multiplier;
	output	TOut product;

	`WIRE(2) negative;
	assign negative[0] = ~isUnsigned & `MSB(multiplicand);
	assign negative[1] = ~isUnsigned & `MSB(multiplier);
	TIn umultiplicand, umultiplier;
	assign umultiplicand = negative[0] ? ~(multiplicand - 1'b1) : multiplicand;
	assign umultiplier = negative[1] ? ~(multiplier - 1'b1) : multiplier;
	TOut tmp[BitWidth - 2];
	genvar i;
	generate
		for (i = 0; i < (BitWidth >> 1); ++i) begin
			assign tmp[i + ((BitWidth >> 1) - 2)] = ~enable ? '0 
				: (umultiplier[i << 1] ? (`EXT(umultiplicand, BitWidth << 1) << (i << 1)) : '0)
				+ (umultiplier[i << 1 | 1] ? (`EXT(umultiplicand, BitWidth << 1) << (i << 1 | 1)) : '0);
		end
		for (i = 0; i < ((BitWidth >> 1) - 2); ++i)
			assign tmp[i] = tmp[i + 1 << 1] + tmp[i + 1 << 1 | 1];
	endgenerate
	TOut uproduct;
	assign uproduct = tmp[0] + tmp[1];
	assign product = negative[0] ^ negative[1] ? ~uproduct + 1'b1 : uproduct;
endmodule