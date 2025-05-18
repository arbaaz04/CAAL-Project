# RV32I 1024-Point FFT Implementation for VeeR-ISS Simulator

This project implements a 1024-point 1-Dimensional Fast Fourier Transform (1D FFT) in RISC-V assembly language, specifically designed for the VeeR-ISS RISC-V simulator. The implementation uses fixed-point arithmetic in Q16.16 format for efficient computation.

## Course Information
This project was developed as part of the course "Computer Architecture and Assembly Language" (CAAL) taught to sophomore year students pursuing Bachelor's in Computer Science at the Institute of Business Administration (IBA), Karachi. The course is instructed by Dr. Salman Zaffar.

## Group Members (Group Name: Fast and Fourierous)
- Arbaaz Murtaza (ERP: 29052)
- Muhammad Hussain (ERP: 28985)
- Piranchal Ghai (ERP: 29050)
- Zarmeen Rahman (ERP: 29011)

## Project Overview

### Features
- 1024-point FFT implementation (both vectorized and non-vectorized versions)
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

### Vectorized Implementation
1. Copy the contents of `vectest.s` to `Vectorized.s`:
   ```bash
   cp Assembly/vectest.s Assembly/Vectorized.s
   ```

2. Run the project using the Makefile:
   ```bash
   cd IBA-Project
   make allV
   ```

### Non-Vectorized Implementation
1. Copy the contents of `nonvectest.s` to `NonVectorized.s`:
   ```bash
   cp Assembly/nonvectest.s Assembly/NonVectorized.s
   ```

2. Run the project using the Makefile:
   ```bash
   cd IBA-Project
   make allNV
   ```

For both implementations:
- The VeeR-ISS simulator will execute the FFT implementation and show:
  - Messages about the FFT computation
  - Results of the FFT operation in hex format
  - Completion message

## Implementation Details

### FFT Algorithm
- Radix-2 Decimation-in-Time (DIT) FFT
- In-place computation
- Bit-reversed addressing
- Fixed-point arithmetic in Q16.16 format
- Vectorized version uses RISC-V Vector (RVV) extensions

### Fixed-Point Arithmetic
The implementation uses Q16.16 fixed-point format with proper handling of multiplication:
- 16 bits for integer part
- 16 bits for fractional part
- Multiplication uses specialized fixed-point operations to maintain precision

### Key Components

1. Main FFT Implementation
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
- `_start`: Main entry point that sets up the test and displays results
- `vector_fft`: Core FFT implementation (vectorized version)
- `vector_bitrev`: Performs bit-reversal addressing
- `vector_complex_mul`: Performs complex multiplication with Q16.16 values
- `printToLogVectorized`: Outputs results via memory-mapped I/O

### Input Signal
The implementation uses an impulse input (1.0 at index 0, zero elsewhere) which results in a flat frequency response, ideal for testing FFT correctness.

## Additional Notes

- The vectorized version uses RV32IMV instruction set (with vector extensions)
- The non-vectorized version uses only RV32IM instruction set
- Output is displayed in hexadecimal format through memory-mapped I/O
- The first 8 bins of the FFT results are displayed for verification

## Acknowledgments

- Dr. Salman Zaffar (Course Instructor)
- Abdul Wasay Imran (Course Teacher Assistant)
- RISC-V Foundation
- VeeR-ISS project contributors
