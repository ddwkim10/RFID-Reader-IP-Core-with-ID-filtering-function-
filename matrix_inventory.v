/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_inventory.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.04.28 Created
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"

module matrix_inventory(Clk, Reset, h_StartHInvRound, h_EndHinvRound, 
                        r_CmdReg, r_CmdPntReg, r_CmdCntReg, r_BigData, r_InvBigDataSel,
                        tx_InvShiftDataIn, tx_InvShiftBitCnt, tx_InvShiftLoad, tx_InvShiftStart, tx_InvShiftEmpty,
                        p_InvFrameSyncLoad, p_InvFrameSyncStart, p_InvFrameSyncDone, 
                        p_InvPreambleLoad, p_InvPreambleStart, p_InvPreambleDone,
                        rx_RN16Received, rx_CollisionDetected, tx_InvStartCRC16Tr, BufCrc16Out, tx_InvFinalShiftLoadErase,
                        r_LnkTimer1, r_LnkTimer2, r_LnkTimer3, r_LnkTimer4,
                        r_DR_Ratio, tx_InvStartCRC5Tr, BufCrc5Out, TagDataType
                        );

parameter Tp = 1;

input Clk;
input Reset;
input h_StartHInvRound;
output h_EndHinvRound;

// CMDREG
input [31:0] r_CmdReg;
input [31:0] r_CmdPntReg;
input [31:0] r_CmdCntReg;
input [255:0] r_BigData;
output [1:0] r_InvBigDataSel;

// Tx Shift Register
output [31:0] tx_InvShiftDataIn;
output [7:0] tx_InvShiftBitCnt;
output tx_InvShiftLoad;
output tx_InvShiftStart;
input tx_InvShiftEmpty;
output p_InvFrameSyncLoad;
output p_InvFrameSyncStart;
input p_InvFrameSyncDone;
output p_InvPreambleLoad;
output p_InvPreambleStart;
input p_InvPreambleDone;

// From Rx
input rx_RN16Received;
input rx_CollisionDetected;

// crc16
output tx_InvStartCRC16Tr;
input [15:0] BufCrc16Out;

// Final Shift Register Load Erase Status
output tx_InvFinalShiftLoadErase;

// Timers
input [15:0] r_LnkTimer1;
input [15:0] r_LnkTimer2;
input [15:0] r_LnkTimer3;
input [15:0] r_LnkTimer4;

// QUERY parameters here
input [12:0] r_DR_Ratio;

// crc5
output tx_InvStartCRC5Tr;
input [4:0] BufCrc5Out;

// From Tag
output TagDataType;

wire [1:0] MuxTimer;
wire TimerStart;
wire [15:0] TimerIn;
wire TimedOut;

parameter [1:0]
          MUX_LT_1               = 2'b00,
          MUX_LT_2               = 2'b01,
          MUX_LT_3               = 2'b10,
          MUX_LT_4               = 2'b11;

// Inventory States
parameter [23:0]                 //enum states
          INVST_IDLE             = 24'h000001,
          INVST_SELECT           = 24'h000002,
          INVST_SELECTIMER       = 24'h000004,
          INVST_QUERY            = 24'h000008, 
          INVST_QUERYSENT        = 24'h000010,
          INVST_RN16RCVDTIMER    = 24'h000020,
          INVST_ACK              = 24'h000040,
          INVST_ACKTIMER         = 24'h000080,
          INVST_T3TIMER          = 24'h000100,
          INVST_T3TIMER2         = 24'h000200, 
          INVST_QUERYREP         = 24'h000400, 
          INVST_QUERYREPSENT     = 24'h000800, 
          INVST_QUERYREPSENTIMER = 24'h001000,
          INVST_PCEPC            = 24'h002000, 
          INVST_PCEPCTIMER       = 24'h004000,
          INVST_PCEPCRCVD        = 24'h008000, 
          INVST_PCEPCRCVDTIMER   = 24'h010000,
          INVST_NAK              = 24'h020000, 
          INVST_NAKSENT          = 24'h040000,
          INVST_COLLISION        = 24'h080000,
          INVST_QUERYADJ         = 24'h100000,
          INVST_QUERYADJSENT     = 24'h200000,
          INVST_QUERYADJSENTIMER = 24'h400000,
          INVST_FAILURE_RCVRY    = 24'h800000;

