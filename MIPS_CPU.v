//顶层模块
//快捷键例化 ctrl i+s
`include "define.v"

//这个版本中，增加了Hi，Lo特殊寄存器模块
//为了解决mflo 和mfhi的数据相关问题，实现了访存和会写阶段的数据回写
//因此在执行模块上增加了来自访存和回写模块的接口
//同时，因为考虑到后续对hi和lo寄存器进行的操作，因此需要加入是否写特殊寄存器，以及写入什么数据 类似gpr的操作

//命名规范更改为每个阶段中实现的模块命名为纯输入输出，而中间信号带上具体的阶段

module MIPS_CPU (
    input wire clk,
    input wire rst_n,
    input wire [`Ins_Addr-1:0] rom_data,//输入指令

    output wire en_rom,
    output wire [`Ins_Addr-1:0] rom_addr //输出指令地址
);


    //*********************************pc信号***************************

    wire  [`DataWidth-1:0]  pc;//输出地址和使能信号连接到外部的rom 读出指令

    //wire [`StopWidth] pc_stop;

    assign rom_addr = pc;
    //assign pc_stop = stop;

    //*****************************pc_de信号****************************

    wire  [`DataWidth-1:0]  pc_if;
    wire  [`DataWidth-1:0]  rom_ins_if;

    //wire [`StopWidth] pc_de_stop;
    //assign pc_de_stop = stop;

    //*****************************Regfile信号**************************


    wire  [`DataWidth-1:0]  rd1_data;
    wire  [`DataWidth-1:0]  rd2_data;


    //*******************************decode信号************************

    //给到寄存器的输入
    wire  en_rd1;
    wire  en_rd2;
    wire  [`Reg_AddrBus] rd1_addr;
    wire  [`Reg_AddrBus] rd2_addr;

    //给到de_ex的输入
    wire  [`DataWidth-1:0]  num1;
    wire  [`DataWidth-1:0]  num2;
    wire  [7:0]  op;
    wire  [2:0]  sel;
    wire  en_wd;
    wire  [4:0]  desReg_addr;

    //给到ctrl输出

    wire StopReq_from_decode;


    //********************************de_ex信号***********************



    wire  [7:0]  op_ex;
    wire  [2:0]  sel_ex;
    wire  [`DataWidth-1:0]  num1_de_ex;
    wire  [`DataWidth-1:0]  num2_de_ex;
    wire  [`Reg_AddrBus] desReg_addr_de_ex;
    wire  en_wd_de_ex;

    //wire [`StopWidth] stop_de_ex;
    //assign stop_de_ex = stop;


    //**********************************ex信号*************************


    wire  en_wd_ex;
    wire  [`Reg_AddrBus] desReg_addr_ex;
    wire  [`DataWidth-1:0]  result_ex;
    
    wire ex_en_hilo;
    wire [`DataWidth-1:0] ex_hi_o;
    wire [`DataWidth-1:0] ex_lo_o;

    //多周期指令计数器和中间数据

    wire [1:0] count_ex_o;
    wire [`DoubleDataWidth-1:0] hilo_tmp_o;

    wire StopReq_from_ex;

    //********************************ex_mem信号*********************

    wire  en_wd_ex_mem;
    wire  [`Reg_AddrBus] desReg_addr_ex_mem;
    wire  [`DataWidth-1:0]  result_ex_mem;

    wire mem_en_hilo;
    wire [`DataWidth-1:0] mem_hi_o;
    wire [`DataWidth-1:0] mem_lo_o;

    //wire [`StopWidth] stop_ex_mem;
    //assign stop_ex_mem = stop;

    //输入ex的多周期指令相关信息

    wire [1:0] count_ex_mem_o;
    wire [`DoubleDataWidth-1:0] hilo_tmp_ex_mem_o;

    //******************************mem信号**************************

    wire  en_wd_mem;
    wire  [`Reg_AddrBus] desReg_addr_mem;
    wire  [`DataWidth-1:0]  result_mem;

    wire en_hilo_mem;
    wire [`DataWidth-1:0] hi_o_mem;
    wire [`DataWidth-1:0] lo_o_mem;


    //***************************mem_wb信号*************************

    wire  [`DataWidth-1:0]  result_wb;
    wire  en_wb_wb;
    wire  [`Reg_AddrBus] desReg_addr_wb;

    wire wb_en_hilo;
    wire [`DataWidth-1:0] wb_hi_o;
    wire [`DataWidth-1:0] wb_lo_o;    

    //wire [`StopWidth] stop_mem_wb;
    //assign stop_mem_wb = stop;    

    //***************************hilo_reg信号*************************

    wire  [`DataWidth-1:0]  hi_i;
    wire  [`DataWidth-1:0]  lo_i;

    //***************************ctrl信号*************************

    wire [`StopWidth] stop;

    //****************************例化操作**************************
    pc  u_pc (
    .clk                     ( clk     ),
    .rst_n                   ( rst_n   ),
    .stop                    ( stop    ),

    .en                      ( en_rom  ),
    .pc                      ( pc      )
);
    assign rom_addr = pc;//输出信号即为pc


    pc_de  u_pc_de (
        .pc                      ( pc           ),
        .rom_ins                 ( rom_data     ),
        .clk                     ( clk          ),
        .rst_n                   ( rst_n        ),
        .stop                    ( stop         ),        

        .pc_if                   ( pc_if        ),
        .rom_ins_if              ( rom_ins_if   )
    );

    Regfile  u_Regfile (
        .clk                     ( clk        ),
        .rst_n                   ( rst_n      ),
        .rd1_addr                ( rd1_addr   ),
        .rd2_addr                ( rd2_addr   ),
        .en_rd1                  ( en_rd1     ),
        .en_rd2                  ( en_rd2     ),

        .en_wr                   ( en_wb_wb   ),//WB
        .wr_data                 ( result_wb  ),//WB
        .wr_addr                 ( desReg_addr_wb ),//WB

        .rd1_data                ( rd1_data   ),
        .rd2_data                ( rd2_data   )
    );


    decode  u_decode (
    .rst_n                   ( rst_n         ),
    .rd1_data                ( rd1_data      ),
    .rd2_data                ( rd2_data      ),
    .pc_ins                  ( rom_ins_if    ),
    .pc                      ( pc_if         ),
    //ex阶段数据回推
    .ex_en_wd                ( en_wd_ex          ),
    .ex_desReg_addr          ( desReg_addr_ex    ),
    .ex_result               ( result_ex         ),
    //mem阶段数据回推
    .mem_en_wd               ( en_wd_mem         ),
    .mem_desReg_addr         ( desReg_addr_mem   ),
    .mem_result              ( result_mem        ),
    
    //给到Regfile的输出
    .en_rd1                  ( en_rd1        ),
    .en_rd2                  ( en_rd2        ),
    .rd1_addr                (rd1_addr       ),
    .rd2_addr                (rd2_addr       ),

    //给ex的输出
    .num1                    ( num1          ),
    .num2                    ( num2          ),
    .op                      ( op            ),
    .sel                     ( sel           ),
    .en_wd                   ( en_wd         ),
    .desReg_addr             ( desReg_addr   ),

    //给到ctrl的输出
    .StopReq_from_decode     (StopReq_from_decode)
);



de_ex  u_de_ex (
    .clk                            ( clk                             ),
    .rst_n                          ( rst_n                           ),
    .op                             ( op                              ),
    .sel                            ( sel                             ),
    .num1                           ( num1                            ),
    .num2                           ( num2                            ),
    .en_wd                          ( en_wd                           ),
    .desReg_addr                    ( desReg_addr                     ),
    .stop                           ( stop                            ),


    .op_ex                          ( op_ex                           ),
    .sel_ex                         ( sel_ex                          ),
    .num1_ex                        ( num1_de_ex                      ),
    .num2_ex                        ( num2_de_ex                      ),
    .desReg_addr_ex                 (  desReg_addr_de_ex              ),
    .en_wd_ex                       ( en_wd_de_ex                     )
);


ex  u_ex (
    .rst_n                   ( rst_n      ),
    .op                      ( op_ex      ),
    .sel                     ( sel_ex     ),
    .num1                    ( num1_de_ex    ),
    .num2                    ( num2_de_ex    ),
    .en_wd                   ( en_wd_de_ex        ),
    .desReg_addr             ( desReg_addr_de_ex  ),

    .hi_i                    ( hi_i          ),
    .lo_i                    ( lo_i          ),

    .mem_hi_i                ( hi_o_mem      ),
    .mem_lo_i                ( lo_o_mem      ),
    .mem_en_hilo             ( en_hilo_mem   ),

    .wb_hi_i                 ( wb_hi_o       ),
    .wb_lo_i                 ( wb_lo_o       ),
    .wb_en_hilo              ( wb_en_hilo    ),

    .desReg_addr_ex          ( desReg_addr_ex),
    .en_wd_ex                ( en_wd_ex    ),
    .result                  ( result_ex   ),

    .en_hilo                 ( ex_en_hilo       ),
    .hi_o                    ( ex_hi_o          ),
    .lo_o                    ( ex_lo_o          ),

    //多周期指令，从ex_mem传回
    .hilo_tmp_i              ( hilo_tmp_ex_mem_o   ),
    .count_i                 ( count_ex_mem_o      ), 

    //传到ex_mem的信号
    .hilo_tmp_o              ( hilo_tmp_o        ),
    .count_o                 ( count_ex_o        ),
    .StopReq_from_ex         ( StopReq_from_ex   )
);


ex_mem  u_ex_mem (
    .clk                     ( clk          ),
    .rst_n                   ( rst_n        ),
    .en_wd                   ( en_wd_ex      ),
    .result                  ( result_ex       ),
    .desReg_addr             ( desReg_addr_ex),

    .ex_hi_i                 ( ex_hi_o         ),
    .ex_lo_i                 ( ex_lo_o         ),
    .ex_en_hilo_i            ( ex_en_hilo     ),
    .stop                    ( stop           ),//from ctrl    

    
    .en_wd_ex_mem               ( en_wd_ex_mem    ),
    .result_ex_mem              ( result_ex_mem   ),
    .desReg_addr_ex_mem         ( desReg_addr_ex_mem),

    .mem_hi_o                ( mem_hi_o        ),
    .mem_lo_o                ( mem_lo_o        ),
    .mem_en_hilo_o           ( mem_en_hilo     ),
    //from ex
    .hilo_tmp_i              ( hilo_tmp_o      ),
    .count_i                 ( count_ex_o      ),
    //to ex
    .hilo_tmp_o              ( hilo_tmp_ex_mem_o   ),
    .count_o                 ( count_ex_mem_o      )    
);


mem  u_mem (
    .rst_n                   ( rst_n        ),
    .en_wd                   ( en_wd_ex_mem ),
    .result                  ( result_ex_mem),
    .desReg_addr             (desReg_addr_ex_mem),

    .hi_i                    ( mem_hi_o         ),
    .lo_i                    ( mem_lo_o         ),
    .en_hilo_i               ( mem_en_hilo      ),

    .en_wd_mem               ( en_wd_mem    ),
    .result_mem              ( result_mem   ),
    .desReg_addr_mem         ( desReg_addr_mem),

    .hi_o                    ( hi_o_mem         ),
    .lo_o                    ( lo_o_mem         ),
    .en_hilo_o               ( en_hilo_mem      )    
);


mem_wb  u_mem_wb (
    .clk                            ( clk                             ),
    .rst_n                          ( rst_n                           ),
    .en_wb                          ( en_wd_mem                       ),
    .result                         ( result_mem                      ),
    .desReg_addr                    (desReg_addr_mem                  ),
    .stop                           ( stop                            ),    

    .mem_hi_i                       ( hi_o_mem                        ),
    .mem_lo_i                       ( lo_o_mem                        ),
    .mem_en_hilo_i                  ( en_hilo_mem                     ),    

    .result_wb                      ( result_wb                       ),
    .en_wb_wb                       ( en_wb_wb                        ),
    .desReg_addr_wb                 ( desReg_addr_wb                  ),

    .wb_hi_o                        ( wb_hi_o                            ),
    .wb_lo_o                        ( wb_lo_o                            ),
    .wb_en_hilo_o                   ( wb_en_hilo                         ) 
);

hilo_reg  u_hilo_reg (
    .clk                     ( clk       ),
    .rst_n                   ( rst_n     ),
    .en_hilo                 ( wb_en_hilo   ),
    .hi_i                    ( wb_hi_o      ),
    .lo_i                    ( wb_lo_o      ),

    .hi_o                    ( hi_i      ),
    .lo_o                    ( lo_i      )
);

ctrl  u_ctrl (
    .StopReq_from_decode     ( StopReq_from_decode   ),
    .StopReq_from_ex         ( StopReq_from_ex       ),
    .rst_n                   ( rst_n                 ),

    .stop                    ( stop                  )
);
endmodule
