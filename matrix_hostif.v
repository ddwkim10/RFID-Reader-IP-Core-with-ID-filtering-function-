/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_hostif.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.05.23 Created
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"

//////////////////////////////////////////////////////////////////////////////////////////////////
///
///  fifo organization
///   1'bx Record Type 0: RN16,   1: {PC, EPC}
///  11'bx Bit Length
///   1'bx Ownership   0: matrix, 1: host
///   6'bx Next Pointer
///
//////////////////////////////////////////////////////////////////////////////////////////////////

module matrix_hostfifo(Clk, Reset, TagDataType, rx_ShiftDataOut, rx_ShiftBitCnt, rx_ShiftLoad
                       fifoRead, fifoDataOut, fifoFull, fifoEmpty, fifoCnt, rx_RN16Received,
                       rx_PCEPCReceived
                      );

parameter Tp = 1;
parameter NLWINETRY = 20;
parameter FIFODEPTH = 2;

input Clk;
input Reset;
input TagDataType;
input [31:0] rx_ShiftDataOut;
input [7:0] rx_ShiftBitCnt;
input rx_ShiftLoad;          // if FIFO is full, FIFO will post the overflow.
input fifoRead;
output fifoDataOut;
output fifoFull;
output fifoEmpty;
output [1:0] fifoCnt;
output rx_RN16Received;
output rx_PCEPCReceived;

reg [31:0] fifo[0:NLWINETRY*FIFODEPTH-1];
reg [1:0] fifoCnt;
reg [5:0] read_pointer;
reg [5:0] write_pointer;

reg [9:0] BitCnt;
//Here
always @ (posedge Clk or posedge Reset)
begin
if(reset)
cnt <=#Tp 0;
else
if(clear)
cnt <=#Tp { {(CNT_WIDTH-1){1'b0}}, read^write};
else
if(read ^ write)
if(read)
cnt <=#Tp cnt - 1'b1;
else
cnt <=#Tp cnt + 1'b1;
end

always @ (posedge clk or posedge reset)
begin
if(reset)
read_pointer <=#Tp 0;
else
if(clear)
read_pointer <=#Tp { {(CNT_WIDTH-2){1'b0}}, read};
else
if(read & ~empty)
read_pointer <=#Tp read_pointer + 1'b1;
end

always @ (posedge clk or posedge reset)
begin
if(reset)
write_pointer <=#Tp 0;
else
if(clear)
write_pointer <=#Tp { {(CNT_WIDTH-2){1'b0}}, write};
else
if(write & ~full)
write_pointer <=#Tp write_pointer + 1'b1;
end

assign empty = ~(|cnt);
assign almost_empty = cnt == 1;
assign full  = cnt == DEPTH;
assign almost_full  = &cnt[CNT_WIDTH-2:0];

 always @ (posedge clk)
begin
if(write & clear)
fifo[0] <=#Tp data_in;
else
if(write & ~full)
fifo[write_pointer] <=#Tp data_in;
end


always @ (posedge clk)
begin
if(clear)
data_out <=#Tp fifo[0];
else
data_out <=#Tp fifo[read_pointer];
end


endmodule