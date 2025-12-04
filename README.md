# ADVANCED_ENCRYPTION_STANDARD_128_DESIGN

## Project Overview

This repository contains a high-performance, hardware-based implementation of the AES-128 (Advanced Encryption Standard) algorithm designed in Verilog HDL. The project is deployed on a Digilent Basys 3 (Xilinx Artix-7) FPGA and interfaces with a host PC via UART for real-time encryption and decryption verification.

The design demonstrates a complete FPGA design flow, from RTL coding and simulation to synthesis, implementation, and static timing analysis (STA), achieving successful timing closure.

## Key Features

  * **Full AES-128 Logic Implementation:** Implements the complete AES cipher suite including Key Expansion, SubBytes, ShiftRows, MixColumns, and AddRoundKey, along with their inverse operations for decryption.
  * **UART Communication Interface:** Features custom-designed `uart_rx` and `uart_tx` modules operating at 9600 baud to ensure reliable bidirectional data transfer between the FPGA and the PC.
  * **Clock Domain Management:** Utilizes a robust clock management strategy, implementing a 100MHz to 10MHz clock divider using Xilinx `BUFG` primitives. This ensures logic stability and resolves setup/hold time violations across the design.
  * **Hardware Verification:** The design is validated on hardware using a custom Python script (utilizing the `pyserial` library) that transmits hex test vectors and verifies the encrypted output against expected standards.
  * **Timing Closure:** Successfully achieved Positive Worst Negative Slack (WNS) through rigorous Static Timing Analysis (STA), utilizing proper XDC constraints and defining False Path exceptions for asynchronous I/O.

## Technical Specifications

  * **Target Device:** Xilinx Artix-7 FPGA (xc7a35tcpg236-1)
  * **Hardware Description Language:** Verilog HDL
  * **EDA Tool:** AMD Xilinx Vivado 2023.2
  * **Simulation & Verification:** Vivado Simulator (XSim) for RTL simulation; Python for hardware-in-the-loop verification.
  * **Constraints:** Static Timing Analysis (STA) and I/O Planning via XDC.

## Implementation Results

  * **Resource Utilization:** Optimized for efficient Logic Unit (LUT) usage suitable for the Artix-7 architecture.
  * **Timing Performance:** The design meets all timing constraints with a WNS \> 8ns, ensuring reliable operation without race conditions.
  * **Throughput:** Capable of processing 128-bit data blocks in real-time via the serial interface.

## Repository Structure

  * `src/` - Verilog source code files (`aes_top.v`, `aes_128.v`, `uart_rx.v`, `uart_tx.v`, etc.).
  * `sim/` - Testbench files for behavioral simulation (`aes_encrypt_tb.v`).
  * `constraints/` - Physical and timing constraints file (`BASYS3.xdc`).
  * `scripts/` - Python script for hardware verification (`aes_test.py`).

## Deployment Instructions

1.  Open the project in **AMD Xilinx Vivado**.
2.  Run Synthesis and Implementation, then generate the bitstream.
3.  Connect the Digilent Basys 3 board and program the device via the Hardware Manager.
4.  Set **Switch 0 (SW0)** on the FPGA to the High position to enable Encryption Mode.
5.  Execute the verification script on the host PC:
    ```bash
    python aes_test.py
    ```
6.  The script will transmit the Key and Plaintext, and the FPGA will return the Encrypted Ciphertext to the console for verification.
