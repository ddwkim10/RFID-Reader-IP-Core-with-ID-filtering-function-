/////////////////////////////////////////////////////////////////////////////////////////////////
///
///  matrix_shiftreg.v
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


module matrix_txshiftreg(Clk, Reset, tx_ShiftDataIn, tx_ShiftBitCnt, tx_ShiftLoad, tx_ShiftStart, 
                         tx_ShiftEmpty, tx_ShiftOut, tx_LoadPIE, tx_StartPIE, tx_ShiftNextBitToPIE,
                         tx_FinalShiftLoadErase
                         );
  
parameter Tp=1;

input Clk;
input Reset;
input [31:0] tx_ShiftDataIn;
input [7:0] tx_ShiftBitCnt;
input tx_ShiftLoad;
input tx_ShiftStart;
output tx_ShiftEmpty;
output tx_ShiftOut;
output tx_LoadPIE;
output tx_StartPIE;
input tx_ShiftNextBitToPIE;
input tx_FinalShiftLoadErase;

reg [31:0] ShiftReg; // Load takes one cycle
reg [7:0] ShiftBitCnt;

assign tx_StartPIE = tx_ShiftStart;
wire ShiftBitCntEQ1;
assign ShiftBitCntEQ1   = (tx_ShiftStart & (ShiftBitCnt == 8'h01));
assign tx_ShiftEmpty = tx_ShiftStart & ShiftBitCntEQ1 & tx_ShiftNextBitToPIE;
assign tx_LoadPIE = (tx_ShiftLoad | tx_ShiftNextBitToPIE) & ~tx_FinalShiftLoadErase;

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      begin
         ShiftReg <= 32'h00000000;
         ShiftBitCnt <= 8'h0;
      end
   else
   if(tx_ShiftLoad)
      begin
          ShiftReg <= tx_ShiftDataIn;
          ShiftBitCnt <= tx_ShiftBitCnt;
      end
   else
   if(tx_ShiftNextBitToPIE)
      begin
         ShiftReg[31:0] <= #Tp {ShiftReg[30:0], 1'b0};
         ShiftBitCnt[7:0] <= #Tp ShiftBitCnt[7:0] - 1'b1;
      end
end

assign tx_ShiftOut = ShiftReg[31];

endmodule


module matrix_rxshiftreg(Clk, Reset, rx_ShiftDataOut, rx_ShiftBitCnt, rx_ShiftLoad,
                         rx_ChainDataReady, rx_ChainOut, rx_CollisionDetected, r_LnkFreq
                         );
  
parameter Tp=1;

input Clk;
input Reset;
output [31:0] rx_ShiftDataOut;
output [7:0] rx_ShiftBitCnt;
output rx_ShiftLoad;          // if FIFO is full, FIFO will post the overflow.
input rx_ChainDataReady;
input rx_ChainOut;
input rx_CollisionDetected;
input [31:0] r_LnkFreq;

reg [31:0] TsamplingCnt;
reg [31:0] ShiftReg0, ShiftReg1;
reg [7:0] ShiftBitCnt0, ShiftBitCnt1;

// Rx Shifter States
parameter [3:0]                 //enum states
          RXSHIFTST_IDLE         = 4'h1,
          RXSHIFTST_FILL0        = 4'h2,
          RXSHIFTST_FILL1        = 4'h4,
          RXSHIFTST_COLLDTCTED   = 4'h8;

reg [3:0] RxShiftState, rxshiftnext_state;

reg rx_ChainDataReady_q;

always @(posedge Clk or posedge Reset)
begin
    if(Reset)
       rx_ChainDataReady_q <= 0;
    else
       rx_ChainDataReady_q <= rx_ChainDataReady;
end

// Adjust TsamplingCnt to compensate the sampling drift 

reg prevRxChainOut;

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      prevRxChainOut <= 0;
   else
      prevRxChainOut <= rx_ChainOut;
end


wire rx_TsampleLoad;
wire TsamplingCntEQ0;
wire TsamplingCntGT0;
wire TsamplingCntOn;
wire rx_Shift0NextBit;
wire rx_Shift1NextBit;
wire AdjustTsampleCnt;

assign rx_TsampleLoad = (rx_ChainDataReady & ~rx_ChainDataReady_q);
assign TsamplingCntEQ0 = (TsamplingCnt == 32'h00000000);
assign TsamplingCntGT0 = (TsamplingCnt > 32'h00000000);
assign TsamplingCntOn = (((RxShiftState == RXSHIFTST_FILL0) | (RxShiftState == RXSHIFTST_FILL1)) & rx_ChainDataReady & TsamplingCntGT0);
assign rx_Shift0NextBit = ((RxShiftState == RXSHIFTST_FILL0) & rx_ChainDataReady & TsamplingCntEQ0);
assign rx_Shift1NextBit = ((RxShiftState == RXSHIFTST_FILL1) & rx_ChainDataReady & TsamplingCntEQ0);
assign AdjustTsampleCnt = (TsamplingCntOn & (prevRxChainOut ^ rx_ChainOut));

always @(posedge Clk or posedge Reset)
begin
   if (Reset)
      begin
         ShiftReg0 <= 32'h00000000;
         ShiftBitCnt0 <= 8'h0;
         ShiftReg1 <= 32'h00000000;
         ShiftBitCnt1 <= 8'h0;
         TsamplingCnt <= 32'h00000000;
      end
   else
   if(rx_TsampleLoad)
      begin
         ShiftReg0 <= 32'h00000000;
         ShiftBitCnt0 <= 8'h0;
         ShiftReg1 <= 32'h00000000;
         ShiftBitCnt1 <= 8'h0;
         TsamplingCnt <= {1'b0, r_LnkFreq[31:1]};
      end
   else
   if(TsamplingCntOn)
      begin
         TsamplingCnt <= TsamplingCnt - 1; 
      end
   else
   if(rx_Shift0NextBit)
      begin
         ShiftReg0[31:0] <= #Tp {ShiftReg0[30:0], rx_ChainOut};
         ShiftBitCnt0[7:0] <= #Tp ShiftBitCnt0[7:0] + 1'b1;
         TsamplingCnt <= r_LnkFreq;
      end
   else
   if(rx_Shift1NextBit)
      begin
         ShiftReg1[31:0] <= #Tp {ShiftReg1[30:0], rx_ChainOut};
         ShiftBitCnt1[7:0] <= #Tp ShiftBitCnt1[7:0] + 1'b1;
         TsamplingCnt <= r_LnkFreq;
      end
   else
   if(AdjustTsampleCnt)
      begin
         TsamplingCnt <= {1'b0, r_LnkFreq[31:1]}; 
      end
end

wire ShiftBitCnt0EQ32;
wire ShiftBitCnt0LT32;
wire ShiftBitCnt1EQ32;
wire ShiftBitCnt1LT32;
assign ShiftBitCnt0EQ32 = (ShiftBitCnt0 == 8'h20);
assign ShiftBitCnt0LT32 = (ShiftBitCnt0 < 8'h20);
assign ShiftBitCnt1EQ32 = (ShiftBitCnt1 == 8'h20);
assign ShiftBitCnt1LT32 = (ShiftBitCnt1 < 8'h20);

assign rx_ShiftLoad  = ((RxShiftState == RXSHIFTST_FILL0) & ShiftBitCnt0EQ32)                      | 
                       ((RxShiftState == RXSHIFTST_FILL0) & ShiftBitCnt0LT32 & ~rx_ChainDataReady) |
                       ((RxShiftState == RXSHIFTST_FILL1) & ShiftBitCnt1EQ32)                      |
                       ((RxShiftState == RXSHIFTST_FILL1) & ShiftBitCnt1LT32 & ~rx_ChainDataReady);

always @(posedge Clk or posedge Reset)
begin
   if(Reset)
      begin
         RxShiftState <= RXSHIFTST_IDLE;
      end
   else
      begin
          RxShiftState <= rxshiftnext_state;
      end
end

reg [31:0] rx_ShiftDataOut;
reg [7:0] rx_ShiftBitCnt;

always @(RxShiftState or rx_ChainDataReady or rx_CollisionDetected or ShiftBitCnt0EQ32 or ShiftBitCnt0LT32 or
         ShiftReg0 or ShiftBitCnt0 or ShiftBitCnt1EQ32 or ShiftBitCnt1LT32 or ShiftReg1 or ShiftBitCnt1) // include every input
begin

   rxshiftnext_state = RxShiftState;
   rx_ShiftDataOut = 32'h00000000;
   rx_ShiftBitCnt = 8'h00;
   
	case(RxShiftState)
	    RXSHIFTST_IDLE:
	       begin
	           if(rx_ChainDataReady)
	              rxshiftnext_state = RXSHIFTST_FILL0;
	           else
	           if(rx_CollisionDetected)
	              rxshiftnext_state = RXSHIFTST_COLLDTCTED;
	       end
	    RXSHIFTST_FILL0:
	       begin
	           if(ShiftBitCnt0EQ32)
	              begin
	                 rx_ShiftDataOut = ShiftReg0;
	                 rx_ShiftBitCnt = ShiftBitCnt0;
	                 rxshiftnext_state = RXSHIFTST_FILL1;
	              end
	           else
	           if(ShiftBitCnt0LT32 & ~rx_ChainDataReady)
	              begin
	                 rx_ShiftDataOut = ShiftReg0;
                    rx_ShiftBitCnt = ShiftBitCnt0;         
	                 rxshiftnext_state = RXSHIFTST_IDLE;
	              end
	           else
	           if(rx_CollisionDetected)
	              begin
	                 rxshiftnext_state = RXSHIFTST_COLLDTCTED;
	              end
	       end
	    RXSHIFTST_FILL1:
	       begin
	           if(ShiftBitCnt1EQ32)
	              begin
	                 rx_ShiftDataOut = ShiftReg1;
	                 rx_ShiftBitCnt = ShiftBitCnt1;	                
                    rxshiftnext_state = RXSHIFTST_FILL0;
                 end
	           else
	           if(ShiftBitCnt1LT32 & ~rx_ChainDataReady)
	              begin
	                 rx_ShiftDataOut = ShiftReg1;
	                 rx_ShiftBitCnt = ShiftBitCnt1;		            
	                 rxshiftnext_state = RXSHIFTST_IDLE;
	              end
	           else
	           if(rx_CollisionDetected)
	              begin
	                 rxshiftnext_state = RXSHIFTST_COLLDTCTED;
	              end
	       end
	    RXSHIFTST_COLLDTCTED:
	       begin
	           if(~rx_CollisionDetected)
	              rxshiftnext_state = RXSHIFTST_IDLE;
	       end
	    default:   // include every comb output used, but not specified in always
          begin
          end
	endcase
end

endmodule
