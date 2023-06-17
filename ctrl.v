`include "define.v"

module ctrl (
    input wire StopReq_from_decode,
    input wire StopReq_from_ex,
    input wire rst_n,

    output reg [5:0]stop//包括pc是否不变，以及每个阶段是否保持不变 
);
    always @(*) begin
        if(!rst_n) begin
            stop = 6'b000000;
        end
        else if(StopReq_from_decode == `Stop) begin
            stop = 6'b000111;
        end
        else if(StopReq_from_ex == `Stop) begin
            stop = 6'b001111;
        end
        else begin
            stop = 6'b000000;
        end
    end
endmodule