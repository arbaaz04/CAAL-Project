#=============================================================
# 1024-Point Fixed-Point FFT (Q16.16) - RV32I Assembly
# Compliant with Radix-2 DIT FFT Matrix Factorization
# No Floating-Point or Dynamic Memory
# Twiddle Factors Linked via .include
#=============================================================

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
    mv      t0, a0                   # t0 = W_real
    mv      t1, a1                   # t1 = W_imag
    mv      a0, a2                   # a0 = x_real (odd)
    mv      a1, a3                   # a1 = x_imag (odd)
    call    fixed_multiply            # W_real * x_real
    mv      t2, a0
    mv      a0, t0
    mv      a1, a3                   # W_real * x_imag
    call    fixed_multiply
    mv      t3, a0
    mv      a0, t1                   # W_imag
    mv      a1, a2                   # x_real (FIXED: a1 = x_real)
    call    fixed_multiply            # W_imag * x_real
    mv      t4, a0
    mv      a0, t1                   # W_imag
    mv      a1, a3                   # x_imag
    call    fixed_multiply            # W_imag * x_imag
    sub     a0, t2, a0               # real_out = W_real*x_real - W_imag*x_imag
    add     a1, t3, t4               # imag_out = W_real*x_imag + W_imag*x_real
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

# --- FFT Core Function ---
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

    mv      s0, a0                   # s0 = input_real
    mv      s1, a1                   # s1 = input_imag
    li      s2, 1024                 # N = 1024
    mv      s3, a3                   # s3 = output_real
    mv      s4, a4                   # s4 = output_imag

    # --- Bit-Reversal Permutation ---
    li      s5, 0
.bitrev_loop:
    mv      a0, s5
    li      a1, 10                   # log2(1024)
    call    bit_reverse
    slli    t0, a0, 2                # Byte offset
    lw      t1, 0(s0)                # Load real
    add     t2, s3, t0
    sw      t1, 0(t2)
    lw      t1, 0(s1)                # Load imag
    add     t2, s4, t0
    sw      t1, 0(t2)
    addi    s5, s5, 1
    blt     s5, s2, .bitrev_loop

    # --- FFT Stages (10 stages) ---
    li      s5, 0                    # Stage counter
    li      s6, 10
.stage_loop:
    li      s7, 1
    addi    t0, s5, 1               
    sll     s7, s7, t0              
    srli    s8, s7, 1                   
    li      s9, 0                    # Group counter
    li      t0, 512                  
    srl     t1, t0, s5               # t1 = 512 >> s5 (max groups)
.group_loop:
    li      s10, 0                   # Butterfly counter
.butterfly_loop:
    # Compute indices
    sll     t0, s9, (s5 + 1)         # group * block_size
    add     t0, t0, s10              # even index
    add     t1, t0, s8               # odd index

    # Load elements
    slli    t0, t0, 2                # Byte offsets
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
    mv      t0, a0                   # t0 = even_real
    mv      t1, a1                   # t1 = even_imag

    # Compute W * odd
    mv      a0, a4                   # W_real
    mv      a1, a5                   # W_imag
    call    fixed_complex_multiply    # a0 = real_out, a1 = imag_out

    # Butterfly operations
    add     t2, t0, a0               # upper_real
    add     t3, t1, a1               # upper_imag
    sub     t4, t0, a0               # lower_real
    sub     t5, t1, a1               # lower_imag

    # Store results (FIXED OFFSET CALCULATION AND BUFFER ADDRESSING)
    sll     t6, s9, (s5 + 1)         # group * (block_size)
    slli    t6, t6, 2                # Convert to byte offset
    slli    a0, s8, 2                # half_block_byte_offset = half_block * 4

    # Store upper results
    add     a1, s3, t6               # output_real base + offset
    sw      t2, 0(a1)                # Store upper_real
    add     a1, s4, t6               # output_imag base + offset
    sw      t3, 0(a1)                # Store upper_imag

    # Store lower results
    add     t6, t6, a0               # Add half_block_byte_offset
    add     a1, s3, t6               # output_real base + lower offset
    sw      t4, 0(a1)                # Store lower_real
    add     a1, s4, t6               # output_imag base + lower offset
    sw      t5, 0(a1)                # Store lower_imag

    addi    s10, s10, 1
    blt     s10, s8, .butterfly_loop

    addi    s9, s9, 1
    #sll     t0, s7, 1
    blt     s9, t1, .group_loop

    addi    s5, s5, 1
    blt     s5, s6, .stage_loop

    # --- Restore Registers ---
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

# --- Twiddle Factor Tables (Q16.16) ---
.section .rodata
.align 4
twiddle_real:
    .include "twiddle_real.s"        # Precomputed cosine values
twiddle_imag:
    .include "twiddle_imag.s"        # Precomputed sine values (negative)

# --- Static Buffers ---
.section .data
.align 4
input_real:  .space 4096
input_imag:  .space 4096
output_real: .space 4096
output_imag: .space 4096

# --- Entry Point ---
main:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    lui     a0, %hi(input_real)
    addi    a0, a0, %lo(input_real)
    lui     a1, %hi(input_imag)
    addi    a1, a1, %lo(input_imag)
    li      a2, 1024
    lui     a3, %hi(output_real)
    addi    a3, a3, %lo(output_real)
    lui     a4, %hi(output_imag)
    addi    a4, a4, %lo(output_imag)
    call    fft_fixed_point
    lw      ra, 12(sp)
    addi    sp, sp, 16
    li      a0, 0
    ret