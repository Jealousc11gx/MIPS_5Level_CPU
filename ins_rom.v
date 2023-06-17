//指令存储器 只读
`include "define.v"
module ins_rom (
    input wire en,//指令使能信号
    input wire [`DataWidth-1:0] pc,

    output reg [`DataWidth-1:0] rom_data
);

    //定义rom存储器大小
    reg [`INS_ADDR_BUS] rom_mem [0:`INS_ROM_NUM-1];//32 2^17

    //使用文件ins_rom.data初始化rom
    initial $readmemh ("rom_data.data",rom_mem);

    //加入给出的pc为 0x4 一共32位 也就是 00000000 00000000 00000000 00000100 
    //                                   Byte     Byte     Byte     Byte
    //                                                 word
    //按字节寻址
    //              0x8                00000000 00000000 00000000 00001000

    //对应 rom_mem[1] rom_mem[2]       也就是4/4 = 1 | 8/4 = 2
    //右移两位 一共有32位     右移两位即是 往左边取2位
    always @(*) begin
        if(en == 0)begin
            rom_data = 0;
        end
        else begin
            rom_data = rom_mem[pc[`INS_ROM_NUM_LOG2+1:2]]; //pc[`INS_ROM_NUM_LOG2-1:0] = 实际位数，也就等于0x4 实际上等价于pc>>2
        end
    end


endmodule