`include "define.v"
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
    parameter IDLE = 2'b00; //空闲
    parameter DIVING = 2'b01;//正在进行
    parameter FINISH = 2'b10;//运行结束
    parameter EXCEPT = 2'b11;//除数为0.异常结束

    wire [32:0] minuend_n;//n为除数，minuend被减数 这里是相减结果小于0情况下更新被减数
    reg [31:0] divisor;//除数
    reg [64:0] dividend;//？


    reg [5:0] div_cnt;//除数32个周期计数
    reg [1:0] current_state;//当前状态
    reg [31:0] opdata1_temp;
    reg [31:0] opdata2_temp;

    assign minuend_n = {1'b0,dividend[63:32]}-{1'b0,divisor};

	always @ (posedge clk) begin
		if (!rst_n) begin
			current_state <= IDLE;
			complete_flag <= 0;
			div_result <= 0;
		end
        else begin
		case (current_state)
            IDLE:begin
                if((start_flag == 1) && (cancel_flag == 1'b0)) begin
                    if(opdata2 == 0) begin
                        current_state <= EXCEPT;
                    end
                    else begin
                        current_state <= DIVING;
                        div_cnt <= 6'b000000;
                        if((signed_flag == 1'b1) && (opdata1[31] == 1'b1) ) begin//被除数为负数，使用补码计算
                            opdata1_temp = ~opdata1 + 1;
                        end
                        else begin
                            opdata1_temp = opdata1;
                        end
                        if((signed_flag == 1'b1) && (opdata2[31] == 1'b1) ) begin//除数为负数，使用补码计算
                            opdata2_temp = ~opdata2 + 1;
                        end
                        else begin
                            opdata2_temp = opdata2;
                        end
                        dividend <= 0;
                        dividend[32:1] <= opdata1_temp;//第0位留作商的位置,后面32位是被除数
                        divisor <= opdata2_temp;
                        end
                end
                else begin
					complete_flag <= 0;
					div_result <= 0;
                end          	
            end


            EXCEPT:	begin 
                dividend <= 0;
                current_state <= FINISH;		 		
            end
            
            DIVING:	begin 
                if(cancel_flag == 1'b0) begin
                    if(div_cnt != 6'b100000) begin
                        if(minuend_n[32] == 1'b1) begin//此处为什么32位为一就表示是结果小于0
                            dividend <= {dividend[63:0] , 1'b0};//留了一位商，其他的分别是余数和还没计算的被除数
                        end
                        else begin
                            dividend <= {minuend_n[31:0] , dividend[31:0] , 1'b1};//因为一开始加了一个0 最高位本位和为1则为负
                        end
                        div_cnt <= div_cnt + 1;
                        end
                        else begin
                            if((signed_flag == 1'b1) && ((opdata1[31] ^ opdata2[31]) == 1'b1)) begin//有符号运算 且被除数和除数异号
                                dividend[31:0] <= (~dividend[31:0] + 1);//没有给32位赋值
                            end
                            if((signed_flag == 1'b1) && ((opdata1[31] ^ dividend[64]) == 1'b1)) begin//被除数和商？这里是余数的符号
                                dividend[64:33] <= (~dividend[64:33] + 1);//没有给32位赋值
                            end
                            current_state <= FINISH;
                            div_cnt <= 6'b000000;            	
                            end
                end 
                else begin
                    current_state <= IDLE;
                end	
            end

            FINISH:	begin
                div_result <= {dividend[64:33], dividend[31:0]};  //这里的32位是什么？
                complete_flag <= 1;
                if(start_flag == 0) begin
                    current_state <= IDLE;
					complete_flag <= 0;
					div_result <= 0;       	
                end		  	
            end
		endcase
		end
	end
endmodule