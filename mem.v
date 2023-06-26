`include "define.v"
module mem (
    input wire rst_n,
    input wire en_wd,
    input wire [`Reg_AddrBus] desReg_addr,
    input wire [`DataWidth-1:0]result,

    input wire [`DataWidth-1:0] hi_i,
    input wire [`DataWidth-1:0] lo_i,
    input wire en_hilo_i,
    input wire [`DataWidth-1:0] mem_cp0_wdata_i,
    input wire mem_cp0_rw_en_i,
    input wire [4:0] mem_cp0_waddr_i,    

    //访存指令输入*************************************
    input wire [7:0] op,//指令码，进行什么操作
    input wire [`DataWidth-1:0] ram_addr_i,//写入的地址
    input wire [`DataWidth-1:0] num2,//输入的num2，可以是写入的数据，可以是不对齐指令的初始值
    input wire [`DataWidth-1:0] data_from_ram,//读出的数据

    input wire wb_LLbit_data,//为了防止数据相关，从mem_wb阶段传回的数据
    input wire wb_LLbit_en,//为了防止数据相关，从mem_wb阶段传回的使能信号
    input wire LLbit_data_i,//供sc阶段判断的llbit模块传来的数据

    //访存指令输出*************************************
    output reg en_wd_mem,
    output reg [`Reg_AddrBus] desReg_addr_mem,
    output reg [`DataWidth-1:0] result_mem,//这个是写到GPR中的结果

    output reg [`DataWidth-1:0] mem_cp0_wdata,
    output reg mem_cp0_rw_en,
    output reg [4:0] mem_cp0_waddr,    

    output reg [`DataWidth-1:0] hi_o,
    output reg [`DataWidth-1:0] lo_o,
    output reg en_hilo_o,

    output wire wr_en,//写还是读，1为写,为啥要单独ling出来？
    output reg ram_en,//ram使能信号    
    output reg [3:0] Bits_Sel,//字节选择，适用于不对齐指令
    output reg [`DataWidth-1:0] ram_addr_o,//写入存储器的地址
    output reg [`DataWidth-1:0] data_to_ram,//写入数据

    output reg LLbit_data_o,
    output reg LLbit_en_o
);

    reg wr_en_reg;//为什么要单独把wr_en给成reg信号
    assign wr_en = wr_en_reg;

    reg LLbit;//存储最新的LLbit内的值

    always @(*) begin //防止数据相关，在时钟上升沿之前送回数据判断
        if(!rst_n)begin
            LLbit = 0;
        end
        else if(wb_LLbit_en)begin
            LLbit = wb_LLbit_data;
        end
        else begin
            LLbit = LLbit_data_i;
        end
    end

    always @(*) begin
        if(!rst_n) begin
            en_wd_mem = 0;
            desReg_addr_mem = 0;
            result_mem = 0;
            hi_o = 0;
            lo_o = 0;
            en_hilo_o = 0;
            wr_en_reg = 0;
            ram_en = 0;
            Bits_Sel = 0;
            ram_addr_o = 0;
            data_to_ram = 0;
            LLbit_data_o = 0;
            LLbit_en_o = 0;
            mem_cp0_wdata = 0;
            mem_cp0_rw_en = 0;
            mem_cp0_waddr = 0;            
        end
        else begin
            en_wd_mem = en_wd;
            desReg_addr_mem = desReg_addr;
            result_mem = result;
            hi_o = hi_i;
            lo_o = lo_i;
            en_hilo_o = en_hilo_i;
            wr_en_reg = 0;
            ram_en = 0;
            Bits_Sel = 4'b1111;//？
            ram_addr_o = 0;
            data_to_ram = 0;
            LLbit_data_o = 0;
            LLbit_en_o = 0;
            mem_cp0_wdata = mem_cp0_wdata_i;
            mem_cp0_rw_en = mem_cp0_rw_en_i;
            mem_cp0_waddr = mem_cp0_waddr_i;                         
            case (op)
                `EXE_LB_OP:begin
                    wr_en_reg = `READ;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            Bits_Sel = 4'b1000;
                            result_mem = {{24{data_from_ram[31]}},data_from_ram[31:24]};
                        end
                        2'b01:begin
                            Bits_Sel = 4'b0100;
                            result_mem = {{24{data_from_ram[23]}},data_from_ram[23:16]};
                        end
                        2'b10:begin
                            Bits_Sel = 4'b0010;
                            result_mem = {{24{data_from_ram[15]}},data_from_ram[15:8]};
                        end
                        2'b11:begin
                            Bits_Sel = 4'b0001;
                            result_mem = {{24{data_from_ram[7]}},data_from_ram[7:0]};
                        end                        
                        default: begin
                            Bits_Sel = 4'b1111;
                            result_mem = 0;
                        end
                    endcase
                end
                
                `EXE_LBU_OP:begin
                    wr_en_reg = `READ;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            Bits_Sel = 4'b1000;
                            result_mem = {{24{1'b0}},data_from_ram[31:24]};
                        end
                        2'b01:begin
                            Bits_Sel = 4'b0100;
                            result_mem = {{24{1'b0}},data_from_ram[23:16]};
                        end
                        2'b10:begin
                            Bits_Sel = 4'b0010;
                            result_mem = {{24{1'b0}},data_from_ram[15:8]};
                        end
                        2'b11:begin
                            Bits_Sel = 4'b0001;
                            result_mem = {{24{1'b0}},data_from_ram[7:0]};
                        end                        
                        default: begin
                            Bits_Sel = 4'b1111;
                            result_mem = 0;
                        end
                    endcase
                end

                `EXE_LHU_OP:begin
                    wr_en_reg = `READ;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    case (ram_addr_i[1:0])
                        2'b00:begin//00
                            Bits_Sel = 4'b1100;
                            result_mem = {{16{1'b0}},data_from_ram[31:16]};
                        end
                        2'b10:begin//10
                            Bits_Sel = 4'b0011;
                            result_mem = {{24{1'b0}},data_from_ram[15:0]};
                        end                    
                        default: begin
                            Bits_Sel = 4'b1111;
                            result_mem = 0;
                        end
                    endcase
                end

                `EXE_LH_OP:begin
                    wr_en_reg = `READ;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    case (ram_addr_i[1:0])
                        2'b00:begin//末尾都是0
                            Bits_Sel = 4'b1100;
                            result_mem = {{16{data_from_ram[31]}},data_from_ram[31:16]};
                        end
                        2'b10:begin//10
                            Bits_Sel = 4'b0011;
                            result_mem = {{16{data_from_ram[15]}},data_from_ram[15:0]};
                        end                    
                        default: begin
                            Bits_Sel = 4'b1111;
                            result_mem = 0;
                        end
                    endcase
                end

                `EXE_LW_OP:begin
                    wr_en_reg = `READ;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    Bits_Sel = 4'b1111;
                    result_mem = data_from_ram;
                end
                
                `EXE_LWL_OP:begin//由于GPR一共只有32位，因此L意为从左开始写，往右边写 4-n
                    wr_en_reg = `READ;
                    ram_en = 1;
                    ram_addr_o = {ram_addr_i[31:2],2'b00};//对齐
                    Bits_Sel = 4'b1111;
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            result_mem = data_from_ram[31:0];                            
                        end
                        2'b01:begin
                            result_mem = {data_from_ram[23:0],num2[7:0]};                            
                        end
                        2'b10:begin
                            result_mem = {data_from_ram[15:0],num2[15:0]};                            
                        end
                        2'b11:begin
                            result_mem = {data_from_ram[7:0],num2[23:0]};                            
                        end                                                                        
                        default:begin
                            result_mem = 0;
                        end 
                    endcase
                end

                `EXE_LWR_OP:begin//相应的，R意为从右开始写，往左边写 n+1
                    wr_en_reg = `READ;
                    ram_en = 1;
                    ram_addr_o = {ram_addr_i[31:2],2'b00};//对齐
                    Bits_Sel = 4'b1111;
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            result_mem = {num2[31:8],data_from_ram[31:24]};                            
                        end
                        2'b01:begin
                            result_mem = {num2[31:16],data_from_ram[31:16]};                            
                        end
                        2'b10:begin
                            result_mem = {num2[31:24],data_from_ram[31:8]};                            
                        end
                        2'b11:begin
                            result_mem = data_from_ram;                            
                        end                                                                        
                        default:begin
                            result_mem = 0;
                        end 
                    endcase
                end
//**********************************************STORE************************************
                `EXE_SB_OP:begin
                    wr_en_reg = `WRITE;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    data_to_ram = {num2[7:0],num2[7:0],num2[7:0],num2[7:0]};
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            Bits_Sel = 4'b1000;
                        end
                        2'b01:begin
                            Bits_Sel = 4'b0100;
                        end
                        2'b10:begin
                            Bits_Sel = 4'b0010;
                        end
                        2'b11:begin
                            Bits_Sel = 4'b0001;
                        end                        
                        default: begin
                            Bits_Sel = 4'b0000;
                        end
                    endcase
                end

                `EXE_SH_OP:begin
                    wr_en_reg = `WRITE;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    data_to_ram = {num2[15:0],num2[15:0]};                    
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            Bits_Sel = 4'b1100;
                        end
                        2'b10:begin
                            Bits_Sel = 4'b0011;
                        end                    
                        default: begin
                            Bits_Sel = 4'b0000;
                        end
                    endcase
                end

                `EXE_SW_OP:begin
                    wr_en_reg = `WRITE;
                    ram_en = 1;
                    ram_addr_o = ram_addr_i;
                    Bits_Sel = 4'b1111;
                    data_to_ram = num2;
                end


                `EXE_SWL_OP:begin//内存地址连续，L是往左边写，往ram_addr_o中往左边写，从高位地址开始写低位数据 大端
                    wr_en_reg = `WRITE;
                    ram_en = 1;
                    ram_addr_o = {ram_addr_i[31:2],2'b00};
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            data_to_ram = num2;
                            Bits_Sel = 4'b1111;                            
                        end
                        2'b01:begin
                            data_to_ram = {8'b0,num2[31:8]};
                            Bits_Sel = 4'b0111;                         
                        end
                        2'b10:begin
                            data_to_ram = {16'b0,num2[31:15]};
                            Bits_Sel = 4'b0011;                          
                        end
                        2'b11:begin
                            data_to_ram = {24'b0,num2[31:24]}; 
                            Bits_Sel = 4'b0001;
                        end                                                                        
                        default:begin
                            Bits_Sel = 0;
                        end 
                    endcase
                end

                `EXE_SWR_OP:begin//内存地址连续，R是往左边写，往ram_addr_o中往右边边写，从低位地址开始写高位数据 大端
                    wr_en_reg = `WRITE;
                    ram_en = 1;
                    ram_addr_o = {ram_addr_i[31:2],2'b00};
                    case (ram_addr_i[1:0])
                        2'b00:begin
                            data_to_ram = {num2[7:0],24'b0};
                            Bits_Sel = 4'b1000;                            
                        end
                        2'b01:begin
                            data_to_ram = {num2[15:0],16'b0};
                            Bits_Sel = 4'b1100;                         
                        end
                        2'b10:begin
                            data_to_ram = {num2[23:0],8'b0};
                            Bits_Sel = 4'b1110;                          
                        end
                        2'b11:begin
                            data_to_ram =  num2;
                            Bits_Sel = 4'b1111;
                        end                                                                        
                        default:begin
                            Bits_Sel = 0;
                        end 
                    endcase
                end

                `EXE_LL_OP:begin
                    wr_en_reg = `READ;//读
                    ram_en = 1;//ram有效
                    ram_addr_o = ram_addr_i;//存储地址
                    result_mem = data_from_ram;
                    Bits_Sel = 4'b1111;//读出一个字节
                    LLbit_data_o = 1;//写一个1表示占用
                    LLbit_en_o = 1;//使用LLbitReg
                end

                `EXE_SC_OP:begin
                    if(LLbit_data_i)begin
                        wr_en_reg = `WRITE;//写
                        ram_en = 1;//ram有效
                        ram_addr_o = ram_addr_i;//存储地址
                        result_mem = 32'b1;//向rt中写入一个1
                        data_to_ram = num2;//向存储地址处写入一个rt内的值
                        Bits_Sel = 4'b1111;//存储一个字
                        LLbit_data_o = 0;//占用结束
                        LLbit_en_o = 1;//使用LLbitReg                        
                    end
                    else begin//向rt中写0
                        result_mem = 32'b0;
                    end
                    
                end                
                default: begin
                end
            endcase
        end
    end
endmodule