//invnext_state is declared as registers because it is within the fsm combinatorial block
reg [14:0] InvState, invnext_state;
reg [14:0] PrevInvState;

wire StartSelect;
wire [1:0] SelectDone;
wire StartQuery;
wire [1:0] QueryDone;
wire StartQueryAdjust;
wire StartQueryRep;
wire StartACK;
wire StartNAK;

assign h_EndHinvRound =  (PrevInvState == INVST_QUERYREP) & (InvState == INVST_IDLE);

assign StartSelect = (InvState == INVST_SELECT);
assign StartQuery = (InvState == INVST_QUERY);

assign TimerStart = (InvState == INVST_SELECTIMER) | (InvState == INVST_QUERYSENT);  // bitwise |
assign MuxTimer = (InvState == INVST_SELECTIMER) ? MUX_LT_4:
                  ((InvState == INVST_QUERYSENT) ? MUX_LT_1 : MUX_LT_2);

assign TagDataType = (InvState == INVST_PCEPC | InvState == INVST_PCEPCTIMER) ? `MAT_TAG_DT_PCEPC : `MAT_TAG_DT_RN16;

//////////////////////////////////////////////////////////////////////////////////////////////////
// HOST_INVENTORY Finite State Machine

`ifdef MAT_DEBUG_FLAG
always @(InvState)
begin
    wait(tb_matrix_top.StartTB);
    $fdisplay( tb_matrix_top.tb_log_file, "\n(%0t) Inventory State: 0x%0x", $time, InvState);
    $write("\n(%0t) Inventory State: 0x%0x", $time, InvState);
end
`endif

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      begin
         InvState <= INVST_IDLE;
      end
   else
      begin
          PrevInvState <= InvState;
          InvState <= invnext_state;
      end
end

always @(InvState or h_StartHInvRound or SelectDone or TimedOut or QueryDone or rx_RN16Received or 
         rx_CollisionDetected) // include every input
begin

   invnext_state = InvState;
   
	case(InvState)
       INVST_IDLE:
          begin
              if(h_StartHInvRound)
                 invnext_state = INVST_SELECT;
          end
       INVST_SELECT:
          begin
              if(SelectDone == `MAT_CMD_SUCCESS)
                 begin
                    invnext_state = INVST_SELECTIMER;
                 end 
              else
              if(SelectDone == `MAT_CMD_FAILURE)
                 invnext_state = INVST_FAILURE_RCVRY;
          end
       INVST_SELECTIMER:
          begin
              if(TimedOut)
                 begin
                    invnext_state = INVST_QUERY;  
                 end
          end
       INVST_QUERY:
          begin
              if(QueryDone == `MAT_CMD_SUCCESS)
                 begin
                    invnext_state = INVST_QUERYSENT;
                 end 
              else
              if(QueryDone == `MAT_CMD_FAILURE)
                 invnext_state = INVST_FAILURE_RCVRY;
          end
       INVST_QUERYSENT:
          begin
              if(rx_RN16Received)
                 begin
                    invnext_state = INVST_RN16RCVDTIMER;
                 end
              else
              if(rx_CollisionDetected)
                 begin
                    invnext_state = INVST_QUERYREP;
                 end
              else
              if(TimedOut)
                 begin
                    invnext_state = INVST_T3TIMER;  
                 end
          end    
       INVST_RN16RCVDTIMER:
          begin
          end
       INVST_ACK:
          begin
          end
       INVST_ACKTIMER:
          begin
          end
       INVST_T3TIMER:
          begin
          end
       INVST_T3TIMER2:
          begin
          end
       INVST_QUERYREP:
          begin
          end
       INVST_QUERYREPSENT:
          begin
          end
       INVST_QUERYREPSENTIMER:
          begin
          end
       INVST_PCEPC:
          begin
          end
       INVST_PCEPCTIMER:
          begin
          end
       INVST_PCEPCRCVD:
          begin
          end
       INVST_PCEPCRCVDTIMER:
          begin
          end
       INVST_NAK:
          begin
          end
       INVST_NAKSENT:
          begin
          end
       INVST_COLLISION:
          begin
          end
       INVST_QUERYADJ:
          begin
          end
       INVST_QUERYADJSENT:
          begin
          end
       INVST_QUERYADJSENTIMER:
          begin
          end
       INVST_FAILURE_RCVRY:
          begin
          end
       default:
          begin
          end
   endcase
