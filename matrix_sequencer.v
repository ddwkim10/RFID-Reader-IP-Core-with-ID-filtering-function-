/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_sequencer.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.04.21 Created
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"

module matrix_sequencer(Clk, Reset, SeqState, r_ExecHostCmd, s_RstHostCmd, h_StartHInvRound, h_EndHinvRound
                        );

parameter Tp = 1;

input Clk;
input Reset;
output [4:0] SeqState;
input [3:0] r_ExecHostCmd; 
output s_RstHostCmd;
output h_StartHInvRound;
input h_EndHinvRound;

reg s_RstHostCmd;

//Registers are declared for all of the fsm combinational outputs only
//reg h_StartHInvRound; 

//Define Host Command States
parameter [4:0]         //enum states
          HST_IDLE     = 5'b00001,
          HST_FILTER   = 5'b00010,
          HST_INV      = 5'b00100,
          HST_REQRN    = 5'b01000,
          HST_ACCESS   = 5'b10000;

//next_state is declared as registers because it is within the fsm combinatorial block
reg [4:0] SeqState, next_state;

wire r_ExecHostCmdOn;
assign r_ExecHostCmdOn = (r_ExecHostCmd == `MAT_HCSR_EXEC_FLITER)    |
                         (r_ExecHostCmd == `MAT_HCSR_EXEC_INVENTORY) |
                         (r_ExecHostCmd == `MAT_HCSR_EXEC_ACCESS)    |
                         (r_ExecHostCmd == `MAT_HCSR_EXEC_PURGE)     |
                         (r_ExecHostCmd == `MAT_HCSR_EXEC_STOP_INV); 
								 
assign h_StartHInvRound = (SeqState == HST_INV);

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      s_RstHostCmd <= #Tp 1'b0;
   else
      s_RstHostCmd <= #Tp r_ExecHostCmdOn;
end

//////////////////////////////////////////////////////////////////////////////////////////////////
// Sequencer Finite State Machine

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      begin
         SeqState <= HST_IDLE; 
         //next_state are combinatorial outputs 
      end
   else
      SeqState <= next_state;
end

always @(SeqState or r_ExecHostCmd or h_EndHinvRound)  // States and Inputs in the sensitivity list
begin

   next_state = SeqState;
   
	case(SeqState)
       HST_IDLE:
          begin
              if (r_ExecHostCmd == `MAT_HCSR_EXEC_FLITER)
                  next_state = HST_FILTER;
              else if (r_ExecHostCmd == `MAT_HCSR_EXEC_INVENTORY)
						next_state = HST_INV;
              else if (r_ExecHostCmd == `MAT_HCSR_EXEC_ACCESS)
                  next_state = HST_IDLE;
              else if (r_ExecHostCmd == `MAT_HCSR_EXEC_PURGE)
                  next_state = HST_IDLE;
              else if (r_ExecHostCmd == `MAT_HCSR_EXEC_STOP_INV)
                  next_state = HST_IDLE;
          end
       HST_FILTER:
          begin
          end
       HST_INV:
          begin
              // Set SELECT/QUERY parameters from Tx FIFO
              // Signal HOST_INVENTORY process
              if(h_EndHinvRound)
					begin
                 next_state = HST_IDLE;
					end
          end
       HST_REQRN:
          begin
          end
       HST_ACCESS:
          begin
          end
       default:
          begin
          end
   endcase
end

endmodule
