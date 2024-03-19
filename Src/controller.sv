
module controller(input  logic       clk,
                  input  logic       reset,  
                  input  logic[6:0]   op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite  
        );
        logic Branch,PCUpdate;
        logic [1:0] ALUOp;
        fsm MAINFSM(clk,reset,op,PCUpdate,Branch,RegWrite,MemWrite,IRWrite,AdrSrc,ResultSrc,ALUSrcA,ALUSrcB,ALUOp);
        assign PCWrite=PCUpdate | (Branch & Zero);
        aludec ALUDEC(op[5],funct3,funct7b5,ALUOp,ALUControl);
        instrdec INSDEC(op,ImmSrc);
endmodule