end

wire [1:0] r_SelBigDataSel;
wire [31:0] tx_SelShiftDataIn;
wire [7:0] tx_SelShiftBitCnt;
wire tx_SelShiftLoad;
wire tx_SelShiftStart;
wire p_SelFrameSyncLoad;
wire p_SelFrameSyncStart;
wire p_SelPreambleLoad;
wire p_SelPreambleStart;
wire tx_SelFinalShiftLoadErase;

wire [31:0] tx_QueryShiftDataIn;
wire [7:0] tx_QueryShiftBitCnt;
wire tx_QueryShiftLoad;
wire tx_QueryShiftStart;
wire p_QueryFrameSyncLoad;
wire p_QueryFrameSyncStart;
wire p_QueryPreambleLoad;
wire p_QueryPreambleStart;
wire tx_QueryFinalShiftLoadErase;

assign r_InvBigDataSel     = r_SelBigDataSel;    // bitwise |
assign tx_InvShiftDataIn   = tx_SelShiftDataIn   | tx_QueryShiftDataIn;
assign tx_InvShiftBitCnt   = tx_SelShiftBitCnt   | tx_QueryShiftBitCnt;  
assign tx_InvShiftLoad     = tx_SelShiftLoad     | tx_QueryShiftLoad; 
assign tx_InvShiftStart    = tx_SelShiftStart    | tx_QueryShiftStart;
assign p_InvFrameSyncLoad  = p_SelFrameSyncLoad  | p_QueryFrameSyncLoad; 
assign p_InvFrameSyncStart = p_SelFrameSyncStart | p_QueryFrameSyncStart;  
assign p_InvPreambleLoad   = p_SelPreambleLoad   | p_QueryPreambleLoad;
assign p_InvPreambleStart  = p_SelPreambleStart  | p_QueryPreambleStart;
assign tx_InvFinalShiftLoadErase = tx_SelFinalShiftLoadErase | tx_QueryFinalShiftLoadErase;

wire tx_SelStartCRC16Tr;

assign tx_InvStartCRC16Tr = tx_SelStartCRC16Tr; // bitwise |

matrix_inv_select mtxinvselect1
(
.Clk(Clk),                                .Reset(Reset),                                 .StartSelect(StartSelect), 
.SelectDone(SelectDone),                  .r_CmdReg(r_CmdReg),                           .r_CmdPntReg(r_CmdPntReg), 
.r_CmdCntReg(r_CmdCntReg),                .r_BigData(r_BigData),                         .r_SelBigDataSel(r_SelBigDataSel),
.tx_SelShiftDataIn(tx_SelShiftDataIn),    .tx_SelShiftBitCnt(tx_SelShiftBitCnt),         .tx_SelShiftLoad(tx_SelShiftLoad), 
.tx_SelShiftStart(tx_SelShiftStart),      .tx_SelShiftEmpty(tx_InvShiftEmpty),           .p_SelFrameSyncLoad(p_SelFrameSyncLoad), 
.p_SelFrameSyncStart(p_SelFrameSyncStart),.p_SelFrameSyncDone(p_InvFrameSyncDone),       .p_SelPreambleLoad(p_SelPreambleLoad),
.p_SelPreambleStart(p_SelPreambleStart),  .tx_SelStartCRC16Tr(tx_SelStartCRC16Tr),       .BufCrc16Out(BufCrc16Out),
.tx_SelFinalShiftLoadErase(tx_SelFinalShiftLoadErase)
);

wire tx_QueryStartCRC5Tr;

assign tx_InvStartCRC5Tr = tx_QueryStartCRC5Tr; // bitwise |

matrix_inv_query mtxinvquery1
(
.Clk(Clk),                                .Reset(Reset),                                 .StartQuery(StartQuery), 
.QueryDone(QueryDone),                    .r_DR_Ratio(r_DR_Ratio),                       .tx_QueryShiftDataIn(tx_QueryShiftDataIn), 
.tx_QueryShiftBitCnt(tx_QueryShiftBitCnt),.tx_QueryShiftLoad(tx_QueryShiftLoad),         .tx_QueryShiftStart(tx_QueryShiftStart), 
.tx_QueryShiftEmpty(tx_InvShiftEmpty),    .p_QueryPreambleLoad(p_QueryPreambleLoad),     .p_QueryPreambleStart(p_QueryPreambleStart), 
.p_QueryPreambleDone(p_InvPreambleDone),  .p_QueryFrameSyncLoad(p_QueryFrameSyncLoad),   .p_QueryFrameSyncStart(p_QueryFrameSyncStart),
.tx_QueryStartCRC5Tr(tx_QueryStartCRC5Tr),.BufCrc5Out(BufCrc5Out),                       .tx_QueryFinalShiftLoadErase(tx_QueryFinalShiftLoadErase)
);

assign TimerIn = (MuxTimer == MUX_LT_1)  ? r_LnkTimer1 :
                 ((MuxTimer == MUX_LT_2) ? r_LnkTimer2 :
                 ((MuxTimer == MUX_LT_3) ? r_LnkTimer3 : r_LnkTimer4));

matrix_timer mtxinvtimer1
(
.Clk(Clk),                                 .Reset(Reset),                                .TimerIn(TimerIn), 
.TimerStart(TimerStart),                   .TimedOut(TimedOut)
);

endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Tx SELECT Command
//

module matrix_inv_select(Clk, Reset, StartSelect, SelectDone, r_CmdReg, r_CmdPntReg, r_CmdCntReg, r_BigData, r_SelBigDataSel,
                         tx_SelShiftDataIn, tx_SelShiftBitCnt, tx_SelShiftLoad, tx_SelShiftStart, tx_SelShiftEmpty,
                         p_SelFrameSyncLoad, p_SelFrameSyncStart, p_SelFrameSyncDone, p_SelPreambleLoad, p_SelPreambleStart,
                         tx_SelStartCRC16Tr, BufCrc16Out, tx_SelFinalShiftLoadErase
                         );
    
parameter Tp = 1;

input Clk;
input Reset;
input StartSelect;
output [1:0] SelectDone;

// CMDREG
input [31:0] r_CmdReg;
input [31:0] r_CmdPntReg;
input [31:0] r_CmdCntReg;
input [255:0] r_BigData;
output [1:0] r_SelBigDataSel;

// Tx Shift Register
output [31:0] tx_SelShiftDataIn;
output [7:0] tx_SelShiftBitCnt;
output tx_SelShiftLoad;
output tx_SelShiftStart;
input tx_SelShiftEmpty;
output p_SelFrameSyncLoad;
output p_SelFrameSyncStart;
input p_SelFrameSyncDone;
output p_SelPreambleLoad;
output p_SelPreambleStart;

//crc16
output tx_SelStartCRC16Tr;
input [15:0] BufCrc16Out;

// Final Shift Register Load Erase Status to remove spurious ShiftPIEOut
output tx_SelFinalShiftLoadErase;

reg [31:0] tx_SelShiftDataIn; // make compiler happy
reg [7:0] tx_SelShiftBitCnt;

