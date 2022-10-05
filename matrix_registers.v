/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_registers.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Revision History
///      - 2008.04.11
///
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"

module matrix_registers(DataIn, Address, Rw, Cs, Clk, Reset, DataOut,
                        r_HCSR_HostInvNumber, r_HCSR_FilterOpStatus, r_HCSR_InvOpStatus,
                        r_HCSR_AccessOpStatus, s_RstHostCmd, r_ExecHostCmd,
                        int_o, i_Crc16_error_irq, i_Fltr_match_irq, i_Tx_error_irq, i_Rx_error_irq, i_Host_purge_cmplt_irq, 
                        i_Host_access_cmplt_irq, i_Host_inv_cmplt_irq, i_Host_flt_cmplt_irq, i_Seq_stall_irq, i_Cb_ovf_irq, 
                        i_Fdb_ovf_irq,
                        r_TxRxModer_TxModType, r_TxRxModer_FHSS_E, r_TxRxModer_RxTrExt, r_TxRxModer_RxM,
                        r_TxRxModer_RxModType, r_TxRxModer_ScanMode,
                        r_Data0Len, r_Data1Len, r_PiePWLen, r_RTCalLen, r_TRCalLen, r_DR_Ratio, r_LnkFreq, r_ChanNum,
                        r_LnkTimer1, r_LnkTimer2, r_LnkTimer3, r_LnkTimer4, r_RplyTimer,
                        r_CmdReg, r_CmdPntReg, r_CmdCntReg, r_HndlReg, 
                        r_FltrOpReg_BufferOp, r_FltrOpReg_HostOp, r_FltrOpReg_IntOp, r_FltrOpReg_StickyOp, 
                        r_FltrOpReg_PhraseOp, r_FltrOpReg_LogicOp,
                        r_FltrCntReg, 
                        r_DfltFltrOpReg_BufferOp, r_DfltFltrOpReg_HostOp, r_DfltFltrOpReg_IntOp, r_DfltFltrOpReg_StickyOp,
                        r_PhyCSR_TxCW, r_PwrManReg_Onoff, r_TxRxCtrlReg_Tx_E, r_TxRxCtrlReg_Rx_E,
                        r_BigData, r_BigDataSel, r_Delimiter
                        );

parameter Tp = 1;

input [31:0] DataIn;
input [7:0] Address;

input Rw;
input [3:0] Cs;
input Clk;
input Reset;

output [31:0] DataOut;
reg    [31:0] DataOut;

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin RF Module I/O's
// HOSTCSR
output [15:0]  r_HCSR_HostInvNumber;
output r_HCSR_FilterOpStatus;
output r_HCSR_InvOpStatus;
output r_HCSR_AccessOpStatus;
input s_RstHostCmd;
output [3:0] r_ExecHostCmd;
// IRQ
output int_o;
// INT-SRC
input i_Crc16_error_irq;
input i_Fltr_match_irq;
input i_Tx_error_irq;
input i_Rx_error_irq;
input i_Host_purge_cmplt_irq;
input i_Host_access_cmplt_irq;
input i_Host_inv_cmplt_irq;
input i_Host_flt_cmplt_irq;
input i_Seq_stall_irq;
input i_Cb_ovf_irq;
input i_Fdb_ovf_irq;
// Tx-Moder
output [1:0] r_TxRxModer_TxModType;
output r_TxRxModer_FHSS_E;
output r_TxRxModer_RxTrExt;
output [1:0]r_TxRxModer_RxM;
output r_TxRxModer_RxModType;
output r_TxRxModer_ScanMode;
// Signal Parameters
output [15:0] r_Data0Len;
output [15:0] r_Data1Len;
output [15:0] r_PiePWLen;
output [15:0] r_RTCalLen;
output [15:0] r_TRCalLen;
output [12:0] r_DR_Ratio;
output [31:0] r_LnkFreq;
output [7:0] r_ChanNum;
output [15:0] r_LnkTimer1;
output [15:0] r_LnkTimer2;
output [15:0] r_LnkTimer3;
output [15:0] r_LnkTimer4;
output [31:0] r_RplyTimer;
// CMDREG
output [31:0] r_CmdReg;
output [31:0] r_CmdPntReg;
output [31:0] r_CmdCntReg;
//HNDLREG
output [15:0] r_HndlReg;
// FLTROPREG
output r_FltrOpReg_BufferOp;
output r_FltrOpReg_HostOp;
output r_FltrOpReg_IntOp;
output r_FltrOpReg_StickyOp; 
output r_FltrOpReg_PhraseOp;
output [1:0] r_FltrOpReg_LogicOp; 
output [7:0] r_FltrCntReg;  
output r_DfltFltrOpReg_BufferOp;
output r_DfltFltrOpReg_HostOp;
output r_DfltFltrOpReg_IntOp;
output r_DfltFltrOpReg_StickyOp;
// Misc.
output r_PhyCSR_TxCW;
output r_PwrManReg_Onoff;
output r_TxRxCtrlReg_Tx_E;
output r_TxRxCtrlReg_Rx_E;
output [255:0] r_BigData;
input [1:0] r_BigDataSel;
output [15:0] r_Delimiter;

// End RF Module I/O's
//////////////////////////////////////////////////////////////////////////////////////////////////

