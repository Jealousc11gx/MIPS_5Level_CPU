`include "define.v"

module min_sopc (
    input wire clk,
    input wire rst_n
);
    wire en_rom;
    wire [`INS_ADDR_BUS] rom_addr;
    wire [`DataWidth-1:0] rom_data;

    wire [`DataWidth-1:0] data_from_ram;

    wire wr_en;
    wire ram_en;
    wire [3:0] Bits_Sel;
    wire [`INS_ADDR_BUS] ram_addr;
    wire [`DataWidth-1:0] data_to_ram;

    wire timer_interrupt;
    wire [5:0] interrupt;

    assign interrupt = {5'b00000, timer_interrupt};

    MIPS_CPU  u_MIPS_CPU (
        .clk                     ( clk        ),
        .rst_n                   ( rst_n      ),
        .rom_data                ( rom_data   ),
        .interrupt               ( interrupt  ),

        .timer_interrupt         (timer_interrupt  ),

        .data_from_ram           ( data_from_ram   ),

        .en_rom                  ( en_rom     ),
        .rom_addr                ( rom_addr   ),

        .wr_en                   ( wr_en           ),
        .ram_en                  ( ram_en          ),
        .Bits_Sel                ( Bits_Sel        ),
        .ram_addr_o              ( ram_addr        ),
        .data_to_ram             ( data_to_ram     )       
    );

    ins_rom  u_ins_rom (
        .en                      ( en_rom     ),
        .pc                      ( rom_addr   ),

        .rom_data                ( rom_data    )
    );

    ram  u_ram (
        .clk                     ( clk             ),
        .wr_en                   ( wr_en           ),
        .ram_en                  ( ram_en          ),
        .Bits_Sel                ( Bits_Sel        ),
        .ram_addr_i              ( ram_addr        ),
        .data_to_ram             ( data_to_ram     ),

        .data_from_ram           ( data_from_ram   )
);
endmodule