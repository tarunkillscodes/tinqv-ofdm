# SPDX-FileCopyrightText: © 2025 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from tqv import TinyQV

# When submitting your design, change this to 16 + the peripheral number
# in peripherals.v.  e.g. if your design is i_user_simple00, set this to 16.
# The peripheral number is not used by the test harness.
PERIPHERAL_NUM = 16

# Register map
CTRL   = 0x0
STATUS = 0x1
DIN    = 0x2
DOUT   = 0x3

# Control bits
CTRL_START  = 1 << 0
CTRL_SCHEME = 1 << 1
CTRL_VALID  = 1 << 2

@cocotb.test()
async def test_qpsk_mapping(dut):
    dut._log.info("QPSK test start")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()

    # Start QPSK mapping (scheme=0)
    await tqv.write_reg(0x0,5)
    
    # Write input bits for QPSK (use only 2 LSBs)
    await tqv.write_reg(0x2, 0b01)  # expect I=+1, Q=-1

    # Wait some cycles
    await ClockCycles(dut.clk, 20)

    status = await tqv.read_reg(0x1)
    bitcount = (status >> 1) & 0xF   # extract bits [4:1]
    dut._log.info(f"Bitcount = {bitcount}")

    # Read status
    status = await tqv.read_reg(0x1)
    assert (status & 0x01) == 1, "QPSK: ready bit not set"

    # Read output symbol
    dout = await tqv.read_reg(0x3)
    q = dout & 0x0F
    i = (dout >> 4) & 0x0F
    dut._log.info(f"QPSK mapped output: I={i}, Q={q}")

    # Example check: For input=01, expect I=+1, Q=-1
    assert i == 1 and q == 0xF, "QPSK output mismatch"


@cocotb.test()
async def test_qam16_mapping(dut):
    dut._log.info("16-QAM test start")

    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, PERIPHERAL_NUM)
    await tqv.reset()
    # Start 16-QAM mapping (scheme=1)
    await tqv.write_reg(0x0, CTRL_START | CTRL_VALID | CTRL_SCHEME)

    # Write input bits for 16-QAM (use 4 LSBs)
    await tqv.write_reg(0x2, 0b1010)  # should map to I=+3, Q=+3

    # Wait cycles
    await ClockCycles(dut.clk, 5)

    # Read status
    status = await tqv.read_reg(0x1)
    assert (status & 0x01) == 1, "16-QAM: ready bit not set"

    # Read output symbol
    dout = await tqv.read_reg(0x3)
    q = dout & 0x0F
    i = (dout >> 4) & 0x0F
    dut._log.info(f"16-QAM mapped output: I={i}, Q={q}")

    # Expected: I=3, Q=3
    assert i == 3 and q == 3, "16-QAM output mismatch"

'''
@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Interact with your design's registers through this TinyQV class.
    # This will allow the same test to be run when your design is integrated
    # with TinyQV - the implementation of this class will be replaces with a
    # different version that uses Risc-V instructions instead of the SPI 
    # interface to read and write the registers.
    tqv = TinyQV(dut, PERIPHERAL_NUM)

    # Reset, always start the test by resetting TinyQV
    await tqv.reset()

    dut._log.info("Test project behavior")

    # Test register write and read back
    await tqv.write_reg(0, 20)
    assert await tqv.read_reg(0) == 20

    # Set an input value, in the example this will be added to the register value
    dut.ui_in.value = 30

    # Wait for two clock cycles to see the output values, because ui_in is synchronized over two clocks,
    # and a further clock is required for the output to propagate.
    await ClockCycles(dut.clk, 3)

    # The following assertion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
 '''
