/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_defines.v
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

`define MAT_DEBUG_FLAG 1

`define MAT_MBIST_CTRL_WIDTH 3        // width of MBIST control bus

// Register Addresses

`define MAT_BASE_ADDRESS           32'h00000000
`define MAT_HOST_CSR_ADR           8'h00   	//0x0 Devices outside the chip can access only multiple of 4 bytes addresses 
`define MAT_INT_SRC_ADR            8'h01   	//0x4
`define MAT_INT_MSK_ADR            8'h02   	//0x8
`define MAT_TXRX_MODER_ADR         8'h03   	//0xC
`define MAT_DATA0LEN_ADR           8'h04   	//0x10
`define MAT_DATA1LEN_ADR           8'h05   	//0x14
`define MAT_PIEPWLEN_ADR           8'h06   	//0x18
`define MAT_RTCALLEN_ADR           8'h07   	//0x1C
`define MAT_TRCALLEN_ADR           8'h08   	//0x20
`define MAT_DR_RATIO_ADR           8'h09   	//0x24
`define MAT_LNKFREQ_ADR            8'h0A   	//0x28
`define MAT_CHANNUM_ADR            8'h0B   	//0x2C
`define MAT_LNKTIMER1_ADR          8'h0C   	//0x30
`define MAT_LNKTIMER2_ADR          8'h0D   	//0x34
`define MAT_LNKTIMER3_ADR          8'h0E   	//0x38
`define MAT_LNKTIMER4_ADR          8'h0F   	//0x3C
`define MAT_RPLYTIMER_ADR          8'h10  	//0x40
`define MAT_CMDREG_ADR             8'h11  	//0x44
`define MAT_CMDPNTREG_ADR          8'h12  	//0x48
`define MAT_CMDCNTREG_ADR          8'h13  	//0x4C
`define MAT_HNDLREG_ADR            8'h14  	//0x50
`define MAT_FLTROPREG_ADR          8'h15  	//0x54
`define MAT_FLTRCNTREG_ADR         8'h16  	//0x58
`define MAT_DFLTFLTROPREG_ADR      8'h17  	//0x5C
`define MAT_CMDATAREG0_ADR         8'h18  	//0x60
`define MAT_CMDATAREG1_ADR         8'h19  	//0x64
`define MAT_CMDATAREG2_ADR         8'h1A  	//0x68
`define MAT_CMDATAREG3_ADR         8'h1B  	//0x6C
`define MAT_CMDATAREG4_ADR         8'h1C  	//0x70
`define MAT_CMDATAREG5_ADR         8'h1D  	//0x74
`define MAT_CMDATAREG6_ADR         8'h1E  	//0x78
`define MAT_CMDATAREG7_ADR         8'h1F  	//0x7C
`define MAT_CMDATAREG8_ADR         8'h20  	//0x80
`define MAT_CMDATAREG9_ADR         8'h21  	//0x84
`define MAT_CMDATAREGA_ADR         8'h22  	//0x88
`define MAT_CLASSIFIEREG0_ADR      8'h23  	//0x8C
`define MAT_CLASSIFIEREG1_ADR      8'h24  	//0x90
`define MAT_CLASSIFIEREG2_ADR      8'h25  	//0x94
`define MAT_CLASSIFIEREG3_ADR      8'h26  	//0x98
`define MAT_CLASSIFIEREG4_ADR      8'h27  	//0x9C
`define MAT_CLASSIFIEREG5_ADR      8'h28  	//0xA0
`define MAT_CLASSIFIEREG6_ADR      8'h29  	//0xA4
`define MAT_CLASSIFIEREG7_ADR      8'h2A  	//0xA8
`define MAT_CLASSIFIEREG8_ADR      8'h2B  	//0xAc
`define MAT_CLASSIFIEREG9_ADR      8'h2C  	//0xB0
`define MAT_CLASSIFIEREGA_ADR      8'h2D  	//0xB4
`define MAT_PHYCSR_ADR             8'h2E  	//0xB8
`define MAT_PWRMANREG_ADR          8'h2F  	//0xBC
`define MAT_TXRXCTRLREG_ADR        8'h30  	//0xC0
`define MAT_DELIMITER_ADR          8'h31  	//0xC4
`define MAT_IDLE_BUSTRANS_ADR      8'hff    

// Default Reset Value

