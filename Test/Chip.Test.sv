`timescale 1ns / 1ps

`include "../Include/Parameter.sv"

package PrintingTime;
	typedef enum bit{
		BeforeExecution = '0,
		AfterExecution = '1
	} PrintingTimeEnum;
endpackage
import PrintingTime::*;
class Configuration;
	real Period;
	bit ClearPcOffset;
	int MaxReplication;
	bit FileOutput;
	string FileName;
	PrintingTimeEnum PrintingTime;
	function new (
		input real period = 10,
		input bit clearPcOffset = '0,
		input int maxReplication = 8,
		input bit fileOutput = '1,
		input string fileName = "output.txt",
		input PrintingTimeEnum pTime = PrintingTime::AfterExecution
	);
		this.Period = period;
		this.ClearPcOffset = clearPcOffset;
		this.MaxReplication = maxReplication;
		this.FileOutput = fileOutput;
		this.FileName = fileName;
		this.PrintingTime = pTime;
	endfunction
endclass

import Parameter::InstrOffset;
import Parameter::Instr;
module ChipTest;
	Configuration conf = new(2, '0, 8, '1, "output.txt", PrintingTime::BeforeExecution);
	logic enable, reset, clock;
	Chip chip(.*);
	int file, replicationCount = 0;
	Instr lastInstruction = 'z;
	initial begin
		if (conf.FileOutput)
			file = $fopen(conf.FileName, "w");
		enable = '0;
		reset = '0;
		clock = '0;
		#(conf.Period / 2);
		reset = '1;
		#(conf.Period / 2);
		reset = '0;
		enable = '1;
	end
	always begin
		if (~enable)
			#(conf.Period / 2);
		else begin
			if (conf.PrintingTime == PrintingTime::BeforeExecution) begin
				#(conf.Period / 2);
				clock = ~clock;
			end
			if (clock & ~reset) begin
				if (chip.instr === lastInstruction) begin
					++replicationCount;
					if (replicationCount >= conf.MaxReplication) begin
						if (conf.FileOutput)
							$fclose(file);
						$stop();
					end
				end
				else begin
					lastInstruction = chip.instr;
					replicationCount = 0;
				end
				if (conf.FileOutput) begin
					$fdisplay(file, "pc: %h", chip.cpu.pc);
					$fdisplay(file, "instr: %h", chip.instr);
					for (int i = 0; i < 32; ++i)
						$fdisplay(file, "regfile%0d: %h", i, chip.cpu.regFile.registers[i]);
				end
			end
			if (conf.PrintingTime == PrintingTime::AfterExecution) begin
				clock = ~clock;
				#(conf.Period / 2);
			end;
		end
	end
endmodule