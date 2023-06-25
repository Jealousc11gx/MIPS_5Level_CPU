`include "define.v"
module LLbit (
    input wire clk,
    input wire rst_n,
    input wire Excep_Signal,
    input wire LLbit_en,
    input wire LLbit_data_i,

    output reg LLbit_data_o
);
    always @(posedge clk) begin
        if(!rst_n) begin
            LLbit_data_o <= 0;
        end
        else if(Excep_Signal)begin//发生异常
            LLbit_data_o <= 0;
        end
        else if(LLbit_en)begin
            LLbit_data_o <= LLbit_data_i;
        end
    end
endmodule