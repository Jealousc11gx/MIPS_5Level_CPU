//de到ex中间的分隔
`include "define.v"

module de_ex (
    input wire clk,
    input wire rst_n,
    input wire [7:0]op,
    input wire [2:0]sel,
    input wire [`DataWidth-1:0] num1,
    input wire [`DataWidth-1:0] num2,
    input wire [`Reg_AddrBus]desReg_addr,
    input wire en_wd,
    //from ctrl
    input wire [`StopWidth] stop,

    //output

    output reg [7:0]op_ex,
    output reg [2:0]sel_ex,
    output reg [`DataWidth-1:0] num1_ex,
    output reg [`DataWidth-1:0] num2_ex,
    output reg [`Reg_AddrBus] desReg_addr_ex,
    output reg en_wd_ex
);
    always @(posedge clk ) begin
        if(!rst_n) begin
                op_ex <= 0;
                sel_ex <= 0;
                num1_ex <= 0;
                num2_ex <= 0;
                desReg_addr_ex <= 0;
                en_wd_ex <= 0;
        end
        else if((stop[2] ==`Stop)&&(stop[3] ==`NoStop)) begin
                op_ex <= `EXE_NOP_OP;
                sel_ex <= `EXE_RES_NOP;
                num1_ex <= 0;
                num2_ex <= 0;
                desReg_addr_ex <= 0;
                en_wd_ex <= 0;
        end
        else if((stop[2] ==`NoStop)) begin
                op_ex <= op;
                sel_ex <= sel;
                num1_ex <= num1;
                num2_ex <= num2;
                desReg_addr_ex <= desReg_addr;
                en_wd_ex <= en_wd;
        end        
    end
endmodule