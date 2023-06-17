//从内存中取得的指令的地址
//传递pc 中的指针递增
`include "define.v"
module pc_de (
    input wire [`DataWidth-1:0] pc,
    input wire [`DataWidth-1:0] rom_ins,
    input wire clk,
    input wire rst_n,
    input wire [5:0] stop,

    output reg [`DataWidth-1:0] pc_if,
    output reg [`DataWidth-1:0] rom_ins_if
);
    always @(posedge clk) begin
        if(!rst_n)
            pc_if <= 0;
        else if((stop[1]==`Stop)&&(stop[2]==`NoStop))
            pc_if <= 0;
        else if(stop[1]==`NoStop)
            pc_if <= pc;
    end
    
    always @(posedge clk) begin
        if(!rst_n)
            rom_ins_if <= 0;
        else if((stop[1]==`Stop)&&(stop[2]==`NoStop))
            rom_ins_if <= 0;
        else if(stop[1]==`NoStop)
            rom_ins_if <= rom_ins;
    end
endmodule