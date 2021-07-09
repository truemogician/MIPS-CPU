`timescale 1ns / 1ps

`include "../Include/Enum.sv"
`include "../Include/Function.sv"

import AluCode::*;
import Function::GetMinWidth;
module ALU #(
	parameter BitWidth = 32
)(a, b, control, c, zero, carry, negative, overflow);
	typedef `LOGIC(BitWidth) Data;
	input	Data	a;
	input	Data	b;
	input	AluCodeEnum	control;
	output	Data	c;
	output	bit		zero = '0;
	output	bit		carry = '0;
	output	bit		negative = '0;
	output	bit		overflow = '0;
	localparam ShiftMask = `ONE(GetMinWidth(BitWidth));
	always_comb begin
		unique case (control)
			AluCode::ADDU:	{carry, c} = a + b;
			AluCode::ADD:	begin
				{carry, c} = a + b;
				overflow = (~`MSB(a) ^ ~`MSB(b)) & (carry ^ `MSB(c));
			end
			AluCode::SUBU:	{carry, c} = a - b;
			AluCode::SUB:	begin
				{carry, c} = a - b;
				overflow = (`MSB(a) ^ `MSB(b)) & (~carry ^ `MSB(c));
			end
			AluCode::AND:	c = a & b;
			AluCode::OR:	c = a | b;
			AluCode::XOR:	c = a ^ b;
			AluCode::NOR:	c = ~(a | b);
			AluCode::LUI:	c = {`LOW(b), `ZERO(BitWidth >> 1)};
			AluCode::SLTU:	begin
				c = a < b ? 1'b1 : 1'b0;
				carry = `LSB(c);
			end
			AluCode::SLT:	c = $signed(a) < $signed(b) ? 1'b1 : 1'b0;
			AluCode::SRA:	begin
				carry = a === '0 ? 1'b0 : b[(a & ShiftMask) - 1];
				c = $signed(b) >>> (a & ShiftMask);
			end
			AluCode::SRL:	begin
				carry = a === '0 ? 1'b0 : b[(a & ShiftMask) - 1];
				c = b >> (a & ShiftMask);
			end
			AluCode::SLL:	begin
				carry = a === '0 ? 1'b0 : b[BitWidth - (a & ShiftMask)];
				c = b << (a & ShiftMask);
			end
			default: c = 'z;
		endcase
		zero = control === AluCode::NONE ? zero : control === AluCode::SLT || control === AluCode::SLTU ? a == b : c == '0;
		negative = control === AluCode::NONE ? negative : control === AluCode::SLT ? `LSB(c) : `MSB(c);
	end
endmodule