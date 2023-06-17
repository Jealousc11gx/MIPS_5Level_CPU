`include "define.v"
//执行阶段到访存阶段的中间
module ex_mem (
    input wire clk,
    input wire rst_n,
    input wire en_wd,
    input wire [`Reg_AddrBus] desReg_addr,
    input wire [`DataWidth-1:0] result,

    input wire [`DataWidth-1:0] ex_hi_i,
    input wire [`DataWidth-1:0] ex_lo_i,
    input wire ex_en_hilo_i,

    input wire [`DoubleDataWidth-1:0] hilo_tmp_i,//多周期指令的临时结果存放
    input wire [1:0] count_i,//识别第几个执行的指令周期

    //from ctrl
    input wire [5:0] stop,

    output reg en_wd_ex_mem,
    output reg [`Reg_AddrBus] desReg_addr_ex_mem,
    output reg [`DataWidth-1:0] result_ex_mem,

    output reg [`DataWidth-1:0] mem_hi_o,
    output reg [`DataWidth-1:0] mem_lo_o,
    output reg mem_en_hilo_o,

    output reg [`DoubleDataWidth-1:0] hilo_tmp_o,
    output reg [1:0] count_o
);
    always @(posedge clk) begin
        if(!rst_n) begin
            en_wd_ex_mem <= 0;
            desReg_addr_ex_mem <= 0;
            result_ex_mem <= 0;
            mem_hi_o <= 0;
            mem_lo_o <= 0;
            mem_en_hilo_o <= 0;
            hilo_tmp_o <= 0;
            count_o <= 0;
        end
        else if((stop[3] ==`Stop)&&(stop[4]==`NoStop)) begin//流水线暂停
            en_wd_ex_mem <= 0;
            desReg_addr_ex_mem <= 0;
            result_ex_mem <= 0;
            mem_hi_o <= 0;
            mem_lo_o <= 0;
            mem_en_hilo_o <= 0;
            hilo_tmp_o <= hilo_tmp_i;
            count_o <= count_i;
        end        
        else if(stop[3]==`NoStop) begin
            en_wd_ex_mem <= en_wd;
            desReg_addr_ex_mem <= desReg_addr;
            result_ex_mem <= result;
            mem_hi_o <= ex_hi_i;
            mem_lo_o <= ex_lo_i;
            mem_en_hilo_o <= ex_en_hilo_i;
            hilo_tmp_o <= 0;
            count_o <= 0;
        end
    end
endmodule