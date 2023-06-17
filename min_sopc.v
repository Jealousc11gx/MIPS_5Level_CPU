`include "define.v"

module min_sopc (
    input wire clk,
    input wire rst_n
);
    wire en_rom;
    wire [`INS_ADDR_BUS] rom_addr;
    wire [`DataWidth-1:0] rom_data;


    MIPS_CPU  u_MIPS_CPU (
        .clk                     ( clk        ),
        .rst_n                   ( rst_n      ),
        .rom_data                ( rom_data   ),

        .en_rom                  ( en_rom     ),
        .rom_addr                ( rom_addr   )
    );



    ins_rom  u_ins_rom (
        .en                      ( en_rom     ),
        .pc                      ( rom_addr   ),

        .rom_data                ( rom_data    )
    );
endmodule