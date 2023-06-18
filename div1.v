/*`include "define.v"
parameter IDLE = 2'b00; //空闲
parameter DIVING = 2'b01;//正在进行
parameter FINISH = 2'b10;//运行结束
parameter EXCEPT = 2'b11;//除数为0.异常结束

module div1 (
    input wire clk,
    input wire rst_n,
    input wire signed_flag,//是否为有符号除法
    input wire [`DivBus] opdata1,//被除数
    input wire [`DivBus] opdata2,//除数
    input wire start_flag,//开始标志
    input wire cancel_flag,//是否取消运算


    output reg complete_flag,//运算完成标志
    output reg [`DivResultBus] div_result//结果
);
    wire [32:0] minuend_n;//n为除数，minuend被减数 这里是相减结果小于0情况下更新被减数
    reg [31:0] divisor;//除数
    reg [64:0] dividend;//？


    reg [5:0] div_cnt;//除数32个周期计数
    reg [1:0] current_state;//当前状态
    reg [1:0] next_state;
    reg [31:0] opdata1_temp;
    reg [31:0] opdata2_temp;

    assign minuend_n = {1'b0,dividend[63:32]}-{1'b0,divisor};

    //*******************三段式状态机**********************

    //*******************第一段***************************
    always @(posedge clk or negedge rst_n) begin//描述状态转移
        if(!rst_n) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end
    //*******************第二段***************************
    always @(*) begin//次态
        case (current_state)
            IDLE:begin
                if ((start_flag ==1)&&(cancel_flag == 0)&&(opdata2 !=0)) begin
                    next_state = DIVING;
                end
                else if((start_flag ==1)&&(cancel_flag == 0)&&(opdata2 ==0)) begin
                    next_state = EXCEPT;
                end
                else begin //其余时候状态都不变
                    next_state = IDLE;
                end
            end
            DIVING:begin
                if((cancel_flag == 1))begin
                    next_state = IDLE;
                end
                else if((cancel_flag ==0)&&(div_cnt == 6'b100000))begin
                    next_state = FINISH;
                end
                else begin
                    next_state = DIVING;
                end
            end
            FINISH:begin
                if(start_flag == 0)begin
                    next_state = IDLE;
                end
                else begin
                    next_state = FINISH;
                end
            end
            EXCEPT:begin
                next_state = FINISH;
            end
            default:begin
                next_state = IDLE;
            end 
        endcase
    end
    //*******************第三段***************************    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
                minuend_n <= 0;
                divisor <= 0;
                dividend <= 0;
                div_cnt <= 0;
                opdata1_temp <= 0;
                opdata2_temp <= 0;
                complete_flag <= 0;
                div_result <= 0;
        end
        else begin
            case (current_state)
                IDLE:begin
                    complete_flag <= 0;
                    div_result <= 0;
                end
                DIVING:begin
                    div_cnt <= 0;
                    if((signed_flag == 1)&&(opdata1[31] == 1))begin
                        opdata1_temp <= ~opdata1+1;
                    end
                    else begin
                        opdata1_temp <= opdata1;
                    end
                    if((signed_flag == 1)&&(opdata2[31] == 1))begin
                        opdata2_temp <= ~opdata2+1;
                    end
                    else begin
                        opdata2_temp <= opdata2;
                    end
                    if(minuend_n[32] == 1)begin
                        dividend <= {dividend[63:0],1'b0};
                    end
                    else()
                end
                default: 
            endcase
        end
    end

endmodule
*/



//此模块作废，三段式描述这个状态机感觉有非常大的问题 