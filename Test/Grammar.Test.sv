`timescale 1ns / 1ps

`include "../Include/Macro.sv"

module GrammerTest;
	`LOGIC(2) a,b,c;
	initial begin
		a = 2'b10;
		b = 2'b0z;
		c = 'z;
		unique case({a,b}) inside
			4'b10??: c='1;
			default: c='0;
		endcase
		#5 $stop();
	end
endmodule