wire [3:0] Write =   Cs  & {4{Rw}};
wire       Read  = (|Cs) &   ~Rw;

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin HOSTCSR register
// Define HCSR address & WR signals
wire HCSR_Sel      = (Address == `MAT_HOST_CSR_ADR       );

wire [3:0] HCSR_Wr;
wire HCSRInvN_Wr;

assign HCSR_Wr[0]       = Write[0]  & HCSR_Sel;
assign HCSR_Wr[1]       = Write[1]  & HCSR_Sel;
assign HCSR_Wr[2]       = Write[2]  & HCSR_Sel;
assign HCSR_Wr[3]       = Write[3]  & HCSR_Sel;
assign HCSRInvN_Wr      = HCSR_Wr[0] & HCSR_Wr[1];

// Define HCSR output signals
wire [31:0] HCSROut;

// Instantiate CSR Register
matrix_register #(`MAT_HOST_CSR_WIDTH_0, `MAT_HOST_CSR_DEFLT_0)        HCSR_0
  (
   .DataIn    (DataIn[`MAT_HOST_CSR_WIDTH_0 - 1:0]),
   .DataOut   (HCSROut[`MAT_HOST_CSR_WIDTH_0 - 1:0]),
   .Write     (HCSRInvN_Wr),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );

matrix_register #(`MAT_HOST_CSR_WIDTH_1, `MAT_HOST_CSR_DEFLT_1)        HCSR_1
  (
   .DataIn    (DataIn[`MAT_HOST_CSR_WIDTH_1 + 15:16]),
   .DataOut   (HCSROut[`MAT_HOST_CSR_WIDTH_1 + 15:16]),
   .Write     (HCSR_Wr[2]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
 
matrix_register #(`MAT_HOST_CSR_WIDTH_2, `MAT_HOST_CSR_DEFLT_2)        HCSR_2
   (
    .DataIn    (DataIn[`MAT_HOST_CSR_WIDTH_2 + 23:24]),
    .DataOut   (HCSROut[`MAT_HOST_CSR_WIDTH_2 + 23:24]),
    .Write     (HCSR_Wr[3]),
    .Clk       (Clk),
    .Reset     (Reset),
    .SyncReset (s_RstHostCmd)
   );
   
assign HCSROut[23:`MAT_HOST_CSR_WIDTH_1 + 16] = 0;
assign HCSROut[31:`MAT_HOST_CSR_WIDTH_2 + 24] = 0;

// Assign module outputs from CSR
assign r_HCSR_HostInvNumber[15:0] = HCSROut[15:0];
assign r_HCSR_FilterOpStatus = HCSROut[16];
assign r_HCSR_InvOpStatus = HCSROut[17];
assign r_HCSR_AccessOpStatus = HCSROut[18];
assign r_ExecHostCmd[3:0] = HCSROut[27:24];

// End of CSR register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin INT-MSK register
// Define INT-MSK address & WR signals
wire INT_MASK_Sel      = (Address == `MAT_INT_MSK_ADR       );

wire [1:0] INT_MASK_Wr;

assign INT_MASK_Wr[0]     = Write[0]  & INT_MASK_Sel;
assign INT_MASK_Wr[1]     = Write[1]  & INT_MASK_Sel;

// Define INT-MSK output signals
wire [31:0] INT_MASKOut;


// Instantiate INT-MSK Register
matrix_register #(`MAT_INT_MSK_WIDTH_0, `MAT_INT_MSK_DEFLT_0)  INT_MASK_0
(
.DataIn    (DataIn[`MAT_INT_MSK_WIDTH_0 - 1:0]),  
.DataOut   (INT_MASKOut[`MAT_INT_MSK_WIDTH_0 - 1:0]),
.Write     (INT_MASK_Wr[0]),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

matrix_register #(`MAT_INT_MSK_WIDTH_1, `MAT_INT_MSK_DEFLT_1)  INT_MASK_1
(
.DataIn    (DataIn[`MAT_INT_MSK_WIDTH_1 + 7:8]),  
.DataOut   (INT_MASKOut[`MAT_INT_MSK_WIDTH_1 + 7:8]),
.Write     (INT_MASK_Wr[1]),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign INT_MASKOut[31:`MAT_INT_MSK_WIDTH_1 + 8] = 0;

// End of INT-MSK register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin INT-SRC register
wire INT_SRC_Sel      = (Address == `MAT_INT_SRC_ADR       );

wire [1:0] INT_SRC_Wr;

assign INT_SRC_Wr[0]     = Write[0]  & INT_SRC_Sel;
assign INT_SRC_Wr[1]     = Write[1]  & INT_SRC_Sel;

wire [31:0] INT_SOURCEOut;

reg irq_fdb_ovf;
reg irq_cb_ovf;
reg irq_seq_stall;
reg irq_host_flt_cmplt;
reg irq_host_inv_cmplt;
reg irq_host_access_cmplt;
reg irq_host_purge_cmplt;
reg irq_rx_error;
reg irq_tx_error;
reg irq_fltr_match;
reg irq_crc16_error;

// Interrupt generation
always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_fdb_ovf <= 1'b0;
   else
   if(i_Fdb_ovf_irq)
      irq_fdb_ovf <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[0])
      irq_fdb_ovf <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_cb_ovf <= 1'b0;
   else
   if(i_Cb_ovf_irq)
      irq_cb_ovf <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[1])
      irq_cb_ovf <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_seq_stall <= 1'b0;
   else
   if(i_Seq_stall_irq)
      irq_seq_stall <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[2])
      irq_seq_stall <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_host_flt_cmplt <= 1'b0;
   else
   if(i_Host_flt_cmplt_irq)
      irq_host_flt_cmplt <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[3])
      irq_host_flt_cmplt <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_host_inv_cmplt <= 1'b0;
   else
   if(i_Host_inv_cmplt_irq)
      irq_host_inv_cmplt <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[4])
      irq_host_inv_cmplt <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_host_access_cmplt <= 1'b0;
   else
   if(i_Host_access_cmplt_irq)
      irq_host_access_cmplt <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[5])
      irq_host_access_cmplt <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_host_purge_cmplt <= 1'b0;
   else
   if(i_Host_purge_cmplt_irq)
      irq_host_purge_cmplt <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[6])
      irq_host_purge_cmplt <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_rx_error <= 1'b0;
   else
   if(i_Rx_error_irq)
      irq_rx_error <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[0] & DataIn[7])
      irq_rx_error <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_tx_error <= 1'b0;
   else
   if(i_Tx_error_irq)
      irq_tx_error <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[1] & DataIn[8])
      irq_tx_error <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_fltr_match <= 1'b0;
   else
   if(i_Fltr_match_irq)
      irq_fltr_match <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[1] & DataIn[9])
      irq_fltr_match <= #Tp 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
   if(Reset)
      irq_crc16_error <= 1'b0;
   else
   if(i_Crc16_error_irq)
      irq_crc16_error <= #Tp 1'b1;
   else
   if(INT_SRC_Wr[1] & DataIn[10])
      irq_crc16_error <= #Tp 1'b0;
end

// Generating output interrupt signal
assign int_o = irq_fdb_ovf           & INT_MASKOut[0] | 
               irq_cb_ovf            & INT_MASKOut[1] | 
               irq_seq_stall         & INT_MASKOut[2] | 
               irq_host_flt_cmplt    & INT_MASKOut[3] | 
               irq_host_inv_cmplt    & INT_MASKOut[4] | 
               irq_host_access_cmplt & INT_MASKOut[5] | 
               irq_host_purge_cmplt  & INT_MASKOut[6] |
               irq_rx_error          & INT_MASKOut[7] |  
               irq_tx_error          & INT_MASKOut[8] |
               irq_fltr_match        & INT_MASKOut[9] |
               irq_crc16_error       & INT_MASKOut[10];

