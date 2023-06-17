`include "define.v"
//hi,lo 特殊寄存器
module hilo_reg (
    input wire clk,
    input wire rst_n,

    input wire en_hilo,
    input wire [`DataWidth-1:0] hi_i,
    input wire [`DataWidth-1:0] lo_i,

    output reg [`DataWidth-1:0] hi_o,
    output reg [`DataWidth-1:0] lo_o
);
    always @(posedge clk) begin
        if(!rst_n) begin
            hi_o <= 0;
            lo_o <= 0;
        end
        else if(en_hilo) begin //人工创造了一个latch
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end
endmodule