`timescale 1ns / 1BC
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.12.2016 19:59:07
// Design Name: 
// Module Name: gameTop
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


module gameTop(
    input logic clk, BCdata,
    output logic hs, vs, [7:0] rgb,
    output logic BCclk, BCcommand, BCattention, [7:0] BCkeys,
    output logic [7:0] LEDout, audio_output, [23:1] ram_address,
    inout logic [15:0] ram_data,
    output logic [15:0] indata, memrdy, ram_clk, ram_adv, ram_cre, ram_ce, ram_oe, ram_we, ram_lb, ram_ub);
    
    //game logic registers
    
    reg [23:0] address;
    reg [7:0] LEDout;
    reg [7:0] rgb;
    reg [1:0] hitnote;
    reg [4:0] streak;
    reg [12:0] points;
    reg shownote;
    reg [9:0] hitdata; 
    reg [12:0] targetnode;
    
    //guitar registers  
    
    reg [2:0] dselect;
    reg [2:0] dstart;
    reg [2:0] dstrum;
    reg started;
    reg [10:0] guitarcounter;
    reg guitarclock;
    
    //sound registers
    
    reg [11:0] pwmcount;
    reg [15:0] pwm_input;
    
    //vga registers
    
    reg [31:0] count;
    reg [8:0] pixelcount;
    reg [15:0] beatcount;
    reg [3:0] ncount;
    reg [8:0] ncounter;
    reg [7:0] fcount;  //distance between buttons 
    reg [8:0] fcounter;
    reg [10:0] fline;   //new line to be drawn
    reg [15:0] bcount;  //beat count
    reg clk_half;   //25 MHz
    
    //local memory registers
    
    reg readmem;
    
    //parameters
    
    parameter bpm = 346;    //173*2
    parameter vpb = 64;     //pixel per beat
    parameter fretstart = 60; //startpoint
    parameter hitlength = 360; // scoreboard
    parameter fretlength = 420; //length of board
    parameter pwmfull = 1563; // 50 MHz/32
    
    //internal wires 
    
    logic [9:0] notedata; //for vga connection
    logic select_press = (dselect[2:1] == 2'b01);
    logic start_press = (dstart[2:1] == 2'b01);
    logic strum = (dstrum[2:1] == 2'b01);
    logic blank;
    logic [10:0] hcount;
    logic [10:0] vcount;
    
    //some sub-modules
    
    songData bram(clk, targetnode, notedata);
    vgaTop vga(.rst(1'b0),.pixel_clk(clk_half),.HS(hs),.VS(vs),.hcount(hcount),.vcount(vcount),.blank(blank));
    buttonController guitar(guitarclock,BCkeys,BCclk,BCcommand,BCattention,BCdata);
    songsync ss(clk,started,pwm_input,audio_output);
    counter RAM_module(1'b0,clk_half,address,indata,memrdy,ram_clk,ram_adv,ram_cre,ram_ce,ram_oe,ram_we,ram_lb,ram_ub,ram_data,ram_address);
    
    //initializations of the variables
    
    initial begin
        clk_half <= 0;
        beatcount <= 0;
        pixelcount <= vpb/2;
        bcount <= 0;
        count <= 0;
        started <= 0;
        address <= 0;
        readmem <= 0;
        pwmcount <= 0;
        pwm_input <= 0;
        hitnote <= 0;
        streak <= 0;
        points <= 0;
        targetnote <= 0;
        hitdata <= 0;
    end
    
    //where magic is about to happen
    
    always_ff @(posedge clk) begin
        clk_half = ~clk_half;
        if(pwmcount == 1 && started) begin
            readmem <= 1;
            address <= address + 1'b1;
        end
        //waits for 3 cycles
        
        //reads file
        if(pwmcount < 11 && pwmcount > 1 && memrdy && readmem) begin
            readmem <= 0;
            pwm_input[15:0] <= indata[15:0];
            //if pwm_input is negative, following block takes the 2's complement
            if(pwm_input[15]) begin
                pwm_input <= ~pwm_input;
                pwm_input <= pwm_input + 1'b1;
                pwm_input <= 16'b1000000000000000 - pwm_input;
            end
            //if it is positive
            else pwm_input <= pwm_input + 16'b1000000000000000;
        end
        
        pwmcount = pwmcount + started;
        
        if(pwmcount > pwmfull)  pwmcount <= 0;
        //reset
        if(select_press) begin
            address <= 0;
            readmem <= 0;
            pwmcount <= 0;
            pwm_input <= 0;
        end
    end
    
    always_ff @(posedge clk_half) begin
        if(beatcount == 1150)   started <= 0;
        //user input timer sync
        guitarcounter <= guitarcounter + 1'b1;
        if(guitarcounter == 25) begin
            guitarcounter <= 0;
            guitarclock = ~guitarclock;
        end
        
        LEDout[7:5] <= beatcount[2:0];
        LEDout[4:0] <= notedata [4:0];
        dstrum[1:0] <= dstrum[1:0];
        dstrum[2] <= BCkeys[2];
        dstart[1:0] <= dstart[1:0];
        dstart[2] <= BCkeys[1];
        dselect[1:0] <= dselect[1:0];
        dselect[2] <= BCkeys[0];
        count <= count + started;
        
        //if count equals to the cycles per vline of movement moves the display down
        if(count == 25000000/bpm/vpb) begin
            count <= 0;
            pixelcount <= pixelcount + 1'b1;
            //if it reaches bottom of the screen it hides the display below the screen
            if(pixelcount == vpb) begin
                hitnote[1] <= hitnote[0];
                hitnode[0] <= 0;
                pixelcount <= 0;
                beatcount <= beatcount + 1'b1;
            end
        end
        //if song plays
        if(started && hitdata[4:0] != 5'b00000) begin
            //and player doesn't presses the button
            if(pixelcount >7 && pixelcount<57 && !hitnote[0]) begin
                //if notes match
                if(BCkeys[7:3] == hitdata[4:0] && strum) begin 
                    hitnote[0] <= 1;
                    if(streak < 15) streak <= streak + 1'b1;
                    if(streak == 15) points <= points + 3'b100;
                    else if(streak > 9) points <= points + 2'b11;
                    else if(streak > 4) points <= points + 2'b10;
                    else points <= points + 1'b1;
                end
                //if player presses(!) on the wrong buttons
                else if(pixelcount==56) streak <= 0;
            end
        end
        //if it is a blank note
        else if(started) begin
            if(strum) streak <= 0;
        end
        
        //VGA configuration
        
        //reset counters before the display begins
        if(hcount == 0 && vcount == 0) begin
            ncounter <= 0;
            ncount <= 4'b0101;
            fcounter <= 0;
            fcount <= vpb/2;
            fline <= fretstart + pixelcount/2;
            bcount <= beatcount;
            targetnode <= beatcount + 3'b111;
        end
        
        if(hcount == 0 && vcount > fretstart) begin
            ncounter <= ncounter + 1'b1;
            fcounter <= fcounter + 1'b1;
            if(ncounter == fretlength/5) begin
                ncounter <= 0;
                ncount <= ncount + 1'b1;
            end
            if(fcounter == hitlength/(vpb/2)) begin
                fcounter <= 0;
                fcount <= fcount + 1'b1;
                if(vcount < fline +1'b1) fline <= fline+1'b1;
            end                
        end
        
        //now its time to set the new line
        if(vcount > fline + fcount/2) begin
            bcount <= bcount + 1'b1;
            targetnote <= targetnote - 1'b1;
            fline <= fline + fcount;
        end
        
        //note calculation
        if(targetnote == beatcount && pixelcount < 7) hitdata[9:0] <= notedata[9:0];
        if(targetnote == beatcount) shownote <= ~hitnote[0];
        else if(targetnote == beatcount-1'b1) shownote <= ~hitnote[1];
        else shownote <= 1'b1;
        
        //VGA
        
        if(blank) rgb <=0;
        else begin
            //draw score
            rgb <= 8'b01001001; //gray
            if(-4*(vcount - 180) <= 15*(hcount - 56) && -4*(vcount - 180) > 15*(hcount - 76) && vcount > 59 && vcount < 375) begin
                rgb <= 8'b00000000;
                if(-4*(vcount - 180) <= 15*(hcount - 57) && -4*(vcount - 180) > 15*(hcount - 75) && vcount > 60 && vcount < 374) begin
                    if(vcount*10 > 3740 - points*2 || points > 1670) rgb <= 8'b00010100;//green
                    else rgb <= 8'b11111100; //yellow
                end
            end
            //player's bar
            if(-4*(vcount-180) <= 15*(hcount - 80) && 4*(vcount - 180) > 15*(hcount - 241) && vcount > 59) begin
                rgb <= 8'b01100100; //brown
                if(vcount == fline && bcount[0] == 1) rgb <= 8'b11011011;//white
                if(vcount == fline && bcount[0] == 0) rgb <= 8'b01101110;//grey
                //draw notes
                if(vcount > fline - ncount && vcount < fline + ncount && shownote) begin
                    if (-4*(vcount - 180) <= 15*(hcount - 84) && -4*(vcount - 180) > 25*(hcount - 109) && notedata[4]) rgb <= 8'b00011100;
                    if (-4*(vcount - 180) <= 25*(hcount - 116) && -4*(vcount - 180) > 75*(hcount - 141) && notedata[3]) rgb <= 8'b11100000;
                    if (-4*(vcount - 180) <= 75*(hcount - 148) && 4*(vcount - 180) > 75*(hcount - 173) && notedata[2]) rgb <= 8'b11111100;
                    if (4*(vcount - 180) <= 75*(hcount - 180) && 4*(vcount - 180) > 25*(hcount - 205) && notedata[1]) rgb <= 8'b00000011;
                    if (4*(vcount - 180) <= 25*(hcount - 212) && 4*(vcount - 180) > 15*(hcount - 237) && notedata[0]) rgb <= 8'b11101100;
                end
                //hitbar
                if(vcount > 344 && vcount < 437) rgb <= 8'b11111111;//top
                if(vcount > 404 && vcount < 407) rgb <= 8'b11111111;//bottom
                if(vcount > 409 && vcount < 432) begin
                    if (-4*(vcount - 180) <= 15*(hcount - 84) && -4*(vcount - 180) > 25*(hcount - 109) && BCkeys[7]) rgb <= 8'b00011100;
                    if (-4*(vcount - 180) <= 25*(hcount - 116) && -4*(vcount - 180) > 75*(hcount - 141) && BCkeys[6]) rgb <= 8'b11100000;
                    if (-4*(vcount - 180) <= 75*(hcount - 148) && 4*(vcount - 180) > 75*(hcount - 173) && BCkeys[5]) rgb <= 8'b11111100;
                    if (4*(vcount - 180) <= 75*(hcount - 180) && 4*(vcount - 180) > 25*(hcount - 205) && BCkeys[4]) rgb <= 8'b00000011;
                    if (4*(vcount - 180) <= 25*(hcount - 212) && 4*(vcount - 180) > 15*(hcount - 237) && BCkeys[3]) rgb <= 8'b11101100;
                end    
                //draw vertical lines
                if (-4*(vcount - 180) <= 15*(hcount - 80)  && -4*(vcount - 180) > 15*(hcount - 81)) rgb <= 8'b11111111; //white
                if (-4*(vcount - 180) <= 25*(hcount - 112) && -4*(vcount - 180) > 25*(hcount - 113)) rgb <= 8'b11111111;
                if (-4*(vcount - 180) <= 75*(hcount - 144) && -4*(vcount - 180) > 75*(hcount - 145)) rgb <= 8'b11111111;
                if (4*(vcount - 180) <= 75*(hcount - 176)  && 4*(vcount - 180) > 75*(hcount - 177)) rgb <= 8'b11111111;
                if (4*(vcount - 180) <= 25*(hcount - 208)  && 4*(vcount - 180) > 25*(hcount - 209)) rgb <= 8'b11111111;
                if (4*(vcount - 180) <= 15*(hcount - 240)  && 4*(vcount - 180) > 15*(hcount - 241)) rgb <= 8'b11111111;             
            end
            if (4*(vcount - 180) <= 15*(hcount - 244) && 4*(vcount - 180) > 15*(hcount - 264) && vcount > 253 && vcount < 375) begin
                rgb = 8'b00000000;
                if (4*(vcount - 180) <= 15*(hcount - 245) && 4*(vcount - 180) > 15*(hcount - 263) && vcount > 254 && vcount < 374) begin
                    if (streak == 15) rgb = 8'b01100011; // purple
                    else if (streak > 9) rgb = 8'b01001111; // light blue
                    else if (streak > 4) rgb = 8'b00111101; // light green
                    else rgb = 8'b11111101; // light yellow
                // draw streak
                    if (vcount < 375-streak*8) rgb = 8'b01001001;
                end
            end
        end
    end  
endmodule
