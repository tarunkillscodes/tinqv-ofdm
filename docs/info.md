<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

The peripheral index is the number TinyQV will use to select your peripheral.  You will pick a free
slot when raising the pull request against the main TinyQV repository, and can fill this in then.  You
also need to set this value as the PERIPHERAL_NUM in your test script.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# OFDM Offloader 

Author: Tarun Vignesh G and Shreya Ranjitha M

Peripheral index: nn

## What it does

The peripheral provides efficient symbol mapping for two common modulation schemes used in OFDM systems: QPSK (Quadrature Phase Shift Keying) and 16-QAM(16-level Quadrature Amplitude Modulation).

Functional Description:

The peripheral accepts input bits from the CPU, groups them according to the selected modulation scheme, and produces corresponding I (in-phase) and Q (quadrature) symbol components.

Mapping is performed in hardware using lookup-table–style combinational logic for low latency.

A simple finite state machine (FSM) controls the flow:

IDLE: Waits for CPU start command.

MAP: Performs symbol mapping.

OUTPUT: Makes the I/Q output available to the CPU.

Modulation Schemes:

QPSK: Maps 2 input bits → 1 complex symbol (I/Q each ±1).

16-QAM: Maps 4 input bits → 1 complex symbol (I/Q each ∈ {–3, –1, +1, +3}).

## Register map

Document the registers that are used to interact with your peripheral
# QPSK/16-QAM Modulation Peripheral – Memory Map

This peripheral provides a memory-mapped interface for the CPU to control and monitor modulation operations.

## Register Map

| Address | Name        | Bits        | Description                                                                 |
|---------|-------------|-------------|-----------------------------------------------------------------------------|
| 0x0     | Control     | [0] start   | Start modulation process (1 = start)                                        |
|         |             | [1] scheme  | Select modulation scheme (0 = QPSK, 1 = 16-QAM)                             |
|         |             | [2] valid   | valid in(if the input is valid an you want to start mapping)                |                                   |         |             | [7:3]       | Reserved                                                                    |
| 0x1     | Status      | [0] ready   | Indicates dataout is valid (1 = ready)                                      |
|         |             | [4:1] count | Remaining bit count of input to be mapped(decreases as bits are consumed)   |                     
|         |             | [7:5]       | Reserved                                                                    |
| 0x2     | Data In     | [7:0]       | Input data (8-bit payload to be mapped into QPSK/16-QAM symbols)            |
| 0x3     | Data Out    | [3:0] Q     | Q (quadrature) component of symbol                                          |
|         |             | [7:4] I     | I (in-phase) component of symbol                                            |
| Others  | Reserved    |             | Always return 0x00                                                          |

## How to test

Explain how to use your project

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
