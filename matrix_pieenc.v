/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_pieenc.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.05.02 Created
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"


module matrix_pieenc(Clk, Reset, tx_ShiftOut, tx_LoadPIE, tx_StartPIE, tx_ShiftNextBitToPIE, tx_ShiftPIEOut,
                     r_Data0Len, r_Data1Len, r_PiePWLen, r_RTCalLen, r_TRCalLen, r_Delimiter, 
                     p_FrameSyncLoad, p_FrameSyncStart, p_FrameSyncDone, 
                     p_PreambleLoad, p_PreambleStart, p_PreambleDone
                     );

parameter Tp=1;

input Clk;
input Reset;
input tx_ShiftOut;
input tx_LoadPIE;
input tx_StartPIE;
output tx_ShiftNextBitToPIE;
output tx_ShiftPIEOut;
input [15:0] r_Data0Len; //Load takes one cycle
input [15:0] r_Data1Len;
input [15:0] r_PiePWLen;
input [15:0] r_RTCalLen;
input [15:0] r_TRCalLen;
input [15:0] r_Delimiter;
input p_FrameSyncLoad;
input p_FrameSyncStart;
output p_FrameSyncDone;
input p_PreambleLoad;
input p_PreambleStart;
output p_PreambleDone;

wire tx_ShiftPIEOut1;
wire tx_ShiftPIEOut2;
wire tx_ShiftPIEOut3;

assign tx_ShiftPIEOut = (tx_ShiftPIEOut1 | tx_ShiftPIEOut2 | tx_ShiftPIEOut3);

matrix_txPieEncShiftReg txpieshiftreg1
(
.Clk(Clk),                                .Reset(Reset),                                 .tx_ShiftOut(tx_ShiftOut), 
.tx_LoadPIE(tx_LoadPIE),                  .tx_StartPIE(tx_StartPIE),                     .tx_ShiftNextBitToPIE(tx_ShiftNextBitToPIE), 
.tx_ShiftPIEOut(tx_ShiftPIEOut1),         .r_Data0Len(r_Data0Len),                       .r_Data1Len(r_Data1Len), 
.r_PiePWLen(r_PiePWLen)
);

matrix_txPieEncFrameSync txpieframesync
(
.Clk(Clk),                                .Reset(Reset),                                 .tx_ShiftPIEOut(tx_ShiftPIEOut2), 
.r_Data0Len(r_Data0Len),                  .r_PiePWLen(r_PiePWLen),                       .r_RTCalLen(r_RTCalLen),  
.r_Delimiter(r_Delimiter),                .p_FrameSyncLoad(p_FrameSyncLoad),             .p_FrameSyncStart(p_FrameSyncStart), 
.p_FrameSyncDone(p_FrameSyncDone)
);

matrix_txPieEncPreamble txpiepreamble
(
.Clk(Clk),                                .Reset(Reset),                                 .tx_ShiftPIEOut(tx_ShiftPIEOut3), 
.r_Data0Len(r_Data0Len),                  .r_PiePWLen(r_PiePWLen),                       .r_RTCalLen(r_RTCalLen),  
.r_TRCalLen(r_TRCalLen),                  .r_Delimiter(r_Delimiter),                     .p_PreambleLoad(p_PreambleLoad), 
.p_PreambleStart(p_PreambleStart),        .p_PreambleDone(p_PreambleDone)
);

endmodule

module matrix_txPieEncShiftReg(Clk, Reset, tx_ShiftOut, tx_LoadPIE, tx_StartPIE, tx_ShiftNextBitToPIE, tx_ShiftPIEOut,
                               r_Data0Len, r_Data1Len, r_PiePWLen
                               );

parameter Tp=1;

input Clk;
input Reset;
input tx_ShiftOut;
input tx_LoadPIE;
input tx_StartPIE;
output tx_ShiftNextBitToPIE;
output tx_ShiftPIEOut;
input [15:0] r_Data0Len; //Load takes one cycle
input [15:0] r_Data1Len;
input [15:0] r_PiePWLen;

reg tx_ShiftPIEOut;

reg [15:0] DataLenCnt;
reg [15:0] PiePWLenCnt;


wire LoadData0LenReg;
wire LoadData1LenReg;
wire PieOneCntOn;
wire PieZeroCntOn;

wire DataLenCntEQ0;
wire DataLenCntGT0;
wire PiePWLenCntEQ0;
wire PiePWLenCntGT0;
wire PiePWLenCntEQ1;

