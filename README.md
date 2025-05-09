# RV32I FFT Implementation for VeeR Core

This project implements a 1024-point 1-Dimentional Fast Fourier Transform (1D FFT) in RISC-V assembly language, specifically designed for the VeeR RISC-V core. The implementation uses fixed-point arithmetic in Q16.16 format for efficient computation.

## Course Information
This project was developed as part of the course "Computer Architecture and Assembly Language" (CAAL) taught to sophomore year students pursuing Bachelor's in Computer Science at the Institute of Business Administration (IBA), Karachi. The course is instructed by Dr. Salman Zaffar.

## Group Members
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
- Optimized for VeeR RISC-V core
- Modular design with separate twiddle factor tables

### Technical Specifications
- FFT Size: 1024 points
- Fixed-point Format: Q16.16 (16 integer bits, 16 fractional bits)
- Input Modes: Real-only or Complex
- Memory Requirements:
  - Input buffers: 8KB (4KB real + 4KB imaginary)
  - Output buffers: 8KB (4KB real + 4KB imaginary)
  - Twiddle factors: 8KB (4KB real + 4KB imaginary)
  - Bit-reversed indices: 4KB

## Prerequisites

### Required Software
1. RISC-V GCC Toolchain
   ```bash
   # For Ubuntu/Debian
   sudo apt-get install gcc-riscv64-linux-gnu
   ```

2. VeeR Core Simulator
   - Clone the VeeR repository:
     ```bash
     git clone https://github.com/chipsalliance/Cores-VeeR.git
     cd Cores-VeeR
     ```

### Directory Structure
```
.
├── RV32i Assembly Code
│   ├── fft_rv32i_1024.s      # Main FFT implementation
│   ├── twiddle_real.s        # Real part of twiddle factors
│   ├── twiddle_imag.s        # Imaginary part of twiddle factors
│   ├── build.sh             # Build script
│   ├── linker.ld            # Linker script
├── Python Code
│   ├── fft_python_implement.py # Python reference implementation
│   ├── generate_twiddle.py  # Twiddle factor generation script
│   ├── fft_results.txt      # FFT results for verification
│   ├── Figure_1.png         # Visualization of FFT results
├── Requirements
│   ├── 1D FFT Documentation.pdf # Detailed documentation
│   ├── Project Deliverables.pdf # Summary of project deliverables
├── README.md                # This file
```

## Building the Project

1. Make the build script executable:
   ```bash
   chmod +x build.sh
   ```

2. Run the build script:
   ```bash
   ./build.sh
   ```

The build process will:
- Compile the FFT assembly program
- Generate a hex file for simulation
- Create a disassembly file for reference

### Build Output Files
- `fft_rv32i_1024` - Binary executable
- `fft_rv32i_1024.hex` - Hex file for simulation
- `fft_rv32i_1024.dump` - Disassembly for reference

## Running in VeeR Simulator

1. Navigate to the VeeR simulator directory:
   ```bash
   cd Cores-VeeR/verif/dv
   ```

2. Run the simulation:
   ```bash
   make -f Makefile.veer
   ```

3. The simulator will:
   - Load the FFT program
   - Execute the computation
   - Output results to the memory-mapped I/O region

## Memory Layout

### VeeR Memory Map
- Stack: 0x1000
- MMIO Status: 0x10000
- MMIO Result: 0x10100

### Data Organization
- Input buffers start at 0x20000
- Output buffers start at 0x21000
- Twiddle factors start at 0x22000

## Implementation Details

### FFT Algorithm
- Radix-2 Decimation-in-Time (DIT) FFT
- In-place computation
- Bit-reversed addressing
- Fixed-point arithmetic in Q16.16 format

### Key Components
1. Main FFT Implementation (`fft_rv32i_1024.s`)
   - Core FFT computation
   - Memory management
   - I/O handling

2. Twiddle Factor Tables
   - `twiddle_real.s`: Real components
   - `twiddle_imag.s`: Imaginary components
   - Pre-computed for 1024-point FFT

3. Build System
   - `build.sh`: Compilation and linking
   - `linker.ld`: Memory layout configuration

## Additional Resources

### Python Code
The following Python scripts and resources are included for reference and testing purposes:

1. `fft_python_implement.py`: A Python implementation of the 1D FFT algorithm for verification and comparison with the assembly implementation.
2. `generate_twiddle.py`: A script to generate twiddle factor tables for the FFT algorithm.
3. `fft_results.txt`: Contains the results of the FFT computation for verification purposes.
4. `Figure_1.png`: A visualization of the FFT results.

### Documentation
The `Requirements` folder contains the following documents:

1. `1D FFT Documentation.pdf`: Detailed documentation on the 1D FFT algorithm and its implementation.
2. `Project Deliverables.pdf`: A summary of the project deliverables and requirements.

## Acknowledgments

- Dr. Salman Zaffar (Course Instructor)
- Abdul Wasay Imran (Course Teacher Assistant)
- RISC-V Foundation

## References
1. 1D FFT Documentation Guide by Dr. Salman Zaffar and Abdul Wasay Imran
2. RISC-V Assembly Language Programming
2. FFT Algorithm References
   - Cooley-Tukey FFT Algorithm
   - Fixed-point FFT Implementation