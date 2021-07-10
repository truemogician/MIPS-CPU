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
	real period;
	bit clearPcOffset;
	int maxReplication;
	bit fileOutput;
	string fileName;
	PrintingTimeEnum printingTime;
	function new (
		input real period = 10,
		input bit clearPcOffset = '0,
		input int maxReplication = 8,
		input bit fileOutput = '1,
		input string fileName = "output.txt",
		input PrintingTimeEnum printingTime = PrintingTime::AfterExecution
	);
		this.period = period;
		this.clearPcOffset = clearPcOffset;
		this.maxReplication = maxReplication;
		this.fileOutput = fileOutput;
		this.fileName = fileName;
		this.printingTime = printingTime;
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
		if (conf.fileOutput)
			file = $fopen(conf.fileName, "w");
		enable = '0;
		reset = '0;
		clock = '0;
		#(conf.period / 2);
		reset = '1;
		#(conf.period / 2);
		reset = '0;
		enable = '1;
	end
	always begin
		if (~enable)
			#(conf.period / 2);
		else begin
			if (conf.printingTime == PrintingTime::BeforeExecution) begin
				#(conf.period / 2);
				clock = ~clock;
			end
			if (clock & ~reset) begin
				if (chip.instr === lastInstruction) begin
					++replicationCount;
					if (replicationCount >= conf.maxReplication) begin
						if (conf.fileOutput)
							$fclose(file);
						$stop();
					end
				end
				else begin
					lastInstruction = chip.instr;
					replicationCount = 0;
				end
				if (conf.fileOutput) begin
					$fdisplay(file, "pc: %h", conf.clearPcOffset ? chip.cpu.pc - InstrOffset : chip.cpu.pc);
					$fdisplay(file, "instr: %h", chip.instr);
					for (int i = 0; i < 32; ++i)
						$fdisplay(file, "regfile%0d: %h", i, chip.cpu.regFile.registers[i]);
				end
			end
			if (conf.printingTime == PrintingTime::AfterExecution) begin
				clock = ~clock;
				#(conf.period / 2);
			end;
		end
	end
endmodule