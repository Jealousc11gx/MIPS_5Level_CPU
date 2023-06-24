//执行阶段
`include "define.v"
module ex (
    input wire rst_n,
    input wire [7:0]op,
    input wire [2:0]sel,
    input wire [`DataWidth-1:0] num1,
    input wire [`DataWidth-1:0] num2,
    input wire [`Reg_AddrBus] desReg_addr,
    input wire en_wd,
    input wire [`DataWidth-1:0] rom_ins_ex,

    input wire [`DataWidth-1:0] link_address,
    input wire this_ins_in_delayslot,

    //来自lo和hi的输入
    input wire [`DataWidth-1:0] hi_i,
    input wire [`DataWidth-1:0] lo_i,

    //来自访存和回写阶段的数据前推
    //是否要写特殊寄存器？输入hi，输入lo
    input wire [`DataWidth-1:0] mem_hi_i,
    input wire [`DataWidth-1:0] mem_lo_i,
    input wire mem_en_hilo,

    input wire [`DataWidth-1:0] wb_hi_i,
    input wire [`DataWidth-1:0] wb_lo_i,
    input wire wb_en_hilo,

    //多周期指令的输入
    input wire [`DoubleDataWidth-1:0] hilo_tmp_i,
    input wire [1:0] count_i,

    //来自div模块的输入
    input wire [`DivResultBus] div_result,//除法结果
    input wire complete_flag,//是否完成

    //输出 是否要写回？ 写回的地址？ 运算的结果？
    //输出向de阶段的数据回推
    output reg en_wd_ex,
    output reg [`Reg_AddrBus] desReg_addr_ex,//同时还有处理load相关的作用
    output reg [`DataWidth-1:0] result,

    //输出向下一阶段传递的是否写特殊寄存器，以及写lo和hi的数据
    output reg en_hilo,
    output reg [`DataWidth-1:0] hi_o,
    output reg [`DataWidth-1:0] lo_o,

    //多周期指令的输出
    output reg [`DoubleDataWidth-1:0] hilo_tmp_o,
    output reg [1:0] count_o,

    //向div模块输出
    output reg signed_flag,
    output reg [`DivBus] div_opdata1,
    output reg [`DivBus] div_opdata2,
    output reg start_flag,
    //暂停机制输出
    output reg StopReq_from_ex,
    //输出访存指令需要的信号:op,num2,ram_addr
    output wire [7:0] op_o,//输出的op码 同时还有处理load相关的作用
    output wire [`DataWidth-1:0] num2_o,//对于store，是需要存储的数据，对于load，是对于lwl和lwr的初始值
    output wire [`DataWidth-1:0] ram_addr//存储器地址,由计算得出
);
    reg [`DataWidth-1:0] LogicOut;//存储逻辑输出
    reg [`DataWidth-1:0] ShiftRes;//存储移位输出
    reg [`DataWidth-1:0] MoveRes;//存储移动的输出
    reg [`DataWidth-1:0] ArithRes;//存储算数的输出

    wire overflow;//是否溢出
    wire num1_lt_num2;//1小于2？
    wire num1_eq_num2;//1等于2？
    
    //简单算术指令的中间信号
    wire [`DataWidth-1:0] num1_i_not;//1的反码
    wire [`DataWidth-1:0] num2_i_mux;//2的补码
    wire [`DataWidth-1:0] sum_result;//加法结果
    wire [`DataWidth-1:0] opdata1_mult;//被乘数
    wire [`DataWidth-1:0] opdata2_mult;//乘数

    wire [`DoubleDataWidth-1:0] mul_temp;//临时乘法结果 64位

    reg [`DoubleDataWidth-1:0] mul_2period_temp;//两周期指令临时结果
    reg StopReq_for_madd_msub;

    reg [`DoubleDataWidth-1:0] MulRes;//乘法结果 64位

    reg [`DataWidth-1:0] HI;//存储高位结果
    reg [`DataWidth-1:0] LO;//存储低位结果

    reg StopReq_for_div;

    //访存指令的输出
    assign op_o = op;
    assign num2_o = num2;
    assign ram_addr = {{16{rom_ins_ex[15]}},rom_ins_ex[15:0]} + num1;//store都是符号拓展
    //减法或比较运算 决定减数是补码还是原码***********************************
    assign num2_i_mux =((op ==`EXE_SUB_OP) || //减法
                        (op ==`EXE_SUBU_OP) || //无符号减法
                        (op ==`EXE_SLT_OP))? //比较
                        (~num2+1) : num2; //值存储的方式都是补码 负数的补码按位取反再+1等于其正数 因此将减法转换为加法参与运算

    //减法，加法，比较运算的运算结果都可以使用sum_result表示**************************
    assign sum_result = num1 + num2_i_mux;

    //计算是否溢出，针对的是add指令和addi以及sub指令*******************
    assign overflow = (((!num1[31] && !num2_i_mux[31]) && sum_result[31]) || //两负结果正
                        ((num1[31] && num2_i_mux[31]) && !sum_result[31]))? //两正结果负
                        1 : 0;

    //计算num1是否小于num2 num1_lt_num2*********************
    assign num1_lt_num2 = (op == `EXE_SLT_OP)?
                        ((num1[31] && !num2[31]) || //正大于负
                        (num1[31] && num2[31] && sum_result[31]) || //正正结果负
                        (!num1[31] && !num2[31] && sum_result[31])): //负负结果负
                        (num1 < num2);//无符号比较

    //num1_i_not***************************
    assign num1_i_not = ~num1;//逐位取反
    
    //简单运算结果*************************
    always @(*) begin
        if(!rst_n) begin
            ArithRes = 0;
        end
        else begin
            case(op)
                `EXE_ADD_OP,`EXE_ADDI_OP,`EXE_ADDU_OP,`EXE_ADDIU_OP:begin//加法指令
                    ArithRes = sum_result;
                end
                `EXE_SUB_OP,`EXE_SUBU_OP:begin//减法指令
                    ArithRes = sum_result;
                end
                `EXE_SLT_OP,`EXE_SLTU_OP:begin//比较指令
                    ArithRes = num1_lt_num2;
                end
                `EXE_CLZ_OP:begin//数零*********************************
                    ArithRes =  num1[31]?0:num1[30]?1:
                                num1[29]?2:num1[28]?3:
                                num1[27]?4:num1[26]?5:
                                num1[25]?6:num1[24]?7:
                                num1[23]?8:num1[22]?9:
                                num1[21]?10:num1[20]?11:
                                num1[19]?12:num1[18]?13:
                                num1[17]?14:num1[16]?15:
                                num1[15]?16:num1[14]?17:
                                num1[13]?18:num1[12]?19:
                                num1[11]?20:num1[10]?21:
                                num1[9]?22:num1[8]?23:
                                num1[7]?24:num1[6]?25:
                                num1[5]?26:num1[4]?27:
                                num1[3]?28:num1[2]?29:
                                num1[1]?30:num1[0]?31:32;
                end

                `EXE_CLO_OP:begin//数一******************************
                    ArithRes =  num1_i_not[31]?0:num1_i_not[30]?1:
                                num1_i_not[29]?2:num1_i_not[28]?3:
                                num1_i_not[27]?4:num1_i_not[26]?5:
                                num1_i_not[25]?6:num1_i_not[24]?7:
                                num1_i_not[23]?8:num1_i_not[22]?9:
                                num1_i_not[21]?10:num1_i_not[20]?11:
                                num1_i_not[19]?12:num1_i_not[18]?13:
                                num1_i_not[17]?14:num1_i_not[16]?15:
                                num1_i_not[15]?16:num1_i_not[14]?17:
                                num1_i_not[13]?18:num1_i_not[12]?19:
                                num1_i_not[11]?20:num1_i_not[10]?21:
                                num1_i_not[9]?22:num1_i_not[8]?23:
                                num1_i_not[7]?24:num1_i_not[6]?25:
                                num1_i_not[5]?26:num1_i_not[4]?27:
                                num1_i_not[3]?28:num1_i_not[2]?29:
                                num1_i_not[1]?30:num1_i_not[0]?31:32;
                end
                default: begin
                    ArithRes = 0;
                end
            endcase
        end
    end

//乘法运算*******************************
    assign opdata1_mult = (((op == `EXE_MUL_OP)||(op == `EXE_MULT_OP)||(op ==`EXE_MADD_OP)||(op ==`EXE_MSUB_OP))&& num1[31])?(~num1+1):num1; //乘法运算并且被乘数为负数

    assign opdata2_mult = (((op == `EXE_MUL_OP)||(op == `EXE_MULT_OP)||(op ==`EXE_MADD_OP)||(op ==`EXE_MSUB_OP))&& num2[31])?(~num2+1):num2; //乘数为负数

    assign  mul_temp = opdata1_mult * opdata2_mult;//暂时存储

    always @(*) begin
        if (!rst_n) begin
            MulRes = 0;
        end
        else if((op == `EXE_MUL_OP) || (op == `EXE_MULT_OP)||(op ==`EXE_MADD_OP)||(op ==`EXE_MSUB_OP)) begin //乘法运算
            if(num1[31]^num2[31]) begin //异号     *********出过BUGGGGGG*******
                MulRes = ~mul_temp+1;
            end
            else begin //同号
                MulRes = mul_temp;
            end
        end
        else begin//无符号运算
            MulRes = mul_temp;
        end
        end

    //更新最新的HI和LO值***************************
    always @(*) begin
        if(!rst_n) begin
            HI = 0;
            LO = 0;
        end
        else if(mem_en_hilo) begin
            HI = mem_hi_i;
            LO = mem_lo_i;
        end
        else if(wb_en_hilo) begin
            HI = wb_hi_i;
            LO = wb_lo_i;
        end
        else begin
            HI = hi_i;
            LO = lo_i;
        end
    end
    //实现乘累加 乘累减指令************************
    always @(*) begin
        if(!rst_n) begin
            hilo_tmp_o = 0;
            count_o = 0;
            mul_2period_temp = 0;
            StopReq_for_madd_msub = `NoStop;
        end
        else begin
            case(op) 
                `EXE_MADD_OP,`EXE_MADDU_OP:begin//累乘加
                    if (count_i == 2'b00) begin //在第一个计算的时钟周期
                        hilo_tmp_o = MulRes; //加法
                        count_o = 2'b01;//表示第二个周期
                        mul_2period_temp = 0;
                        StopReq_for_madd_msub = `Stop;
                    end
                    else if(count_i == 2'b01) begin //第二个时钟周期
                        hilo_tmp_o = 0; //不需要中间变量了
                        count_o = 2'b10;//防止因为其他情况流水线暂停的时候继续执行指令
                        mul_2period_temp = hilo_tmp_i + {HI,LO};//加的是最新的HI和LO的值
                        StopReq_for_madd_msub = `NoStop;
                    end
                end

                `EXE_MSUB_OP,`EXE_MSUBU_OP:begin//累乘减
                    if (count_i == 2'b00) begin //在第一个计算的时钟周期
                        hilo_tmp_o = ~MulRes+1; //减法
                        count_o = 2'b01;//表示第二个周期
                        mul_2period_temp = 0;
                        StopReq_for_madd_msub = `Stop;
                    end
                    else if(count_i == 2'b01) begin //第二个时钟周期
                        hilo_tmp_o = 0; //不需要中间变量了
                        count_o = 2'b10;//防止因为其他情况流水线暂停的时候继续执行指令
                        mul_2period_temp = hilo_tmp_i + {HI,LO};//加的是最新的HI和LO的值
                        StopReq_for_madd_msub = `NoStop;
                    end
                end
                default:begin
                    hilo_tmp_o = 0;
                    count_o = 0;
                    StopReq_for_madd_msub = `NoStop;
                end
            endcase
        end
    end

    //除法运算控制********************************

    always @(*) begin
        if(!rst_n) begin
            StopReq_for_div = 0;
            div_opdata1 = 0;
            div_opdata2 = 0;
            start_flag = 0;
            signed_flag = 0;
        end
        else begin
            StopReq_for_div = 0;
            div_opdata1 = 0;
            div_opdata2 = 0;
            start_flag = 0;
            signed_flag = 0;
        end
        case(op)
            `EXE_DIV_OP:begin
                if(complete_flag == 0)begin
                    div_opdata1 = num1;
                    div_opdata2 = num2;
                    start_flag = 1;
                    signed_flag = 1;
                    StopReq_for_div = `Stop;
                end
                else if(complete_flag ==1)begin
                    div_opdata1 = num1;
                    div_opdata2 = num2;
                    start_flag = 0;
                    signed_flag = 1;
                    StopReq_for_div = `NoStop;
                end
                else begin
                    div_opdata1 = 0;
                    div_opdata2 = 0;
                    start_flag = 0;
                    signed_flag = 0;
                    StopReq_for_div = `NoStop;
                end
            end

            `EXE_DIVU_OP:begin
                if(complete_flag == 0)begin
                    div_opdata1 = num1;
                    div_opdata2 = num2;
                    start_flag = 1;
                    signed_flag = 0;
                    StopReq_for_div = `Stop;
                end
                else if(complete_flag ==1)begin
                    div_opdata1 = num1;
                    div_opdata2 = num2;
                    start_flag = 0;
                    signed_flag = 0;
                    StopReq_for_div = `NoStop;
                end
                else begin
                    div_opdata1 = 0;
                    div_opdata2 = 0;
                    start_flag = 0;
                    signed_flag = 0;
                    StopReq_for_div = `NoStop;
                end
            end            
        endcase
    end

    //输出流水线暂停信号***************************
    always @(*) begin
        if(!rst_n)begin
            StopReq_from_ex = 0;
        end
        else begin
            StopReq_from_ex = StopReq_for_madd_msub || StopReq_for_div;
        end
    end

    //规定HILO输出*******************************
    always @(*) begin
        if(!rst_n) begin
            en_hilo = 0;
            hi_o = 0;
            lo_o = 0;
        end
        else begin
            case(op)
                `EXE_MTHI_OP:begin
                    en_hilo = 1;
                    hi_o = num1;
                    lo_o = LO;
                end
                `EXE_MTLO_OP:begin
                    en_hilo = 1;
                    hi_o = HI;
                    lo_o = num1;
                end
                `EXE_MULT_OP,`EXE_MULTU_OP:begin //对hi和lo进行操作
                    en_hilo = 1;
                    hi_o = MulRes[63:32];
                    lo_o = MulRes[31:0];
                end
                `EXE_MADD_OP,`EXE_MADDU_OP: begin
                    en_hilo = 1;
                    hi_o = mul_2period_temp[63:32];
                    lo_o = mul_2period_temp[31:0];
                end
                `EXE_MSUB_OP,`EXE_MSUBU_OP: begin
                    en_hilo = 1;
                    hi_o = mul_2period_temp[63:32];
                    lo_o = mul_2period_temp[31:0];
                end
                `EXE_DIV_OP,`EXE_DIVU_OP:begin
                    en_hilo = 1;
                    hi_o = div_result[63:32];
                    lo_o = div_result[31:0];
                end
                default:begin
                    en_hilo = 0;
                    hi_o = 0;
                    lo_o = 0;
                end
            endcase
        end
    end
    //移动运算结果 除了MTHI和MTLO指令，因为其是对SPR进行操作****************************

    always @(*) begin
        if(!rst_n) begin
            MoveRes = 0;
        end
        else begin
            case(op)
                `EXE_MOVN_OP:begin
                    MoveRes = num1;
                end
                `EXE_MOVZ_OP:begin
                    MoveRes = num1;
                end
                `EXE_MFHI_OP:begin
                    MoveRes = HI;
                end
                `EXE_MFLO_OP:begin
                    MoveRes = LO;
                end
                default:begin
                    MoveRes = 0;
                end
            endcase
        end
    end
    //逻辑运算结果*********************************************************
    always @(*) begin
        if(!rst_n) begin
            LogicOut = 0;
        end
        else begin
            case(op)
            `EXE_OR_OP: begin
                LogicOut = num1 | num2;
            end
            `EXE_AND_OP: begin
                LogicOut = num1 & num2;
            end
            `EXE_XOR_OP:begin
                LogicOut = num1 ^ num2;
            end
            `EXE_NOR_OP:begin
                LogicOut = ~( num1 | num2 );
            end
            default: begin
                LogicOut = 0;
            end
            endcase
        end
    end

    //移位运算结果******************************************************
    always @(*) begin
        if(!rst_n) begin
            ShiftRes = 0;
        end
        else begin
            case(op)
            `EXE_SLL_OP: begin
                ShiftRes = num2 << num1[4:0];
            end
            `EXE_SRL_OP: begin
                ShiftRes = num2 >> num1[4:0];
            end
            `EXE_SRA_OP:begin
                ShiftRes = ({32{num2[31]}}<<(6'd32-{1'b0,num1[4:0]})) | num2 >> num1[4:0];
                //{32{num2[31]}}：这部分代码是将 num2[31] 这一位的值复制到一个32位的向量中。这样做是为了在进行算术右移时保持符号位的值不变。
                //<<(6'd32-{1'b0,num1[4:0]})：这部分代码是将上一步得到的32位向量向左移动一个特定的位数。移动的位数由 32-{1'b0,num1[4:0]} 决定。
                //1'b0 是一个单独的位，num1[4:0] 是一个5位的向量。通过将它们组合在一起，形成一个6位的向量，然后减去32，可以得到一个表示向左移动的位数的值。
                //| num2 >> num1[4:0]：这部分代码是将 num2 向右移动 num1[4:0] 位，并与上一步得到的结果进行按位或操作。这样做是为了将右移后的低位部分与左移后的高位部分组合在一起。
            end
            default: begin
                ShiftRes = 0;
            end
            endcase
        end
    end
    //输出的always块，给出是否写入，写入哪，然后再写数据**********************************************

    always @(*) begin

        desReg_addr_ex = desReg_addr;
        if(overflow && (op ==`EXE_ADD_OP||op ==`EXE_ADDI_OP||op ==`EXE_SUB_OP)) begin //有符号加法减法可能存在溢出
            en_wd_ex = 0;
        end
        else begin
            en_wd_ex = en_wd;
        end
        case (sel)
            `EXE_RES_LOGIC: begin 
                result = LogicOut;
            end
            `EXE_RES_SHIFT: begin 
                result = ShiftRes;
            end
            `EXE_RES_MOVE:begin
                result = MoveRes;
            end
            `EXE_RES_MUL:begin
                result = MulRes[31:0]; //不写入SPR，那么只有低位能写入GPR
            end
            `EXE_RES_ARITHMETIC:begin
                result = ArithRes;
            end
            `EXE_RES_JUMP_BRANCH:begin
                result = link_address;
            end
            default: begin 
                result = 0;
            end
        endcase
    end
endmodule