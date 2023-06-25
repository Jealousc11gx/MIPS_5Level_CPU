`include "define.v"
module ram (
    input wire clk,
    input wire wr_en,
    input wire ram_en,
    input wire [3:0] Bits_Sel,
    input wire [`DataWidth-1:0] ram_addr_i,//传进来的地址按字节寻址，要乘一个4，对应左移两位
    input wire [`DataWidth-1:0] data_to_ram,

    output reg [`DataWidth-1:0] data_from_ram
);
    //定义一些寄存器，数据位宽8位，地址位宽17位，总大小128K Word
    reg [7:0] RAM0 [0:`RAM_NUM-1];
    reg [7:0] RAM1 [0:`RAM_NUM-1];
    reg [7:0] RAM2 [0:`RAM_NUM-1];
    reg [7:0] RAM3 [0:`RAM_NUM-1];

    //写功能，采用时序逻辑
    always @(posedge clk ) begin
        if(ram_en == 0)begin
            //do nothing
        end
        else begin
            if(wr_en == `WRITE)begin
                if(Bits_Sel[3] == 1)begin
                    RAM3[ram_addr_i[`RAM_NUM_LOG2+1:2]] <= data_to_ram[31:24];
                end
                if(Bits_Sel[2] == 1)begin
                    RAM2[ram_addr_i[`RAM_NUM_LOG2+1:2]] <= data_to_ram[23:16];
                end
                if(Bits_Sel[1] == 1)begin
                    RAM1[ram_addr_i[`RAM_NUM_LOG2+1:2]] <= data_to_ram[15:8];
                end
                if(Bits_Sel[0] == 1)begin
                    RAM0[ram_addr_i[`RAM_NUM_LOG2+1:2]] <= data_to_ram[7:0];
                end
            end
        end
    end

    //读功能，采用组合逻辑
    always @(*) begin
        if(ram_en == 0)begin
            data_from_ram = 0;
        end
        else if(wr_en == `READ) begin//读功能
                data_from_ram ={RAM3[ram_addr_i[`RAM_NUM_LOG2+1:2]],
                                RAM2[ram_addr_i[`RAM_NUM_LOG2+1:2]],
                                RAM1[ram_addr_i[`RAM_NUM_LOG2+1:2]],
                                RAM0[ram_addr_i[`RAM_NUM_LOG2+1:2]]};
            end
        else begin
            data_from_ram = 0;
        end
    end
endmodule