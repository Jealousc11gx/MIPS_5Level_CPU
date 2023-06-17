//ori指令不需要访存,因此直接传到回写

`include "define.v"
module mem (
    input wire rst_n,
    input wire en_wd,
    input wire [`Reg_AddrBus] desReg_addr,
    input wire [`DataWidth-1:0]result,

    input wire [`DataWidth-1:0] hi_i,
    input wire [`DataWidth-1:0] lo_i,
    input wire en_hilo_i,

    output reg en_wd_mem,
    output reg [`Reg_AddrBus] desReg_addr_mem,
    output reg [`DataWidth-1:0] result_mem,

    output reg [`DataWidth-1:0] hi_o,
    output reg [`DataWidth-1:0] lo_o,
    output reg en_hilo_o
);
    always @(*) begin
        if(!rst_n) begin
            en_wd_mem = 0;
            desReg_addr_mem = 0;
            result_mem = 0;
            hi_o = 0;
            lo_o = 0;
            en_hilo_o = 0;
        end
        else begin
            en_wd_mem = en_wd;
            desReg_addr_mem = desReg_addr;
            result_mem = result;
            hi_o = hi_i;
            lo_o = lo_i;
            en_hilo_o = en_hilo_i;
        end
    end
endmodule