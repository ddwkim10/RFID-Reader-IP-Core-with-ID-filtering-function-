/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_timer.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.05.19 Created
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "timescale.v"


module matrix_timer(Clk, Reset, TimerIn, TimerStart, TimedOut);
// TimerIn .GT. 1

parameter Tp = 1;

input Clk;
input Reset;
input [15:0] TimerIn;
input TimerStart; 
output TimedOut;

reg [15:0] Timer;

wire TimerCntGT2;
wire TimerCntEQ2;
assign TimerCntGT2 = TimerStart & (Timer > 16'h0002);
assign TimerCntEQ2 = TimerStart & (Timer == 16'h0002);

reg TimerStart_q;

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      TimerStart_q <= #Tp 1'b0;
   else
      TimerStart_q <= #Tp TimerStart;
end

wire TimerLoad;
assign TimerLoad = (TimerStart & ~TimerStart_q); 

wire TimerClear;
assign TimerClear = (~TimerStart & TimerStart_q); 

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      begin
         Timer <= #Tp 16'h0000;
      end
   else
   if(TimerLoad)
      begin
         Timer <= #Tp TimerIn;
      end
   else
   if(TimerCntGT2)
      begin
         Timer <= #Tp Timer - 1;
      end
   else
   if(TimerClear)
      begin
         Timer <= #Tp 16'h0000; 
      end
end

assign TimedOut = TimerCntEQ2;

endmodule
