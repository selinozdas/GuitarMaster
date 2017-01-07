`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.12.2016 03:50:14
// Design Name: 
// Module Name: buttonController
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


module buttonController(input logic clk, data, output logic command, attention, [7:0] keys);
    //registers
    reg outclk;
    reg command;
    reg attention;
    reg [7:0] keys;
    
    reg [3:0] packetstate;
    reg [3:0] gotostate;
    reg [3:0] bytecounter;
    reg [3:0] bitcounter;
    reg [10:0] waitcounter;
    

    reg [7:0] commandshift;// values for shift register
    reg [7:0] datashift; // data shift register
    
    initial begin
        packetstate <= 4'b1111;
        gotostate   <= 4'b0001;
        bytecounter <= 5'b00000; // starts at 0, every packet state adds one first, so counting starts at 1.
        bitcounter <=  4'b0000;
        waitcounter <= 0;
    end
    
    always_ff @ (posedge outclk) begin
        datashift[0] <= data;
        datashift[7:1] <= datashift[7:1];
    end
    
    always @ (posedge clk) begin
        // main state machine
        case (packetstate)
        
            4'b1111: begin // wait state 
                waitcounter <= waitcounter + 1;
                if (waitcounter < 2000) begin
                    attention <= 1;
                    command <= 1;
                    bitcounter <= 0;
                end else begin
                    waitcounter <= 0;
                    packetstate <= gotostate;
                    attention <= 0;
                end
            end
            
            4'b1110: begin // pause 
                bitcounter <= bitcounter + 1;
                if (bitcounter > 13) begin
                    bitcounter <= 0;
                    packetstate <= gotostate;
                end
            end
            
            4'b0000: begin 
                outclk <= ~outclk; // 250 kHz
                command <= commandshift[bitcounter];
                bitcounter <= bitcounter + outclk;
                if (bitcounter == 8) begin
                    packetstate <= 4'b1110;
                    bitcounter <= 0;
                end
            end
            
            4'b0001: begin
                bytecounter <= bytecounter + 1;
                packetstate <= 4'b0000; 
                case (bytecounter)
                    5'b00001: commandshift <= 8'h01; // 1e
                    5'b00010: commandshift <= 8'h43; // 2
                    5'b00011: commandshift <= 8'h00; // 3
                    5'b00100: commandshift <= 8'h01; // 4
                    5'b00101: commandshift <= 8'h00; // 5
                    5'b00110: begin
                        packetstate <= 4'b1111;
                        gotostate   <= 4'b0010; // go to next packet
                        bytecounter <= 5'b00000;
                    end
                endcase
                //
            end
            
            4'b0010: begin
                bytecounter <= bytecounter + 1; 
                gotostate <= 4'b0010;
                packetstate <= 4'b0000; 
                case (bytecounter)
                    5'b00001: commandshift <= 8'h01; // 1
                    5'b00010: commandshift <= 8'h44; // 2
                    5'b00011: commandshift <= 8'h00; // 3
                    5'b00100: commandshift <= 8'h01; // 4
                    5'b00101: commandshift <= 8'h03; // 5
                    5'b00110: commandshift <= 8'h00; // 6
                    5'b00111: commandshift <= 8'h00; // 7
                    5'b01000: commandshift <= 8'h00; // 8
                    5'b01001: commandshift <= 8'h00; // 9
                    5'b01010: begin // done
                        packetstate <= 4'b1111;
                        gotostate   <= 4'b0011;
                        bytecounter <= 5'b00000;
                    end
                endcase
                //
            end
            
            4'b0011: begin
                bytecounter <= bytecounter + 1;
                gotostate <= 4'b0011;
                packetstate <= 4'b0000; 
                case (bytecounter)
                    5'b00001: commandshift <= 8'h01; // 1
                    5'b00010: commandshift <= 8'h43; // 2
                    5'b00011: commandshift <= 8'h00; // 3
                    5'b00100: commandshift <= 8'h00; // 4
                    5'b00101: commandshift <= 8'h5A; // 5
                    5'b00110: commandshift <= 8'h5A; // 6
                    5'b00111: commandshift <= 8'h5A; // 7
                    5'b01000: commandshift <= 8'h5A; // 8
                    5'b01001: commandshift <= 8'h5A; // 9
                    5'b01010: begin
                        packetstate <= 4'b1111;
                        gotostate   <= 4'b0100;
                        bytecounter <= 5'b00000;
                    end
                endcase
                //
            end
            
            4'b0100: begin
                bytecounter <= bytecounter + 1;
                packetstate <= 4'b0000; 
                gotostate <= 4'b0100;
                case (bytecounter)
                    5'b00001: commandshift <= 8'h01; // 1
                    5'b00010: commandshift <= 8'h42; // 2
                    5'b00011: commandshift <= 8'h00; // 3
                    5'b00100: commandshift <= 8'h00; // 4
                    5'b00101: begin
                        commandshift <= 8'h00; // 5
                        keys[0] <= ~datashift[0];						// select
                        keys[1] <= ~datashift[3];						// start
                        keys[2] <= ~datashift[4] | ~datashift[6];	// up or down
                    end
                    5'b00110: begin
                        commandshift <= 8'h00; // 6
                        keys[3] <= ~datashift[7];						// orange
                        keys[4] <= ~datashift[6];						// blue
                        keys[5] <= ~datashift[4];						// yellow
                        keys[6] <= ~datashift[5];						// red
                        keys[7] <= ~datashift[1];						// green
                    end
                    5'b00111: begin
                        commandshift <= 8'h00; // 7
                    end					
                    5'b01000: begin
                        commandshift <= 8'h00; // 8
                    end
                    5'b01001: begin
                        commandshift <= 8'h00; // 9
                    end
                    5'b01010: begin // done
                        packetstate <= 4'b1111;
                        gotostate   <= 4'b0100;
                        bytecounter <= 5'b00000;
                    end					
                endcase
            end    
        endcase       
    end
endmodule