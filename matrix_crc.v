/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_crc.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.05.01 Created
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"

// CCITT-CRC16 x^16+x^12+x^5+1
module matrix_crc16(Clk, Reset, Crc16Preset, Crc16PresetValue, Crc16DataIn, Crc16Enable, Crc16Out, Crc16Error
                   );

parameter Tp = 1;

input Clk;
input Reset;
input Crc16Preset;
input [15:0] Crc16PresetValue;
input Crc16DataIn;
input Crc16Enable;

output [15:0] Crc16Out;
output Crc16Error;

reg  [15:0] Crc16Out;

wire [15:0] next_crc16;

assign next_crc16[0] = Crc16Enable & (Crc16Out[15]^Crc16DataIn);
assign next_crc16[1] = Crc16Out[0];
assign next_crc16[2] = Crc16Out[1];
assign next_crc16[3] = Crc16Out[2];
assign next_crc16[4] = Crc16Out[3];
assign next_crc16[5] = Crc16Out[4]^next_crc16[0];
assign next_crc16[6] = Crc16Out[5];
assign next_crc16[7] = Crc16Out[6];
assign next_crc16[8] = Crc16Out[7];
assign next_crc16[9] = Crc16Out[8];
assign next_crc16[10] = Crc16Out[9];
assign next_crc16[11] = Crc16Out[10];
assign next_crc16[12] = Crc16Out[11]^next_crc16[0];
assign next_crc16[13] = Crc16Out[12];
assign next_crc16[14] = Crc16Out[13];
assign next_crc16[15] = Crc16Out[14];

always @ (posedge Clk or posedge Reset)
begin
  if (Reset)
    Crc16Out <= #Tp 32'hffffffff;
  else
  if(Crc16Preset)
    Crc16Out <= #Tp Crc16PresetValue;
  else
    Crc16Out <= #Tp next_crc16;
end

