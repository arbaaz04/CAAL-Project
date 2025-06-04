# RV32I 1024-Point FFT Implementation for VeeR-ISS Simulator

This project implements a 1024-point 1-Dimensional Fast Fourier Transform (1D FFT) in RISC-V assembly language, specifically designed for the VeeR-ISS RISC-V simulator. The implementation uses IEEE 754 single-precision floating-point arithmetic for high precision computation.
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
- IEEE 754 single-precision floating-point arithmetic
- Support for complex input signals (interleaved real/imaginary format)
- Memory-mapped I/O for result output
- Optimized for VeeR-ISS RISC-V simulator with Vector extensions
- Modular design with separate twiddle factor and input data files
- Proper RISC-V calling convention implementation
- Vectorized implementation using RISC-V Vector (RVV) extensions
- File I/O capabilities for saving intermediate and final results

### Technical Specifications
- FFT Size: 1024 points
- Arithmetic Format: IEEE 754 single-precision floating-point (32-bit)
- Input Format: Complex numbers in interleaved format (real, imaginary, real, imaginary...)
- Algorithm: Radix-2 Decimation-in-Time (DIT) with Cooley-Tukey butterfly operations
- Memory Requirements:
  - Input data: 8KB (1024 complex numbers × 8 bytes each)
  - Output buffers: 8KB (1024 complex numbers × 8 bytes each)
  - Twiddle factors: 4KB (512 complex twiddle factors × 8 bytes each)
  - Temporary buffers: 8KB (for planar format conversion in vectorized version)

## Running the Project

### Prerequisites
- RISC-V GCC toolchain (`riscv32-unknown-elf-gcc`)
- VeeR-ISS RISC-V simulator (whisper)
- Python 3 for post-processing scripts

### Vectorized Implementation
Download the folder locally and run the vectorized FFT implementation using RISC-V Vector extensions:
```bash
make allV
```

This will:
1. Compile `assembly/Vectorized.s` with vector extension support
2. Execute the program on the VeeR-ISS simulator
3. Display the FFT results using Python post-processing


### Output
For the implementation, the simulator will:
- Execute the FFT computation with bit-reversal and butterfly operations
- Save final FFT results to `fft_output.hex`
- Display the first several FFT bins in floating-point format
- Show completion status

## Implementation Details

### FFT Algorithm
- **Radix-2 Decimation-in-Time (DIT)** Cooley-Tukey FFT algorithm
- **10-stage computation** for 1024-point transform (2^10 = 1024)
- **Bit-reversal permutation** for proper input ordering
- **In-place butterfly operations** with complex multiplication
- **IEEE 754 single-precision floating-point** arithmetic throughout
- **Vectorized implementation** uses RISC-V Vector (RVV) extensions for parallel processing

### Floating-Point Arithmetic
The implementation uses IEEE 754 single-precision (32-bit) floating-point format:
- **High precision**: No quantization errors typical of fixed-point implementations
- **Native RISC-V support**: Uses `flw`, `fsw`, `fmul.s`, `fadd.s`, `fsub.s` instructions
- **Complex multiplication**: Properly handles (a+bi) × (c+di) = (ac-bd) + (ad+bc)i
- **Vectorized operations**: Uses vector floating-point instructions for parallel computation

### Key Components

#### 1. Main FFT Implementation (`assembly/Vectorized.s`)
- **Entry point** (`_start`): Initializes stack and orchestrates the FFT computation
- **Bit-reversal** (`vector_bit_reverse`): Reorders input data for FFT algorithm
- **Format conversion**: Converts between interleaved and planar data formats
- **Core FFT** (`vector_fft_core`): 10-stage butterfly computation with vectorized operations
- **File I/O**: Saves intermediate and final results to hex files
- **Memory-mapped output**: Displays results via MMIO for simulator interaction

#### 2. Input Data (`assembly/input_data.s`)
- **1024 complex samples** in interleaved format (real, imag, real, imag...)
- **Test pattern**: Impulse response (non-zero values at beginning, zeros elsewhere)
- **Floating-point format**: IEEE 754 single-precision values
- **Total size**: 8KB (1024 × 2 × 4 bytes)

