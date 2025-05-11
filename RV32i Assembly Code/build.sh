#!/bin/bash

# Exit on error
set -e
cd "$(dirname "$0")"

# Toolchain
RISCV_CC="riscv32-unknown-elf-gcc"
RISCV_OBJCOPY="riscv32-unknown-elf-objcopy"
RISCV_OBJDUMP="riscv32-unknown-elf-objdump"

# Flags
CFLAGS="-march=rv32im -mabi=ilp32 -static -mcmodel=medany -nostdlib -nostartfiles -T linker.ld"

# Files
SRC="fft_rv32i_1024.s twiddle_real.s twiddle_imag.s"
OUTPUT="fft_rv32i_1024"
HEX="${OUTPUT}.hex"
VEER_HEX="${OUTPUT}_veer.hex"
DUMP="${OUTPUT}.dump"
BIN="${OUTPUT}.bin"

echo "Building FFT program..."

# Compile and link
$RISCV_CC $CFLAGS -o $OUTPUT $SRC

# Generate standard hex file
$RISCV_OBJCOPY -O verilog $OUTPUT $HEX

# Generate VeeR-ISS compatible hex (reversed byte order)
$RISCV_OBJCOPY -O binary $OUTPUT $BIN  # Convert to raw binary
$RISCV_OBJCOPY -I binary -O verilog --reverse-bytes=4 $BIN $VEER_HEX  # Proper 32-bit word reversal

# Disassembly
$RISCV_OBJDUMP -D $OUTPUT > $DUMP

echo "Build complete!"
echo "Output files:"
echo "- Binary: $OUTPUT"
echo "- Standard hex: $HEX"
echo "- VeeR-ISS hex (reversed): $VEER_HEX"
echo "- Disassembly: $DUMP"