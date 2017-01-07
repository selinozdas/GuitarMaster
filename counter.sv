`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.12.2016 04:22:06
// Design Name: 
// Module Name: counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module counter(input logic clk, rst,[23:0] addr, 
       output logic [15:0] dout, rdy, sram_clk, sram_adv, sram_cre, sram_ce, sram_oe, sram_we, sram_lb, sram_ub,
       inout logic [15:0] sram_data,
       output logic [23:1] sram_addr
    );
reg [2:0] state = 3'b000;
always_comb
    begin
        assign sram_clk = 0;
        assign sram_adv = 0;
        assign sram_cre = 0;
        assign sram_ce  = 0;
        assign sram_oe  = 0;
        assign sram_ub  = 0;
        assign sram_lb  = 0;
        assign sram_data = 16'hzzzz;
        assign sram_addr = {addr[23:1],1'b0};
        assign sram_we   = 1;
        assign rdy = (state == 3'b000);
    end
    always @(posedge clk) begin
        if (!rst) begin
            if (state == 3'b010) dout <= sram_data;
            if (state == 3'b010) state <= 3'b000;
            else state <= state + 1;
        end 
        else state <= 3'b000;
    end
endmodule