`define MAT_HOST_CSR_DEFLT_0       16'h0000
`define MAT_HOST_CSR_DEFLT_1       3'h0
`define MAT_HOST_CSR_DEFLT_2       4'h0
`define MAT_INT_SRC_DEFLT_0        8'h00
`define MAT_INT_SRC_DEFLT_1        3'h0
`define MAT_INT_MSK_DEFLT_0        8'h00
`define MAT_INT_MSK_DEFLT_1        3'h0
`define MAT_TXRX_MODER_DEFLT       8'h00
`define MAT_DATA0LEN_DEFLT         16'h0000
`define MAT_DATA1LEN_DEFLT         16'h0000
`define MAT_PIEPWLEN_DEFLT         16'h0000
`define MAT_RTCALLEN_DEFLT         16'h0000
`define MAT_TRCALLEN_DEFLT         16'h0000
`define MAT_DR_RATIO_DEFLT         13'h0000
`define MAT_LNKFREQ_DEFLT          32'h00000000
`define MAT_CHANNUM_DEFLT          8'h00
`define MAT_LNKTIMER1_DEFLT        16'h0000      // MAX(RTcal, 10*(1/LF))
`define MAT_LNKTIMER2_DEFLT        16'h0000      // 3.0*(1/LF) <= T2 <= 20.0*(1/LF)
`define MAT_LNKTIMER3_DEFLT        16'h0000      // T3 >= T4 - T1
`define MAT_LNKTIMER4_DEFLT        16'h0000
`define MAT_RPLYTIMER_DEFLT        32'h00000000  // <= 20ms
`define MAT_CMDREG_DEFLT           32'h00000000  // Decoding occurs in Sequencer
`define MAT_CMDPNTREG_DEFLT        32'h00000000
`define MAT_CMDCNTREG_DEFLT        32'h00000000
`define MAT_HNDLREG_DEFLT          16'h0000
`define MAT_FLTROPREG_DEFLT        7'h00
`define MAT_FLTRCNTREG_DEFLT       8'h0
`define MAT_DFLTFLTROPREG_DEFLT    4'h0
`define MAT_CMDATAREG0_DEFLT       32'h00000000
`define MAT_CMDATAREG1_DEFLT       32'h00000000
`define MAT_CMDATAREG2_DEFLT       32'h00000000
`define MAT_CMDATAREG3_DEFLT       32'h00000000
`define MAT_CMDATAREG4_DEFLT       32'h00000000
`define MAT_CMDATAREG5_DEFLT       32'h00000000
`define MAT_CMDATAREG6_DEFLT       32'h00000000
`define MAT_CMDATAREG7_DEFLT       32'h00000000
`define MAT_CMDATAREG8_DEFLT       32'h00000000
`define MAT_CMDATAREG9_DEFLT       32'h00000000
`define MAT_CMDATAREGA_DEFLT       32'h00000000
`define MAT_CLASSIFIEREG0_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG1_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG2_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG3_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG4_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG5_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG6_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG7_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG8_DEFLT    32'h00000000
`define MAT_CLASSIFIEREG9_DEFLT    32'h00000000
`define MAT_CLASSIFIEREGA_DEFLT    32'h00000000
`define MAT_PHYCSR_DEFLT           1'h0
`define MAT_PWRMANREG_DEFLT        1'h0
`define MAT_TXRXCTRLREG_DEFLT      3'h0
`define MAT_DELIMITER_DEFLT        16'h0000

// Bit Range Starting Position