assign Crc16Error = (Crc16Out[15:0] != 16'h1d0f);  // CRC not equal to magic number

endmodule


// CCITT-CRC5 x^5+x^3+1
module matrix_crc5(Clk, Reset, Crc5Preset, Crc5PresetValue, Crc5DataIn, Crc5Enable, Crc5Out, Crc5Error
                  );

parameter Tp = 1;

input Clk;
input Reset;
input Crc5Preset;
input [4:0] Crc5PresetValue;
input Crc5DataIn;
input Crc5Enable;

output [4:0] Crc5Out;
output Crc5Error;

reg  [4:0] Crc5Out;

wire [15:0] next_crc5;

assign next_crc5[0] = Crc5Enable & (Crc5Out[4]^Crc5DataIn);
assign next_crc5[1] = Crc5Out[0];
assign next_crc5[2] = Crc5Out[1];
assign next_crc5[3] = Crc5Out[2]^next_crc5[0];
assign next_crc5[4] = Crc5Out[3];

always @ (posedge Clk or posedge Reset)
begin
  if (Reset)
    Crc5Out <= #Tp 5'b01001;
  else
  if(Crc5Preset)
    Crc5Out <= #Tp Crc5PresetValue;
  else
    Crc5Out <= #Tp next_crc5;
end

assign Crc5Error = (Crc5Out[4:0] != 5'b00000);  // CRC not equal to magic number
    
endmodule


module matrix_buffered_crc16(Clk, Reset, StartCRC16Tr, c_ShiftDataIn, c_ShiftBitCnt, c_ShiftLoad, BufCrc16Out, BufCrc16Error
                            );
parameter Tp = 1;
                            
input Clk;
input Reset;
input StartCRC16Tr;
input [31:0] c_ShiftDataIn;
input [7:0] c_ShiftBitCnt;
input c_ShiftLoad;
output [15:0] BufCrc16Out;
output BufCrc16Error;

reg [31:0] ShiftDataIn;
reg [7:0] ShiftBitCnt;
reg [15:0] BufCrc16;
reg BufCrc16Error;

wire [15:0] BufCrc16Out;
assign BufCrc16Out[15:0] = BufCrc16[15:0];

// wire ShiftBitCntGT1;
// wire ShiftBitCntEQ1;
wire ShiftBitCntGT0;
wire ShiftBitCntEQ0;
wire ShiftBitCntEQ80;

// assign ShiftBitCntGT1 = (ShiftBitCnt > 1);
// assign ShiftBitCntEQ1 = (ShiftBitCnt == 1);
assign ShiftBitCntGT0 = (ShiftBitCnt > 0);
assign ShiftBitCntEQ0 = (ShiftBitCnt == 0);
assign ShiftBitCntEQ80 = (ShiftBitCnt == 8'h80);

wire [15:0] Crc16Out;
wire Crc16Error;

reg StartCRC16Tr_q;

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      StartCRC16Tr_q <= 1'h0;
   else
      StartCRC16Tr_q <= StartCRC16Tr;
end

wire InitCrc16Tr;
wire CrcShiftLoad;
wire CrcShiftBitCntGT0;
wire CrcShiftBitCntEQ0;

assign InitCrc16Tr = (StartCRC16Tr & ~StartCRC16Tr_q);
assign CrcShiftLoad = (StartCRC16Tr & c_ShiftLoad);
assign CrcShiftBitCntGT0 = (StartCRC16Tr & ShiftBitCntGT0 & ~ShiftBitCntEQ80);
assign CrcShiftBitCntEQ0 = (StartCRC16Tr & ShiftBitCntEQ0);

always @ (posedge Clk or posedge Reset)
begin
  if (Reset)
     begin
       BufCrc16 <= #Tp 32'hffffffff;
       BufCrc16Error <= #Tp 1'b0;
       ShiftDataIn <= #Tp 32'h00000000;
       ShiftBitCnt <= #Tp 8'h80;
     end
  else
  if(InitCrc16Tr)
     begin
       BufCrc16 <= #Tp 32'hffffffff;
       BufCrc16Error <= #Tp 1'b0;
       ShiftDataIn <= #Tp 32'h00000000;
       ShiftBitCnt <= #Tp 8'h80; 
     end
  else
  if(CrcShiftLoad)
     begin
        ShiftDataIn <= #Tp c_ShiftDataIn;
        ShiftBitCnt <= #Tp c_ShiftBitCnt;
     end
  else
  if(CrcShiftBitCntGT0)
     begin
        ShiftDataIn[31:0] <= #Tp {ShiftDataIn[30:0], 1'b0};
        ShiftBitCnt <= #Tp ShiftBitCnt -1;
        /*
        if(ShiftBitCntEQ1)
           begin
               BufCrc16 <= #Tp Crc16Out;
               BufCrc16Error <= #Tp Crc16Error;
           end
        */ 
     end
  else
  if(CrcShiftBitCntEQ0)
     begin
        BufCrc16 <= #Tp Crc16Out;
        BufCrc16Error <= #Tp Crc16Error;
        ShiftBitCnt <= #Tp 8'h80;
     end
end

wire Crc16Preset;
wire Crc16DataIn;
wire Crc16Enable;

assign Crc16Preset = c_ShiftLoad;
assign Crc16DataIn = ShiftDataIn[31];
assign Crc16Enable = (ShiftBitCntGT0 & ~ShiftBitCntEQ80);

matrix_crc16 mtxcrc161
(
.Clk(Clk),                                .Reset(Reset),                                 .Crc16Preset(Crc16Preset),
.Crc16PresetValue(BufCrc16Out),           .Crc16DataIn(Crc16DataIn),                     .Crc16Enable(Crc16Enable), 
.Crc16Out(Crc16Out),                      .Crc16Error(Crc16Error)
);

endmodule // matrix_buffered_crc16

module matrix_buffered_crc5(Clk, Reset, StartCRC5Tr, c_ShiftDataIn, c_ShiftBitCnt, c_ShiftLoad, BufCrc5Out, BufCrc5Error
                            );
parameter Tp = 1;
                            
input Clk;
input Reset;
input StartCRC5Tr;
input [31:0] c_ShiftDataIn;
input [7:0] c_ShiftBitCnt;
input c_ShiftLoad;
output [4:0] BufCrc5Out;
output BufCrc5Error;

reg [31:0] ShiftDataIn;
reg [7:0] ShiftBitCnt;
reg [5:0] BufCrc5;
reg BufCrc5Error;

wire [4:0] BufCrc5Out;
assign BufCrc5Out[4:0] = BufCrc5[4:0];

// wire ShiftBitCntGT1;
// wire ShiftBitCntEQ1;
wire ShiftBitCntGT0;
wire ShiftBitCntEQ0;
wire ShiftBitCntEQ80;

// assign ShiftBitCntGT1 = (ShiftBitCnt > 1);
// assign ShiftBitCntEQ1 = (ShiftBitCnt == 1);
assign ShiftBitCntGT0 = (ShiftBitCnt > 0);
assign ShiftBitCntEQ0 = (ShiftBitCnt == 0);
assign ShiftBitCntEQ80 = (ShiftBitCnt == 8'h80);

wire [4:0] Crc5Out;
wire Crc5Error;

reg StartCRC5Tr_q;

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      StartCRC5Tr_q <= 1'h0;
   else
      StartCRC5Tr_q <= StartCRC5Tr;
end

wire InitCrc5Tr;
wire CrcShiftLoad;
wire CrcShiftBitCntGT0;
wire CrcShiftBitCntEQ0;

assign InitCrc5Tr = (StartCRC5Tr & ~StartCRC5Tr_q);
assign CrcShiftLoad = (StartCRC5Tr & c_ShiftLoad);
assign CrcShiftBitCntGT0 = (StartCRC5Tr & ShiftBitCntGT0 & ~ShiftBitCntEQ80);
assign CrcShiftBitCntEQ0 = (StartCRC5Tr & ShiftBitCntEQ0);

always @ (posedge Clk or posedge Reset)
begin
  if (Reset)
     begin
       BufCrc5 <= #Tp 5'b01001;
       BufCrc5Error <= #Tp 1'b0;
       ShiftDataIn <= #Tp 32'h00000000;
       ShiftBitCnt <= #Tp 8'h80;
     end
  else
  if(InitCrc5Tr)
     begin
       BufCrc5 <= #Tp 5'b01001;
       BufCrc5Error <= #Tp 1'b0;
       ShiftDataIn <= #Tp 32'h00000000;
       ShiftBitCnt <= #Tp 8'h80; 
     end
  else
  if(CrcShiftLoad)
     begin
        ShiftDataIn <= #Tp c_ShiftDataIn;
        ShiftBitCnt <= #Tp c_ShiftBitCnt;
     end
  else
  if(CrcShiftBitCntGT0)
     begin
        ShiftDataIn[31:0] <= #Tp {ShiftDataIn[30:0], 1'b0};
        ShiftBitCnt <= #Tp ShiftBitCnt -1;
        /*
        if(ShiftBitCntEQ1)
           begin
               BufCrc16 <= #Tp Crc16Out;
               BufCrc16Error <= #Tp Crc16Error;
           end
        */ 
     end
  else
  if(CrcShiftBitCntEQ0)
     begin
        BufCrc5 <= #Tp Crc5Out;
        BufCrc5Error <= #Tp Crc5Error;
        ShiftBitCnt <= #Tp 8'h80;
     end
end

wire Crc5Preset;
wire Crc5DataIn;
wire Crc5Enable;

assign Crc5Preset = c_ShiftLoad;
assign Crc5DataIn = ShiftDataIn[31];
assign Crc5Enable = (ShiftBitCntGT0 & ~ShiftBitCntEQ80);

matrix_crc5 mtxcrc51
(
.Clk(Clk),                                .Reset(Reset),                                 .Crc5Preset(Crc5Preset),
.Crc5PresetValue(BufCrc5Out),             .Crc5DataIn(Crc5DataIn),                       .Crc5Enable(Crc5Enable), 
.Crc5Out(Crc5Out),                        .Crc5Error(Crc5Error)
);

endmodule // matrix_buffered_crc5

