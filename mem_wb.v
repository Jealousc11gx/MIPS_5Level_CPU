`include "define.v"
//访存和写回之间的流水
module mem_wb (
    input wire clk,
    input wire rst_n,
    input wire [`DataWidth-1:0] result,
    input wire en_wb,
    input wire [`Reg_AddrBus] desReg_addr,

    input wire [`DataWidth-1:0] mem_hi_i,
    input wire [`DataWidth-1:0] mem_lo_i,
    input wire mem_en_hilo_i,

    input wire mem_LLbit_en,
    input wire mem_LLbit_data,

    //from ctrl
    input wire [5:0]stop,

    output reg wb_LLbit_data,
    output reg wb_LLbit_en,

    output reg [`DataWidth-1:0] wb_hi_o,
    output reg [`DataWidth-1:0] wb_lo_o,
    output reg wb_en_hilo_o,

    output reg [`DataWidth-1:0] result_wb,
    output reg en_wb_wb,
    output reg [`Reg_AddrBus] desReg_addr_wb
);
    always @(posedge clk) begin
        if(!rst_n) begin
            result_wb <= 0;
            en_wb_wb <= 0;
            desReg_addr_wb <= 0;
            wb_hi_o <= 0;
            wb_lo_o <= 0;
            wb_en_hilo_o <= 0;
            wb_LLbit_data <= 0;
            wb_LLbit_en <= 0;            
        end
        else if((stop[4]==`Stop)&&(stop[5]==`NoStop)) begin
            result_wb <= 0;
            en_wb_wb <= 0;
            desReg_addr_wb <= 0;
            wb_hi_o <= 0;
            wb_lo_o <= 0;
            wb_en_hilo_o <= 0;
            wb_LLbit_data <= 0;
            wb_LLbit_en <= 0;                         
        end        
        else if(stop[4]==`NoStop) begin
            result_wb <= result;
            en_wb_wb <= en_wb;
            desReg_addr_wb <= desReg_addr;
            wb_hi_o <= mem_hi_i;
            wb_lo_o <= mem_lo_i;
            wb_en_hilo_o <= mem_en_hilo_i;
            wb_LLbit_data <= mem_LLbit_data;
            wb_LLbit_en <= mem_LLbit_en;                         
        end
    end
endmodule