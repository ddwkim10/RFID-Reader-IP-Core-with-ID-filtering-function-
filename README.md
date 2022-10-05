# RFID-Reader-IP-Core-with-ID-filtering-function
This repository stores a Verilog model of Digital Baseband (DBB) of the RFID reader IC. The standard is  specified in EPCTM Radio-Frequency Identity Protocols Class-1 Generation-2 UHF RFID Protocol for Communications at 860 MHz – 960 MHz Version 1.0.9. 

An excerpt from RFID Reader IC Chip Specification.doc is followed.

1. Introduction

This documentation specifies the architecture of Digital Baseband (DBB) of the RFID reader IC  specified in EPCTM Radio-Frequency Identity Protocols Class-1 Generation-2 UHF RFID Protocol for Communications at 860 MHz – 960 MHz Version 1.0.9.  Analog Baseband (ABB) of the reader IC will be briefly introduced in Section 4 only to explain the interface between DBB and ABB.

1.1 The Feature Set

The architecture supports the following feature set:

![image](https://user-images.githubusercontent.com/50349262/193962815-bea464a1-d27c-4a2c-98ea-7198d4d1f82d.png)

Matrix minimizes the number of required gates by not using a processor core.  Its power management module switches off the chip during the idle state and minimizes its power consumption.  The host may set filters on {PC, EPC} tag information.  Matrix performs filter operations on behalf of the host accelerating Reader Protocol process.  It is designed for easy installation in mobile phones and various hand-held devices.

This is level-1 architecture specification of Matrix.  More detailed chip specifications shall follow as we design, develop and implement it.

2. Architecture

As shown in the figure 2.1, the core architecture consists of:

1.	Host Interface
2.	Register File
3.	Reader Protocol Support Block (RPSB)
4.	Core Buffer
5.	Rx Chain
6.	Tx Chain
7.	Sequencer
8.	RF Interface
9.	Power Management
10.	Clock Module
11.	Timer Module

![image](https://user-images.githubusercontent.com/50349262/193963165-67863a7b-a135-4976-9032-154b989a63a9.png)

2.1 Host Interface

Host Interface shall support the following interfaces depending on the customer needs:

1.	USB Device Interface
2.	Wishbone Interface
3.	AMBA-APB
4.	Other serial/bus interfaces used for Audio/Video
5.	GPIO’s

The reader receives host commands and returns the outcomes using Host Interface.

2.2 Register File

Register File is defined in Section 5.  Among them are CSR, Interrupt Source, Interrupt Mask, RFID command and parameter registers, and registers storing various link layer timing parameters specified in the standard.  CSR receives host commands and returns the status.  Sequencer uses CMDREG to send RFID commands to tags.

2.3 RPSB

RPSB maintains Filter Database capturing {Classifier, Filter Mask, FilterOP} in the memory (if the performance is matter, an associative memory may be used).  RPSB performs filter operations using {Classifier, Filter Mask} on incoming {PC, EPC} tag on the fly.  If a match found, it executes filter operations specified in FilterOP.

2.4 Core Buffer

Core Buffer stores the inventory list of tags accessible from the reader.  It maintains the list of {PC, EPC, RN16/Handle, STATE} tuples.  Message Block in which input parameters of RFID commands are stored resides in Core Block.  So does Filter Database.

2.5 Sequencer

Host sets host commands to CSR register.  Sequencer is the main state machine executing the commands and returns the status in the same register.  Sequencer runs an inventory round with tags around the reader and stores the inventory list in Core Buffer.  It executes various host commands specified in Section 3 on behalf of the host.

2.6 Tx Chain

Tx Chain encodes the input data with PIE encoding, then digitally converts it upward using DSB-ASK, SSB-ASK, or PR-ASK modulation.  It outputs the modulated signals to DAC in Analog Front-End (AFE) which transmits the signals in the air.  

2.7 Rx Chain

Rx Chain receives ASK or PSK modulated signals from ADC in AFE.  After demodulation, FM0 or Miller decoder generates original digital baseband signals backscattered from the tag.

2.8 Power Management

Power Manager turns power on or off the chip.  Whole chip except the power management block shall be put into a sleep mode and save the power during the idle state.

2.9 RF Interface

RF Interface provides the signals between DBB and ABB including DAC outputs, ADC inputs, Channel Number, Continuous Wave (CW) Enable, and Power Management On/Off Switch.  Channel Number determines the center frequency of the link and used in locking LO in the PLL block.  In FHSS mode, the output of the channel table is fed into it.  The reader transmits CW RF signal during receiving data to power up tags by setting 1 to the CW Enable Bit. 



