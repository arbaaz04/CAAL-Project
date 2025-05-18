#define STDOUT 0xd0580000

.section .text
.global _start
_start:
    ## Set up stack pointer
    la sp, stack_top

    ## Initialize FFT
    la a0, input_real
    la a1, input_imag
    la a3, output_real
    la a4, output_imag
    call vector_fft

    ## Print real part
    la a0, output_real
    lw a1, fft_size
    call printToLogVectorized

    ## Print imaginary part
    la a0, output_imag
    lw a1, fft_size
    call printToLogVectorized

    j _finish

## --- FFT Functions ---
vector_bitrev:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)

    mv s0, a0                   # input_real
    mv s1, a1                   # input_imag
    li a2, 1024                 # N=1024

    vsetvli t0, a2, e32, m4    # 32-bit elements, LMUL=4
    vid.v v16                   # [0,1,2,...]
    li a5, 0x3FF                # 10-bit mask

    # Bit reversal operations
    vsrl.vi v8, v16, 1
    li t1, 0x55555555
    vand.vx v8, v8, t1
    vand.vx v12, v16, t1
    vsll.vi v12, v12, 1
    vor.vv v8, v8, v12

    vsrl.vi v12, v8, 2
    li t1, 0x33333333
    vand.vx v12, v12, t1
    vand.vx v8, v8, t1
    vsll.vi v8, v8, 2
    vor.vv v8, v12, v8

    vsrl.vi v12, v8, 4
    li t1, 0x0F0F0F0F
    vand.vx v12, v12, t1
    vand.vx v8, v8, t1
    vsll.vi v8, v8, 4
    vor.vv v8, v12, v8

    vsrl.vi v12, v8, 8
    li t1, 0x00FF00FF
    vand.vx v12, v12, t1
    vand.vx v8, v8, t1
    vsll.vi v8, v8, 8
    vor.vv v8, v12, v8

    vsrl.vi v12, v8, 16
    vsll.vi v8, v8, 16
    vor.vv v8, v12, v8
    
    vsrl.vi v8, v8, 22
    vand.vx v8, v8, a5

    # Load bit-reversed data
    vluxei32.v v4, (s0), v8
    vluxei32.v v12, (s1), v8

    # Store results
    vse32.v v4, (a3)
    vse32.v v12, (a4)

    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    addi sp, sp, 16
    ret

vector_complex_mul:
    # a0: W_real, a1: W_imag
    # a2: x_real, a3: x_imag
    # a4: result_real, a5: result_imag
    vsetvli t0, zero, e32, m4
    vle32.v v0, (a0)
    vle32.v v4, (a1)
    vle32.v v8, (a2)
    vle32.v v12, (a3)

    # Real part calculation
    vmul.vv v16, v0, v8
    vmul.vv v20, v4, v12
    vsrl.vi v16, v16, 16
    vsrl.vi v20, v20, 16
    vsub.vv v24, v16, v20

    # Imaginary part calculation
    vmul.vv v28, v0, v12
    vmul.vv v20, v4, v8
    vsrl.vi v28, v28, 16
    vsrl.vi v20, v20, 16
    vadd.vv v8, v28, v20

    # Store results
    vse32.v v24, (a4)
    vse32.v v8, (a5)
    ret

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

    call vector_bitrev

    # FFT stages
    li s5, 0                    # stage
    li s6, 10                   # total stages

.vector_stage_loop:
    li s7, 1 << (s5 + 1)        # block_size
    li s8, s7 >> 1              # half_block
    li s9, 0                    # group counter

.vector_group_loop:
    li s10, 0                   # butterfly counter

.vector_bfly_loop:
    # Calculate indices and twiddle factors
    sll t0, s9, (s5 + 1)       # base index
    add t1, t0, s8
    
    li t3, 512
    srl t3, t3, s5
    mul t2, s10, t3
    slli t2, t2, 2

    # Load twiddles
    la a0, twiddle_real
    la a1, twiddle_imag
    add a0, a0, t2
    add a1, a1, t2

    # Calculate data pointers
    slli t0, t0, 2
    slli t1, t1, 2
    add a2, s3, t0              # even_real
    add a3, s4, t0              # even_imag
    add a4, s3, t1              # odd_real
    add a5, s4, t1              # odd_imag

    call vector_complex_mul

    # Vector butterfly operations
    vsetvli t0, zero, e32, m4
    vle32.v v0, (a4)
    vle32.v v4, (a5)
    vle32.v v8, (a2)
    vle32.v v12, (a3)

    vadd.vv v16, v8, v0
    vadd.vv v20, v12, v4
    vsub.vv v24, v8, v0
    vsub.vv v28, v12, v4

    vse32.v v16, (a4)
    vse32.v v20, (a5)
    vse32.v v24, (a2)
    vse32.v v28, (a3)

    addi s10, s10, 1
    blt s10, s8, .vector_bfly_loop

    addi s9, s9, 1
    li t0, 1024
    srl t0, t0, (s5 + 1)
    blt s9, t0, .vector_group_loop

    addi s5, s5, 1
    blt s5, s6, .vector_stage_loop

    # Restore context
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

## --- Template Functions ---
printToLogVectorized:
    addi sp, sp, -4
    sw a0, 0(sp)

    li t0, 0x123                 # Debug pattern
    li t0, 0x456                 # Debug pattern
    mv a1, a1                    # Use linear size directly
    li t0, 0                     # Reset index

printloop:
    vsetvli t3, a1, e32          # Set vector length
    slli t4, t3, 2               # Calculate byte offset
    vle32.v v1, (a0)             # Load elements
    add a0, a0, t4               # Move pointer
    add t0, t0, t3               # Update index
    blt t0, a1, printloop        # Loop until all elements printed

    li t0, 0x123                 # Debug pattern
    li t0, 0x456                 # Debug pattern
    lw a0, 0(sp)
    addi sp, sp, 4
    jr ra

_finish:
    li x3, STDOUT
    addi x5, x0, 0xff
    sb x5, 0(x3)
    beq x0, x0, _finish

    .rept 100
    nop
    .endr

.section .rodata
.align 4
twiddle_real:
    .include "twiddle_real.s"
twiddle_imag:
    .include "twiddle_imag.s"

.section .data
.align 4
.equ fft_size, 1024
input_real:  .space 4096
input_imag:  .space 4096
output_real: .space 4096
output_imag: .space 4096
fft_size: .word fft_size

.section .stack
stack_bot: .space 4096
stack_top: