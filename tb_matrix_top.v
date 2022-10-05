/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  tb_matrix_top.v
///
///  This file is part of the RFID Reader IP core project
///
///  Author(s):
///      - Donald Kim at Semisus (ddwkim10@hotmail.com)
///
///  Copyright (C) 2008 Authors
///
///  Resvision History
///      - 2008.04.13 Created
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "matrix_defines.v"
`include "timescale.v"


module tb_matrix_top();

parameter Tp = 1;

reg [31:0] mtxDataIn;
reg [7:0] mtxAddress;

reg mtxRw;
reg [3:0] mtxCs;
reg mtxClk;
reg mtxReset;

wire [31:0] mtxDataOut;

`ifdef MAT_DEBUG_FLAG
// reg s_RstHostCmd;
reg [31:0] irq_reg;
wire [4:0] SeqState;
wire tx_ShiftPIEOut;
`endif

wire int_o;

reg StartTB;
reg MtxBusTrInProgress;

matrix_top mattop
(
.mtxDataIn(mtxDataIn), .mtxAddress(mtxAddress), .mtxRw(mtxRw), .mtxCs(mtxCs), 
.mtxClk(mtxClk), .mtxReset(mtxReset), .mtxDataOut(mtxDataOut), 
`ifdef MAT_DEBUG_FLAG
// .s_RstHostCmd(s_RstHostCmd), 
.irq_reg(irq_reg), .SeqState(SeqState), .tx_ShiftPIEOut(tx_ShiftPIEOut),
`endif
.int_o(int_o)
);


integer tb_log_file;

initial
begin
   tb_log_file = $fopen("./log/matrix_tb.log");
   if (tb_log_file < 2)
   begin
      $display("*E Could not open/create testbench log file in ./log/ directory!");
      $finish;
   end
   mtxClk = 0;
   StartTB = 0;

   @ (posedge mtxClk);
   mtxDataIn <= 32'h0;
   mtxAddress <= 8'h0;
   mtxRw <= 1'b0;
   mtxCs <= 4'h0; 
   MtxBusTrInProgress <= 1'b0;
   // s_RstHostCmd <= 1'b0;
   @ (posedge mtxClk);
   StartTB  <= 1'b1;
end


always
begin
   forever #20 mtxClk = ~mtxClk;  // 2*20 ns -> 25 MHz 
end

always @(SeqState)
begin
    wait(StartTB);
    $fdisplay( tb_log_file, "\n(%0t) Sequencer State: 0x%0x", $time, SeqState);
    $write("\n(%0t) Sequencer State: 0x%0x", $time, SeqState);
end

always @(tx_ShiftPIEOut)
begin
    wait(StartTB);
    $fdisplay( tb_log_file, "\n(%0t) tx_ShiftPIEOut: 0x%0x", $time, tx_ShiftPIEOut);
    $write("\n(%0t) tx_ShiftPIEOut: 0x%0x", $time, tx_ShiftPIEOut);
end

initial
begin
wait(StartTB);  // Start of testbench
@(posedge mtxClk);
test_access_registers();
hard_reset;
test_host_commands();
end

task MtxWriteTransaction;
   input [31:0] Data;
   input [7:0] Address;
   input [3:0] Cs;

   begin
      wait(~MtxBusTrInProgress);
      MtxBusTrInProgress <= 1'b1;
      mtxAddress <= Address;
      mtxDataIn <= Data;
      mtxRw <= 1'b1;
      mtxCs <= Cs;
      @ (posedge mtxClk);
      $fdisplay( tb_log_file, "\n(%0t) Write to register (Data: 0x%x, Reg. Addr: 0x%0x)", $time, Data, Address);
      $write("\n(%0t) Write to register (Data: 0x%x, Reg. Addr: 0x%0x)", $time, Data, Address);
      // bus_transaction_idle;
      MtxBusTrInProgress <= 1'b0;
   end
endtask

task MtxReadTransaction;
   input [7:0] Address;
   input [3:0] Cs;

   begin
      wait(~MtxBusTrInProgress);
      MtxBusTrInProgress <= 1'b1;
      mtxAddress <= Address;
      mtxRw <= 1'b0;
      mtxCs <= Cs;
      @ (posedge mtxClk);
      $fdisplay( tb_log_file, "\n(%0t) Read from register (Data: 0x%x, Reg. Addr: 0x%0x)", $time, mtxDataOut, Address);
      $write("\n(%0t) Read from register (Data: 0x%x, Reg. Addr: 0x%0x)", $time, mtxDataOut, Address);
      // bus_transaction_idle;
      MtxBusTrInProgress <= 1'b0;
   end    
endtask

task hard_reset; //  Registers in RF
begin
  // reset registers
  mtxReset <= 1'b1;
  repeat(2) @(posedge mtxClk);
  mtxReset <= 1'b0;
end
endtask // hard_reset

task bus_transaction_idle;
begin
   mtxAddress <= `MAT_IDLE_BUSTRANS_ADR;
   mtxDataIn <= 32'h0;
   mtxRw <= 1'b0;
   mtxCs <= 4'h0;
   @(posedge mtxClk);
