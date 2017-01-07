`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.12.2016 04:15:20
// Design Name: 
// Module Name: songsync
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
module songsync(input logic play,clk_in,[15:0] PWM_in, output logic audio_out);
    reg [16:0] PWM_accumulator;  
    always_ff @(posedge clk_in) begin
        PWM_accumulator[16:0] <= PWM_accumulator[15:0] + PWM_in;
        audio_out <= PWM_accumulator[16] && play;
        PWM_accumulator[16] <= 0;
    end
endmodule
