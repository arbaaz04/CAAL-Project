#=============================================================
# 1024-Point Vectorized Fixed-Point FFT (Q16.16) - RV32I RVV Assembly
# Radix-2 DIT, Iterative Approach with Vectorization
# Updated with Critical Fixes
#=============================================================

# --- Vector Configuration ---
.set VLEN, 32  # Adjust based on target's VLEN

# --- Vector Bit-Reversal Permutation ---
vector_bitrev:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)

    mv s0, a0                   # input_real
    mv s1, a1                   # input_imag
    li a2, 1024                 # N=1024

    vsetvli t0, a2, e32, m4    # 32-bit elements, LMUL=4 (FIXED)
    vid.v v16                   # [0,1,2,...]
    li a5, 0x3FF                # 10-bit mask (FIXED)

    # Bit reversal mask operations
    vsrl.vi v8, v16, 1
    li t1, 0x55555555
    vand.vx v8, v8, t1          # Swap even/odd bits
    vand.vx v12, v16, t1
    vsll.vi v12, v12, 1
    vor.vv v8, v8, v12

    vsrl.vi v12, v8, 2
    li t1, 0x33333333
    vand.vx v12, v12, t1        # Swap pairs
    vand.vx v8, v8, t1
    vsll.vi v8, v8, 2
    vor.vv v8, v12, v8

    vsrl.vi v12, v8, 4
    li t1, 0x0F0F0F0F
    vand.vx v12, v12, t1        # Swap nibbles
    vand.vx v8, v8, t1
    vsll.vi v8, v8, 4
    vor.vv v8, v12, v8

    vsrl.vi v12, v8, 8
    li t1, 0x00FF00FF
    vand.vx v12, v12, t1        # Swap bytes
    vand.vx v8, v8, t1
    vsll.vi v8, v8, 8
    vor.vv v8, v12, v8

    vsrl.vi v12, v8, 16         # Final swap
    vsll.vi v8, v8, 16
    vor.vv v8, v12, v8
    
    vsrl.vi v8, v8, 22
    vand.vx v8, v8, a5          # Apply 10-bit mask (FIXED)

    # Load bit-reversed data
    vluxei32.v v4, (s0), v8     # Load real (FIXED: vluxei32)
    vluxei32.v v12, (s1), v8    # Load imag (FIXED: vluxei32)

    # Store to output buffers
    vse32.v v4, (a3)            # output_real (FIXED: a3 preserved)
    vse32.v v12, (a4)           # output_imag

    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

# --- Vector Fixed-Point Complex Multiply ---
vector_complex_mul:
    # a0: W_real ptr, a1: W_imag ptr
    # a2: x_real ptr, a3: x_imag ptr
    # a4: result_real ptr, a5: result_imag ptr

    vsetvli t0, zero, e32, m4
    vle32.v v0, (a0)            # Load W_real (FIXED)
    vle32.v v4, (a1)            # Load W_imag (FIXED)
    vle32.v v8, (a2)            # Load x_real
    vle32.v v12, (a3)           # Load x_imag

    # Real part: W_real*x_real - W_imag*x_imag
    vmul.vv v16, v0, v8         # W_real * x_real
    vmul.vv v20, v4, v12        # W_imag * x_imag
    vsrl.vi v16, v16, 16        # Q16.16 scaling (FIXED)
    vsrl.vi v20, v20, 16
    vsub.vv v24, v16, v20       # real_part

    # Imag part: W_real*x_imag + W_imag*x_real
    vmul.vv v28, v0, v12        # W_real * x_imag
    vmul.vv v20, v4, v8         # W_imag * x_real
    vsrl.vi v28, v28, 16        # Q16.16 scaling (FIXED)
    vsrl.vi v20, v20, 16
    vadd.vv v8, v28, v20        # imag_part

    # Store results
    vse32.v v24, (a4)
    vse32.v v8, (a5)
    ret

# --- Vector FFT Core ---
vector_fft:
    addi sp, sp, -64
    sw ra, 60(sp)
    sw s0, 56(sp)
    sw s1, 52(sp)
    sw s2, 48(sp)
    sw s3, 44(sp)
    sw s4, 40(sp)
    sw s5, 36(sp)
    sw s6, 32(sp)

    mv s0, a0                   # input_real
    mv s1, a1                   # input_imag
    li s2, 1024                 # N=1024
    mv s3, a3                   # output_real
    mv s4, a4                   # output_imag

    # Vector bit-reversal permutation
    call vector_bitrev

    # FFT stages
    li s5, 0                    # stage counter
    li s6, 10                   # total stages

.vector_stage_loop:
    li s7, 1 << (s5 + 1)       # FIXED: block_size = 2^(stage+1)
    li s8, s7 >> 1              # FIXED: half_block
    li s9, 0                    # group counter

    .vector_group_loop:
        li s10, 0               # butterfly counter

        .vector_bfly_loop:
            # Calculate indices
            sll t0, s9, (s5 + 1)  # FIXED: base index
            add t1, t0, s8
            
            # Calculate twiddle offset
            li t3, 512          # N/2
            srl t3, t3, s5      # 512 / 2^stage
            mul t2, s10, t3
            slli t2, t2, 2      # 4 bytes per entry

            # Load twiddles
            la a0, twiddle_real
            la a1, twiddle_imag
            add a0, a0, t2
            add a1, a1, t2

            # Calculate data pointers
            slli t0, t0, 2      # byte offset
            slli t1, t1, 2
            add a2, s3, t0      # even_real
            add a3, s4, t0      # even_imag
            add a4, s3, t1      # odd_real
            add a5, s4, t1      # odd_imag

            # Perform complex multiply
            call vector_complex_mul

            # Vector butterfly operations
            vsetvli t0, zero, e32, m4
            vle32.v v0, (a4)    # Load upper real
            vle32.v v4, (a5)    # Load upper imag
            vle32.v v8, (a2)    # Load even real
            vle32.v v12, (a3)   # Load even imag

            # Upper = even + W*odd
            vadd.vv v16, v8, v0  # real
            vadd.vv v20, v12, v4 # imag

            # Lower = even - W*odd
            vsub.vv v24, v8, v0  # real
            vsub.vv v28, v12, v4 # imag

            # Store results
            vse32.v v16, (a4)
            vse32.v v20, (a5)
            vse32.v v24, (a2)
            vse32.v v28, (a3)

            addi s10, s10, 1
            blt s10, s8, .vector_bfly_loop  # FIXED: correct loop limit

        addi s9, s9, 1
        li t0, 1024
        srl t0, t0, (s5 + 1)    # FIXED: dynamic group count
        blt s9, t0, .vector_group_loop

    addi s5, s5, 1
    blt s5, s6, .vector_stage_loop

    # Restore registers
    lw ra, 60(sp)
    lw s0, 56(sp)
    lw s1, 52(sp)
    lw s2, 48(sp)
    lw s3, 44(sp)
    lw s4, 40(sp)
    lw s5, 36(sp)
    lw s6, 32(sp)
    addi sp, sp, 64
    ret

# --- Twiddle Factors ---
.section .rodata
.align 4
twiddle_real:
    .include "twiddle_real.s"
twiddle_imag:
    .include "twiddle_imag.s"

# --- Data Section ---
.section .data
.align 4
input_real:  .space 4096
input_imag:  .space 4096
output_real: .space 4096
output_imag: .space 4096

# --- Entry Point ---
.section .text
.global _start
_start:
    la sp, stack_top
    la a0, input_real
    la a1, input_imag
    la a3, output_real
    la a4, output_imag
    call vector_fft
    ecall

.section .stack
stack_bot: .space 4096
stack_top: