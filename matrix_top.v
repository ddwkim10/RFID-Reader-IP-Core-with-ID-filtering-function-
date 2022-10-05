/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_top.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Resvision History
///      - 2008.04.11 Created
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"


module matrix_top(mtxDataIn, mtxAddress, mtxRw, mtxCs, mtxClk, mtxReset, mtxDataOut,
`ifdef MAT_DEBUG_FLAG
                  // s_RstHostCmd, 
                  irq_reg, SeqState, tx_ShiftPIEOut,
`endif
                  int_o
                  );
parameter Tp = 1;

input [31:0] mtxDataIn;
input [7:0] mtxAddress;

input mtxRw;
input [3:0] mtxCs;
input mtxClk;
input mtxReset;

output [31:0] mtxDataOut;

wire [15:0] r_HCSR_HostInvNumber;
wire r_HCSR_FilterOpStatus;
wire r_HCSR_InvOpStatus;
wire r_HCSR_AccessOpStatus;

wire i_Crc16_error_irq;
wire i_Fltr_match_irq;
wire i_Tx_error_irq;
wire i_Rx_error_irq;
wire i_Host_purge_cmplt_irq;
wire i_Host_access_cmplt_irq;
wire i_Host_inv_cmplt_irq;
wire i_Host_flt_cmplt_irq;
wire i_Seq_stall_irq;
wire i_Cb_ovf_irq;
wire i_Fdb_ovf_irq;

`ifdef MAT_DEBUG_FLAG
// input s_RstHostCmd;
input [31:0] irq_reg;

assign i_Crc16_error_irq = irq_reg[10];
assign i_Fltr_match_irq = irq_reg[9];
assign i_Tx_error_irq = irq_reg[8];
assign i_Rx_error_irq = irq_reg[7];
assign i_Host_purge_cmplt_irq = irq_reg[6];
assign i_Host_access_cmplt_irq = irq_reg[5];
assign i_Host_inv_cmplt_irq = irq_reg[4];
assign i_Host_flt_cmplt_irq = irq_reg[3];
assign i_Seq_stall_irq = irq_reg[2];
assign i_Cb_ovf_irq = irq_reg[1];
assign i_Fdb_ovf_irq = irq_reg[0];

output [4:0] SeqState;
output tx_ShiftPIEOut;
`else
wire s_RstHostCmd;
wire [4:0] SeqState;
`endif


wire [3:0] r_ExecHostCmd;

output int_o;

wire [1:0] r_TxRxModer_TxModType;
wire r_TxRxModer_FHSS_E;
wire r_TxRxModer_RxTrExt;
wire [1:0]r_TxRxModer_RxM;
wire r_TxRxModer_RxModType;
wire r_TxRxModer_ScanMode;

wire [15:0] r_Data0Len;
wire [15:0] r_Data1Len;
wire [15:0] r_PiePWLen;
wire [15:0] r_RTCalLen;
wire [15:0] r_TRCalLen;
wire [12:0] r_DR_Ratio;
wire [31:0] r_LnkFreq;
wire [7:0] r_ChanNum;
wire [15:0] r_LnkTimer1;
wire [15:0] r_LnkTimer2;
wire [15:0] r_LnkTimer3;
wire [15:0] r_LnkTimer4;
wire [31:0] r_RplyTimer;

wire [31:0] r_CmdReg;
wire [31:0] r_CmdPntReg;
wire [31:0] r_CmdCntReg;

wire [15:0] r_HndlReg;

wire r_FltrOpReg_BufferOp;
wire r_FltrOpReg_HostOp;
wire r_FltrOpReg_IntOp;
wire r_FltrOpReg_StickyOp; 
wire r_FltrOpReg_PhraseOp;
wire [1:0] r_FltrOpReg_LogicOp; 

wire [7:0] r_FltrCntReg;
  
wire r_DfltFltrOpReg_BufferOp;
wire r_DfltFltrOpReg_HostOp;
wire r_DfltFltrOpReg_IntOp;
wire r_DfltFltrOpReg_StickyOp;

wire r_PhyCSR_TxCW;
wire r_PwrManReg_Onoff;
wire r_TxRxCtrlReg_Tx_E;
wire r_TxRxCtrlReg_Rx_E;
wire [255:0] r_BigData;
wire [1:0] r_BigDataSel;
wire [15:0] r_Delimiter;

// Connecting matrix registers
matrix_registers mtxreg1
(
.DataIn(mtxDataIn),                      .Address(mtxAddress),                           .Rw(mtxRw), 
.Cs(mtxCs),                              .Clk(mtxClk),                                   .Reset(mtxReset), 
.DataOut(mtxDataOut),                    .r_HCSR_HostInvNumber(r_HCSR_HostInvNumber),    .r_HCSR_FilterOpStatus(r_HCSR_FilterOpStatus),
.r_HCSR_InvOpStatus(r_HCSR_InvOpStatus), .r_HCSR_AccessOpStatus(r_HCSR_AccessOpStatus),  .s_RstHostCmd(s_RstHostCmd),
.r_ExecHostCmd(r_ExecHostCmd),
.int_o(int_o),                           
.i_Crc16_error_irq(i_Crc16_error_irq),   .i_Fltr_match_irq(i_Fltr_match_irq),            .i_Tx_error_irq(i_Tx_error_irq),         
.i_Rx_error_irq(i_Rx_error_irq),         .i_Host_purge_cmplt_irq(i_Host_purge_cmplt_irq),.i_Host_access_cmplt_irq(i_Host_access_cmplt_irq),
.i_Host_inv_cmplt_irq(i_Host_inv_cmplt_irq),.i_Host_flt_cmplt_irq(i_Host_flt_cmplt_irq), .i_Seq_stall_irq(i_Seq_stall_irq),
.i_Cb_ovf_irq(i_Cb_ovf_irq),              .i_Fdb_ovf_irq(i_Fdb_ovf_irq),
.r_TxRxModer_TxModType(r_TxRxModer_TxModType),.r_TxRxModer_FHSS_E(r_TxRxModer_FHSS_E),   .r_TxRxModer_RxTrExt(r_TxRxModer_RxTrExt),
.r_TxRxModer_RxM(r_TxRxModer_RxM),        .r_TxRxModer_RxModType(r_TxRxModer_RxModType), .r_TxRxModer_ScanMode(r_TxRxModer_ScanMode),
.r_Data0Len(r_Data0Len),                  .r_Data1Len(r_Data1Len),                       .r_PiePWLen(r_PiePWLen), 
.r_RTCalLen(r_RTCalLen),                  .r_TRCalLen(r_TRCalLen),                       .r_DR_Ratio(r_DR_Ratio), 
.r_LnkFreq(r_LnkFreq),                    .r_ChanNum(r_ChanNum),                         .r_LnkTimer1(r_LnkTimer1), 
.r_LnkTimer2(r_LnkTimer2),                .r_LnkTimer3(r_LnkTimer3),                     .r_LnkTimer4(r_LnkTimer4), 
.r_RplyTimer(r_RplyTimer), 
.r_CmdReg(r_CmdReg),                      .r_CmdPntReg(r_CmdPntReg),                     .r_CmdCntReg(r_CmdCntReg), 
.r_HndlReg(),                             .r_FltrOpReg_BufferOp(),                       .r_FltrOpReg_HostOp(), 
.r_FltrOpReg_IntOp(r_FltrOpReg_IntOp),    .r_FltrOpReg_StickyOp(r_FltrOpReg_StickyOp),   .r_FltrOpReg_PhraseOp(r_FltrOpReg_PhraseOp), 
.r_FltrOpReg_LogicOp(r_FltrOpReg_LogicOp),.r_FltrCntReg(r_FltrCntReg),                   .r_DfltFltrOpReg_BufferOp(r_DfltFltrOpReg_BufferOp), 
.r_DfltFltrOpReg_HostOp(r_DfltFltrOpReg_HostOp),.r_DfltFltrOpReg_IntOp(r_DfltFltrOpReg_IntOp),.r_DfltFltrOpReg_StickyOp(r_DfltFltrOpReg_StickyOp),
.r_PhyCSR_TxCW(r_PhyCSR_TxCW),            .r_PwrManReg_Onoff(r_PwrManReg_Onoff),         .r_TxRxCtrlReg_Tx_E(r_TxRxCtrlReg_Tx_E), 
.r_TxRxCtrlReg_Rx_E(r_TxRxCtrlReg_Rx_E),  .r_BigData(r_BigData),                         .r_BigDataSel(r_BigDataSel),
.r_Delimiter(r_Delimiter)
);

wire h_StartHInvRound;
wire h_EndHinvRound;

matrix_sequencer mtxseq1
(
.Clk(mtxClk),                             .Reset(mtxReset),                              .SeqState(SeqState),
.r_ExecHostCmd(r_ExecHostCmd),            .s_RstHostCmd(s_RstHostCmd),                   .h_StartHInvRound(h_StartHInvRound), 
.h_EndHinvRound(h_EndHinvRound)
);

wire [1:0] r_InvBigDataSel;
wire [31:0] tx_InvShiftDataIn;
wire [7:0] tx_InvShiftBitCnt;
wire tx_InvShiftLoad;
wire tx_InvShiftStart;
wire p_InvFrameSyncLoad; 
wire p_InvFrameSyncStart;
wire p_InvPreambleLoad; 
wire p_InvPreambleStart;
wire rx_RN16Received; 
wire rx_CollisionDetected;

wire tx_ShiftEmpty;
wire p_FrameSyncDone;
wire p_PreambleDone;
wire tx_InvFinalShiftLoadErase;

assign r_BigDataSel = r_InvBigDataSel; // bitwise |

wire tx_InvStartCRC16Tr;
wire [15:0] BufCrc16Out;
wire tx_InvStartCRC5Tr;
wire [4:0] BufCrc5Out;
wire TagDataType;

matrix_inventory mtxinv1
(
.Clk(mtxClk),                             .Reset(mtxReset),                              .h_StartHInvRound(h_StartHInvRound), 
.h_EndHinvRound(h_EndHinvRound),          .r_CmdReg(r_CmdReg),                           .r_CmdPntReg(r_CmdPntReg), 
.r_CmdCntReg(r_CmdCntReg),                .r_BigData(r_BigData),                         .r_InvBigDataSel(r_InvBigDataSel),
.tx_InvShiftDataIn(tx_InvShiftDataIn),    .tx_InvShiftBitCnt(tx_InvShiftBitCnt),         .tx_InvShiftLoad(tx_InvShiftLoad), 
.tx_InvShiftStart(tx_InvShiftStart),      .tx_InvShiftEmpty(tx_ShiftEmpty),              .p_InvFrameSyncLoad(p_InvFrameSyncLoad), 
.p_InvFrameSyncStart(p_InvFrameSyncStart),.p_InvFrameSyncDone(p_FrameSyncDone),          .p_InvPreambleLoad(p_InvPreambleLoad), 
.p_InvPreambleStart(p_InvPreambleStart),  .p_InvPreambleDone(p_PreambleDone),            .rx_RN16Received(rx_RN16Received), 
.rx_CollisionDetected(rx_CollisionDetected),.tx_InvStartCRC16Tr(tx_InvStartCRC16Tr),     .BufCrc16Out(BufCrc16Out),
.tx_InvFinalShiftLoadErase(tx_InvFinalShiftLoadErase), .r_LnkTimer1(r_LnkTimer1),        .r_LnkTimer2(r_LnkTimer2), 
.r_LnkTimer3(r_LnkTimer3),                .r_LnkTimer4(r_LnkTimer4),                     .r_DR_Ratio(r_DR_Ratio),
.tx_InvStartCRC5Tr(tx_InvStartCRC5Tr),    .BufCrc5Out(BufCrc5Out),                       .TagDataType(TagDataType)
);


wire [31:0] tx_ShiftDataIn;
wire [7:0] tx_ShiftBitCnt;
wire tx_ShiftLoad;
wire tx_ShiftStart;
wire tx_ShiftOut;
wire tx_ShiftPIEOut;
wire tx_FinalShiftLoadErase;

assign tx_ShiftDataIn = tx_InvShiftDataIn; // bitwise |
assign tx_ShiftBitCnt = tx_InvShiftBitCnt;
assign tx_ShiftLoad = tx_InvShiftLoad;
assign tx_ShiftStart = tx_InvShiftStart;
assign tx_FinalShiftLoadErase = tx_InvFinalShiftLoadErase;

wire tx_LoadPIE;
wire tx_StartPIE;
wire tx_ShiftNextBitToPIE;
wire p_FrameSyncLoad;
wire p_FrameSyncStart;

wire p_PreambleLoad;
wire p_PreambleStart; 


matrix_txshiftreg mtxtxshiftreg1
(
.Clk(mtxClk),                             .Reset(mtxReset),                              .tx_ShiftDataIn(tx_ShiftDataIn), 
.tx_ShiftBitCnt(tx_ShiftBitCnt),          .tx_ShiftLoad(tx_ShiftLoad),                   .tx_ShiftStart(tx_ShiftStart), 
.tx_ShiftEmpty(tx_ShiftEmpty),            .tx_ShiftOut(tx_ShiftOut),                     .tx_LoadPIE(tx_LoadPIE),
.tx_StartPIE(tx_StartPIE),                .tx_ShiftNextBitToPIE(tx_ShiftNextBitToPIE),   .tx_FinalShiftLoadErase(tx_FinalShiftLoadErase)
);

assign p_FrameSyncLoad  = p_InvFrameSyncLoad;  // bitwise |
assign p_FrameSyncStart = p_InvFrameSyncStart;
assign p_PreambleLoad   = p_InvPreambleLoad;
assign p_PreambleStart  = p_InvPreambleStart; 

matrix_pieenc mtxpieenc1
(
.Clk(mtxClk),                             .Reset(mtxReset),                              .tx_ShiftOut(tx_ShiftOut), 
.tx_LoadPIE(tx_LoadPIE),                  .tx_StartPIE(tx_StartPIE),                     .tx_ShiftNextBitToPIE(tx_ShiftNextBitToPIE), 
.tx_ShiftPIEOut(tx_ShiftPIEOut),          .r_Data0Len(r_Data0Len),                       .r_Data1Len(r_Data1Len), 
.r_PiePWLen(r_PiePWLen),                  .r_RTCalLen(r_RTCalLen),                       .r_TRCalLen(r_TRCalLen), 
.r_Delimiter(r_Delimiter),                .p_FrameSyncLoad(p_FrameSyncLoad),             .p_FrameSyncStart(p_FrameSyncStart), 
.p_FrameSyncDone(p_FrameSyncDone),        .p_PreambleLoad(p_PreambleLoad),               .p_PreambleStart(p_PreambleStart), 
.p_PreambleDone(p_PreambleDone)
);

wire StartCRC16Tr;
wire BufCrc16Error;

assign StartCRC16Tr = tx_InvStartCRC16Tr; // bitwise |

matrix_buffered_crc16 mtxbufcrc161
(
.Clk(mtxClk),                            .Reset(mtxReset),                              .StartCRC16Tr(StartCRC16Tr), 
.c_ShiftDataIn(tx_ShiftDataIn),          .c_ShiftBitCnt(tx_ShiftBitCnt),                .c_ShiftLoad(tx_ShiftLoad), 
.BufCrc16Out(BufCrc16Out),               .BufCrc16Error(BufCrc16Error)
);

wire StartCRC5Tr;
wire BufCrc5Error;

assign StartCRC5Tr = tx_InvStartCRC5Tr; // bitwise |

matrix_buffered_crc5 mtxbufcrc51
(
.Clk(mtxClk),                            .Reset(mtxReset),                              .StartCRC5Tr(StartCRC5Tr),
.c_ShiftDataIn(tx_ShiftDataIn),          .c_ShiftBitCnt(tx_ShiftBitCnt),                .c_ShiftLoad(tx_ShiftLoad), 
.BufCrc5Out(BufCrc5Out),                 .BufCrc5Error(BufCrc5Error) 
);

endmodule
