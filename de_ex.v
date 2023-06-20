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

    input wire next_ins_in_delayslot_i,
    input wire this_ins_in_delayslot_i,
    input wire [`DataWidth-1:0]link_address_i,

    //from ctrl
    input wire [`StopWidth] stop,

    //output

    output reg [7:0]op_ex,
    output reg [2:0]sel_ex,
    output reg [`DataWidth-1:0] num1_ex,
    output reg [`DataWidth-1:0] num2_ex,
    output reg [`Reg_AddrBus] desReg_addr_ex,
    output reg en_wd_ex,

    output reg next_ins_in_delayslot_o,
    output reg this_ins_in_delayslot_o,
    output reg [`DataWidth-1:0] link_address_o
);
    always @(posedge clk ) begin
        if(!rst_n) begin
                op_ex <= 0;
                sel_ex <= 0;
                num1_ex <= 0;
                num2_ex <= 0;
                desReg_addr_ex <= 0;
                en_wd_ex <= 0;
                next_ins_in_delayslot_o <= 0;
                this_ins_in_delayslot_o <= 0;
                link_address_o <= 0;
        end
        else if((stop[2] ==`Stop)&&(stop[3] ==`NoStop)) begin//流水线停止
                op_ex <= `EXE_NOP_OP;
                sel_ex <= `EXE_RES_NOP;
                num1_ex <= 0;
                num2_ex <= 0;
                desReg_addr_ex <= 0;
                en_wd_ex <= 0;
                next_ins_in_delayslot_o <= 0;
                this_ins_in_delayslot_o <= 0;
                link_address_o <= 0;                
        end
        else if((stop[2] ==`NoStop)) begin
                op_ex <= op;
                sel_ex <= sel;
                num1_ex <= num1;
                num2_ex <= num2;
                desReg_addr_ex <= desReg_addr;
                en_wd_ex <= en_wd;
                next_ins_in_delayslot_o <= next_ins_in_delayslot_i;
                this_ins_in_delayslot_o <= this_ins_in_delayslot_i;
                link_address_o <= link_address_i;
        end        
    end
endmodule