// For reading INT-SRC register
assign INT_SOURCEOut = {{(32-`MAT_INT_SRC_WIDTH_1-`MAT_INT_SRC_WIDTH_0){1'b0}}, irq_crc16_error, irq_fltr_match, 
                        irq_tx_error, irq_rx_error, irq_host_purge_cmplt, irq_host_access_cmplt, irq_host_inv_cmplt,
                        irq_host_flt_cmplt, irq_seq_stall, irq_cb_ovf, irq_fdb_ovf};


// End of INT-SRC register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin TxRx-Moder register
// Define TxRx_Moder address & WR signals
wire TxRx_Moder_Sel      = (Address == `MAT_TXRX_MODER_ADR       );

wire TxRx_Moder_Wr;

assign TxRx_Moder_Wr     = Write[0]  & TxRx_Moder_Sel;

// Define TxRx-Moder output signals
wire [31:0] TxRx_ModerOut;

// Instantiate TxRx-Moder Register
matrix_register #(`MAT_TXRX_MODER_WIDTH, `MAT_TXRX_MODER_DEFLT)  TXRX_MODER
(
.DataIn    (DataIn[`MAT_TXRX_MODER_WIDTH - 1:0]),  
.DataOut   (TxRx_ModerOut[`MAT_TXRX_MODER_WIDTH - 1:0]),
.Write     (TxRx_Moder_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign TxRx_ModerOut[31:`MAT_TXRX_MODER_WIDTH] = 0;

// Assign module outputs from Tx-Moder
assign r_TxRxModer_TxModType[1:0] = TxRx_ModerOut[1:0];
assign r_TxRxModer_FHSS_E = TxRx_ModerOut[2];
assign r_TxRxModer_RxTrExt = TxRx_ModerOut[3];
assign r_TxRxModer_RxM[1:0] = TxRx_ModerOut[5:4];
assign r_TxRxModer_RxModType = TxRx_ModerOut[6];
assign r_TxRxModer_ScanMode = TxRx_ModerOut[7];

// End of Tx-Moder register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin DATA0LEN register
// Define DATA0LEN address & WR signals
wire DATA0LEN_Sel      = (Address == `MAT_DATA0LEN_ADR       );

wire DATA0LEN16_Wr;

assign DATA0LEN16_Wr      = Write[0]  & Write[1]  & DATA0LEN_Sel;

// Define DATA0LEN output signals
wire [31:0] DATA0LENOut;


// Instantiate DATA0LEN Register
matrix_register #(`MAT_DATA0LEN_WIDTH, `MAT_DATA0LEN_DEFLT)  DATA0LEN
(
.DataIn    (DataIn[`MAT_DATA0LEN_WIDTH - 1:0]),  
.DataOut   (DATA0LENOut[`MAT_DATA0LEN_WIDTH - 1:0]),
.Write     (DATA0LEN16_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign DATA0LENOut[31:`MAT_DATA0LEN_WIDTH] = 0;

// Assign module outputs from DATA0LEN
assign r_Data0Len[15:0] = DATA0LENOut[15:0];

// End of DATA0LEN register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin DATA1LEN register
// Define DATA1LEN address & WR signals
wire DATA1LEN_Sel      = (Address == `MAT_DATA1LEN_ADR       );

wire DATA1LEN16_Wr;

assign DATA1LEN16_Wr      = Write[0]  & Write[1]  & DATA1LEN_Sel;

// Define DATA1LEN output signals
wire [31:0] DATA1LENOut;


// Instantiate DATA1LEN Register
matrix_register #(`MAT_DATA1LEN_WIDTH, `MAT_DATA1LEN_DEFLT)  DATA1LEN
(
.DataIn    (DataIn[`MAT_DATA1LEN_WIDTH - 1:0]),  
.DataOut   (DATA1LENOut[`MAT_DATA1LEN_WIDTH - 1:0]),
.Write     (DATA1LEN16_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign DATA1LENOut[31:`MAT_DATA1LEN_WIDTH] = 0;

// Assign module outputs from DATA1LEN
assign r_Data1Len[15:0] = DATA1LENOut[15:0];

// End of DATA1LEN register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin PIEPWLEN register
// Define PIEPWLEN address & WR signals
wire PIEPWLEN_Sel      = (Address == `MAT_PIEPWLEN_ADR       );

wire PIEPWLEN16_Wr;

assign PIEPWLEN16_Wr   = Write[0]  & Write[1]  & PIEPWLEN_Sel;

// Define PIEPWLEN output signals
wire [31:0] PIEPWLENOut;


// Instantiate PIEPWLEN Register
matrix_register #(`MAT_PIEPWLEN_WIDTH, `MAT_PIEPWLEN_DEFLT)  PIEPWLEN
(
.DataIn    (DataIn[`MAT_PIEPWLEN_WIDTH - 1:0]),  
.DataOut   (PIEPWLENOut[`MAT_PIEPWLEN_WIDTH - 1:0]),
.Write     (PIEPWLEN16_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign PIEPWLENOut[31:`MAT_PIEPWLEN_WIDTH] = 0;

// Assign module outputs from PIEPWLEN
assign r_PiePWLen[15:0] = PIEPWLENOut[15:0];

// End of PIEPWLEN register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin RTCALLEN register
// Define RTCALLEN address & WR signals
wire RTCALLEN_Sel      = (Address == `MAT_RTCALLEN_ADR       );

wire RTCALLEN16_Wr;

assign RTCALLEN16_Wr   = Write[0]  & Write[1]  & RTCALLEN_Sel;

// Define RTCALLEN output signals
wire [31:0] RTCALLENOut;


// Instantiate RTCALLEN Register
matrix_register #(`MAT_RTCALLEN_WIDTH, `MAT_RTCALLEN_DEFLT)  RTCALLEN
(
.DataIn    (DataIn[`MAT_RTCALLEN_WIDTH - 1:0]),  
.DataOut   (RTCALLENOut[`MAT_RTCALLEN_WIDTH - 1:0]),
.Write     (RTCALLEN16_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign RTCALLENOut[31:`MAT_RTCALLEN_WIDTH] = 0;

// Assign module outputs from RTCALLEN
assign r_RTCalLen[15:0] = RTCALLENOut[15:0];

// End of RTCALLEN register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin TRCALLEN register
// Define TRCALLEN address & WR signals
wire TRCALLEN_Sel      = (Address == `MAT_TRCALLEN_ADR       );

wire TRCALLEN16_Wr;

assign TRCALLEN16_Wr      = Write[0]  & Write[1]  & TRCALLEN_Sel;

// Define TRCALLEN output signals
wire [31:0] TRCALLENOut;


// Instantiate TRCALLEN Register
matrix_register #(`MAT_TRCALLEN_WIDTH, `MAT_TRCALLEN_DEFLT)  TRCALLEN
(
.DataIn    (DataIn[`MAT_TRCALLEN_WIDTH - 1:0]),  
.DataOut   (TRCALLENOut[`MAT_TRCALLEN_WIDTH - 1:0]),
.Write     (TRCALLEN16_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign TRCALLENOut[31:`MAT_TRCALLEN_WIDTH] = 0;

// Assign module outputs from TRCALLEN
assign r_TRCalLen[15:0] = TRCALLENOut[15:0];

// End of TRCALLEN register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin DR-RATIO register
// Define DR-Ratio address & WR signals
wire DR_RATIO_Sel      = (Address == `MAT_DR_RATIO_ADR       );

wire DR_RATIO_Wr;

assign DR_RATIO_Wr     = Write[0] & Write[1] & DR_RATIO_Sel;


// Define DR_RATIO output signals
wire [31:0] DR_RATIOOut;


// Instantiate DR-RATIO Register
matrix_register #(`MAT_DR_RATIO_WIDTH, `MAT_DR_RATIO_DEFLT)  DR_RATIO
(
.DataIn    (DataIn[`MAT_DR_RATIO_WIDTH - 1:0]),  
.DataOut   (DR_RATIOOut[`MAT_DR_RATIO_WIDTH - 1:0]),
.Write     (DR_RATIO_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign DR_RATIOOut[31:`MAT_DR_RATIO_WIDTH] = 0;

// Assign module outputs from DR-RATIO
assign r_DR_Ratio[12:0] = DR_RATIOOut[12:0];

// End of DR-RATIO register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin LNKFREQ register
// Define LNKFREQ address & WR signals
wire LNKFREQ_Sel      = (Address == `MAT_LNKFREQ_ADR       );

wire LNKFREQ32_Wr;

assign LNKFREQ32_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & LNKFREQ_Sel;

// Define LNKFREQ output signals
wire [31:0] LNKFREQOut;


// Instantiate LNKFREQ Register
matrix_register #(`MAT_LNKFREQ_WIDTH, `MAT_LNKFREQ_DEFLT)  LNKFREQ
(
.DataIn    (DataIn[`MAT_LNKFREQ_WIDTH - 1:0]),  
.DataOut   (LNKFREQOut[`MAT_LNKFREQ_WIDTH - 1:0]),
.Write     (LNKFREQ32_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// Assign module outputs from LNKFREQ
assign r_LnkFreq[31:0] = LNKFREQOut[31:0];

// End of LNKFREQ register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CHANNUM register
// Define CHANNUM address & WR signals
wire CHANNUM_Sel      = (Address == `MAT_CHANNUM_ADR       );

wire CHANNUM_Wr;

assign CHANNUM_Wr     = Write[0]  & CHANNUM_Sel;

// Define CHANNUM output signals
wire [31:0] CHANNUMOut;


// Instantiate CHANNUM Register
matrix_register #(`MAT_CHANNUM_WIDTH, `MAT_CHANNUM_DEFLT)  CHANNUM
(
.DataIn    (DataIn[`MAT_CHANNUM_WIDTH - 1:0]),  
.DataOut   (CHANNUMOut[`MAT_CHANNUM_WIDTH - 1:0]),
.Write     (CHANNUM_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign CHANNUMOut[31:`MAT_CHANNUM_WIDTH] = 0;

// Assign module outputs from CHANNUM
assign r_ChanNum[7:0] = CHANNUMOut[7:0];

// End of CHANNUM register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin LNKTIMER1 register
// Define LNKTIMER1 address & WR signals
wire LNKTIMER1_Sel      = (Address == `MAT_LNKTIMER1_ADR       );

wire LNKTIMER116_Wr;

assign LNKTIMER116_Wr   = Write[0]  & Write[1]  & LNKTIMER1_Sel;

// Define LNKTIMER1 output signals
wire [31:0] LNKTIMER1Out;


// Instantiate LNKTIMER1 Register
matrix_register #(`MAT_LNKTIMER1_WIDTH, `MAT_LNKTIMER1_DEFLT)  LNKTIMER1
(
.DataIn    (DataIn[`MAT_LNKTIMER1_WIDTH - 1:0]),  
.DataOut   (LNKTIMER1Out[`MAT_LNKTIMER1_WIDTH - 1:0]),
.Write     (LNKTIMER116_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign LNKTIMER1Out[31:`MAT_LNKTIMER1_WIDTH] = 0;

// Assign module outputs from LNKTIMER1
assign r_LnkTimer1[15:0] = LNKTIMER1Out[15:0];

// End of LNKTIMER1 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin LNKTIMER2 register
// Define LNKTIMER2 address & WR signals
wire LNKTIMER2_Sel      = (Address == `MAT_LNKTIMER2_ADR       );

wire LNKTIMER216_Wr;

assign LNKTIMER216_Wr   = Write[0]  & Write[1]  & LNKTIMER2_Sel;

// Define LNKTIMER2 output signals
wire [31:0] LNKTIMER2Out;


// Instantiate LNKTIMER2 Register
matrix_register #(`MAT_LNKTIMER2_WIDTH, `MAT_LNKTIMER2_DEFLT)  LNKTIMER2
(
.DataIn    (DataIn[`MAT_LNKTIMER2_WIDTH - 1:0]),  
.DataOut   (LNKTIMER2Out[`MAT_LNKTIMER2_WIDTH - 1:0]),
.Write     (LNKTIMER216_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign LNKTIMER2Out[31:`MAT_LNKTIMER2_WIDTH] = 0;

// Assign module outputs from LNKTIMER2
assign r_LnkTimer2[15:0] = LNKTIMER2Out[15:0];


// End of LNKTIMER2 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin LNKTIMER3 register
// Define LNKTIMER3 address & WR signals
wire LNKTIMER3_Sel      = (Address == `MAT_LNKTIMER3_ADR       );

wire LNKTIMER3_Wr;

assign LNKTIMER3_Wr   = Write[0] & LNKTIMER3_Sel;

// Define LNKTIMER3 output signals
wire [31:0] LNKTIMER3Out;


// Instantiate LNKTIMER3 Register
matrix_register #(`MAT_LNKTIMER3_WIDTH, `MAT_LNKTIMER3_DEFLT)  LNKTIMER3
(
.DataIn    (DataIn[`MAT_LNKTIMER3_WIDTH - 1:0]),  
.DataOut   (LNKTIMER3Out[`MAT_LNKTIMER3_WIDTH - 1:0]),
.Write     (LNKTIMER3_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign LNKTIMER3Out[31:`MAT_LNKTIMER3_WIDTH] = 0;

// Assign module outputs from LNKTIMER3
assign r_LnkTimer3[15:0] = LNKTIMER3Out[15:0];

// End of LNKTIMER3 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin LNKTIMER4 register
// Define LNKTIMER4 address & WR signals
wire LNKTIMER4_Sel      = (Address == `MAT_LNKTIMER4_ADR       );

wire LNKTIMER416_Wr;

assign LNKTIMER416_Wr   = Write[0]  & Write[1]  & LNKTIMER4_Sel;

// Define LNKTIMER4 output signals
wire [31:0] LNKTIMER4Out;

// Instantiate LNKTIMER4 Register
matrix_register #(`MAT_LNKTIMER4_WIDTH, `MAT_LNKTIMER4_DEFLT)  LNKTIMER4
(
.DataIn    (DataIn[`MAT_LNKTIMER4_WIDTH - 1:0]),  
.DataOut   (LNKTIMER4Out[`MAT_LNKTIMER4_WIDTH - 1:0]),
.Write     (LNKTIMER416_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign LNKTIMER4Out[31:`MAT_LNKTIMER4_WIDTH] = 0;

// Assign module outputs from LNKTIMER4
assign r_LnkTimer4[15:0] = LNKTIMER4Out[15:0];

// End of LNKTIMER4 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin RPLYTIMER register
// Define RPLYTIMER address & WR signals
wire RPLYTIMER_Sel      = (Address == `MAT_RPLYTIMER_ADR       );

wire RPLYTIMER32_Wr;

assign RPLYTIMER32_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & RPLYTIMER_Sel;

// Define RPLYTIMER output signals
wire [31:0] RPLYTIMEROut;

// Instantiate RPLYTIMER Register
matrix_register #(`MAT_RPLYTIMER_WIDTH, `MAT_RPLYTIMER_DEFLT)  RPLYTIMER
(
.DataIn    (DataIn[`MAT_RPLYTIMER_WIDTH - 1:0]),  
.DataOut   (RPLYTIMEROut[`MAT_RPLYTIMER_WIDTH - 1:0]),
.Write     (RPLYTIMER32_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// Assign module outputs from RPLYTIMER
assign r_RplyTimer[31:0] = RPLYTIMEROut[31:0];

// End of RPLYTIMER register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDREG register
// Define CMDREG address & WR signals
wire CMDREG_Sel      = (Address == `MAT_CMDREG_ADR       );

wire CMDREG32_Wr;

assign CMDREG32_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDREG_Sel;

// Define CMDREG output signals
wire [31:0] CMDREGOut;


// Instantiate CMDREG Register
matrix_register #(`MAT_CMDREG_WIDTH, `MAT_CMDREG_DEFLT)  CMDREG
(
.DataIn    (DataIn[`MAT_CMDREG_WIDTH - 1:0]),  
.DataOut   (CMDREGOut[`MAT_CMDREG_WIDTH - 1:0]),
.Write     (CMDREG32_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// Assign module outputs from CMDREG
assign r_CmdReg[31:0] = CMDREGOut[31:0];

// End of CMDREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDPNTREG register
// Define CMDPNTREG address & WR signals
wire CMDPNTREG_Sel      = (Address == `MAT_CMDPNTREG_ADR       );

wire CMDPNTREG32_Wr;

assign CMDPNTREG32_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDPNTREG_Sel;

// Define CMDPNTREG output signals
wire [31:0] CMDPNTREGOut;

// Instantiate CMDPNTREG Register
matrix_register #(`MAT_CMDPNTREG_WIDTH, `MAT_CMDPNTREG_DEFLT)  CMDPNTREG
(
.DataIn    (DataIn[`MAT_CMDPNTREG_WIDTH - 1:0]),  
.DataOut   (CMDPNTREGOut[`MAT_CMDPNTREG_WIDTH - 1:0]),
.Write     (CMDPNTREG32_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// assign CMDPNTREGOut[31:`MAT_CMDPNTREG_WIDTH] = 0;

// Assign module outputs from CMDPNTREG
assign r_CmdPntReg[31:0] = CMDPNTREGOut[31:0];

// End of CMDPNTREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDCNTREG register
// Define CMDCNTREG address & WR signals
wire CMDCNTREG_Sel      = (Address == `MAT_CMDCNTREG_ADR       );

wire CMDCNTREG32_Wr;

assign CMDCNTREG32_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDCNTREG_Sel;

// Define CMDCNTREG output signals
wire [31:0] CMDCNTREGOut;

// Instantiate CMDCNTREG Register
matrix_register #(`MAT_CMDCNTREG_WIDTH, `MAT_CMDCNTREG_DEFLT)  CMDCNTREG
(
.DataIn    (DataIn[`MAT_CMDCNTREG_WIDTH - 1:0]),  
.DataOut   (CMDCNTREGOut[`MAT_CMDCNTREG_WIDTH - 1:0]),
.Write     (CMDCNTREG32_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// assign CMDCNTREGOut[31:`MAT_CMDCNTREG_WIDTH] = 0;

// Assign module outputs from CMDCNTREG
assign r_CmdCntReg[31:0] = CMDCNTREGOut[31:0];

// End of CMDCNTREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin HNDLREG register
// Define HNDLREG address & WR signals
wire HNDLREG_Sel      = (Address == `MAT_HNDLREG_ADR       );

wire HNDLREG16_Wr;

assign HNDLREG16_Wr   = Write[0]  & Write[1]  & HNDLREG_Sel;

// Define HNDLREG output signals
wire [31:0] HNDLREGOut;

// Instantiate HNDLREG Register
matrix_register #(`MAT_HNDLREG_WIDTH, `MAT_HNDLREG_DEFLT)  HNDLREG
(
.DataIn    (DataIn[`MAT_HNDLREG_WIDTH - 1:0]),  
.DataOut   (HNDLREGOut[`MAT_HNDLREG_WIDTH - 1:0]),
.Write     (HNDLREG16_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign HNDLREGOut[31:`MAT_HNDLREG_WIDTH] = 0;

// Assign module outputs from HNDLREG
assign r_HndlReg[15:0] = HNDLREGOut[15:0];

// End of HNDLREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin FLTROPREG register
// Define FLTROPREG address & WR signals
wire FLTROPREG_Sel      = (Address == `MAT_FLTROPREG_ADR       );

wire FLTROPREG_Wr;

assign FLTROPREG_Wr   = Write[0] & FLTROPREG_Sel;

// Define FLTROPREG output signals
wire [31:0] FLTROPREGOut;


// Instantiate FLTROPREG Register
matrix_register #(`MAT_FLTROPREG_WIDTH, `MAT_FLTROPREG_DEFLT)  FLTROPREG
(
.DataIn    (DataIn[`MAT_FLTROPREG_WIDTH - 1:0]),  
.DataOut   (FLTROPREGOut[`MAT_FLTROPREG_WIDTH - 1:0]),
.Write     (FLTROPREG_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign FLTROPREGOut[31:`MAT_FLTROPREG_WIDTH] = 0;

// Assign module outputs from FLTROPREG
assign r_FltrOpReg_BufferOp = FLTROPREGOut[0];
assign r_FltrOpReg_HostOp = FLTROPREGOut[1];
assign r_FltrOpReg_IntOp = FLTROPREGOut[2];
assign r_FltrOpReg_StickyOp = FLTROPREGOut[3]; 
assign r_FltrOpReg_PhraseOp = FLTROPREGOut[4];
assign r_FltrOpReg_LogicOp[1:0] = FLTROPREGOut[6:5];

// End of FLTROPREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin FLTRCNTREG register
// Define FLTRCNTREG address & WR signals
wire FLTRCNTREG_Sel      = (Address == `MAT_FLTRCNTREG_ADR       );

wire FLTRCNTREG_Wr;

assign FLTRCNTREG_Wr   = Write[0] & FLTRCNTREG_Sel;

// Define FLTRCNTREG output signals
wire [31:0] FLTRCNTREGOut;


// Instantiate FLTRCNTREG Register
matrix_register #(`MAT_FLTRCNTREG_WIDTH, `MAT_FLTRCNTREG_DEFLT)  FLTRCNTREG
(
.DataIn    (DataIn[`MAT_FLTRCNTREG_WIDTH - 1:0]),  
.DataOut   (FLTRCNTREGOut[`MAT_FLTRCNTREG_WIDTH - 1:0]),
.Write     (FLTRCNTREG_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign FLTRCNTREGOut[31:`MAT_FLTRCNTREG_WIDTH] = 0;

// Assign module outputs from FLTRCNTREG
assign r_FltrCntReg[7:0] = FLTRCNTREGOut[7:0];

// End of FLTRCNTREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin DFLTFLTROPREG register
// Define DFLTFLTROPREG address & WR signals
wire DFLTFLTROPREG_Sel      = (Address == `MAT_DFLTFLTROPREG_ADR       );

wire DFLTFLTROPREG_Wr;

assign DFLTFLTROPREG_Wr   = Write[0] & DFLTFLTROPREG_Sel;

// Define DFLTFLTROPREG output signals
wire [31:0] DFLTFLTROPREGOut;


// Instantiate DFLTFLTROPREG Register
matrix_register #(`MAT_DFLTFLTROPREG_WIDTH, `MAT_DFLTFLTROPREG_DEFLT)  DFLTFLTROPREG
(
.DataIn    (DataIn[`MAT_DFLTFLTROPREG_WIDTH - 1:0]),  
.DataOut   (DFLTFLTROPREGOut[`MAT_DFLTFLTROPREG_WIDTH - 1:0]),
.Write     (DFLTFLTROPREG_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign DFLTFLTROPREGOut[31:`MAT_DFLTFLTROPREG_WIDTH] = 0;

// Assign module outputs from DFLTFLTROPREG
assign r_DfltFltrOpReg_BufferOp = FLTRCNTREGOut[0];
assign r_DfltFltrOpReg_HostOp = FLTRCNTREGOut[1];
assign r_DfltFltrOpReg_IntOp = FLTRCNTREGOut[2];
assign r_DfltFltrOpReg_StickyOp = FLTRCNTREGOut[3];

// End of DFLTFLTROPREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG0 register
// Define CMDATAREG0 address & WR signals
wire CMDATAREG0_Sel      = (Address == `MAT_CMDATAREG0_ADR       );

wire CMDATAREG032_Wr;

assign CMDATAREG032_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG0_Sel;

// Define CMDATAREG0 output signals
wire [31:0] CMDATAREG0Out;


// Instantiate CMDATAREG0 Register
matrix_register #(`MAT_CMDATAREG0_WIDTH, `MAT_CMDATAREG0_DEFLT)  CMDATAREG0
(
.DataIn    (DataIn[`MAT_CMDATAREG0_WIDTH - 1:0]),  
.DataOut   (CMDATAREG0Out[`MAT_CMDATAREG0_WIDTH - 1:0]),
.Write     (CMDATAREG032_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG0 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG1 register
// Define CMDATAREG1 address & WR signals
wire CMDATAREG1_Sel      = (Address == `MAT_CMDATAREG1_ADR       );

wire CMDATAREG132_Wr;

assign CMDATAREG132_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG1_Sel;

// Define CMDATAREG1 output signals
wire [31:0] CMDATAREG1Out;


// Instantiate CMDATAREG1 Register
matrix_register #(`MAT_CMDATAREG1_WIDTH, `MAT_CMDATAREG1_DEFLT)  CMDATAREG1
(
.DataIn    (DataIn[`MAT_CMDATAREG1_WIDTH - 1:0]),  
.DataOut   (CMDATAREG1Out[`MAT_CMDATAREG1_WIDTH - 1:0]),
.Write     (CMDATAREG132_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG1 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG2 register
// Define CMDATAREG2 address & WR signals
wire CMDATAREG2_Sel      = (Address == `MAT_CMDATAREG2_ADR       );

wire CMDATAREG232_Wr;

assign CMDATAREG232_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG2_Sel;

// Define CMDATAREG2 output signals
wire [31:0] CMDATAREG2Out;


// Instantiate CMDATAREG2 Register
matrix_register #(`MAT_CMDATAREG2_WIDTH, `MAT_CMDATAREG2_DEFLT)  CMDATAREG2
(
.DataIn    (DataIn[`MAT_CMDATAREG2_WIDTH - 1:0]),  
.DataOut   (CMDATAREG2Out[`MAT_CMDATAREG2_WIDTH - 1:0]),
.Write     (CMDATAREG232_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG2 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG3 register
// Define CMDATAREG3 address & WR signals
wire CMDATAREG3_Sel      = (Address == `MAT_CMDATAREG3_ADR       );

wire CMDATAREG332_Wr;

assign CMDATAREG332_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG3_Sel;

// Define CMDATAREG3 output signals
wire [31:0] CMDATAREG3Out;


// Instantiate CMDATAREG3 Register
matrix_register #(`MAT_CMDATAREG3_WIDTH, `MAT_CMDATAREG3_DEFLT)  CMDATAREG3
(
.DataIn    (DataIn[`MAT_CMDATAREG3_WIDTH - 1:0]),  
.DataOut   (CMDATAREG3Out[`MAT_CMDATAREG3_WIDTH - 1:0]),
.Write     (CMDATAREG332_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG3 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG4 register
// Define CMDATAREG4 address & WR signals
wire CMDATAREG4_Sel      = (Address == `MAT_CMDATAREG4_ADR       );

wire CMDATAREG432_Wr;

assign CMDATAREG432_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG4_Sel;

// Define CMDATAREG4 output signals
wire [31:0] CMDATAREG4Out;


// Instantiate CMDATAREG4 Register
matrix_register #(`MAT_CMDATAREG4_WIDTH, `MAT_CMDATAREG4_DEFLT)  CMDATAREG4
(
.DataIn    (DataIn[`MAT_CMDATAREG4_WIDTH - 1:0]),  
.DataOut   (CMDATAREG4Out[`MAT_CMDATAREG4_WIDTH - 1:0]),
.Write     (CMDATAREG432_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG4 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG5 register
// Define CMDATAREG5 address & WR signals
wire CMDATAREG5_Sel      = (Address == `MAT_CMDATAREG5_ADR       );

wire CMDATAREG532_Wr;

assign CMDATAREG532_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG5_Sel;

// Define CMDATAREG5 output signals
wire [31:0] CMDATAREG5Out;


// Instantiate CMDATAREG5 Register
matrix_register #(`MAT_CMDATAREG5_WIDTH, `MAT_CMDATAREG5_DEFLT)  CMDATAREG5
(
.DataIn    (DataIn[`MAT_CMDATAREG5_WIDTH - 1:0]),  
.DataOut   (CMDATAREG5Out[`MAT_CMDATAREG5_WIDTH - 1:0]),
.Write     (CMDATAREG532_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG5 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG6 register
// Define CMDATAREG6 address & WR signals
wire CMDATAREG6_Sel      = (Address == `MAT_CMDATAREG6_ADR       );

wire CMDATAREG632_Wr;

assign CMDATAREG632_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG6_Sel;

// Define CMDATAREG6 output signals
wire [31:0] CMDATAREG6Out;


// Instantiate CMDATAREG6 Register
matrix_register #(`MAT_CMDATAREG6_WIDTH, `MAT_CMDATAREG6_DEFLT)  CMDATAREG6
(
.DataIn    (DataIn[`MAT_CMDATAREG6_WIDTH - 1:0]),  
.DataOut   (CMDATAREG6Out[`MAT_CMDATAREG6_WIDTH - 1:0]),
.Write     (CMDATAREG632_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG6 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG7 register
// Define CMDATAREG7 address & WR signals
wire CMDATAREG7_Sel      = (Address == `MAT_CMDATAREG7_ADR       );

wire CMDATAREG732_Wr;

assign CMDATAREG732_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG7_Sel;

// Define CMDATAREG7 output signals
wire [31:0] CMDATAREG7Out;


// Instantiate CMDATAREG7 Register
matrix_register #(`MAT_CMDATAREG7_WIDTH, `MAT_CMDATAREG7_DEFLT)  CMDATAREG7
(
.DataIn    (DataIn[`MAT_CMDATAREG7_WIDTH - 1:0]),  
.DataOut   (CMDATAREG7Out[`MAT_CMDATAREG7_WIDTH - 1:0]),
.Write     (CMDATAREG732_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG7 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG8 register
// Define CMDATAREG8 address & WR signals
wire CMDATAREG8_Sel      = (Address == `MAT_CMDATAREG8_ADR       );

wire CMDATAREG832_Wr;

assign CMDATAREG832_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG8_Sel;

// Define CMDATAREG8 output signals
wire [31:0] CMDATAREG8Out;


// Instantiate CMDATAREG8 Register
matrix_register #(`MAT_CMDATAREG8_WIDTH, `MAT_CMDATAREG8_DEFLT)  CMDATAREG8
(
.DataIn    (DataIn[`MAT_CMDATAREG8_WIDTH - 1:0]),  
.DataOut   (CMDATAREG8Out[`MAT_CMDATAREG8_WIDTH - 1:0]),
.Write     (CMDATAREG832_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG8 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREG9 register
// Define CMDATAREG9 address & WR signals
wire CMDATAREG9_Sel      = (Address == `MAT_CMDATAREG9_ADR       );

wire CMDATAREG932_Wr;

assign CMDATAREG932_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREG9_Sel;

// Define CMDATAREG9 output signals
wire [31:0] CMDATAREG9Out;


// Instantiate CMDATAREG9 Register
matrix_register #(`MAT_CMDATAREG9_WIDTH, `MAT_CMDATAREG9_DEFLT)  CMDATAREG9
(
.DataIn    (DataIn[`MAT_CMDATAREG9_WIDTH - 1:0]),  
.DataOut   (CMDATAREG9Out[`MAT_CMDATAREG9_WIDTH - 1:0]),
.Write     (CMDATAREG932_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREG9 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CMDATAREGA register
// Define CMDATAREGA address & WR signals
wire CMDATAREGA_Sel      = (Address == `MAT_CMDATAREGA_ADR       );

wire CMDATAREGA32_Wr;

assign CMDATAREGA32_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CMDATAREGA_Sel;

// Define CMDATAREGA output signals
wire [31:0] CMDATAREGAOut;


// Instantiate CMDATAREGA Register
matrix_register #(`MAT_CMDATAREGA_WIDTH, `MAT_CMDATAREGA_DEFLT)  CMDATAREGA
(
.DataIn    (DataIn[`MAT_CMDATAREGA_WIDTH - 1:0]),  
.DataOut   (CMDATAREGAOut[`MAT_CMDATAREGA_WIDTH - 1:0]),
.Write     (CMDATAREGA32_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CMDATAREGA register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG0 register
// Define CLASSIFIEREG0 address & WR signals
wire CLASSIFIEREG0_Sel      = (Address == `MAT_CLASSIFIEREG0_ADR       );

wire CLASSIFIEREG032_Wr;

assign CLASSIFIEREG032_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG0_Sel;

// Define CLASSIFIEREG0 output signals
wire [31:0] CLASSIFIEREG0Out;


// Instantiate CLASSIFIEREG0 Register
matrix_register #(`MAT_CLASSIFIEREG0_WIDTH, `MAT_CLASSIFIEREG0_DEFLT)  CLASSIFIEREG0
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG0_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG0Out[`MAT_CLASSIFIEREG0_WIDTH - 1:0]),
.Write     (CLASSIFIEREG032_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG0 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG1 register
// Define CLASSIFIEREG1 address & WR signals
wire CLASSIFIEREG1_Sel      = (Address == `MAT_CLASSIFIEREG1_ADR       );

wire CLASSIFIEREG132_Wr;

assign CLASSIFIEREG132_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG1_Sel;

// Define CLASSIFIEREG1 output signals
wire [31:0] CLASSIFIEREG1Out;


// Instantiate CLASSIFIEREG1 Register
matrix_register #(`MAT_CLASSIFIEREG1_WIDTH, `MAT_CLASSIFIEREG1_DEFLT)  CLASSIFIEREG1
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG1_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG1Out[`MAT_CLASSIFIEREG1_WIDTH - 1:0]),
.Write     (CLASSIFIEREG132_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG1 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG2 register
// Define CLASSIFIEREG2 address & WR signals
wire CLASSIFIEREG2_Sel      = (Address == `MAT_CLASSIFIEREG2_ADR       );

wire CLASSIFIEREG232_Wr;

assign CLASSIFIEREG232_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG2_Sel;

// Define CLASSIFIEREG2 output signals
wire [31:0] CLASSIFIEREG2Out;


// Instantiate CLASSIFIEREG2 Register
matrix_register #(`MAT_CLASSIFIEREG2_WIDTH, `MAT_CLASSIFIEREG2_DEFLT)  CLASSIFIEREG2
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG2_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG2Out[`MAT_CLASSIFIEREG2_WIDTH - 1:0]),
.Write     (CLASSIFIEREG232_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG2 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG3 register
// Define CLASSIFIEREG3 address & WR signals
wire CLASSIFIEREG3_Sel      = (Address == `MAT_CLASSIFIEREG3_ADR       );

wire CLASSIFIEREG332_Wr;

assign CLASSIFIEREG332_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG3_Sel;

// Define CLASSIFIEREG3 output signals
wire [31:0] CLASSIFIEREG3Out;


// Instantiate CLASSIFIEREG3 Register
matrix_register #(`MAT_CLASSIFIEREG3_WIDTH, `MAT_CLASSIFIEREG3_DEFLT)  CLASSIFIEREG3
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG3_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG3Out[`MAT_CLASSIFIEREG3_WIDTH - 1:0]),
.Write     (CLASSIFIEREG332_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG3 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG4 register
// Define CLASSIFIEREG4 address & WR signals
wire CLASSIFIEREG4_Sel      = (Address == `MAT_CLASSIFIEREG4_ADR       );

wire CLASSIFIEREG432_Wr;

assign CLASSIFIEREG432_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG4_Sel;

// Define CLASSIFIEREG4 output signals
wire [31:0] CLASSIFIEREG4Out;


// Instantiate CLASSIFIEREG4 Register
matrix_register #(`MAT_CLASSIFIEREG4_WIDTH, `MAT_CLASSIFIEREG4_DEFLT)  CLASSIFIEREG4
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG4_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG4Out[`MAT_CLASSIFIEREG4_WIDTH - 1:0]),
.Write     (CLASSIFIEREG432_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG4 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG5 register
// Define CLASSIFIEREG5 address & WR signals
wire CLASSIFIEREG5_Sel      = (Address == `MAT_CLASSIFIEREG5_ADR       );

wire CLASSIFIEREG532_Wr;

assign CLASSIFIEREG532_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG5_Sel;

// Define CLASSIFIEREG5 output signals
wire [31:0] CLASSIFIEREG5Out;


// Instantiate CLASSIFIEREG5 Register
matrix_register #(`MAT_CLASSIFIEREG5_WIDTH, `MAT_CLASSIFIEREG5_DEFLT)  CLASSIFIEREG5
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG5_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG5Out[`MAT_CLASSIFIEREG5_WIDTH - 1:0]),
.Write     (CLASSIFIEREG532_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG5 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG6 register
// Define CLASSIFIEREG6 address & WR signals
wire CLASSIFIEREG6_Sel      = (Address == `MAT_CLASSIFIEREG6_ADR       );

wire CLASSIFIEREG632_Wr;

assign CLASSIFIEREG632_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG6_Sel;

// Define CLASSIFIEREG6 output signals
wire [31:0] CLASSIFIEREG6Out;


// Instantiate CLASSIFIEREG6 Register
matrix_register #(`MAT_CLASSIFIEREG6_WIDTH, `MAT_CLASSIFIEREG6_DEFLT)  CLASSIFIEREG6
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG6_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG6Out[`MAT_CLASSIFIEREG6_WIDTH - 1:0]),
.Write     (CLASSIFIEREG632_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG6 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG7 register
// Define CLASSIFIEREG7 address & WR signals
wire CLASSIFIEREG7_Sel      = (Address == `MAT_CLASSIFIEREG7_ADR       );

wire CLASSIFIEREG732_Wr;

assign CLASSIFIEREG732_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG7_Sel;

// Define CLASSIFIEREG7 output signals
wire [31:0] CLASSIFIEREG7Out;


// Instantiate CLASSIFIEREG7 Register
matrix_register #(`MAT_CLASSIFIEREG7_WIDTH, `MAT_CLASSIFIEREG7_DEFLT)  CLASSIFIEREG7
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG7_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG7Out[`MAT_CLASSIFIEREG7_WIDTH - 1:0]),
.Write     (CLASSIFIEREG732_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG7 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG8 register
// Define CLASSIFIEREG8 address & WR signals
wire CLASSIFIEREG8_Sel      = (Address == `MAT_CLASSIFIEREG8_ADR       );

wire CLASSIFIEREG832_Wr;

assign CLASSIFIEREG832_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG8_Sel;

// Define CLASSIFIEREG8 output signals
wire [31:0] CLASSIFIEREG8Out;


// Instantiate CLASSIFIEREG8 Register
matrix_register #(`MAT_CLASSIFIEREG8_WIDTH, `MAT_CLASSIFIEREG8_DEFLT)  CLASSIFIEREG8
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG8_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG8Out[`MAT_CLASSIFIEREG8_WIDTH - 1:0]),
.Write     (CLASSIFIEREG832_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG8 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREG9 register
// Define CLASSIFIEREG9 address & WR signals
wire CLASSIFIEREG9_Sel      = (Address == `MAT_CLASSIFIEREG9_ADR       );

wire CLASSIFIEREG932_Wr;

assign CLASSIFIEREG932_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREG9_Sel;

// Define CLASSIFIEREG9 output signals
wire [31:0] CLASSIFIEREG9Out;


// Instantiate CLASSIFIEREG9 Register
matrix_register #(`MAT_CLASSIFIEREG9_WIDTH, `MAT_CLASSIFIEREG9_DEFLT)  CLASSIFIEREG9
(
.DataIn    (DataIn[`MAT_CLASSIFIEREG9_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREG9Out[`MAT_CLASSIFIEREG9_WIDTH - 1:0]),
.Write     (CLASSIFIEREG932_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREG9 register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin CLASSIFIEREGA register
// Define CLASSIFIEREGA address & WR signals
wire CLASSIFIEREGA_Sel      = (Address == `MAT_CLASSIFIEREGA_ADR       );

wire CLASSIFIEREGA32_Wr;

assign CLASSIFIEREGA32_Wr   = Write[0] & Write[1] & Write[2] & Write[3] & CLASSIFIEREGA_Sel;

// Define CLASSIFIEREGA output signals
wire [31:0] CLASSIFIEREGAOut;


// Instantiate CLASSIFIEREGA Register
matrix_register #(`MAT_CLASSIFIEREGA_WIDTH, `MAT_CLASSIFIEREGA_DEFLT)  CLASSIFIEREGA
(
.DataIn    (DataIn[`MAT_CLASSIFIEREGA_WIDTH - 1:0]),  
.DataOut   (CLASSIFIEREGAOut[`MAT_CLASSIFIEREGA_WIDTH - 1:0]),
.Write     (CLASSIFIEREGA32_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

// End of CLASSIFIEREGA register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin r_BigData

assign r_BigData[255:224]  = (r_BigDataSel == 2'b00) ? CMDATAREG0Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG0Out[31:0]:
                            ((r_BigDataSel == 2'b10)? CMDATAREG8Out[31:0]:CLASSIFIEREG8Out[31:0]));
assign r_BigData[223:192] = (r_BigDataSel == 2'b00) ? CMDATAREG1Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG1Out[31:0]:
                            ((r_BigDataSel == 2'b10)? CMDATAREG9Out[31:0]:CLASSIFIEREG9Out[31:0]));
assign r_BigData[191:160] = (r_BigDataSel == 2'b00) ? CMDATAREG2Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG2Out[31:0]:
                            ((r_BigDataSel == 2'b10)? CMDATAREGAOut[31:0]:CLASSIFIEREGAOut[31:0]));
assign r_BigData[159:128] = (r_BigDataSel == 2'b00) ? CMDATAREG3Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG3Out[31:0]: 32'h0);
assign r_BigData[127:96]  = (r_BigDataSel == 2'b00) ? CMDATAREG4Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG4Out[31:0]: 32'h0);
assign r_BigData[95:64]   = (r_BigDataSel == 2'b00) ? CMDATAREG5Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG5Out[31:0]: 32'h0);
assign r_BigData[63:32]   = (r_BigDataSel == 2'b00) ? CMDATAREG6Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG6Out[31:0]: 32'h0);
assign r_BigData[31:0]    = (r_BigDataSel == 2'b00) ? CMDATAREG7Out[31:0]:
                            ((r_BigDataSel == 2'b01)? CLASSIFIEREG7Out[31:0]: 32'h0);

// End r_BigData
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin PHYCSR register
// Define PHYCSR address & WR signals
wire PHYCSR_Sel      = (Address == `MAT_PHYCSR_ADR       );

wire PHYCSR_Wr;

assign PHYCSR_Wr     = Write[0]  & PHYCSR_Sel;


// Define PHYCSR output signals
wire [31:0] PHYCSROut;


// Instantiate PHYCSR Register
matrix_register #(`MAT_PHYCSR_WIDTH, `MAT_PHYCSR_DEFLT)  PHYCSR
(
.DataIn    (DataIn[`MAT_PHYCSR_WIDTH - 1:0]),  
.DataOut   (PHYCSROut[`MAT_PHYCSR_WIDTH - 1:0]),
.Write     (PHYCSR_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign PHYCSROut[31:`MAT_PHYCSR_WIDTH] = 0;

// Assign module outputs from PHYCSR
assign r_PhyCSR_TxCW = PHYCSROut[0];

// End of PHYCSR register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin PWRMANREG register
// Define PWRMANREG address & WR signals
wire PWRMANREG_Sel      = (Address == `MAT_PWRMANREG_ADR       );

wire PWRMANREG_Wr;

assign PWRMANREG_Wr     = Write[0]  & PWRMANREG_Sel;


// Define PWRMANREG output signals
wire [31:0] PWRMANREGOut;


// Instantiate PWRMANREG Register
matrix_register #(`MAT_PWRMANREG_WIDTH, `MAT_PWRMANREG_DEFLT)  PWRMANREG
(
.DataIn    (DataIn[`MAT_PWRMANREG_WIDTH - 1:0]),  
.DataOut   (PWRMANREGOut[`MAT_PWRMANREG_WIDTH - 1:0]),
.Write     (PWRMANREG_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign PWRMANREGOut[31:`MAT_PWRMANREG_WIDTH] = 0;

// Assign module outputs from PWRMANREG
assign r_PwrManReg_Onoff = PWRMANREGOut[0];

// End of PWRMANREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin TXRXCTRLREG register
// Define TXRXCTRLREG address & WR signals
wire TXRXCTRLREG_Sel      = (Address == `MAT_TXRXCTRLREG_ADR       );

wire TXRXCTRLREG_Wr;

assign TXRXCTRLREG_Wr     = Write[0]  & TXRXCTRLREG_Sel;


// Define TXRXCTRLREG output signals
wire [31:0] TXRXCTRLREGOut;


// Instantiate TXRXCTRLREG Register
matrix_register #(`MAT_TXRXCTRLREG_WIDTH, `MAT_TXRXCTRLREG_DEFLT)  TXRXCTRLREG
(
.DataIn    (DataIn[`MAT_TXRXCTRLREG_WIDTH - 1:0]),  
.DataOut   (TXRXCTRLREGOut[`MAT_TXRXCTRLREG_WIDTH - 1:0]),
.Write     (TXRXCTRLREG_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign TXRXCTRLREGOut[31:`MAT_TXRXCTRLREG_WIDTH] = 0;

// Assign module outputs from TXRXCTRLREG
assign r_TxRxCtrlReg_Tx_E = TXRXCTRLREGOut[0];
assign r_TxRxCtrlReg_Rx_E = TXRXCTRLREGOut[1];

// End of TXRXCTRLREG register
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin DELIMITER register
// Define DELIMITER address & WR signals
wire DELIMITER_Sel      = (Address == `MAT_DELIMITER_ADR       );

wire DELIMITER16_Wr;

assign DELIMITER16_Wr      = Write[0]  & Write[1]  & DELIMITER_Sel;

// Define DELIMITER output signals
wire [31:0] DELIMITEROut;


// Instantiate DELIMITER Register
matrix_register #(`MAT_DELIMITER_WIDTH, `MAT_DELIMITER_DEFLT)  DELIMITER
(
.DataIn    (DataIn[`MAT_DELIMITER_WIDTH - 1:0]),  
.DataOut   (DELIMITEROut[`MAT_DELIMITER_WIDTH - 1:0]),
.Write     (DELIMITER16_Wr),
.Clk       (Clk),
.Reset     (Reset),
.SyncReset (1'b0)
);

assign DELIMITEROut[31:`MAT_DELIMITER_WIDTH] = 0;

// Assign module outputs from DELIMITER
assign r_Delimiter[15:0] = DELIMITEROut[15:0];

// End of DELIMITER register
//////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////
// Begin Reading data from registers
always @ (Address or Read or HCSROut or INT_SOURCEOut or INT_MASKOut or TxRx_ModerOut or
          DATA0LENOut or DATA1LENOut or PIEPWLENOut or RTCALLENOut or TRCALLENOut or
          DR_RATIOOut or LNKFREQOut or CHANNUMOut or LNKTIMER1Out or LNKTIMER2Out or
          LNKTIMER3Out or LNKTIMER4Out or RPLYTIMEROut or CMDREGOut or CMDPNTREGOut or
          CMDCNTREGOut or HNDLREGOut or FLTROPREGOut or FLTRCNTREGOut or DFLTFLTROPREGOut or
          CMDATAREG0Out or CMDATAREG1Out or CMDATAREG2Out or CMDATAREG3Out or CMDATAREG4Out or
          CMDATAREG5Out or CMDATAREG6Out or CMDATAREG7Out or CMDATAREG8Out or CMDATAREG9Out or 
          CMDATAREGAOut or CLASSIFIEREG0Out or CLASSIFIEREG1Out or CLASSIFIEREG2Out or
          CLASSIFIEREG3Out or CLASSIFIEREG4Out or CLASSIFIEREG5Out or CLASSIFIEREG6Out or
          CLASSIFIEREG7Out or CLASSIFIEREG8Out or CLASSIFIEREG9Out or CLASSIFIEREGAOut or
          PHYCSROut or PWRMANREGOut or TXRXCTRLREGOut or DELIMITEROut
         )
begin
   if(Read)  // read
      begin
         case(Address)
            `MAT_HOST_CSR_ADR:  	   DataOut <= HCSROut;
            `MAT_INT_SRC_ADR:       DataOut <= INT_SOURCEOut;
            `MAT_INT_MSK_ADR:       DataOut <= INT_MASKOut;
            `MAT_TXRX_MODER_ADR:      DataOut <= TxRx_ModerOut;
            `MAT_DATA0LEN_ADR:      DataOut <= DATA0LENOut;
            `MAT_DATA1LEN_ADR:      DataOut <= DATA1LENOut;
            `MAT_PIEPWLEN_ADR:      DataOut <= PIEPWLENOut;
            `MAT_RTCALLEN_ADR:      DataOut <= RTCALLENOut;
            `MAT_TRCALLEN_ADR:      DataOut <= TRCALLENOut;
            `MAT_DR_RATIO_ADR:      DataOut <= DR_RATIOOut;
            `MAT_LNKFREQ_ADR:       DataOut <= LNKFREQOut;
            `MAT_CHANNUM_ADR:       DataOut <= CHANNUMOut;
            `MAT_LNKTIMER1_ADR:     DataOut <= LNKTIMER1Out;
            `MAT_LNKTIMER2_ADR:     DataOut <= LNKTIMER2Out;
            `MAT_LNKTIMER3_ADR:     DataOut <= LNKTIMER3Out;
            `MAT_LNKTIMER4_ADR:     DataOut <= LNKTIMER4Out;
            `MAT_RPLYTIMER_ADR:     DataOut <= RPLYTIMEROut;
            `MAT_CMDREG_ADR:        DataOut <= CMDREGOut;
            `MAT_CMDPNTREG_ADR:     DataOut <= CMDPNTREGOut;
            `MAT_CMDCNTREG_ADR:     DataOut <= CMDCNTREGOut;
            `MAT_HNDLREG_ADR:       DataOut <= HNDLREGOut;
            `MAT_FLTROPREG_ADR:     DataOut <= FLTROPREGOut;
            `MAT_FLTRCNTREG_ADR:    DataOut <= FLTRCNTREGOut;
            `MAT_DFLTFLTROPREG_ADR: DataOut <= DFLTFLTROPREGOut;
            `MAT_CMDATAREG0_ADR:    DataOut <= CMDATAREG0Out;
            `MAT_CMDATAREG1_ADR:    DataOut <= CMDATAREG1Out;
            `MAT_CMDATAREG2_ADR:    DataOut <= CMDATAREG2Out;
            `MAT_CMDATAREG3_ADR:    DataOut <= CMDATAREG3Out;
            `MAT_CMDATAREG4_ADR:    DataOut <= CMDATAREG4Out;
            `MAT_CMDATAREG5_ADR:    DataOut <= CMDATAREG5Out;
            `MAT_CMDATAREG6_ADR:    DataOut <= CMDATAREG6Out;
            `MAT_CMDATAREG7_ADR:    DataOut <= CMDATAREG7Out;
            `MAT_CMDATAREG8_ADR:    DataOut <= CMDATAREG8Out;
            `MAT_CMDATAREG9_ADR:    DataOut <= CMDATAREG9Out;
            `MAT_CMDATAREGA_ADR:    DataOut <= CMDATAREGAOut;
            `MAT_CLASSIFIEREG0_ADR: DataOut <= CLASSIFIEREG0Out;
            `MAT_CLASSIFIEREG1_ADR: DataOut <= CLASSIFIEREG1Out;
            `MAT_CLASSIFIEREG2_ADR: DataOut <= CLASSIFIEREG2Out;
            `MAT_CLASSIFIEREG3_ADR: DataOut <= CLASSIFIEREG3Out;
            `MAT_CLASSIFIEREG4_ADR: DataOut <= CLASSIFIEREG4Out;
            `MAT_CLASSIFIEREG5_ADR: DataOut <= CLASSIFIEREG5Out;
            `MAT_CLASSIFIEREG6_ADR: DataOut <= CLASSIFIEREG6Out;
            `MAT_CLASSIFIEREG7_ADR: DataOut <= CLASSIFIEREG7Out;
            `MAT_CLASSIFIEREG8_ADR: DataOut <= CLASSIFIEREG8Out;
            `MAT_CLASSIFIEREG9_ADR: DataOut <= CLASSIFIEREG9Out;
            `MAT_CLASSIFIEREGA_ADR: DataOut <= CLASSIFIEREGAOut;
            `MAT_PHYCSR_ADR:        DataOut <= PHYCSROut;
            `MAT_PWRMANREG_ADR:     DataOut <= PWRMANREGOut;
            `MAT_TXRXCTRLREG_ADR:   DataOut <= TXRXCTRLREGOut;
            `MAT_DELIMITER_ADR:     DataOut <= DELIMITEROut;
            default:  				          DataOut <= 32'h0;
         endcase
      end
   else
      DataOut <= 32'h0;
end
// End Reading data from registers
//////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
                      