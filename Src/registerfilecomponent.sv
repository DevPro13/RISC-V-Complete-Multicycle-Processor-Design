module registerfilecomponent (
        input logic clk,
        input logic[4:0]rr1,rr2,wr,
        input logic[31:0]wd,
        input logic we,
        output logic[31:0] rd1,rd2
);
    reg[31:0] registers[31:0];//Register files of each 32 bit 
    initial begin
        //assign content of reg_0 to 0
        registers[0]=0;
    end
    //read data from register files
    assign rd1=registers[rr1];
    assign rd2=registers[rr2];
    //write to the register files
    always @(posedge clk) begin
        //donot write to reg_0 aswell
        if(we && wr!=0)begin
            registers[wr]<=wd;//write data
        end
    end
endmodule