.section .text
    .global _start
    .option norvc

# RISC-V RV32 1024-Point Vectorized FFT Implementation
_start:
    la sp, stack_top

    # Stage 1: Bit-reverse permutation of input data
    la      a0, input_data
    la      a1, bitrev_output
    li      a2, 1024
    call    vector_bit_reverse

    # Save bit-reversed data for analysis
    la      a0, bitrev_filename
    la      a1, bitrev_output
    li      a2, 8192
    call    write_to_file

    # Stage 2: Execute 10-stage vectorized FFT
    la      a0, bitrev_output
    la      a1, fft_output
    li      a2, 1024
    call    vector_fft_stages

    # Save final FFT results
    la      a0, fft_filename
    la      a1, fft_output
    li      a2, 8192
    call    write_to_file

    # Output results to console
    la      a0, fft_output
    li      a1, 1024
    call    printToLogVectorized_interleaved

    # Signal completion
_finish:
    lui     x3, %hi(STDOUT_ADDR)
    addi    x3, x3, %lo(STDOUT_ADDR)
    li      x5, 0xff
    sb      x5, 0(x3)
    beq     x0, x0, _finish

# Bit-reverse permutation for FFT input reordering
# Arguments: a0=input_ptr, a1=output_ptr, a2=size
.globl vector_bit_reverse
vector_bit_reverse:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)

    mv s0, a0
    mv s1, a1
    mv s2, a2

    li t1, 0
bitrev_scalar_loop:
    beq t1, s2, bitrev_done
    
    # Perform 10-bit reversal for 1024-point FFT
    mv t2, t1
    li t3, 0
    li t4, 10
    
reverse_bits:
    beqz t4, reverse_done
    slli t3, t3, 1
    andi t5, t2, 1
    or t3, t3, t5
    srli t2, t2, 1
    addi t4, t4, -1
    j reverse_bits
    
reverse_done:
    # Load complex number from bit-reversed index
    slli t4, t3, 3
    add t4, s0, t4
    flw f0, 0(t4)
    flw f1, 4(t4)
    
    # Store to sequential output location
    slli t5, t1, 3
    add t5, s1, t5
    fsw f0, 0(t5)
    fsw f1, 4(t5)
    
    addi t1, t1, 1
    j bitrev_scalar_loop

bitrev_done:
    lw ra, 28(sp)
    lw s0, 24(sp)
    lw s1, 20(sp)
    lw s2, 16(sp)
    lw s3, 12(sp)
    addi sp, sp, 32
    ret

# Main FFT processing with format conversion wrapper
# Arguments: a0=input_ptr, a1=output_ptr, a2=size
.globl vector_fft_stages
vector_fft_stages:
    addi sp, sp, -64
    sw ra, 60(sp)
    sw s0, 56(sp)
    sw s1, 52(sp)
    sw s2, 48(sp)
    sw s3, 44(sp)
    sw s4, 40(sp)
    sw s5, 36(sp)
    sw s6, 32(sp)
    sw s7, 28(sp)
    sw s8, 24(sp)

    mv s0, a0
    mv s1, a1
    mv s2, a2

    # Allocate temporary planar arrays
    li t0, 4096
    sub sp, sp, t0
    mv s3, sp
    sub sp, sp, t0
    mv s4, sp

    # Convert interleaved input to planar format
    li t1, 0
convert_to_planar:
    beq t1, s2, planar_done
    
    slli t2, t1, 3
    add t3, s0, t2
    flw f0, 0(t3)
    flw f1, 4(t3)
    
    slli t2, t1, 2
    add t4, s3, t2
    add t5, s4, t2
    fsw f0, 0(t4)
    fsw f1, 0(t5)
    
    addi t1, t1, 1
    j convert_to_planar

planar_done:
    # Execute vectorized FFT computation
    mv a0, s3
    mv a1, s4
    mv a2, s2
    call vector_fft_core

    # Convert planar results back to interleaved format
    li t1, 0
convert_to_interleaved:
    beq t1, s2, interleaved_done
    
    slli t2, t1, 2
    add t4, s3, t2
    add t5, s4, t2
    flw f0, 0(t4)
    flw f1, 0(t5)
    
    slli t2, t1, 3
    add t3, s1, t2
    fsw f0, 0(t3)
    fsw f1, 4(t3)
    
    addi t1, t1, 1
    j convert_to_interleaved

interleaved_done:
    # Restore stack allocation
    li t0, 8192
    add sp, sp, t0

    lw ra, 60(sp)
    lw s0, 56(sp)
    lw s1, 52(sp)
    lw s2, 48(sp)
    lw s3, 44(sp)
    lw s4, 40(sp)
    lw s5, 36(sp)
    lw s6, 32(sp)
    lw s7, 28(sp)
    lw s8, 24(sp)
    addi sp, sp, 64
    ret

# Vectorized Cooley-Tukey FFT implementation
# Arguments: a0=real_array, a1=imag_array, a2=size
vector_fft_core:
    addi sp, sp, -64
    sw ra, 60(sp)
    sw s0, 56(sp)
    sw s1, 52(sp)
    sw s2, 48(sp)
    sw s3, 44(sp)
    sw s4, 40(sp)
    sw s5, 36(sp)
    sw s6, 32(sp)
    sw s7, 28(sp)
    sw s8, 24(sp)

    mv s0, a0
    mv s1, a1
    mv s2, a2
    li s3, 10

    # Execute 10 stages for 1024-point FFT
    li s4, 0