assign DataLenCntEQ0  = (DataLenCnt == 16'h0);
assign DataLenCntGT0  = (DataLenCnt > 16'h0);
assign PiePWLenCntEQ0  = (PiePWLenCnt == 16'h0);
assign PiePWLenCntGT0 = (PiePWLenCnt > 16'h0);
assign PiePWLenCntEQ1 = (PiePWLenCnt == 16'h1);

reg tx_LoadPIE_q;

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      tx_LoadPIE_q <= 1'h0;
   else
      tx_LoadPIE_q <= tx_LoadPIE;
end

assign LoadData0LenReg  = (tx_StartPIE & tx_LoadPIE_q & ~tx_ShiftOut);
assign LoadData1LenReg  = (tx_StartPIE & tx_LoadPIE_q & tx_ShiftOut);
assign PieOneCntOn  = (tx_StartPIE & DataLenCntGT0);
assign PieZeroCntOn = (tx_StartPIE & DataLenCntEQ0 & PiePWLenCntGT0);

wire DataLenEQ1;
assign DataLenEQ1   = (tx_StartPIE & DataLenCntEQ0 & PiePWLenCntEQ1);

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      tx_ShiftPIEOut <= 1'b0;
   else
   if(tx_LoadPIE)
      tx_ShiftPIEOut <= 1'b1;
   else
   if(PieZeroCntOn)
      tx_ShiftPIEOut <= 1'b0;
end

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      begin
         DataLenCnt <= 16'h0;
         PiePWLenCnt <= 16'h0;
      end
   else
   if(LoadData0LenReg)
      begin
          DataLenCnt <= r_Data0Len - 1;
          PiePWLenCnt <= r_PiePWLen;
      end
   else
   if(LoadData1LenReg)
      begin
          DataLenCnt <= r_Data1Len - 1;
          PiePWLenCnt <= r_PiePWLen;
      end
   else
   if(PieOneCntOn)
      begin
         DataLenCnt[15:0] <= #Tp DataLenCnt[15:0] - 1'b1;
     end
   else
   if(PieZeroCntOn)
      begin
         PiePWLenCnt[15:0] <= #Tp PiePWLenCnt[15:0] - 1'b1;
      end
end

assign tx_ShiftNextBitToPIE = DataLenEQ1;

endmodule

module matrix_txPieEncFrameSync(Clk, Reset, tx_ShiftPIEOut, r_Data0Len, r_PiePWLen, r_RTCalLen,  r_Delimiter, 
                                p_FrameSyncLoad, p_FrameSyncStart, p_FrameSyncDone
                                );

parameter Tp=1;

input Clk;
input Reset;
output tx_ShiftPIEOut;
input [15:0] r_Data0Len; //Load takes one cycle
input [15:0] r_PiePWLen;
input [15:0] r_RTCalLen;
input [15:0] r_Delimiter;
input p_FrameSyncLoad;
input p_FrameSyncStart;
output p_FrameSyncDone;

reg tx_ShiftPIEOut;

reg [15:0] DelimiterCnt;
reg [15:0] DataLenCnt;
reg [15:0] PiePWLenCnt;
reg [15:0] RTCalLenCnt;
reg [15:0] RTCalPWLenCnt;

wire DelimiterCntOn;
wire Data0OneCntOn;
wire Data0ZeroCntOn;
wire RTCalOneCntOn;
wire RTCalZeroCntOn;

wire DataLenCntEQ0;
wire DataLenCntGT0;
wire PiePWLenCntEQ0;
wire PiePWLenCntGT0;
wire DelimiterCntEQ0;
wire DelimiterCntGT0;
wire RTCalLenCntEQ0;
wire RTCalLenCntGT0;
wire RTCalPWLenCntEQ0;
wire RTCalPWLenCntEQ1;
wire RTCalPWLenCntGT0;

assign DataLenCntEQ0  = (DataLenCnt == 16'h0);
assign DataLenCntGT0  = (DataLenCnt > 16'h0);
assign PiePWLenCntEQ0  = (PiePWLenCnt == 16'h0);
assign PiePWLenCntGT0 = (PiePWLenCnt > 16'h0);

assign DelimiterCntEQ0 = (DelimiterCnt == 16'h0);
assign DelimiterCntGT0 = (DelimiterCnt > 16'h0);
assign RTCalLenCntEQ0  = (RTCalLenCnt == 16'h0);
assign RTCalLenCntGT0  = (RTCalLenCnt > 16'h0);
assign RTCalPWLenCntEQ0= (RTCalPWLenCnt == 16'h0);
assign RTCalPWLenCntEQ1= (RTCalPWLenCnt == 16'h1);
assign RTCalPWLenCntGT0 =(RTCalPWLenCnt > 16'h0);

assign DelimiterCntOn = (p_FrameSyncStart & DelimiterCntGT0);
assign Data0OneCntOn  = (p_FrameSyncStart & DelimiterCntEQ0 & DataLenCntGT0);
assign Data0ZeroCntOn = (p_FrameSyncStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntGT0);
assign RTCalOneCntOn  = (p_FrameSyncStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntGT0);
assign RTCalZeroCntOn = (p_FrameSyncStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntEQ0 & RTCalPWLenCntGT0);

wire FrameSyncLenEQ1;
assign FrameSyncLenEQ1= (p_FrameSyncStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntEQ0 & RTCalPWLenCntEQ1);


always @(posedge Clk or posedge Reset)
begin
	if(Reset)
			tx_ShiftPIEOut <= 1'b0;
	else
   if(p_FrameSyncLoad)
      begin
          DelimiterCnt <= r_Delimiter;
          DataLenCnt <= r_Data0Len;
          PiePWLenCnt <= r_PiePWLen;  // > 1%
          RTCalLenCnt <= r_RTCalLen;
          RTCalPWLenCnt <= r_PiePWLen;
          tx_ShiftPIEOut <= 1'b0;
      end
   else
   if(DelimiterCntOn)
      begin
         DelimiterCnt[15:0] <= #Tp DelimiterCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b0;
      end
   else
   if(Data0OneCntOn)
      begin
         DataLenCnt[15:0] <= #Tp DataLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b1;
      end
   else
   if(Data0ZeroCntOn)
      begin
         PiePWLenCnt[15:0] <= #Tp PiePWLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b0;
      end
   else
   if(RTCalOneCntOn)
      begin
         RTCalLenCnt[15:0] <= #Tp RTCalLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b1;
      end
   else
   if(RTCalZeroCntOn)
      begin
         RTCalPWLenCnt[15:0] <= #Tp RTCalPWLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b0;
      end
end

assign p_FrameSyncDone = FrameSyncLenEQ1;

endmodule

module matrix_txPieEncPreamble(Clk, Reset, tx_ShiftPIEOut, r_Data0Len, r_PiePWLen, r_RTCalLen, r_TRCalLen, r_Delimiter, 
                               p_PreambleLoad, p_PreambleStart, p_PreambleDone
                               );

parameter Tp=1;

input Clk;
input Reset;
output tx_ShiftPIEOut;
input [15:0] r_Data0Len; //Load takes one cycle
input [15:0] r_PiePWLen;
input [15:0] r_RTCalLen;
input [15:0] r_TRCalLen;
input [15:0] r_Delimiter;
input p_PreambleLoad;
input p_PreambleStart;
output p_PreambleDone;

reg tx_ShiftPIEOut;

reg [15:0] DelimiterCnt;
reg [15:0] DataLenCnt;
reg [15:0] PiePWLenCnt;
reg [15:0] RTCalLenCnt;
reg [15:0] RTCalPWLenCnt;
reg [15:0] TRCalLenCnt;
reg [15:0] TRCalPWLenCnt;

wire DataLenCntEQ0;
wire DataLenCntGT0;
wire PiePWLenCntEQ0;
wire PiePWLenCntGT0;
wire DelimiterCntEQ0;
wire DelimiterCntGT0;
wire RTCalLenCntEQ0;
wire RTCalLenCntGT0;
wire RTCalPWLenCntEQ0;
wire RTCalPWLenCntGT0;
wire TRCalLenCntEQ0;
wire TRCalLenCntGT0;
wire TRCalPWLenCntEQ1;
wire TRCalPWLenCntGT0;

wire DelimiterCntOn;
wire Data0OneCntOn;
wire Data0ZeroCntOn;
wire RTCalOneCntOn;
wire RTCalZeroCntOn;
wire TRCalOneCntOn;
wire TRCalZeroCntOn;

assign DataLenCntEQ0  = (DataLenCnt == 16'h0);
assign DataLenCntGT0  = (DataLenCnt > 16'h0);
assign PiePWLenCntEQ0  = (PiePWLenCnt == 16'h0);
assign PiePWLenCntGT0 = (PiePWLenCnt > 16'h0);
assign DelimiterCntEQ0 = (DelimiterCnt == 16'h0);
assign DelimiterCntGT0 = (DelimiterCnt > 16'h0);
assign RTCalLenCntEQ0  = (RTCalLenCnt == 16'h0);
assign RTCalLenCntGT0  = (RTCalLenCnt > 16'h0);
assign RTCalPWLenCntEQ0= (RTCalPWLenCnt == 16'h0);
assign RTCalPWLenCntGT0 =(RTCalPWLenCnt > 16'h0);
assign TRCalLenCntEQ0 = (TRCalLenCnt == 16'h0);
assign TRCalLenCntGT0 = (TRCalLenCnt > 16'h0);
assign TRCalPWLenCntEQ1 = (TRCalPWLenCnt == 16'h1);
assign TRCalPWLenCntGT0 = (TRCalPWLenCnt > 16'h0);

assign DelimiterCntOn = (p_PreambleStart & DelimiterCntGT0);
assign Data0OneCntOn  = (p_PreambleStart & DelimiterCntEQ0 & DataLenCntGT0);
assign Data0ZeroCntOn = (p_PreambleStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntGT0);
assign RTCalOneCntOn  = (p_PreambleStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntGT0);
assign RTCalZeroCntOn = (p_PreambleStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntEQ0 & RTCalPWLenCntGT0);
assign TRCalOneCntOn  = (p_PreambleStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntEQ0 & RTCalPWLenCntEQ0 & 
                         TRCalLenCntGT0);
assign TRCalZeroCntOn = (p_PreambleStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntEQ0 & RTCalPWLenCntEQ0 & 
                         TRCalLenCntEQ0 & TRCalPWLenCntGT0);

wire PreambleLenEQ1;

assign PreambleLenEQ1 = (p_PreambleStart & DelimiterCntEQ0 & DataLenCntEQ0 & PiePWLenCntEQ0 & RTCalLenCntEQ0 & RTCalPWLenCntEQ0 & 
                         TRCalLenCntEQ0 & TRCalPWLenCntEQ1);


always @(posedge Clk or posedge Reset)
begin
	if(Reset)
	   begin
			tx_ShiftPIEOut <= 1'b0;
         DelimiterCnt <= 16'h0;
         DataLenCnt <= 16'h0;
         PiePWLenCnt <= 16'h0;
         RTCalLenCnt <= 16'h0;
         RTCalPWLenCnt <= 16'h0;
         TRCalLenCnt <= 16'h0;
         TRCalPWLenCnt <= 16'h0;
     end
	else
   if(p_PreambleLoad)
      begin
          DelimiterCnt <= r_Delimiter;
          DataLenCnt <= r_Data0Len;
          PiePWLenCnt <= r_PiePWLen;  // > 1%
          RTCalLenCnt <= r_RTCalLen;
          RTCalPWLenCnt <= r_PiePWLen;
          TRCalLenCnt <= r_TRCalLen;
          TRCalPWLenCnt <= r_PiePWLen;
          tx_ShiftPIEOut <= 1'b0;
      end
   else
   if(DelimiterCntOn)
      begin
         DelimiterCnt[15:0] <= #Tp DelimiterCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b0;
      end
   else
   if(Data0OneCntOn)
      begin
         DataLenCnt[15:0] <= #Tp DataLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b1;
      end
   else
   if(Data0ZeroCntOn)
      begin
         PiePWLenCnt[15:0] <= #Tp PiePWLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b0;
      end
   else
   if(RTCalOneCntOn)
      begin
         RTCalLenCnt[15:0] <= #Tp RTCalLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b1;
      end
   else
   if(RTCalZeroCntOn)
      begin
         RTCalPWLenCnt[15:0] <= #Tp RTCalPWLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b0;
      end
   else
   if(TRCalOneCntOn)
      begin
         TRCalLenCnt[15:0] <= #Tp TRCalLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b1;
      end
   else
   if(TRCalZeroCntOn)
      begin
         TRCalPWLenCnt[15:0] <= #Tp TRCalPWLenCnt[15:0] - 1'b1;
         tx_ShiftPIEOut <= 1'b0;
      end
end

assign p_PreambleDone = PreambleLenEQ1;

endmodule
