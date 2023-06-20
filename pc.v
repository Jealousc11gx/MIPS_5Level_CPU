//32位CPU的Program Counter
//用于向内存中读取指令以及给出使能信号 2023/5/31
`include "define.v"
module pc (
    input wire clk,
    input wire rst_n,
    input wire [5:0] stop,//ctrl模块的流水线暂停

    input wire branch_flag,//是否分支
    input wire [`DataWidth-1:0] branch_target_address,
    
    output reg en,
    output reg [`DataWidth-1:0] pc
);
    always @(posedge clk) begin
        if(!rst_n)
            en <= 0;
        else
            en <= 1;
    end

    always @(posedge clk) begin
        if(en == 0)
            pc <= 0;
        else if(stop[0] == `NoStop)
            if(branch_flag) begin
                pc <= branch_target_address;
            end
            else begin
            pc <= pc + 4'h4;//其余情况形成latch  保持pc指针不变
            end
    end
endmodule
