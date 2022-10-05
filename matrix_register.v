/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_register.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.04.11 Created
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "timescale.v"


module matrix_register(DataIn, DataOut, Write, Clk, Reset, SyncReset);

parameter WIDTH = 32; // default parameter of the register width
parameter RESET_VALUE = 0;

input [WIDTH-1:0] DataIn;

input Write;
input Clk;
input Reset;
input SyncReset;

output [WIDTH-1:0] DataOut;
reg    [WIDTH-1:0] DataOut;



always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    DataOut<=#1 RESET_VALUE;
  else
  if(SyncReset)
    DataOut<=#1 RESET_VALUE;
  else
  if(Write)                         // write
    DataOut<=#1 DataIn;
end



endmodule   // Register
