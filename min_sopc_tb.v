`timescale 1ns/1ps

module min_sopc_tb ();
    reg clock_50;
    reg rst_n;

    initial begin
        clock_50 = 1'b0;
        forever #10 clock_50 = ~clock_50;
    end

    initial begin
        rst_n = 0;
        #195 rst_n = 1;
        #10000;
        $finish;
    end

    initial begin
        $fsdbDumpfile("test.fsdb");
        $fsdbDumpvars(0,"min_sopc_tb","+mda");
    end

    min_sopc  u_min_sopc (
    .clk                     ( clock_50   ),
    .rst_n                   ( rst_n   )
);
endmodule
