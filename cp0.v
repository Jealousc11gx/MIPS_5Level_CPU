`include "define.v"
//用于系统控制 异常控制 存储管理单元控制等
module CP0 (
    input wire clk,
    input wire rst_n,
    input wire [`DataWidth-1:0] w_data,
    input wire [4:0] w_addr,
    input wire wr_en,
    input wire [4:0] r_addr,
    input wire [5:0] interrupt,//6个外部硬件中断

    output reg [`DataWidth-1:0] data_o,//输出数据
    output reg [`DataWidth-1:0] count_o,//自增count寄存器
    output reg [`DataWidth-1:0] compare_o,//定时中断
    output reg [`DataWidth-1:0] status_o,//控制操作模式 CU3-CU0 IM7-IM0 EXL IE
    output reg [`DataWidth-1:0] cause_o,//异常发生原因 BD IP[7:2] 硬件中断 IP[1:0] 软件中断 Exccode 异常中断原因
    output reg [`DataWidth-1:0] epc_o,//异常程序计数器
    output reg [`DataWidth-1:0] config_o,//配置功能 BE AT
    output reg [`DataWidth-1:0] prid_o,//处理器信息
    output reg timer_interrupt
);
    //写寄存器以及初始化
    always @(posedge clk ) begin
        if(!rst_n)begin
            data_o <= 32'b0;
            count_o <= 32'b0;
            compare_o <= 32'b0;
            status_o <= {4'b0001,28'b0};
            cause_o <= 32'b0;
            epc_o <= 32'b0;
            config_o <= {16'b0,1'b1,15'b0};
            prid_o <= {8'b0,8'b1,8'b1,8'b1};
            timer_interrupt <= `InterruptNotAssert;
        end
        else begin
            cause_o[15:0] <= interrupt;
            count_o <= count_o + 1'b1;
            if( (compare_o!=0) && (compare_o==count_o))begin//一直在中断状态，除非写入compare
                timer_interrupt <= `InterruptAssert;//发生中断
            end
            if(wr_en)begin
                case(w_addr)
                `CP0_REG_COUNT:begin
                    count_o <= w_data;
                end
                `CP0_REG_COMPARE:begin
                    compare_o <= w_data;
                    timer_interrupt <= `InterruptNotAssert;//写入compare就是没有中断
                end
                `CP0_REG_STATUS:begin
                    status_o <= w_data;
                end
                `CP0_REG_EPC:begin
                    epc_o <= w_data;
                end
                `CP0_REG_CAUSE:begin
                    cause_o[9:8] <= w_data[9:8];
                    cause_o[23] <= w_data[23];
                    cause_o[22] <= w_data[22];
                end
                default:begin
                end
                endcase
            end
        end
    end

    //读操作
    always @(*) begin
        if(!rst_n)begin
            data_o <= 0;
        end
        else begin
            case(r_addr)
                `CP0_REG_COUNT:begin
                    data_o <= count_o;
                end
                `CP0_REG_COMPARE:begin
                    data_o <= compare_o;
                end
                `CP0_REG_STATUS:begin
                    data_o <= status_o;
                end
                `CP0_REG_EPC:begin
                    data_o <= epc_o;
                end
                `CP0_REG_CAUSE:begin
                    data_o <= cause_o;
                end
                `CP0_REG_PrId:begin
                    data_o <= prid_o;
                end
                `CP0_REG_CONFIG:begin
                    data_o <= config_o;
                end                       
            default:begin
            end
            endcase
        end
    end
endmodule


