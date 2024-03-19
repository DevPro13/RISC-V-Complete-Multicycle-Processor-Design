///////////////////////////////////////////////////////////////
// testbench
//
// Expect simulator to print "Simulation succeeded"
// when the value 25 (0x19) is written to address 100 (0x64)
///////////////////////////////////////////////////////////////

module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;
  logic [31:0] hash;

  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);
  
  // initialize test
  initial
    begin
      hash <= 0;
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if(MemWrite) begin
        if(DataAdr === 100 & WriteData === 25) begin
          $display("Simulation succeeded");
 	   	  $display("hash = %h", hash);
          $stop;
        end else if (DataAdr !== 96) begin
          $display("Simulation failed");
          $stop;
        end
      end
    end

  // Make 32-bit hash of Instruction, PC, ALU
  always @(negedge clk)
    if (~reset) begin
      hash = hash ^ dut.rvmulti.dp.Instr ^ dut.rvmulti.dp.PC;
      if (MemWrite) hash = hash ^ WriteData;
      hash = {hash[30:0], hash[9] ^ hash[29] ^ hash[30] ^ hash[31]};
    end

endmodule

///////////////////////////////////////////////////////////////
// top
//
// Instantiates multicycle RISC-V processor and memory
///////////////////////////////////////////////////////////////

module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] ReadData;
  
  // instantiate processor and memories
  riscvmulti rvmulti(clk, reset, ReadData,MemWrite, DataAdr, 
                     WriteData);
  mem mem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule
///////////////////////////////////////////////////////////////
// mem
//
// Single-ported RAM with read and write ports
// Initialized with machine language program
///////////////////////////////////////////////////////////////

module mem(input  logic        clk, we,
           input  logic [31:0] a, wd,
           output logic [31:0] rd);

  logic [31:0] RAM[63:0];
  
  initial
      $readmemh("riscvtest.txt",RAM);

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

///////////////////////////////////////////////////////////////
// riscvmulti
//
// Multicycle RISC-V microprocessor
///////////////////////////////////////////////////////////////
module riscvmulti(input  logic        clk, reset,
                  input  logic [31:0] ReadData,
                  output logic        MemWrite,
                  output logic [31:0] Adr, WriteData
                  );
  logic [31:0] Instr;
  logic       Zero;
  logic [1:0] ImmSrc;
  logic [1:0] ALUSrcA, ALUSrcB;
  logic [1:0] ResultSrc;
  logic       AdrSrc;
  logic [2:0] ALUControl;
  logic       IRWrite, PCWrite;
  logic       RegWrite;

controller c0(clk,reset,Instr[6:0],Instr[14:12],Instr[30],
			Zero,ImmSrc,ALUSrcA,ALUSrcB,ResultSrc,AdrSrc,ALUControl,IRWrite,PCWrite,RegWrite,MemWrite);
datapath dp(clk,reset,
			ImmSrc,
			ALUControl,
			ResultSrc,IRWrite,
			RegWrite,ALUSrcA,ALUSrcB,AdrSrc,
			PCWrite,ReadData,Zero,Adr,WriteData,Instr
			);
endmodule
///////////////////////////////////////////////////////////////
// datapath
///////////////////////////////////////////////////////////////
module datapath (input logic clk, reset,
					  input logic [1:0] ImmSrc, 
					  input logic [2:0] ALUControl, 
					  input logic [1:0] ResultSrc, 
					  input logic IRWrite,
					  input logic RegWrite,
					  input logic [1:0] ALUSrcA, ALUSrcB, 
					  input logic AdrSrc, 
					  input logic PCWrite,  
					  input logic [31:0] ReadData,
					  output logic Zero, 
					  output logic [31:0] Adr, 
					  output logic [31:0] WriteData,
					  output logic [31:0] Instr);

