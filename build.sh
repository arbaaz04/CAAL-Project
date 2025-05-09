#!/bin/bash

# Exit on error
set -e

# Compiler and linker settings
RISCV_CC="riscv64-unknown-elf-gcc"
RISCV_OBJCOPY="riscv64-unknown-elf-objcopy"
RISCV_OBJDUMP="riscv64-unknown-elf-objdump"

# Compile flags
CFLAGS="-march=rv32im -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles"

# Source files
SRC="fft_rv32i_1024.s twiddle_real.s twiddle_imag.s"

# Output files
OUTPUT="fft_rv32i_1024"
HEX="${OUTPUT}.hex"
DUMP="${OUTPUT}.dump"

echo "Building FFT program..."

# Compile and link
$RISCV_CC $CFLAGS -o $OUTPUT $SRC

# Generate hex file for simulation
$RISCV_OBJCOPY -O verilog $OUTPUT $HEX

# Generate disassembly for reference
$RISCV_OBJDUMP -D $OUTPUT > $DUMP

echo "Build complete!"
echo "Output files:"
echo "- Binary: $OUTPUT"
echo "- Hex file: $HEX"
echo "- Disassembly: $DUMP" 