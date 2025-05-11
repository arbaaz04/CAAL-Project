# RV32I 1024-Point FFT Implementation for VeeR-ISS Simulator

This project implements a 1024-point 1-Dimentional Fast Fourier Transform (1D FFT) in RISC-V assembly language, specifically designed for the VeeR-ISS RISC-V simulator. The implementation uses fixed-point arithmetic in Q16.16 format for efficient computation.

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
  - Bit-reversed indices: 4KB

## Prerequisites for Ubuntu

### Required Software
1. System Packages
   ```bash
   sudo apt-get update
   sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev libboost-all-dev
   ```

2. RISC-V Toolchain
   ```bash
   # Clone the toolchain repository
   git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
   cd riscv-gnu-toolchain
   
   # Initialize submodules
   git submodule update --init --recursive
   
   # Build the toolchain
   mkdir build
   cd build
   ./configure --prefix=/tools/rv32imfcv --with-arch=rv32imfcv --with-abi=ilp32f
   sudo make
   
   # Add to PATH
   echo 'export PATH=/tools/rv32imfcv/bin/:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

3. VeeR-ISS Simulator
   ```bash
   # Clone and build VeeR-ISS
   git clone https://github.com/chipsalliance/VeeR-ISS.git
   cd VeeR-ISS
   make SOFT_FLOAT=1
   ```

### Directory Structure
```
.
├── RV32i Assembly Code
│   ├── fft_rv32i_1024.s      # Main FFT implementation
│   ├── twiddle_real.s        # Real part of twiddle factors
│   ├── twiddle_imag.s        # Imaginary part of twiddle factors
│   ├── build.sh              # Build script
│   ├── linker.ld             # Linker script
│   ├── whisper.json          # VeeR-ISS configuration
├── Python Code
│   ├── fft_python_implement.py # Python reference implementation
│   ├── generate_twiddle.py   # Twiddle factor generation script
│   ├── fft_results.txt       # FFT results for verification
│   ├── Figure_1.png          # Visualization of FFT results
├── Requirements
│   ├── 1D FFT Documentation.pdf # Detailed documentation
│   ├── Project Deliverables.pdf # Summary of project deliverables
├── README.md                 # This file
```

## Building the Project

1. Make the build script executable:
   ```bash
   chmod +x RV32i\ Assembly\ Code/build.sh
   ```

2. Run the build script:
   ```bash
   cd RV32i\ Assembly\ Code/
   ./build.sh
   ```

The build process will:
- Compile the FFT assembly program using the RISC-V toolchain
- Generate a standard hex file for simulation
- Create a VeeR-ISS compatible hex file with reversed byte order
- Generate a disassembly file for reference

### Build Output Files
- `fft_rv32i_1024` - Binary executable
- `fft_rv32i_1024.hex` - Standard hex file
- `fft_rv32i_1024_veer.hex` - VeeR-ISS compatible hex file with reversed bytes
- `fft_rv32i_1024.dump` - Disassembly for reference

## Running in VeeR-ISS Simulator

1. Ensure the build process has been completed and generated the VeeR-ISS compatible hex file.

2. Create the VeeR-ISS configuration file (whisper.json) if not already present:
   ```json
   {
     "verbose": false,
     "verbosity_level": 0,
     "stack_address": "0x1000",
     "tohost_address": "0x10000",
     "fromhost_address": "0x10100",
     "memories": [
       {
         "address_range": ["0x00000000", "0x10000000"],
         "type": "ram",
         "file": "fft_rv32i_1024_veer.hex"
       }
     ],
     "debug_buffer": {
       "address": 0,
       "size": 0
     }
   }
   ```

3. Run the simulation with VeeR-ISS:
   ```bash
   whisper --interactive -x fft_rv32i_1024_veer.hex -s 0x00000000 --configfile whisper.json
   ```

4. In the interactive prompt:
   - Type `step` to execute a single instruction
   - Type `step N` (e.g., `step 100`) to execute multiple instructions
   - Type `run` to execute until completion
   - Type `quit` to exit the simulator
   - Type `mem 0x10100 16` to inspect the results after simulation completes

## Memory Layout

### VeeR Memory Map
- Stack: 0x1000
- MMIO Status: 0x10000
- MMIO Result: 0x10100

### Data Organization
- Input buffers: allocated statically
- Output buffers: allocated statically
- Twiddle factors: included as static tables

## Implementation Details

### FFT Algorithm
- Radix-2 Decimation-in-Time (DIT) FFT
- In-place computation
- Bit-reversed addressing
- Fixed-point arithmetic in Q16.16 format using proper high-precision multiply operations

### Fixed-Point Arithmetic
The implementation uses Q16.16 fixed-point format with proper handling of multiplication:
- 16 bits for integer part
- 16 bits for fractional part
- Multiplication uses `mulh` instruction to extract the high 32 bits of the 64-bit product
- This approach avoids precision loss in intermediate calculations

### Key Components
1. Main FFT Implementation (`fft_rv32i_1024.s`)
   - Core FFT computation with butterfly algorithm
   - Fixed-point math for sine/cosine functions
   - Memory management
   - I/O handling

2. Twiddle Factor Tables
   - `twiddle_real.s`: Real components
   - `twiddle_imag.s`: Imaginary components
   - Pre-computed for 1024-point FFT

3. Build and Configuration
   - `build.sh`: Compilation and linking
   - `linker.ld`: Memory layout configuration
   - `whisper.json`: VeeR-ISS simulator configuration

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
- VeeR-ISS project contributors

## References
1. 1D FFT Documentation Guide by Dr. Salman Zaffar and Abdul Wasay Imran
2. RISC-V Assembly Language Programming
3. RISC-V Calling Convention
4. FFT Algorithm References
   - Cooley-Tukey FFT Algorithm
   - Fixed-point FFT Implementation
5. VeeR-ISS Documentation: https://github.com/chipsalliance/VeeR-ISS
