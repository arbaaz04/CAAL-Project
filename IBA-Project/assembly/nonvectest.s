#define STDOUT 0xd0580000

.section .text
.global _start
_start:
        .word 0x00000123     # Marker 1
    .word 0x00000456     # Marker 2
    # Initialize input buffers (DC signal: real=1.0, imag=0)
    lui a0, %hi(input_real)
    addi a0, a0, %lo(input_real)
    lui a1, %hi(input_imag)
    addi a1, a1, %lo(input_imag)
    li t0, 0x00010000              # Q16.16 value for 1.0
    li t1, 1024                    # N = 1024
.init_loop:
    sw t0, 0(a0)                   # Set real part
    sw zero, 0(a1)                 # Set imag part to 0
    addi a0, a0, 4
    addi a1, a1, 4
    addi t1, t1, -1
    bnez t1, .init_loop

    # Perform FFT
    lui a0, %hi(input_real)
    addi a0, a0, %lo(input_real)
    lui a1, %hi(input_imag)
    addi a1, a1, %lo(input_imag)
    li a2, 1024
    lui a3, %hi(output_real)
    addi a3, a3, %lo(output_real)
    lui a4, %hi(output_imag)
    addi a4, a4, %lo(output_imag)
    call fft_fixed_point

    # Print FFT results to log
    lui a0, %hi(output_real)
    addi a0, a0, %lo(output_real)
    li a1, 1024
    call printToLog

    j _finish

# --- Fixed-Point Arithmetic Functions ---
fixed_multiply:
    srai    a5, a0, 31
    srai    a4, a1, 31
    mul     a5, a5, a1
    mul     a4, a4, a0
    add     a5, a5, a4
    mul     a4, a0, a1
    mulhu   a0, a0, a1
    add     a5, a5, a0
    slli    a5, a5, 16
    srli    a0, a4, 16
    or      a0, a5, a0
    ret

fixed_complex_multiply:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    mv      t0, a0                   # W_real
    mv      t1, a1                   # W_imag
    mv      a0, a2                   # x_real
    mv      a1, a3                   # x_imag
    call    fixed_multiply            # W_real * x_real
    mv      t2, a0
    mv      a0, t0
    mv      a1, a3                   # W_real * x_imag
    call    fixed_multiply
    mv      t3, a0
    mv      a0, t1                   # W_imag
    mv      a1, a2                   # W_imag * x_real
    call    fixed_multiply
    mv      t4, a0
    mv      a0, t1                   # W_imag
    mv      a1, a3                   # W_imag * x_imag
    call    fixed_multiply
    sub     a0, t2, a0               # real = W_real*x_real - W_imag*x_imag
    add     a1, t3, t4               # imag = W_real*x_imag + W_imag*x_real
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

# --- Bit-Reversal Permutation ---
bit_reverse:
    mv      a5, a0
    li      a0, 0
    li      a4, 0
.bit_loop:
    slli    a0, a0, 1
    andi    a3, a5, 1
    or      a0, a3, a0
    srli    a5, a5, 1
    addi    a4, a4, 1
    bne     a4, a1, .bit_loop
    ret

# --- FFT Core Implementation ---
fft_fixed_point:
    addi    sp, sp, -64
    sw      ra, 60(sp)
    sw      s0, 56(sp)
    sw      s1, 52(sp)
    sw      s2, 48(sp)
    sw      s3, 44(sp)
    sw      s4, 40(sp)
    sw      s5, 36(sp)
    sw      s6, 32(sp)
    sw      s7, 28(sp)
    sw      s8, 24(sp)
    sw      s9, 20(sp)
    sw      s10, 16(sp)
    sw      s11, 12(sp)

    mv      s0, a0                   # input_real
    mv      s1, a1                   # input_imag
    li      s2, 1024                 # N
    mv      s3, a3                   # output_real
    mv      s4, a4                   # output_imag

    # Bit-reversal permutation
    li      s5, 0
.bitrev_loop:
    mv      a0, s5
    li      a1, 10                   # log2(1024)
    call    bit_reverse
    slli    t0, a0, 2                # byte offset
    lw      t1, 0(s0)
    add     t2, s3, t0
    sw      t1, 0(t2)                # Store real
    lw      t1, 0(s1)
    add     t2, s4, t0
    sw      t1, 0(t2)                # Store imag
    addi    s5, s5, 1
    blt     s5, s2, .bitrev_loop

    # FFT stages
    li      s5, 0                    # stage
    li      s6, 10                   # total stages
.stage_loop:
    li      s7, 1
    sll     s7, s7, s5               # block_size = 2^stage
    srli    s8, s7, 1                # half_block
    li      s9, 0                    # group

.group_loop:
    li      s10, 0                   # butterfly
.butterfly_loop:
    # Calculate indices
 addi t3, s5, 1
sll t0, s9, t3          # equivalent to sll t0, s9, s5 + 1

    add     t0, t0, s10              # even index
    add     t1, t0, s8               # odd index

    # Load elements
    slli    t0, t0, 2                # byte offsets
    slli    t1, t1, 2
    add     t2, s3, t0               # even_real
    lw      a0, 0(t2)
    add     t2, s4, t0               # even_imag
    lw      a1, 0(t2)
    add     t2, s3, t1               # odd_real
    lw      a2, 0(t2)
    add     t2, s4, t1               # odd_imag
    lw      a3, 0(t2)

    # Load twiddle factors
    li      t4, 512                  # N/2
    srl     t4, t4, s5               # stride
    mul     t3, s10, t4              # index
    slli    t3, t3, 3                # 8 bytes per entry
    lui     t4, %hi(twiddle_real)
    add     t4, t4, t3
    lw      a4, %lo(twiddle_real)(t4) # W_real
    lui     t4, %hi(twiddle_imag)
    add     t4, t4, t3
    lw      a5, %lo(twiddle_imag)(t4) # W_imag

    # Preserve even elements
    mv      t0, a0                   # even_real
    mv      t1, a1                   # even_imag

    # Complex multiply (W * odd)
    mv      a0, a4
    mv      a1, a5
    call    fixed_complex_multiply

    # Butterfly operations
    add     t2, t0, a0               # upper_real
    add     t3, t1, a1               # upper_imag
    sub     t4, t0, a0               # lower_real
    sub     t5, t1, a1               # lower_imag

    # Store results
   addi t3, s5, 1
sll t6, s9, t3          # equivalent to sll t6, s9, s5 + 1

    slli    t6, t6, 2                # byte offset
    slli    a0, s8, 2                # half_block offset

    add     a1, s3, t6
    sw      t2, 0(a1)                # upper_real
    add     a1, s4, t6
    sw      t3, 0(a1)                # upper_imag

    add     t6, t6, a0
    add     a1, s3, t6
    sw      t4, 0(a1)                # lower_real
    add     a1, s4, t6
    sw      t5, 0(a1)                # lower_imag

    addi    s10, s10, 1
    blt     s10, s8, .butterfly_loop

    addi    s9, s9, 1
    li      t0, 512
    srl     t0, t0, s5
    blt     s9, t0, .group_loop

    addi    s5, s5, 1
    blt     s5, s6, .stage_loop

    # Restore context
    lw      ra, 60(sp)
    lw      s0, 56(sp)
    lw      s1, 52(sp)
    lw      s2, 48(sp)
    lw      s3, 44(sp)
    lw      s4, 40(sp)
    lw      s5, 36(sp)
    lw      s6, 32(sp)
    lw      s7, 28(sp)
    lw      s8, 24(sp)
    lw      s9, 20(sp)
    lw      s10, 16(sp)
    lw      s11, 12(sp)
    addi    sp, sp, 64
    ret

# --- Print Function (Q16.16) ---
printToLog:
    li t0, 0x123                # Identifier
    li t0, 0x456                # Identifier
    mv t0, a0                   # Base address
    slli t1, a1, 2              # N * 4 bytes
    add t1, t0, t1              # End address
.print_loop:
    bge t0, t1, .print_end
    lw t2, 0(t0)                # Load Q16.16 value
    addi t0, t0, 4
    j .print_loop
.print_end:
    li t0, 0x123                # Identifier
    li t0, 0x456
    ret

# --- Simulator Exit ---
_finish:
    li x3, 0xd0580000
    addi x5, x0, 0xff
    sb x5, 0(x3)
    beq x0, x0, _finish
    .rept 100
        nop
    .endr

# --- Data Sections ---
.section .rodata
.align 4
twiddle_real:
    .include "./assembly/twiddle_real.s"   # Include 512 Q16.16 entries
twiddle_imag:
    .include "./assembly/twiddle_imag.s"   # Include 512 Q16.16 entries

.section .data
.align 4
input_real:  .space 4096         # 1024 elements (Q16.16)
input_imag:  .space 4096
output_real: .space 4096
output_imag: .space 4096