end
endtask

task test_heading;
 input [799:0] test_heading ;
 reg   [799:0] display_test ;
begin
 display_test = test_heading;
 while ( display_test[799:792] == 0 )
   display_test = display_test << 8 ;
 $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
 $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
 $fdisplay( tb_log_file, "  Heading: %s", display_test ) ;
 $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
 $fdisplay( tb_log_file, "  ***************************************************************************************" ) ;
 $fdisplay( tb_log_file, " " ) ;
end
endtask // test_heading

task test_access_registers();
reg [7:0] addr;
reg [31:0] data;
reg [3:0] sel;
begin
    test_heading("ACCESS TO MAC REGISTERS TEST");
    $display(" ");
    $display("ACCESS TO MAC REGISTERS TEST");
    
    // Reset Registers
    hard_reset;
    
    // Test R/W registers
    data <= 32'hffffffff;
    sel <= 4'hf;
    @(posedge mtxClk);
    for(addr = `MAT_HOST_CSR_ADR; addr <= `MAT_TXRXCTRLREG_ADR; addr = addr + 1)
    begin: REG_TEST
        // if(addr == `MAT_HOST_CSR_ADR || addr == `MAT_CMDREG_ADR) 
        //   disable REG_TEST;
        MtxWriteTransaction(data, addr, sel);
        MtxReadTransaction(addr, sel);
    end
    /*
    // Test resetting HostCmd
    // s_RstHostCmd <= 1'h1;
    @ (posedge mtxClk);
    $fdisplay( tb_log_file, "\n(%0t) Reset HostCmd", $time);
    $write("\n(%0t) Reset HostCmd", $time);
    // s_RstHostCmd <= 1'h0;
    MtxReadTransaction(`MAT_HOST_CSR_ADR, 4'hf);
    */
    // Test setting IRQ's
    $fdisplay( tb_log_file, "\n(%0t) interrupt output: 0x%x", $time, int_o);
    $write("\n(%0t) interrupt output: 0x%x", $time, int_o);
    @ (posedge mtxClk);
    irq_reg <= 32'h000007ff;
    @ (posedge mtxClk);
    $fdisplay( tb_log_file, "\n(%0t) irq_reg: 0x%x", $time, irq_reg);
    $write("\n(%0t) irq_reg: 0x%x", $time, irq_reg);
    irq_reg <= 32'h00000000;
    bus_transaction_idle;
    MtxReadTransaction(`MAT_INT_SRC_ADR, 4'hf);
    $fdisplay( tb_log_file, "\n(%0t) interrupt output: 0x%x", $time, int_o);
    $write("\n(%0t) interrupt output: 0x%x", $time, int_o);
    // Test resetting IRQ's
    bus_transaction_idle;
    MtxWriteTransaction(32'h000007ff, `MAT_INT_SRC_ADR, 4'hf);
    bus_transaction_idle;
    $fdisplay( tb_log_file, "\n(%0t) interrupt output: 0x%x", $time, int_o);
    $write("\n(%0t) interrupt output: 0x%x", $time, int_o);
end
endtask

task test_host_commands;
reg [7:0] addr;
reg [31:0] data;
reg [3:0] sel;
begin

    // Specify performance parameters
    // Tari = 6250 ns / 40 ns = 156.25 (-PW) = 78
    addr = `MAT_DATA0LEN_ADR;
    // data = 16'h004e;
    data = 16'h0005;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;    
    // 2*Tari = 312.5 (-PW) = 234 
    addr = `MAT_DATA1LEN_ADR;
    //data = 16'h00ea;
    data = 16'h000f;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;  
    // PW = 0.5*Tari = 78.125
    addr = `MAT_PIEPWLEN_ADR;
    // data = 16'h004e;
    data = 16'h0005;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;    
    // Modulation Depth is 90%
    // RTcal = 3*Tari (-PW) = 2.5*Tari = 390.625
    addr = `MAT_RTCALLEN_ADR;
    // data = 16'h0186;
    data = 16'h0019;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;       
    // TRcal = 2*RTcal (-PW) = 6*Tari (-PW) = 5.5*Tari
    addr = `MAT_TRCALLEN_ADR;
    // data = 16'h035b;
    data = 16'h0037;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;       
    // DR Ratio = 64/3
    addr = `MAT_DR_RATIO_ADR;
    data = {3'h0, 1'h0, 2'b00, 1'b0, 2'b00, 2'b00, 1'b0, 4'b0100};
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;
    // LF = DR/TRcal = 64/3/(6*Tari) = 568890 Hz
    // 10^9/LF = 1.7578e+003 (/40) = 43.9452
    addr = `MAT_LNKFREQ_ADR;
    // data = 32'h0008ae3a;
    data = 32'h0000002c;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;
    // Channel Number = [1:50]
    addr = `MAT_CHANNUM_ADR;
    data = 1 + {$random}%50;
    sel = 4'h1;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;
    // T1 = max(RTcal, 10/LF) = RTcal = 18750 ns = 469
    addr = `MAT_LNKTIMER1_ADR;
    // data = 16'h01d5;
    data = 16'h001e;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;   
    // T2 = 10/LF = 17578 ns = 440
    addr = `MAT_LNKTIMER2_ADR;
    // data = 16'h01b8;
    data = 16'h001c;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;   
    // T3 = T4 - T1 = 469, so 470
    addr = `MAT_LNKTIMER3_ADR;
    // data = 16'h01d6;
    data = 16'h001e;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;   
    // T4 = 2*RTcal = 6*Tari = 37500 ns = 938
    addr = `MAT_LNKTIMER4_ADR;
    // data = 16'h01d5;
    data = 16'h003c;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;   
    // Treply = 20 ms = 500000
    addr = `MAT_RPLYTIMER_ADR;
    // data = 32'h0007a120;
    data = 16'h0064;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;   
            
    // TXRX-Moder
    addr = `MAT_TXRX_MODER_ADR; 
    data = {24'h000000, 1'b1, 1'b1, 2'b00, 1'b0, 1'b0, 2'b00};
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;    
    
    // DELIMITER
    // Delimiter = 12500 ns / 40 ns = 312 = x138
    addr = `MAT_DELIMITER_ADR; 
    // data = 16'h0138;
    data = 16'h0014;
    sel = 4'h3;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;   
                       
    // Specify SELECT command
    addr = `MAT_CMDREG_ADR; 
    data = {4'b1010, 3'b100, 3'b101, 2'b01, 1'b0, 14'h0000, 5'b00101};
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;
    addr = `MAT_CMDPNTREG_ADR;
    data = {8'b10000001, 8'b10000000, 8'b10000000, 8'b00000000};
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDCNTREG_ADR;      // max 255
    data = 32'h000000fc;            // 252
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;   
    addr = `MAT_CMDATAREG0_ADR;
    data = 32'haa55aa55;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDATAREG1_ADR;
    data = 32'haa55aa55;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDATAREG2_ADR;
    data = 32'haa55aa55;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDATAREG3_ADR;
    data = 32'haa55aa55;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDATAREG4_ADR;
    data = 32'haa55aa55;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDATAREG5_ADR;
    data = 32'haa55aa55;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDATAREG6_ADR;
    data = 32'haa55aa55;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    addr = `MAT_CMDATAREG7_ADR;
    data = 32'haa55aa50;
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle; 
    // Now trigger HOST_INVENTORY command 
    addr = `MAT_HOST_CSR_ADR;
    data = {4'h0, 4'b1001, 24'h000000};
    sel = 4'hf;
    MtxWriteTransaction(data, addr, sel);
    bus_transaction_idle;
end
endtask

endmodule