parameter [8:0]                  //enum states
          SELECTST_IDLE          = 9'h001,
          SELECTST_TXFRAMESYNC   = 9'h002,     
          SELECTST_TXCMDREG      = 9'h004,   
          SELECTST_TXPOINTER     = 9'h008,
          SELECTST_TXLENGTH      = 9'h010,
          SELECTST_TXMASK        = 9'h020,
          SELECTST_TXTRUNC       = 9'h040,
          SELECTST_TXCRC16       = 9'h080,
          SELECTST_FAILURE_RCVRY = 9'h100;

reg [7:0] SelectState, selnext_state;

reg p_SelFrameSyncStart_q;

always @(posedge Clk or posedge Reset)
begin
    if(Reset)
        p_SelFrameSyncStart_q <= 0;
    else
       p_SelFrameSyncStart_q <= p_SelFrameSyncStart;
end

assign tx_SelShiftStart = (SelectState == SELECTST_TXCMDREG)  | 
                          (SelectState == SELECTST_TXPOINTER) | 
                          (SelectState == SELECTST_TXLENGTH)  | 
                          (SelectState == SELECTST_TXMASK)    | 
                          (SelectState == SELECTST_TXTRUNC)   |
                          (SelectState == SELECTST_TXCRC16); 
wire tx_SelStartCRC16Tr;
assign tx_SelStartCRC16Tr = (SelectState == SELECTST_TXFRAMESYNC) | tx_SelShiftStart;

wire tx_SelFinalShiftLoadErase;
assign tx_SelFinalShiftLoadErase = (SelectState == SELECTST_TXCRC16 & tx_SelShiftEmpty);

assign tx_SelShiftLoad = (tx_SelShiftEmpty | p_SelFrameSyncDone);       
assign p_SelFrameSyncStart = (SelectState == SELECTST_TXFRAMESYNC);
assign p_SelFrameSyncLoad = (p_SelFrameSyncStart & (p_SelFrameSyncStart_q == 0));
assign p_SelPreambleLoad = 1'b0;
assign p_SelPreambleStart = 1'b0;

wire [4:0] hCmd;
wire [3:0] SelCmdCode;
assign hCmd = r_CmdReg[4:0];
assign SelCmdCode = r_CmdReg[31:28];

wire [7:0] EBVCnt;
assign EBVCnt[7:0] = (r_CmdPntReg[31] == 1) ? 8'h20:
                     ((r_CmdPntReg[23] == 1)? 8'h18:
                     ((r_CmdPntReg[15] == 1)? 8'h10: 8'h08));
