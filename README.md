
# RV32I 1024-Point FFT Implementation for VeeR-ISS Simulator

This project implements a 1024-point 1-Dimensional Fast Fourier Transform (1D FFT) in RISC-V assembly language, specifically designed for the VeeR-ISS RISC-V simulator. The implementation uses fixed-point arithmetic in Q16.16 format for efficient computation.

## Course Information
This project was developed as part of the course "Computer Architecture and Assembly Language" (CAAL) taught to sophomore year students pursuing Bachelor's in Computer Science at the Institute of Business Administration (IBA), Karachi. The course is instructed by Dr. Salman Zaffar.

## Group Members (Group Name: Fast and Fourierous)
- Arbaaz Murtaza (ERP: 29052)
- Muhammad Hussain (ERP: 28985)
- Piranchal Ghai (ERP: 29050)
- Zarmeen Rehman (ERP: 29011)

## Project Overview

### Features
- 1024-point FFT implementation
- Fixed-point arithmetic (Q16.16 format)
- Support for both real and complex input signals
- Memory-mapped I/O for result output
- Optimized for VeeR-ISS RISC-V simulator
- Modular design with separate twiddle factor tables
- Proper RISC-V calling convention implementation

### Technical Specifications
- FFT Size: 1024 points
- Fixed-point Format: Q16.16 (16 integer bits, 16 fractional bits)
- Input Modes: Real-only or Complex
- Memory Requirements:
  - Input buffers: 8KB (4KB real + 4KB imaginary)
  - Output buffers: 8KB (4KB real + 4KB imaginary)
  - Twiddle factors: 8KB (4KB real + 4KB imaginary)

## Running the Project

1. Copy the contents of `c_translation.s` to `Vectorized.s`:
   ```bash
   # Either use a text editor to copy/paste the content
   # or use a command like:
   cp IBA-Project/assembly/c_translation.s IBA-Project/assembly/Vectorized.s
   ```

2. Run the project using the Makefile:
   ```bash
   cd IBA-Project
   make allV
   ```

3. The VeeR-ISS simulator will execute the FFT implementation and show:
   - Messages about the FFT computation
   - Results of the FFT operation in hex format
   - Completion message

## Implementation Details

### FFT Algorithm
- Radix-2 Decimation-in-Time (DIT) FFT
- In-place computation
- Bit-reversed addressing
- Fixed-point arithmetic in Q16.16 format

### Fixed-Point Arithmetic
The implementation uses Q16.16 fixed-point format with proper handling of multiplication:
- 16 bits for integer part
- 16 bits for fractional part
- Multiplication uses specialized fixed-point operations to maintain precision

### Key Components

1. Main FFT Implementation (`Vectorized.s`)
   - Core FFT computation using butterfly operations
   - Bit-reversal algorithm for proper indexing
   - MMIO for output display
   - Static memory allocation for buffers

2. Twiddle Factor Tables
   - `twiddle_real.s`: Real components (cos values in Q16.16)
   - `twiddle_imag.s`: Imaginary components (-sin values in Q16.16)
   - Pre-computed for all 1024 points

3. Memory Organization
   - Input/output arrays allocated in `.bss` section
   - Twiddle factors included in `.rodata` section
   - Memory-mapped I/O for result output

## Code Structure

### Key Functions
- `test_1024point_fixed`: Main entry point that sets up the test and displays results
- `fft_fixed_point`: Core FFT implementation
- `generate_twiddle_factors`: Returns pointers to pre-computed twiddle factor tables
- `fixed_complex_multiply`: Performs complex multiplication with Q16.16 values
- `bit_reverse`: Performs bit-reversal addressing for FFT indexing

### Input Signal
The implementation uses an impulse input (1.0 at index 0, zero elsewhere) which results in a flat frequency response, ideal for testing FFT correctness.

## Additional Notes

- The code is fully compatible with VeeR-ISS's RV32IM instruction set (no floating-point)
- The implementation uses only integer operations for all calculations
- Output is displayed in hexadecimal format through memory-mapped I/O
- The first 8 bins of the FFT results are displayed for verification

## Acknowledgments

- Dr. Salman Zaffar (Course Instructor)
- Abdul Wasay Imran (Course Teacher Assistant)
- RISC-V Foundation
- VeeR-ISS project contributors