`define MAT_HOST_CSR_WIDTH_0       16
`define MAT_HOST_CSR_WIDTH_1       3
`define MAT_HOST_CSR_WIDTH_2       4
`define MAT_INT_SRC_WIDTH_0        8
`define MAT_INT_SRC_WIDTH_1        3
`define MAT_INT_MSK_WIDTH_0        8
`define MAT_INT_MSK_WIDTH_1        3
`define MAT_TXRX_MODER_WIDTH       8
`define MAT_DATA0LEN_WIDTH         16
`define MAT_DATA1LEN_WIDTH         16
`define MAT_PIEPWLEN_WIDTH         16
`define MAT_RTCALLEN_WIDTH         16
`define MAT_TRCALLEN_WIDTH         16
`define MAT_DR_RATIO_WIDTH         13
`define MAT_LNKFREQ_WIDTH          32
`define MAT_CHANNUM_WIDTH          8
`define MAT_LNKTIMER1_WIDTH        16
`define MAT_LNKTIMER2_WIDTH        16
`define MAT_LNKTIMER3_WIDTH        16
`define MAT_LNKTIMER4_WIDTH        16
`define MAT_RPLYTIMER_WIDTH        32
`define MAT_CMDREG_WIDTH           32
`define MAT_CMDPNTREG_WIDTH        32
`define MAT_CMDCNTREG_WIDTH        32
`define MAT_HNDLREG_WIDTH          16
`define MAT_FLTROPREG_WIDTH        7
`define MAT_FLTRCNTREG_WIDTH       8
`define MAT_DFLTFLTROPREG_WIDTH    4
`define MAT_CMDATAREG0_WIDTH       32
`define MAT_CMDATAREG1_WIDTH       32
`define MAT_CMDATAREG2_WIDTH       32
`define MAT_CMDATAREG3_WIDTH       32
`define MAT_CMDATAREG4_WIDTH       32
`define MAT_CMDATAREG5_WIDTH       32
`define MAT_CMDATAREG6_WIDTH       32
`define MAT_CMDATAREG7_WIDTH       32
`define MAT_CMDATAREG8_WIDTH       32
`define MAT_CMDATAREG9_WIDTH       32
`define MAT_CMDATAREGA_WIDTH       32
`define MAT_CLASSIFIEREG0_WIDTH    32
`define MAT_CLASSIFIEREG1_WIDTH    32
`define MAT_CLASSIFIEREG2_WIDTH    32
`define MAT_CLASSIFIEREG3_WIDTH    32
`define MAT_CLASSIFIEREG4_WIDTH    32
`define MAT_CLASSIFIEREG5_WIDTH    32
`define MAT_CLASSIFIEREG6_WIDTH    32
`define MAT_CLASSIFIEREG7_WIDTH    32
`define MAT_CLASSIFIEREG8_WIDTH    32
`define MAT_CLASSIFIEREG9_WIDTH    32
`define MAT_CLASSIFIEREGA_WIDTH    32
`define MAT_PHYCSR_WIDTH           1
`define MAT_PWRMANREG_WIDTH        1
`define MAT_TXRXCTRLREG_WIDTH      3
`define MAT_DELIMITER_WIDTH        16

// Outputs are registered (uncomment when needed)
`define MAT_REGISTERED_OUTPUTS

//Host Commands

`define MAT_HCSR_EXEC_FLITER      4'b1000
`define MAT_HCSR_EXEC_INVENTORY   4'b1001
`define MAT_HCSR_EXEC_ACCESS      4'b1010
`define MAT_HCSR_EXEC_PURGE       4'b1011
`define MAT_HCSR_EXEC_STOP_INV    4'b1100

// Command Status
`define MAT_CMD_NOP               2'b00
`define MAT_CMD_INPROGRESS        2'b01
`define MAT_CMD_SUCCESS           2'b10
`define MAT_CMD_FAILURE           2'b11

// Air Interface Commands

`define MAT_AIR_IF_NOP            5'b00000
`define MAT_AIR_IF_QueryRep       5'b00001
`define MAT_AIR_IF_ACK            5'b00010 
`define MAT_AIR_IF_Query          5'b00011 
`define MAT_AIR_IF_QueryAdjust    5'b00100 
`define MAT_AIR_IF_Select         5'b00101
`define MAT_AIR_IF_NAK            5'b00110 
`define MAT_AIR_IF_Req_RN         5'b00111 
`define MAT_AIR_IF_READ           5'b01000 
`define MAT_AIR_IF_Write          5'b01001 
`define MAT_AIR_IF_Kill           5'b01010 
`define MAT_AIR_IF_Lock           5'b01011
`define MAT_AIR_IF_Access         5'b01100 
`define MAT_AIR_IF_BlockWrite     5'b01101 
`define MAT_AIR_IF_BlockErase     5'b01110 

// Tag Data Type
`define MAT_TAG_DT_RN16           1'b0
`define MAT_TAG_DT_PCEPC          1'b1

// HOSTCSR[15:0] FAILURE_REASON_CODE

`define MAT_HCSR_FRC_SELECT_CMDCODE_MISMATCH  15'h0001

`define TIME $display("  Time: %0t", $time)