.vector_stage_loop:
    li t0, 1
    sll s5, t0, s4
    sll s6, s5, 1

    # Process all groups in current stage
    li s7, 0
.vector_group_loop:
    mul t0, s7, s6
    
    # Vectorized butterfly operations within group
    li s8, 0
.vector_butterfly_loop:
    sub t3, s5, s8
    beqz t3, .vector_butterfly_end
    
    # Set vector processing length
    vsetvli t4, t3, e32, m1
    
    # Generate butterfly index vectors
    vid.v v31
    vadd.vx v31, v31, s8
    
    # Calculate data element indices
    vadd.vx v30, v31, t0
    vadd.vx v29, v30, s5
    
    # Convert to memory byte offsets
    vsll.vi v30, v30, 2
    vsll.vi v29, v29, 2
    
    # Load twiddle factors using vectorized indexing
    la t5, twiddle_real
    la t6, twiddle_imag
    
    li t2, 512
    srl t2, t2, s4
    vmul.vx v28, v31, t2
    
    vsll.vi v28, v28, 2
    vluxei32.v v16, (t5), v28
    vluxei32.v v20, (t6), v28
    
    # Load data arrays using vectorized gather
    vluxei32.v v0, (s0), v30
    vluxei32.v v4, (s1), v30
    vluxei32.v v8, (s0), v29
    vluxei32.v v12, (s1), v29
    
    # Vectorized complex multiplication
    vfmul.vv v24, v16, v8
    vfnmsac.vv v24, v20, v12
    
    vfmul.vv v25, v16, v12
    vfmacc.vv v25, v20, v8
    
    # Vectorized butterfly computation
    vfadd.vv v1, v0, v24
    vfadd.vv v5, v4, v25
    
    vfsub.vv v9, v0, v24
    vfsub.vv v13, v4, v25
    
    # Store results using vectorized scatter
    vsuxei32.v v1, (s0), v30
    vsuxei32.v v5, (s1), v30
    vsuxei32.v v9, (s0), v29
    vsuxei32.v v13, (s1), v29
    
    add s8, s8, t4
    j .vector_butterfly_loop

.vector_butterfly_end:
    addi s7, s7, 1
    
    # Calculate number of groups for current stage
    addi t1, s4, 1
    srl t0, s2, t1
    blt s7, t0, .vector_group_loop

    addi s4, s4, 1
    blt s4, s3, .vector_stage_loop

    lw ra, 60(sp)
    lw s0, 56(sp)
    lw s1, 52(sp)
    lw s2, 48(sp)
    lw s3, 44(sp)
    lw s4, 40(sp)
    lw s5, 36(sp)
    lw s6, 32(sp)
    lw s7, 28(sp)
    lw s8, 24(sp)
    addi sp, sp, 64
    ret

# Output FFT results to console in interleaved format
printToLogVectorized_interleaved:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw a0, 8(sp)
    sw a1, 4(sp)

    lui t1, 0xd0580
    mv t2, t1
    mv t0, a0
    mv t3, a1

printloop_interleaved:
    beqz t3, print_done_interleaved
    
    lw t4, 0(t0)
    sw t4, 0(t1)
    addi t1, t1, 4
    
    lw t4, 4(t0)
    sw t4, 0(t1)
    addi t1, t1, 4
    
    addi t0, t0, 8
    addi t3, t3, -1
    j printloop_interleaved

print_done_interleaved:
    lw ra, 12(sp)
    lw a0, 8(sp)
    lw a1, 4(sp)
    addi sp, sp, 16
    ret

# System call interface implementations
.globl open
open:
    li a7, 1024
    ecall
    ret

.globl write  
write:
    li a7, 64
    ecall
    ret

.globl close
close:
    li a7, 57
    ecall
    ret

# File I/O utility for saving computation results
# Arguments: a0=filename, a1=buffer, a2=length
.globl write_to_file
write_to_file:
    addi    sp, sp, -16
    sw      ra,  0(sp)
    sw      s0,  4(sp)
    sw      s1,  8(sp)
    sw      s2, 12(sp)

    mv      s1, a1
    mv      s2, a2

    li      a1, 0x601
    li      a2, 0x1B6
    call    open
    mv      s0, a0

    mv      a0, s0
    mv      a1, s1
    mv      a2, s2
    call    write

    mv      a0, s0
    call    close

    lw      s2, 12(sp)
    lw      s1,  8(sp)
    lw      s0,  4(sp)
    lw      ra,  0(sp)
    addi    sp, sp, 16
    ret

# Data allocation and external references
.section .data
.align 2
bitrev_output:
    .space 8192

.align 2  
fft_output:
    .space 8192

.align 2
 bitrev_filename:
   .string "bitreversalout.hex"
.align 2
fft_filename:
    .string "finalout.hex"

.equ STDOUT_ADDR, 0xd0580000

# External data includes
.section .rodata
.align 6
.include "./assembly/twiddle_factors.s"   

.align 2
.include "./assembly/input_data.s"

.section .stack
.align 4
stack_bot: .space 8192
stack_top:
