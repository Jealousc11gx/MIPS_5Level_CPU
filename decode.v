`include "define.v"
//     op           rs                   rt      immediately
// 6   5  5  16
// operation register source      register target       
module decode (
    input wire rst_n,
    input wire [`DataWidth-1:0] rd1_data,
    input wire [`DataWidth-1:0] rd2_data,
    input wire [`Ins_Addr-1:0] pc_ins,
    input wire [`DataWidth-1:0] pc,



    //为了解决相邻和相隔一个指令的数据相关问题  RAW Read After Write

    // 采用数据前推的方法 传递ex阶段和mem阶段的数据到解码阶段
    //多行同时编辑 ctrl shift 
    //ex阶段数据回写
    input wire ex_en_wd,
    input wire [4:0] ex_desReg_addr,
    input wire [`DataWidth-1:0] ex_result,

    //mem阶段数据回写
    input wire mem_en_wd,
    input wire [4:0] mem_desReg_addr,
    input wire [`DataWidth-1:0] mem_result,

    //当前指令是否位于延迟槽
    input wire this_ins_in_delayslot_i,

    //向GPR中给出两个读使能和两个读地址 对应rs和rt
    output reg en_rd1,
    output reg en_rd2,
    output reg [`Reg_AddrBus] rd1_addr,
    output reg [`Reg_AddrBus] rd2_addr,

    //向执行阶段给出源操作数1，2，并指示指令操作码和子类型，并指示是否需要写回，以及写回地址
    output reg [`DataWidth-1:0] num1,
    output reg [`DataWidth-1:0] num2,
    output reg [7:0] op,  //运算类型     决定对什么类型的输出做什么运算
    output reg [2:0] sel, //运算子类型   决定写入数据是什么，如果为0 那么就不向GPR中写入数据
    output reg en_wd, //是否写回寄存器
    output reg [4:0] desReg_addr, //写回寄存器的地址

    //输出当前指令是否位于延迟槽，存储的返回地址，下一条指令是否位于延迟槽，是否要转移，转移的目标地址
    output reg this_ins_in_delayslot_o,
    output reg [`DataWidth-1:0] link_address,
    output reg next_ins_in_delayslot,
    output reg branch_flag,
    output reg [`DataWidth-1:0] branch_target_address,

    //向ctrl模块给出流水线暂停信号

    output reg StopReq_from_decode
);
    wire [5:0]op1 = pc_ins [31:26]; //op位pc的高6位 指令码
    wire [4:0]op2 = pc_ins [10:6];//sa
    wire [5:0]op3 = pc_ins [5:0]; //功能码
    wire [4:0]op4 = pc_ins [20:16];//rt

    reg [`Reg_BUS] Imm; //存放立即数 32位

    reg Ins_Valid; //指令有效性

    wire [`DataWidth-1:0] pc_plus4;//指令地址按字节编址+4,也就是延迟槽指令
    wire [`DataWidth-1:0] pc_plus8;//返回地址
    wire [`DataWidth-1:0] offset_sll2_signextend;//offset 左移两位(因为字节编码和按字寻址的原因),符号拓展(指令对齐)

    assign pc_plus4 = pc + 4;
    assign pc_plus8 = pc + 8;
    assign offset_sll2_signextend = {{14{pc_ins[15]}},pc_ins[15:0],2'b0};

//进行初始化
always @(*) begin
    if(!rst_n)begin
        en_rd1 = 0;
        en_rd2 = 0;
        rd1_addr = 0;
        rd2_addr = 0;
        op = `EXE_NOP_OP; 
        sel = `EXE_RES_NOP;
        en_wd = 0;
        desReg_addr = 0;
        Ins_Valid = 1;
        Imm = 0;
        link_address = 0;
        next_ins_in_delayslot = 0;
        branch_flag = 0;
        branch_target_address = 0;
    end
    else begin //其实就是改变了三个默认的寄存器的地址 其余都还是置0
        en_rd1 = 0;
        en_rd2 = 0;
        rd1_addr = pc_ins [25:21];//第一个地址为rs
        rd2_addr = pc_ins [20:16];//第二个地址为rt
        en_wd = 0;
        desReg_addr = pc_ins [15:11];//默认第三个地址位rd 
        Ins_Valid = 0;
        op = `EXE_NOP_OP;
        Imm = 0;
        sel = `EXE_RES_NOP;
        link_address = 0;
        next_ins_in_delayslot = 0;
        branch_flag = 0;
        branch_target_address = 0;        
        case (op1) //case指令码  在always块内完成
            `EXE_SPECIAL_INST:begin //指令码为R指令
                    case (op2) //case sa
                        5'b00000:begin // 没有立即数嘛
                            case (op3) //case功能码
                                    `EXE_AND:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_AND_OP; 
                                    sel = `EXE_RES_LOGIC;
                                    end

                                    `EXE_OR:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_OR_OP; 
                                    sel = `EXE_RES_LOGIC;
                                    end

                                    `EXE_XOR:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_XOR_OP; 
                                    sel = `EXE_RES_LOGIC;
                                    end

                                    `EXE_NOR:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_NOR_OP; 
                                    sel = `EXE_RES_LOGIC;
                                    end

                                    `EXE_SLLV:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    //op = `EXE_SLLV_OP; 
                                    op = `EXE_SLL_OP;
                                    sel = `EXE_RES_SHIFT;
                                    end

                                    `EXE_SRLV:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    //op = `EXE_SRLV_OP; 
                                    op = `EXE_SRL_OP;
                                    sel = `EXE_RES_SHIFT;
                                    end

                                    `EXE_SRAV:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    //op = `EXE_SRAV_OP; 
                                    op = `EXE_SRA_OP;
                                    sel = `EXE_RES_SHIFT;
                                    end

                                    `EXE_SYNC:begin //看作空操作
                                    en_rd1 = 0;//读端口1
                                    en_rd2 = 1;//读端口2 
                                    en_wd = 0;//需要写回 不需要写回的话en_rd2有什么关系
                                    Ins_Valid = 1;//指令有效
                                    //op = `EXE_SYNC_OP; 
                                    op = `EXE_NOP_OP;                 
                                    sel = `EXE_RES_NOP;
                                    end

                                    `EXE_MOVN:begin //不相等的话向
                                    en_rd1 = 1;//读端口1 rs
                                    en_rd2 = 1;//读端口2 rt
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MOVN_OP;                 
                                    sel = `EXE_RES_MOVE;
                                    //if(rd2_addr != 0) begin
                                    if(num2 != 0) begin
                                        en_wd = 1;
                                    end
                                    else begin
                                        en_wd = 0;
                                    end
                                    end

                                    `EXE_MOVZ:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2 
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MOVZ_OP;                 
                                    sel = `EXE_RES_MOVE;
                                    //if(rd2_addr == 0) begin  BUG!!!
                                    if(num2 == 0) begin
                                        en_wd = 1;
                                    end
                                    else begin
                                        en_wd = 0;
                                    end
                                    end

                                    `EXE_MTHI:begin
                                    en_rd1 = 1;//读端口1 rs
                                    en_rd2 = 0;//读端口2 rt
                                    en_wd = 0;//不需要写回GPR 
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MTHI_OP;                 
                                    sel = `EXE_RES_NOP;//不对GPR进行操作
                                    end      

                                    `EXE_MTLO:begin
                                    en_rd1 = 1;//读端口1 rs
                                    en_rd2 = 0;//读端口2 rt
                                    en_wd = 0;//不需要写回GPR 
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MTLO_OP;                 
                                    sel = `EXE_RES_NOP;//不对GPR进行操作
                                    end

                                    `EXE_MFHI:begin // 对rd进行操作
                                    en_rd1 = 0;//读端口1 rs
                                    en_rd2 = 0;//读端口2 rt
                                    en_wd = 1;//需要写回 
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MFHI_OP;                 
                                    sel = `EXE_RES_MOVE;//要对GPR进行操作
                                    end

                                    `EXE_MFLO:begin
                                    en_rd1 = 0;//读端口1 rs
                                    en_rd2 = 0;//读端口2 rt
                                    en_wd = 1;//需要写回 
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MFLO_OP;                 
                                    sel = `EXE_RES_MOVE;//要对GPR进行操作
                                    end

                                    `EXE_ADD:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_ADD_OP; 
                                    sel = `EXE_RES_ARITHMETIC;
                                    end

                                    `EXE_ADDU:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_ADDU_OP; 
                                    sel = `EXE_RES_ARITHMETIC;
                                    end

                                    `EXE_SUB:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_SUB_OP; 
                                    sel = `EXE_RES_ARITHMETIC;
                                    end

                                    `EXE_SUBU:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_SUBU_OP; 
                                    sel = `EXE_RES_ARITHMETIC;
                                    end    

                                    `EXE_SLT:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_SLT_OP; 
                                    sel = `EXE_RES_ARITHMETIC;
                                    end

                                    `EXE_SLTU:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 1;//需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_SLTU_OP; 
                                    sel = `EXE_RES_ARITHMETIC;
                                    end

                                    `EXE_MULT:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 0;//不需要写回
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MULT_OP; 
                                    sel = `EXE_RES_NOP; //不对GPR进行操作
                                    end

                                    `EXE_MULTU:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 0;//不需要写回GPR
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_MULTU_OP; 
                                    sel = `EXE_RES_NOP; //不对GPR进行操作
                                    end

                                    `EXE_DIV:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 0;//不需要写回GPR
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_DIV_OP; 
                                    sel = `EXE_RES_NOP; //不对GPR进行操作
                                    end


                                    `EXE_DIVU:begin
                                    en_rd1 = 1;//读端口1
                                    en_rd2 = 1;//读端口2
                                    en_wd = 0;//不需要写回GPR
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_DIVU_OP; 
                                    sel = `EXE_RES_NOP; //不对GPR进行操作
                                    end
                                    
                                    `EXE_JR:begin//Jump Register
                                    en_rd1 = 1;//rs
                                    en_rd2 = 0;
                                    en_wd = 0;//不需要写回GPR
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_JR_OP; 
                                    sel = `EXE_RES_JUMP_BRANCH; //不对GPR进行操作
                                    link_address = 0; //没有设置返回地址
                                    next_ins_in_delayslot = 1;
                                    branch_flag = 1;
                                    branch_target_address = num1;                                    
                                    end
                                    
                                    `EXE_JALR:begin//Jump And Link Register
                                    en_rd1 = 1;//rs
                                    en_rd2 = 0;
                                    en_wd = 1;//需要写回rd，将link地址写到rd  默认写到rd中
                                    Ins_Valid = 1;//指令有效
                                    op = `EXE_JALR_OP; 
                                    sel = `EXE_RES_JUMP_BRANCH; //不对GPR进行操作
                                    link_address = pc_plus8; //jump and link register link address pc_plus8
                                    next_ins_in_delayslot = 1;
                                    branch_flag = 1;
                                    branch_target_address = num1;//num1为rs                                    
                                    end

                                    default:begin //其余为无效指令
                                    end                                                                                                                                      
                            endcase
                        end
                        default: begin//其余为无效指令
                        end
                    endcase
            end

            //立即数指令也即是I型指令 出去前六位指令码和最后六位操作码，之间的rs rt rd sa中，I型指令很明显的没有rd和sa，其将立即数作为操作数之一，其操作数为rs和imm
            //没有了rd，写入rt，因此目的地也需要更改

            `EXE_ANDI:begin
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            Ins_Valid = 1;//指令有效          
            op = `EXE_AND_OP; 
            //op = `EXE_ANDI_OP; 
            sel = `EXE_RES_LOGIC;          
            Imm = {16'b0000_0000_0000_0000,pc_ins[15:0]};
            desReg_addr = pc_ins[20:16];//rt为写入寄存器
            end

            `EXE_ORI:begin
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            Ins_Valid = 1;//指令有效
            //op = `EXE_ORI_OP; 
            op = `EXE_OR_OP;
            sel = `EXE_RES_LOGIC;           
            Imm = {16'b0000_0000_0000_0000,pc_ins[15:0]};
            desReg_addr = pc_ins[20:16];//rt为写入寄存器
            end

            `EXE_XORI:begin
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            Ins_Valid = 1;//指令有效
            //op = `EXE_XORI_OP; 
            op = `EXE_XOR_OP;
            sel = `EXE_RES_LOGIC;          
            Imm = {16'b0000_0000_0000_0000,pc_ins[15:0]};
            desReg_addr = pc_ins[20:16];//rt为写入寄存器
            end

            `EXE_ANDI:begin
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            Ins_Valid = 1;//指令有效
            //op = `EXE_ANDI_OP;
            op = `EXE_AND_OP;
            sel = `EXE_RES_LOGIC;           
            Imm = {16'b0000_0000_0000_0000,pc_ins[15:0]};
            desReg_addr = pc_ins[20:16];//rt为写入寄存器
            end

            `EXE_LUI:begin //LOAD UPPER IMMEDIATELY
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            Ins_Valid = 1;//指令有效
            //op = `EXE_LUI_OP; //与 $0 寄存器相或 把结果存到 rt 之中********这里只是译码过程不是执行过程
            op = `EXE_OR_OP; //与 $0 寄存器相或 把结果存到 rt 之中********这里只是译码过程不是执行过程            
            sel = `EXE_RES_LOGIC;           
            Imm = {pc_ins[15:0],16'b0000_0000_0000_0000};
            desReg_addr = pc_ins[20:16];//rt为写入寄存器
            end

            `EXE_PREF:begin //看作空操作！
            en_rd1 = 0;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 0;//需要写回
            Ins_Valid = 1;//指令有效
            //op = `EXE_PREF_OP; // WATCHing！
            op = `EXE_NOP_OP; // WATCHing！
            sel = `EXE_RES_NOP;           
            end

            `EXE_ADDI:begin //看作空操作！
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            desReg_addr = pc_ins[20:16];
            Ins_Valid = 1;//指令有效
            op = `EXE_ADDI_OP; // WATCHing！
            sel = `EXE_RES_ARITHMETIC;
            Imm = {{16{pc_ins[15]}},pc_ins[15:0]};//Sign Extend           
            end

            `EXE_ADDIU:begin //看作空操作！
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            desReg_addr = pc_ins[20:16];
            Ins_Valid = 1;//指令有效
            op = `EXE_ADDIU_OP; // WATCHing！
            sel = `EXE_RES_ARITHMETIC;
            Imm = {{16{pc_ins[15]}},pc_ins[15:0]};//Sign Extend            
            end

            `EXE_SLTI:begin //看作空操作！
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            desReg_addr = pc_ins[20:16];
            Ins_Valid = 1;//指令有效
            op = `EXE_SLT_OP; // WATCHing！
            sel = `EXE_RES_ARITHMETIC;  
            Imm = {{16{pc_ins[15]}},pc_ins[15:0]};//Sign Extend           
            end

            `EXE_SLTIU:begin //看作空操作！
            en_rd1 = 1;//读端口1
            en_rd2 = 0;//读端口2
            en_wd = 1;//需要写回
            desReg_addr = pc_ins[20:16];
            Ins_Valid = 1;//指令有效
            op = `EXE_SLTU_OP; // WATCHing！
            sel = `EXE_RES_ARITHMETIC;           
            Imm = {{16{pc_ins[15]}},pc_ins[15:0]};//Sign Extend  
            end

            `EXE_J:begin//J inst_index有26位
            en_rd1 = 0;
            en_rd2 = 0;
            en_wd = 0;//不需要写回rd
            Ins_Valid = 1;//指令有效
            op = `EXE_J_OP; 
            sel = `EXE_RES_JUMP_BRANCH; 
            link_address = 0; //rd
            next_ins_in_delayslot = 1;
            branch_flag = 1;
            branch_target_address = {pc_plus4[31:28],pc_ins[25:0],2'b00};                                    
            end

            `EXE_JAL:begin//Jump And Link
            en_rd1 = 0;//rs
            en_rd2 = 0;
            en_wd = 1;//
            Ins_Valid = 1;//指令有效
            op = `EXE_JAL_OP; 
            sel = `EXE_RES_JUMP_BRANCH;
            desReg_addr = 5'b11111;//默认将返回地址存到$31
            link_address = pc_plus8; //rd
            next_ins_in_delayslot = 1;
            branch_flag = 1;
            branch_target_address = {pc_plus4[31:28],pc_ins[25:0],2'b00};                                    
            end

            `EXE_BEQ:begin//Branch If Equal
            en_rd1 = 1;//rs
            en_rd2 = 1;//rt
            en_wd = 0;
            Ins_Valid = 1;//指令有效
            op = `EXE_BEQ_OP; 
            sel = `EXE_RES_JUMP_BRANCH; //不对GPR进行操作
            link_address = 0; //rd
            if(num1 == num2) begin//源操作数的取出根据不同的数据相关的情况有不同的取值
                next_ins_in_delayslot = 1;
                branch_flag = 1;
                branch_target_address = pc_plus4 + offset_sll2_signextend;
            end                                    
            end

            `EXE_BNE:begin//Branch If Not Equal
            en_rd1 = 1;//rs
            en_rd2 = 1;//rt
            en_wd = 0;
            Ins_Valid = 1;//指令有效
            op = `EXE_BNE_OP; 
            sel = `EXE_RES_JUMP_BRANCH; //不对GPR进行操作
            link_address = 0; //rd
            if(num1 != num2) begin
                next_ins_in_delayslot = 1;
                branch_flag = 1;
                branch_target_address = pc_plus4 + offset_sll2_signextend;
            end                                    
            end

            `EXE_BGTZ:begin//Branch If Greater than zero 
            en_rd1 = 1;//rs
            en_rd2 = 0;//rt
            en_wd = 0;
            Ins_Valid = 1;//指令有效
            op = `EXE_BGTZ_OP; 
            sel = `EXE_RES_JUMP_BRANCH; //不对GPR进行操作
            link_address = 0; //rd
            if((num1[31] == 0) && (num1 != 0)) begin
                next_ins_in_delayslot = 1;
                branch_flag = 1;
                branch_target_address = pc_plus4 + offset_sll2_signextend;
            end
            end

            `EXE_BLEZ:begin//Branch If Less than zero  or equal
            en_rd1 = 1;//rs
            en_rd2 = 0;//rt
            en_wd = 0;
            Ins_Valid = 1;//指令有效
            op = `EXE_BLEZ_OP; 
            sel = `EXE_RES_JUMP_BRANCH; //不对GPR进行操作
            link_address = 0; //rd
            if((num1[31] == 1) || (num1 == 0))begin//负数或者为0
                next_ins_in_delayslot = 1;
                branch_flag = 1;
                branch_target_address = pc_plus4 + offset_sll2_signextend;
            end
            end

            `EXE_SPECIAL2_INST:begin
                case (op3)
                `EXE_CLO:begin //只用到rs和rd
                en_rd1 = 1;//读端口1
                en_rd2 = 0;//读端口2 不用rt
                en_wd = 1;//需要写回
                Ins_Valid = 1;//指令有效
                op = `EXE_CLO_OP; // WATCHing！
                sel = `EXE_RES_ARITHMETIC;
                //为什么不需要指明写回地址，不是需要写回rd之中吗:默认rd
                end

                `EXE_CLZ:begin //看作空操作！
                en_rd1 = 1;//读端口1
                en_rd2 = 0;//读端口2
                en_wd = 1;//需要写回
                Ins_Valid = 1;//指令有效
                op = `EXE_CLZ_OP; // WATCHing！
                sel = `EXE_RES_ARITHMETIC;           
                end
                
                `EXE_MUL:begin //特殊乘法指令，只放到GPR中
                en_rd1 = 1;//读端口1 都要用
                en_rd2 = 1;//读端口2 都要用
                en_wd = 1;//需要写回
                Ins_Valid = 1;//指令有效
                op = `EXE_MUL_OP; 
                sel = `EXE_RES_MUL;           
                end
                
                `EXE_MADDU:begin //乘累加无符号
                en_rd1 = 1;//读端口1 都要用
                en_rd2 = 1;//读端口2 都要用
                en_wd = 0;//不需要写回
                Ins_Valid = 1;//指令有效
                op = `EXE_MADDU_OP; 
                sel = `EXE_RES_NOP;           
                end

                `EXE_MADD:begin 
                en_rd1 = 1;//读端口1 都要用
                en_rd2 = 1;//读端口2 都要用
                en_wd = 0;//不需要写回
                Ins_Valid = 1;//指令有效
                op = `EXE_MADD_OP; 
                sel = `EXE_RES_NOP;           
                end

                `EXE_MSUBU:begin //乘累减
                en_rd1 = 1;//读端口1 都要用
                en_rd2 = 1;//读端口2 都要用
                en_wd = 0;//不需要写回
                Ins_Valid = 1;//指令有效
                op = `EXE_MSUBU_OP; 
                sel = `EXE_RES_NOP;           
                end

                `EXE_MSUB:begin 
                en_rd1 = 1;//读端口1 都要用
                en_rd2 = 1;//读端口2 都要用
                en_wd = 0;//不需要写回
                Ins_Valid = 1;//指令有效
                op = `EXE_MSUB_OP; 
                sel = `EXE_RES_NOP;           
                end

                default:begin                        
                end 
                endcase
            end
            

            `EXE_REGIMM_INST:begin
                case(op4)
                    `EXE_BLTZ:begin//Branch less than zero
                        en_rd1 = 1;//rs
                        en_rd2 = 0;
                        en_wd = 0;//
                        Ins_Valid = 1;//指令有效
                        op = `EXE_BLTZ_OP; 
                        sel = `EXE_RES_JUMP_BRANCH; 
                        link_address = 0; //rd
                        if(num1[31] ==1) begin
                            next_ins_in_delayslot = 1;
                            branch_flag = 1;
                            branch_target_address = pc_plus4 + offset_sll2_signextend;
                        end
                    end

                    `EXE_BLTZAL:begin//Branch less than zero and link
                        en_rd1 = 1;//rs
                        en_rd2 = 0;
                        en_wd = 1;//
                        Ins_Valid = 1;//指令有效
                        op = `EXE_BLTZAL_OP; 
                        sel = `EXE_RES_JUMP_BRANCH; 
                        desReg_addr = 5'b11111;//默认将返回地址存到$31
                        link_address = pc_plus8; //rd
                        if(num1[31] ==1) begin
                            next_ins_in_delayslot = 1;
                            branch_flag = 1;
                            branch_target_address = pc_plus4 + offset_sll2_signextend;
                        end
                    end

                    `EXE_BGEZAL:begin//Branch greater or equal zero and link
                        en_rd1 = 1;//rs
                        en_rd2 = 0;
                        en_wd = 1;//
                        Ins_Valid = 1;//指令有效
                        op = `EXE_BGEZAL_OP; 
                        sel = `EXE_RES_JUMP_BRANCH;
                        desReg_addr = 5'b11111;//默认将返回地址存到$31 
                        link_address = pc_plus8; //rd
                        if(num1[31] == 0) begin
                            next_ins_in_delayslot = 1;
                            branch_flag = 1;
                            branch_target_address = pc_plus4 + offset_sll2_signextend;
                        end
                    end

                    `EXE_BGEZ:begin//Branch greater or equal zero
                        en_rd1 = 1;//rs
                        en_rd2 = 0;
                        en_wd = 0;//
                        Ins_Valid = 1;//指令有效
                        op = `EXE_BGEZ_OP; 
                        sel = `EXE_RES_JUMP_BRANCH; 
                        link_address = 0; //rd
                        if(num1[31] == 0) begin
                            next_ins_in_delayslot = 1;
                            branch_flag = 1;
                            branch_target_address = pc_plus4 + offset_sll2_signextend;
                        end
                    end

                    default: begin
                    end
                endcase       
            end
            default:begin
            end
        endcase
        if(pc_ins[31:21] == 11'b000_0000_0000) begin //使用case排除先后
            case (op3) //case功能码
                `EXE_SLL:begin
                    en_rd1 = 0;//rs全都是0了
                    en_rd2 = 1;//rt register target
                    en_wd = 1;
                    Ins_Valid = 1;
                    op = `EXE_SLL_OP;
                    sel = `EXE_RES_SHIFT;
                    Imm[4:0] = pc_ins[10:6];//sa
                    desReg_addr = pc_ins[15:11];//写入rd register destination
                end

                `EXE_SRL:begin
                    en_rd1 = 0;//rs全都是0了
                    en_rd2 = 1;//rt register target
                    en_wd = 1;
                    Ins_Valid = 1;
                    op = `EXE_SRL_OP;
                    sel = `EXE_RES_SHIFT;
                    Imm[4:0] = pc_ins[10:6];
                    desReg_addr = pc_ins[15:11];//写入rd register destination
                end

                `EXE_SRA:begin
                    en_rd1 = 0;//rs全都是0了
                    en_rd2 = 1;//rt register target
                    en_wd = 1;
                    Ins_Valid = 1;
                    op = `EXE_SRA_OP;
                    sel = `EXE_RES_SHIFT;
                    Imm[4:0] = pc_ins[10:6];
                    desReg_addr = pc_ins[15:11];//写入rd register destination
                end

                default: begin
                end
            endcase
        end
    end
end
//给num1赋值
always @(*) begin
    if(!rst_n)
        num1 = 0;
    //解决访存和执行阶段的数据冲突
    else if( (en_rd1) && (rd1_addr == ex_desReg_addr) && (ex_en_wd) )//译码阶段要读取的寄存器地址和执行阶段写入的寄存器地址一致的话，进行数据前推
        num1 = ex_result;
    //ctrl shift + 上 复制一整行
    else if( (en_rd1) && (rd1_addr == mem_desReg_addr) && (mem_en_wd) )//译码阶段要读取的寄存器地址和访存阶段写入的寄存器地址一致的话，进行数据前推
        num1 = mem_result;
    else if(en_rd1)
        num1 = rd1_data;
    else if(!en_rd1)
        num1 = Imm;
    else
        num1 = 0;
end
//给num2赋值 
always @(*) begin
    if(!rst_n)
        num2 = 0;
    else if( (en_rd2) && (rd2_addr == ex_desReg_addr) && (ex_en_wd) )//译码阶段要读取的寄存器地址和执行阶段写入的寄存器地址一致的话，进行数据前推
        num2 = ex_result;
    //ctrl shift + 上 复制一整行
    else if( (en_rd2) && (rd2_addr == mem_desReg_addr) && (mem_en_wd) )//译码阶段要读取的寄存器地址和访存阶段写入的寄存器地址一致的话，进行数据前推
        num2 = mem_result;
    else if(en_rd2)
        num2 = rd2_data;
    else if(!en_rd2)
        num2 = Imm;
    else
        num2 = 0;
end

//给Stop赋值
always @(*) begin
    if(!rst_n)
        StopReq_from_decode = 0;
    else
        StopReq_from_decode = `NoStop;//加载存储才使用
end
//给this_ins_in_delayslot_o赋值
always @(*) begin
    if(!rst_n)begin
        this_ins_in_delayslot_o = 0;
    end
    else begin
        this_ins_in_delayslot_o = this_ins_in_delayslot_i;
    end
end
endmodule