#### 3. Twiddle Factors (`assembly/twiddle_factors.s`)
- **Pre-computed coefficients**: cos(2πk/N) and sin(2πk/N) values
- **512 unique factors**: Sufficient for 1024-point FFT due to symmetry
- **High precision**: IEEE 754 single-precision floating-point
- **Separate arrays**: `twiddle_real` and `twiddle_imag` for efficient access
- **Memory alignment**: Properly aligned for vectorized memory operations

#### 4. Memory Organization
- **Input/output buffers**: Allocated in `.data` section (8KB each)
- **Twiddle factors**: Stored in `.rodata` section (4KB total)
- **Temporary arrays**: Stack-allocated for planar format conversion
- **Stack space**: 8KB allocated for function calls and temporary storage

## Code Structure

### Key Functions

#### Core FFT Functions
- **`_start`**: Main entry point that initializes stack, calls FFT stages, and handles file output
- **`vector_bit_reverse`**: Performs 10-bit reversal for 1024-point FFT input reordering
- **`vector_fft_stages`**: Wrapper function that handles format conversion and calls core FFT
- **`vector_fft_core`**: Main FFT computation with 10 stages of vectorized butterfly operations

#### Vectorized Operations
- **Vectorized gather/scatter**: Uses `vluxei32.v` and `vsuxei32.v` for non-contiguous memory access
- **Vector arithmetic**: Employs `vfmul.vv`, `vfadd.vv`, `vfsub.vv` for parallel floating-point operations
- **Complex multiplication**: Vectorized implementation of (a+bi)×(c+di) using fused multiply-add
- **Dynamic vector length**: Uses `vsetvli` for optimal vector processing length

#### Utility Functions
- **`printToLogVectorized_interleaved`**: Outputs results via memory-mapped I/O
- **`write_to_file`**: Saves computation results to hex files for analysis
- **System calls**: `open`, `write`, `close` for file I/O operations

### Input Signal Characteristics
The implementation uses a test pattern with:
- **Non-zero values** at the beginning (1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0)
- **Zero padding** for the remaining 1016 samples
- **Interleaved format**: Real and imaginary components alternating
- **Purpose**: Creates a known frequency response for FFT verification

## Vectorization Details

### RISC-V Vector Extension Usage
- **Instruction set**: RV32GCV (with Vector and Floating-point extensions)
- **Vector length**: Dynamic, determined by `vsetvli` instruction
- **Element width**: 32-bit (e32) for single-precision floating-point
- **Vector registers**: Uses v0-v31 for parallel data processing
- **Memory operations**: Vectorized indexed loads/stores for twiddle factor access

### Performance Optimizations
- **Parallel butterfly operations**: Multiple butterflies computed simultaneously
- **Efficient twiddle indexing**: Vectorized computation of twiddle factor indices
- **Reduced memory bandwidth**: Planar format conversion minimizes data movement
- **Fused operations**: Uses `vfmacc.vv` and `vfnmsac.vv` for efficient complex multiplication

## File Structure

```
IBA-Project/
├── assembly/
│   ├── Vectorized.s          # Main vectorized FFT implementation
│   ├── NonVectorized.s       # Scalar FFT implementation
│   ├── input_data.s          # 1024-point test input data
│   ├── twiddle_factors.s     # Pre-computed twiddle factors
│   └── Source codes(raw, no test)/  # Raw implementation files
├── python/
│   ├── generate_twiddle.py   # Twiddle factor generation script
│   ├── print_log_array.py    # Result visualization script
│   └── write_array.py        # Input data generation script
├── veer/
│   ├── link.ld              # Linker script for VeeR-ISS
│   └── whisper.json         # Simulator configuration
└── Makefile                 # Build automation
```

## Additional Notes

- **Instruction sets**:
  - Vectorized version: RV32GCV (Base + Multiply + Float + Vector)
- **Output formats**: Results saved in both hex files and displayed via MMIO
- **Precision**: IEEE 754 single-precision provides high accuracy for signal processing
- **Simulator compatibility**: Optimized for VeeR-ISS with proper memory mapping

## Acknowledgments

- Dr. Salman Zaffar (Course Instructor)
- Abdul Wasay Imran (Course Teacher Assistant)
- RISC-V Foundation
- VeeR-ISS project contributors