wire [31:0] EBVCmdPnt;
assign EBVCmdPnt[31:0] = (r_CmdPntReg[31] == 1) ? r_CmdPntReg[31:0]:
                         ((r_CmdPntReg[23] == 1)? {r_CmdPntReg[23:0], 8'h00}:
                         ((r_CmdPntReg[15] == 1)? {r_CmdPntReg[15:0], 16'h0000}: {r_CmdPntReg[7:0], 24'h000000}));

assign r_SelBigDataSel = (SelectState == SELECTST_TXPOINTER & tx_SelShiftEmpty)? 2'b00: 2'b00;

reg [255:0] MaskReg;
reg [7:0] MaskLength;

wire MaskLengthEQ0;
wire MaskLengthGT0;
wire MaskLengthGT32;

assign MaskLengthEQ0 = (MaskLength == 8'h0);
assign MaskLengthGT0 = (MaskLength > 8'h0);
assign MaskLengthGT32 = (MaskLength > 8'h20);

always @(posedge Clk or posedge Reset)
begin
    if(Reset)
       begin
          MaskReg <= 256'h0;
          MaskLength <= 8'h00;
       end
    else
    if(SelectState == SELECTST_TXPOINTER & tx_SelShiftEmpty)
       begin
          MaskReg <= r_BigData;
          MaskLength[7:0] <= r_CmdCntReg[7:0];
       end
    else
    if(SelectState == SELECTST_TXLENGTH & tx_SelShiftEmpty)
       begin
          MaskReg[255:0] <= {MaskReg[223:0], 32'h00000000};
          if(MaskLengthGT32)
             MaskLength <= MaskLength - 8'h20;
         else
             MaskLength <= 8'h00;
       end
    else
    if(SelectState == SELECTST_TXMASK & tx_SelShiftEmpty & MaskLengthGT32)
       begin
           MaskReg[255:0] <= {MaskReg[223:0], 32'h00000000};
           MaskLength <= MaskLength - 8'h20;
       end
    else
    if(SelectState == SELECTST_TXMASK & tx_SelShiftEmpty & ~MaskLengthGT32 & MaskLengthGT0)
       begin
           MaskReg[255:0] <= {MaskReg[223:0], 32'h00000000};
           MaskLength <= 8'h00;
       end
end

wire [1:0] SelectDone;
assign SelectDone = (SelectState == SELECTST_TXCRC16 & tx_SelShiftEmpty) ? `MAT_CMD_SUCCESS:
                    ((SelectState == SELECTST_FAILURE_RCVRY) ? `MAT_CMD_FAILURE : 
                    ((SelectState == SELECTST_IDLE) ? `MAT_CMD_NOP : `MAT_CMD_INPROGRESS));

/////////////////////////////////////////////////////////////////////////////////////////////////
// SELECT FSM
//

`ifdef MAT_DEBUG_FLAG
always @(SelectState)
begin
    wait(tb_matrix_top.StartTB);
    $fdisplay( tb_matrix_top.tb_log_file, "\n(%0t) Select State: 0x%0x", $time, SelectState);
    $write("\n(%0t) Select State: 0x%0x", $time, SelectState);
end
`endif

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      begin
         SelectState <= SELECTST_IDLE;
      end
   else
      begin
          SelectState <= selnext_state;
      end
end

always @(SelectState or StartSelect or p_SelFrameSyncDone or tx_SelShiftEmpty or hCmd or SelCmdCode or r_CmdReg or EBVCmdPnt or
	      EBVCnt or r_CmdCntReg or MaskReg or MaskLengthGT32 or MaskLength or MaskLengthGT0 or MaskLengthEQ0 or BufCrc16Out) // include every comb input
begin

   selnext_state = SelectState;
   tx_SelShiftDataIn = 32'h00000000;
   tx_SelShiftBitCnt = 8'h00;
   
	case(SelectState)
       SELECTST_IDLE:
          begin
              if(StartSelect) 
                 begin
                    if(hCmd != `MAT_AIR_IF_Select | SelCmdCode != 4'b1010)
                       begin
                         selnext_state = SELECTST_FAILURE_RCVRY;
                       end
                    else
                       begin
                          selnext_state = SELECTST_TXFRAMESYNC;
                       end
                end
          end
       SELECTST_TXFRAMESYNC:
          begin
              if(p_SelFrameSyncDone) 
                 begin
                    tx_SelShiftDataIn = {r_CmdReg[31:20], 20'h00000};
                    tx_SelShiftBitCnt = 8'h0c;
                    selnext_state = SELECTST_TXCMDREG;
                end
          end
       SELECTST_TXCMDREG:
          begin
              if(tx_SelShiftEmpty)
                 begin
                    tx_SelShiftDataIn = EBVCmdPnt;
                    tx_SelShiftBitCnt = EBVCnt;
                    selnext_state = SELECTST_TXPOINTER;     
                 end
          end
       SELECTST_TXPOINTER:
          begin
              if(tx_SelShiftEmpty)
                 begin
                    tx_SelShiftDataIn = {r_CmdCntReg[7:0], 24'h000000};
                    tx_SelShiftBitCnt = 8'h08;
                    selnext_state = SELECTST_TXLENGTH;     
                 end
          end          
       SELECTST_TXLENGTH:
          begin
              if(tx_SelShiftEmpty)
                 begin
                    tx_SelShiftDataIn[31:0] = MaskReg[255:224];
                    if(MaskLengthGT32)
                       begin
                          tx_SelShiftBitCnt = 8'h20;
                       end
                    else
                       begin
                          tx_SelShiftBitCnt = MaskLength;
                       end
                    selnext_state = SELECTST_TXMASK;     
                 end
          end             
       SELECTST_TXMASK:
          begin
              if(tx_SelShiftEmpty & MaskLengthGT32)
                 begin
                     tx_SelShiftDataIn = MaskReg[255:224];
                     tx_SelShiftBitCnt = 8'h20;
                 end
              else
              if(tx_SelShiftEmpty & ~MaskLengthGT32 & MaskLengthGT0)
                 begin
                     tx_SelShiftDataIn = MaskReg[255:224];
                     tx_SelShiftBitCnt = MaskLength;
                 end
              else
              if(tx_SelShiftEmpty & MaskLengthEQ0)
                 begin
                    tx_SelShiftDataIn = {r_CmdReg[19], 31'h00000000};
                    tx_SelShiftBitCnt = 8'h01;
                    selnext_state = SELECTST_TXTRUNC;
                 end
          end
       SELECTST_TXTRUNC:
          begin
              if(tx_SelShiftEmpty)
                 begin
                    tx_SelShiftDataIn[31:16] = ~BufCrc16Out[15:0];
                    tx_SelShiftBitCnt = 8'h10;
                    selnext_state = SELECTST_TXCRC16;     
                 end
          end          
       SELECTST_TXCRC16:
          begin
              if(tx_SelShiftEmpty)
                 begin
                    tx_SelShiftDataIn = 32'h00000000;
                    tx_SelShiftBitCnt = 8'h00;
                    selnext_state = SELECTST_IDLE;     
                 end
          end 
       SELECTST_FAILURE_RCVRY:
          begin
          // INVENTORY_OP_STATUS Failed
          // FAILURE_REASON_CODE
          // INT-SRC[4]
          end            
       default:   // include every comb output used, but not specified in always
          begin
          end
   endcase
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Tx QUERY Command
//

module matrix_inv_query(Clk, Reset, StartQuery, QueryDone, r_DR_Ratio, tx_QueryShiftDataIn, tx_QueryShiftBitCnt, 
                        tx_QueryShiftLoad, tx_QueryShiftStart, tx_QueryShiftEmpty,
                        p_QueryPreambleLoad, p_QueryPreambleStart, p_QueryPreambleDone, p_QueryFrameSyncLoad, p_QueryFrameSyncStart,
                        tx_QueryStartCRC5Tr, BufCrc5Out, tx_QueryFinalShiftLoadErase
                        );
    
parameter Tp = 1;

input Clk;
input Reset;
input StartQuery;
output [1:0] QueryDone;

// CMDREG
input [12:0] r_DR_Ratio;

// Tx Shift Register
output [31:0] tx_QueryShiftDataIn;
output [7:0] tx_QueryShiftBitCnt;
output tx_QueryShiftLoad;
output tx_QueryShiftStart;
input tx_QueryShiftEmpty;

output p_QueryPreambleLoad; 
output p_QueryPreambleStart;
input p_QueryPreambleDone;
output p_QueryFrameSyncLoad;
output p_QueryFrameSyncStart;

//crc5
output tx_QueryStartCRC5Tr;
input [4:0] BufCrc5Out;

// Final Shift Register Load Erase Status to remove spurious ShiftPIEOut
output tx_QueryFinalShiftLoadErase;

reg [31:0] tx_QueryShiftDataIn; // make compiler happy
reg [7:0] tx_QueryShiftBitCnt;

parameter [4:0]                  //enum states
          QUERYST_IDLE           = 5'h01,
          QUERYST_TXPREAMBLE     = 5'h02,     
          QUERYST_TXDRREG        = 5'h04,   
          QUERYST_TXCRC5         = 5'h08,
          QUERYST_FAILURE_RCVRY  = 5'h10;

reg [7:0] QueryState, querynext_state;

reg p_QueryPreambleStart_q;

always @(posedge Clk or posedge Reset)
begin
    if(Reset)
       p_QueryPreambleStart_q <= 0;
    else
       p_QueryPreambleStart_q <= p_QueryPreambleStart;
end

assign tx_QueryShiftStart = (QueryState == QUERYST_TXDRREG)  | 
                            (QueryState == QUERYST_TXCRC5); 

wire tx_QueryStartCRC5Tr;
assign tx_QueryStartCRC5Tr = (QueryState == QUERYST_TXPREAMBLE) | tx_QueryShiftStart;

wire tx_QueryFinalShiftLoadErase;
assign tx_QueryFinalShiftLoadErase = (QueryState == QUERYST_TXCRC5 & tx_QueryShiftEmpty);

assign tx_QueryShiftLoad = (tx_QueryShiftEmpty | p_QueryPreambleDone);       
assign p_QueryPreambleStart = (QueryState ==  QUERYST_TXPREAMBLE);
assign p_QueryPreambleLoad = (p_QueryPreambleStart & (p_QueryPreambleStart_q == 0));
assign p_QueryFrameSyncLoad = 1'b0;
assign p_QueryFrameSyncStart = 1'b0;

wire [1:0] QueryDone;
assign QueryDone =  (QueryState == QUERYST_TXCRC5 & tx_QueryShiftEmpty) ? `MAT_CMD_SUCCESS:
                    ((QueryState == QUERYST_FAILURE_RCVRY) ? `MAT_CMD_FAILURE : 
                    ((QueryState == QUERYST_IDLE) ? `MAT_CMD_NOP : `MAT_CMD_INPROGRESS));

/////////////////////////////////////////////////////////////////////////////////////////////////
// QUERY FSM
//

`ifdef MAT_DEBUG_FLAG
always @(QueryState)
begin
    wait(tb_matrix_top.StartTB);
    $fdisplay( tb_matrix_top.tb_log_file, "\n(%0t) Query State: 0x%0x", $time, QueryState);
    $write("\n(%0t) Query State: 0x%0x", $time, QueryState);
end
`endif

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      begin
         QueryState <= QUERYST_IDLE;
      end
   else
      begin
          QueryState <= querynext_state;
      end
end

always @(QueryState or StartQuery or p_QueryPreambleDone or tx_QueryShiftEmpty or BufCrc5Out) // include every comb input
begin

   querynext_state = QueryState;
   tx_QueryShiftDataIn = 32'h00000000;
   tx_QueryShiftBitCnt = 8'h00;
   
	case(QueryState)
       QUERYST_IDLE:
          begin
              if(StartQuery)
                 querynext_state = QUERYST_TXPREAMBLE;
          end
       QUERYST_TXPREAMBLE:
          begin
              if(p_QueryPreambleDone) 
                 begin
                    tx_QueryShiftDataIn = {4'b1000, r_DR_Ratio[12:0], 15'h0000};
                    tx_QueryShiftBitCnt = 8'h11;
                    querynext_state =  QUERYST_TXDRREG;
                end
          end
       QUERYST_TXDRREG:
          begin
              if(tx_QueryShiftEmpty)
                 begin
                    tx_QueryShiftDataIn[31:27] = BufCrc5Out[4:0];
                    tx_QueryShiftBitCnt = 8'h05;
                    querynext_state =  QUERYST_TXCRC5;  
                 end
          end
       QUERYST_TXCRC5:
          begin
              if(tx_QueryShiftEmpty)
                 begin
                    tx_QueryShiftDataIn = 32'h00000000;
                    tx_QueryShiftBitCnt = 8'h00;
                    querynext_state = QUERYST_IDLE;     
                 end
          end 
       QUERYST_FAILURE_RCVRY:
          begin
          // INVENTORY_OP_STATUS Failed
          // FAILURE_REASON_CODE
          // INT-SRC[4]
          end            
       default:   // include every comb output used, but not specified in always
          begin
          end
   endcase
end

endmodule
