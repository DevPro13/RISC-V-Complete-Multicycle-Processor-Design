module fsm(
    input logic clk,reset,
    input logic [6:0]op,
    output logic PCUpdate,Branch,RegWrite,MemWrite,IRWrite,AdrSrc,
    output logic [1:0] ResultSrc,
    output logic [1:0]ALUSrcA,
    output logic [1:0]ALUSrcB,
    output logic [1:0] ALUOp
);			
    typedef enum logic[3:0]{
    s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10
    }fsmState;
    typedef enum logic[6:0] {r_type_op=7'b0110011,
                            i_type_alu_op=7'b0010011,
                            lw_op=7'b0000011,
                            sw_op=7'b0100011,
                            beq_op=7'b1100011,
                            jal_op=7'b1101111
                        } opcodetype;
    fsmState state,stateNext;
    //flipflop/ state register
    always_ff @(posedge clk or posedge reset ) begin
       if(reset)begin
        state<=s0;
       end
       else begin
        state<=stateNext;
       end
    end
    //state change logic
    always_comb begin
        case(state)
            s0: begin
                stateNext=s1;
                //output
                PCUpdate=1'b1;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b1;
                AdrSrc=1'b0;
                ResultSrc=2'b10;
                ALUSrcA=2'b00;
                ALUSrcB=2'b10;
                ALUOp=2'b00;
            end
            s1:begin
                if(op==r_type_op)begin
                    stateNext=s6;
                end
                else if(op==i_type_alu_op)begin
                    stateNext=s8;
                end
                else if(op==lw_op)begin
                    stateNext=s2;
                end
                else if(op==sw_op)begin
                    stateNext=s2;
                end
                else if(op==beq_op)begin
                    stateNext=s10;
                end
                else begin
                    //op==jal_op
                    stateNext=s9;
                end
                //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b00;
                ALUSrcA=2'b01;
                ALUSrcB=2'b01;
                ALUOp=2'b00;
            end
            s2:begin
                if(op==lw_op)begin
                    stateNext=s3;
                end
                else begin
                    //op==sw_op
                    stateNext=s5;
                end
                //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b00;
                ALUSrcA=2'b10;
                ALUSrcB=2'b01;
                ALUOp=2'b00;
            end
            s3:begin
                stateNext=s4;
                //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b1;
                ResultSrc=2'b00;
                ALUSrcA=2'b00;
                ALUSrcB=2'b00;
                ALUOp=2'b00;
            end
            s4:begin
                stateNext=s0;
                //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b1;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b01;
                ALUSrcA=2'b00;
                ALUSrcB=2'b00;
                ALUOp=2'b00;
            end
            s5:begin
                stateNext=s0;
                //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b1;
                IRWrite=1'b0;
                AdrSrc=1'b1;
                ResultSrc=2'b00;
                ALUSrcA=2'b00;
                ALUSrcB=2'b00;
                ALUOp=2'b00;
            end
            s6:begin
                stateNext=s7;
                 //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b00;
                ALUSrcA=2'b10;
                ALUSrcB=2'b00;
                ALUOp=2'b10;
            end
            s7:begin
                stateNext=s0;
                 //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b1;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b00;
                ALUSrcA=2'b00;
                ALUSrcB=2'b00;
                ALUOp=2'b00;
            end
            s8:begin
                stateNext=s7;
                //output
                PCUpdate=1'b0;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b00;
                ALUSrcA=2'b10;
                ALUSrcB=2'b01;
                ALUOp=2'b10;
            end
            s9:begin
                stateNext=s7;
                //output
                PCUpdate=1'b1;
                Branch=1'b0;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b00;
                ALUSrcA=2'b01;
                ALUSrcB=2'b10;
                ALUOp=2'b00;
            end
            s10:begin
                stateNext=s0;
                //output
                PCUpdate=1'b0;
                Branch=1'b1;
                RegWrite=1'b0;
                MemWrite=1'b0;
                IRWrite=1'b0;
                AdrSrc=1'b0;
                ResultSrc=2'b00;
                ALUSrcA=2'b10;
                ALUSrcB=2'b00;
                ALUOp=2'b01;
            end
    endcase
    end
endmodule
