//32个GPR，可以同时进行两个寄存器的读和一个寄存器的写
//索引地址一共5位
`include "define.v"
module Regfile (
    input wire clk,
    input wire rst_n,
    input wire [`Reg_Addr-1:0] wr_addr,
    input wire [`Reg_Addr-1:0] rd1_addr,
    input wire [`Reg_Addr-1:0] rd2_addr,
    input wire [`DataWidth-1:0] wr_data,

    input wire en_rd1,
    input wire en_rd2,
    input wire en_wr,

    output reg [`DataWidth-1:0] rd1_data,
    output reg [`DataWidth-1:0] rd2_data
);
    //定义32个32位的寄存器
    reg [`Reg_BUS] regs [0:`DataWidth-1];

    wire [31:0]Regtest1;
    wire [31:0]Regtest2;
    wire [31:0]Regtest3;
    wire [31:0]Regtest4;

    assign Regtest1 = regs[1];
    assign Regtest2 = regs[2];
    assign Regtest3 = regs[3];
    assign Regtest4 = regs[4];
    //写功能采用时序逻辑
    always @(posedge clk) begin
        if(rst_n == 1) begin   //无复位
            if((en_wr)&&(wr_addr!=`Reg_Addr'h0))
                regs [wr_addr] <= wr_data;
        end
    end
    //rd1端口
    always @(*) begin
        if (!rst_n)
            rd1_data = 0;
        else if(rd1_addr == `Reg_Addr'h0)
            rd1_data = 0;
        else if((wr_addr == rd1_addr) && (en_rd1) && (en_wr))
            rd1_data = wr_data;
        else if(en_rd1)
            rd1_data = regs [rd1_addr];
        else
            rd1_data = 0;
    end

        //rd2端口
    always @(*) begin
        if (!rst_n)
            rd2_data = 0;
        else if(rd2_addr == `Reg_Addr'h0)
            rd2_data = 0;
        else if((wr_addr == rd2_addr) && (en_rd2) && (en_wr))
            rd2_data = wr_data;
        else if(en_rd2)
            rd2_data = regs[rd2_addr];
        else
            rd2_data = 0;
    end
endmodule