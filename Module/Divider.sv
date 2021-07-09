`timescale 1ns / 1ps

`include "../Include/Macro.sv"

module Divider #(
	parameter BitWidth = 32
)(enable, isUnsigned, dividend, divisor, quotient, remainder);
	typedef `LOGIC(BitWidth) T;
	input	wire enable;
	input	wire isUnsigned;
	input	T dividend;
	input	T divisor;
	output	T quotient;
	output	T remainder;

	`WIRE(2) negative;
	assign negative[0] = ~isUnsigned & `MSB(dividend);
	assign negative[1] = ~isUnsigned & `MSB(divisor);
	T udividend, udivisor, uquotient, uremainder;
	assign udividend = negative[0] ? ~(dividend - 1'b1) : dividend;
	assign udivisor = negative[1] ? ~(divisor - 1'b1) : divisor;
	`LOGIC(BitWidth + 1) subResult[BitWidth];
	T tmp[BitWidth - 1];
	genvar i;
	generate
		assign subResult[0] = ~enable ? '0 : {`ZERO(BitWidth - 1), udividend[BitWidth - 1]} - udivisor;
		assign uquotient[BitWidth - 1] = ~enable ? '0 : ~subResult[0][BitWidth];
		assign tmp[0] = ~enable ? '0 : subResult[0][BitWidth] ? {`ZERO(BitWidth - 1), udividend[BitWidth - 1]} : subResult[0];
		for (i = 1; i < BitWidth; ++i) begin
			assign subResult[i] = ~enable ? '0 : {tmp[i - 1], udividend[BitWidth - i - 1]} - udivisor;
			assign uquotient[BitWidth - i - 1] = ~enable ? '0 : ~subResult[i][BitWidth];
		end
		for (i = 1; i < BitWidth - 1; ++i)
			assign tmp[i] = ~enable ? '0 : subResult[i][BitWidth] ? {tmp[i - 1], udividend[BitWidth - i - 1]} : subResult[i];
		assign uremainder = ~enable ? '0 : subResult[BitWidth - 1][BitWidth] ? {tmp[BitWidth - 2], udividend[0]} : subResult[BitWidth - 1];
	endgenerate
	assign quotient = negative[0] ^ negative[1] ? ~uquotient + 1'b1 : uquotient;
	assign remainder = negative[0] ? ~uremainder + 1'b1 : uremainder;
endmodule