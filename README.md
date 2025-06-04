# RV32I 1024-Point FFT Implementation for VeeR-ISS Simulator

A 1024-point Fast Fourier Transform implementation in RISC-V assembly using IEEE 754 single-precision floating-point arithmetic, optimized for the VeeR-ISS simulator with RISC-V Vector extensions.

**Course:** Computer Architecture and Assembly Language (CAAL) - IBA Karachi

**Instructor:** Dr. Salman Zaffar

**Group:** Fast and Fourierous (Arbaaz Murtaza, Muhammad Hussain, Piranchal Ghai, Zarmeen Rahman)

## Features & Specifications
- **Algorithm:** 1024-point Radix-2 DIT FFT with Cooley-Tukey butterfly operations
- **Arithmetic:** IEEE 754 single-precision floating-point (32-bit)
- **Vectorization:** RISC-V Vector (RVV) extensions for parallel processing
- **Input:** Complex signals in interleaved format (real, imag, real, imag...)
- **Memory:** 8KB input/output buffers, 4KB twiddle factors
- **I/O:** File output and memory-mapped display

## Quick Start

**Prerequisites:** RISC-V GCC toolchain, VeeR-ISS simulator (whisper), Python 3

**Run Vectorized Version:**
```bash
make allV
```

**Output:** FFT results saved to `fft_output.hex` and displayed via memory-mapped I/O

## Implementation Overview

### Core Components
1. **`assembly/Vectorized.s`** - Main FFT with 10-stage butterfly operations, bit-reversal, and vectorized processing
2. **`assembly/input_data.s`** - 1024 complex test samples (8KB)
3. **`assembly/twiddle_factors.s`** - Pre-computed cos/sin coefficients (4KB)

### Key Features
- **10-stage computation** for 1024-point transform using Cooley-Tukey algorithm
- **Bit-reversal permutation** for proper FFT input ordering
- **Vectorized operations** using RVV instructions (`vfmul.vv`, `vfadd.vv`, `vluxei32.v`)
- **Complex multiplication** with fused multiply-add operations
- **Format conversion** between interleaved and planar layouts for optimization

## Key Functions
- **`_start`** - Main entry point with stack initialization and file I/O
- **`vector_bit_reverse`** - 10-bit reversal for 1024-point FFT input reordering
- **`vector_fft_core`** - 10-stage vectorized butterfly operations
- **`write_to_file`** - Saves results to hex files

## Vectorization Features
- **RV32GCV instruction set** with Vector and Floating-point extensions
- **Dynamic vector length** using `vsetvli` for optimal processing
- **Parallel butterfly operations** with vectorized gather/scatter memory access
- **Fused multiply-add** operations for efficient complex multiplication

## File Structure
```
IBA-Project/
├── assembly/
│   ├── Vectorized.s          # Main vectorized FFT implementation
│   ├── input_data.s          # 1024-point test input data
│   └── twiddle_factors.s     # Pre-computed twiddle factors
├── python/                   # Post-processing scripts
├── veer/                     # Simulator configuration
└── Makefile                  # Build automation
```

## Acknowledgments
Dr. Salman Zaffar (Instructor), Abdul Wasay Imran (TA), RISC-V Foundation
