`timescale 1ns / 1ps

`ifndef FUNCTION
`define FUNCTION

package Function;
	function int GetMsb(input int value);
		for (int i = 31; i >= 0; --i)
			if (value[i])
				return i;
		return '1;
	endfunction

	function int GetMinWidth(input int value);
		automatic int result = '1, prev = '1;
		for (int i = 0; i < 32; ++i)
			if (value[i]) begin
				if (result != '1)
					prev = result;
				result = i;
			end
		return prev == '1 ? result : result + 1;
	endfunction
	
	function bit IsPowerOf2(input int value);
		automatic bit count = '0;
		for (int i = 0; i < 32; ++i)
			if (value[i]) begin
				if (~count)
					count = '1;
				else
					return 1'b0;
			end
		return count;
	endfunction
endpackage

`endif