logic [31:0] Result , ALUOut, ALUResult;
logic [31:0] RD1, RD2, A , SrcA, SrcB, Data;
logic [31:0] ImmExt;
logic [31:0] PC, OldPC;
//pc
flopenr #(32) pcFlop0(clk, reset, PCWrite, Result, PC);
//register file
registerfilecomponent rf(clk, Instr[19:15], Instr[24:20], Instr[11:7], Result, RegWrite, RD1, RD2); 
extend ext(Instr[31:7], ImmSrc, ImmExt);
flopr #(32) regF( clk, reset, RD1, A);
flopr #(32) regF_2( clk, reset, RD2, WriteData);

//alu unit
mux3 #(32) srcAmux(PC, OldPC, A, ALUSrcA, SrcA);
mux3 #(32) srcBmux(WriteData, ImmExt, 32'd4, ALUSrcB, SrcB);

alu alu(SrcA, SrcB, ALUControl, ALUResult, Zero);

flopr #(32) aluReg (clk, reset, ALUResult, ALUOut);
mux3 #(32) resultMux(ALUOut, Data, ALUResult, ResultSrc, Result );

//memory
mux2 #(32) adrMux(PC, Result, AdrSrc, Adr);
flopenr #(32) memFlop1(clk, reset, IRWrite, PC, OldPC); 
flopenr #(32) memFlop2(clk, reset, IRWrite, ReadData, Instr);
flopr #(32) memDataFlop(clk, reset, ReadData, Data);
endmodule
///////////////////////////////////////////////////////////////
// flop flop
///////////////////////////////////////////////////////////////
module flopr  #(parameter WIDTH = 8) 
	       (input logic clk, reset, input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);
	always_ff @(posedge clk, posedge reset)
		if (reset) q <= 0;
		else q <= d;
endmodule
///////////////////////////////////////////////////////////////
// flop flop with enable signal
///////////////////////////////////////////////////////////////
module flopenr #(parameter WIDTH = 8)
		(input logic clk, reset, en, input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);
	
	always_ff @(posedge clk, posedge reset)
		if (reset) q <= 0;
		else if (en) q <= d;

endmodule
///////////////////////////////////////////////////////////////
// Extend
///////////////////////////////////////////////////////////////
module extend (input logic [31:7] Instr, input logic [1:0] ImmSrc, output logic [31:0] ImmExt);

	always_comb
		case(ImmSrc) //controller produces immsrc signal
			//I
			2'b00: ImmExt = {{20{Instr[31]}}, Instr[31:20]};
			//S
			2'b01: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
			//B
			2'b10: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};
			//J
			2'b11: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0};
			default: ImmExt = 32'bx;
		endcase
endmodule 
///////////////////////////////////////////////////////////////
// Mux
///////////////////////////////////////////////////////////////
module mux2 #(parameter WIDTH = 8)
	     (input logic [WIDTH-1:0] d0, d1, input logic s, output logic [WIDTH-1:0] y);
	assign y = s ? d1 : d0; 
endmodule
module mux3 #(parameter WIDTH = 8) 
             (input logic [WIDTH-1:0] d0, d1, d2,
				  input logic [1:0] s,
				  output logic [WIDTH-1:0] y); 
 assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule
///////////////////////////////////////////////////////////////
// ALU Control decoder
///////////////////////////////////////////////////////////////
module alu(input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

  logic [31:0] condinvb, sum;
  logic        v;              // overflow
  logic        isAddSub;       // true when is add or subtract operation

  assign condinvb = alucontrol[0] ? ~b : b;
  assign sum = a + condinvb + alucontrol[0];
  assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
                    ~alucontrol[1] & alucontrol[0];
  always_comb
    case (alucontrol)
      3'b000:  result = sum;         // add
      3'b001:  result = sum;         // subtract
      3'b010:  result = a & b;       // and
      3'b011:  result = a | b;       // or
      3'b100:  result = a ^ b;       // xor
      3'b101:  result = sum[31] ^ v; // slt
      3'b110:  result = a << b[4:0]; // sll
      3'b111:  result = a >> b[4:0]; // srl
      default: result = 32'bx;
    endcase
  assign zero = (result == 32'b0);
  assign v = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
endmodule