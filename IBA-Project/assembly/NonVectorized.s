#define STDOUT 0xd0580000

.section .text
.global _start
_start:
    # Initialize stack pointer properly
    la sp, STACK

## START YOUR CODE HERE

# Initialize input array (impulse signal)
la s0, input_real
la s1, input_imag
li s4, 0                # counter
li s5, 1024             # size
    
init_input_loop:
    # For first element use 1.0, others 0 (impulse)
    beqz s4, set_impulse
    sw zero, 0(s0)      # input_real[i] = 0 
    j set_imag
    
set_impulse:
    li t0, 0x00010000   # 1.0 in Q16.16 fixed point
    sw t0, 0(s0)        # input_real[0] = 1.0
    
set_imag:
    sw zero, 0(s1)      # input_imag[i] = 0
    
    addi s0, s0, 4
    addi s1, s1, 4
    addi s4, s4, 1
    bne s4, s5, init_input_loop

# Run the FFT
la a0, input_real
la a1, input_imag
li a2, 1024
la a3, output_real
la a4, output_imag
call fft_fixed_point
    
# Print the first 8 real parts of the FFT result
la a0, output_real
li a1, 8
call printToLog

# Print the first 8 imaginary parts of the FFT result 
la a0, output_imag
li a1, 8
call printToLog

j _finish

# Fixed-point multiplication for Q16.16 format
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

# Complex multiplication with Q16.16 values
fixed_complex_multiply:
    addi    sp, sp, -16
    srai    t3, a0, 31
    srai    t4, a2, 31
    srai    a4, a1, 31
    srai    a5, a3, 31
    mul     a6, t3, a2
    mul     a7, t4, a0
    add     a6, a6, a7
    mul     t1, a0, a2
    mulhu   a7, a0, a2
    add     a6, a6, a7
    slli    a6, a6, 16
    srli    t1, t1, 16
    or      t1, a6, t1
    mul     a6, a4, a3
    mul     a7, a5, a1
    add     a6, a6, a7
    mul     a7, a1, a3
    mulhu   t5, a1, a3
    add     a6, a6, t5
    slli    a6, a6, 16
    srli    a7, a7, 16
    or      a7, a6, a7
    mul     a4, a4, a2
    mul     t4, t4, a1
    add     a4, a4, t4
    mul     a6, a1, a2
    mulhu   a1, a1, a2
    add     a4, a4, a1
    slli    a4, a4, 16
    srli    a1, a6, 16
    or      a1, a4, a1
    mul     a5, a5, a0
    mul     t3, t3, a3
    add     a5, a5, t3
    mul     a4, a3, a0
    mulhu   a3, a3, a0
    add     a3, a5, a3
    slli    a3, a3, 16
    srli    a4, a4, 16
    or      a4, a3, a4
    sub     a0, t1, a7
    add     a1, a1, a4
    addi    sp, sp, 16
    ret

# Modified generate_twiddle_factors to use pre-computed tables
generate_twiddle_factors:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    
    # Return pointer to pre-computed table
    la      a0, twiddle_real
    
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

# Function to bit-reverse an integer
bit_reverse:
    mv      a5, a0
    ble     a1, zero, .L17
    li      a4, 0
    li      a0, 0
.L16:
    slli    a0, a0, 1
    andi    a3, a5, 1
    or      a0, a3, a0
    srai    a5, a5, 1
    addi    a4, a4, 1
    bne     a1, a4, .L16
    ret
.L17:
    li      a0, 0
    ret

# Core FFT implementation
fft_fixed_point:
    addi    sp, sp, -128
    sw      ra, 124(sp)
    sw      s0, 120(sp)
    sw      s1, 116(sp)
    sw      s2, 112(sp)
    sw      s3, 108(sp)
    sw      s4, 104(sp)
    sw      s5, 100(sp)
    sw      s6, 96(sp)
    sw      s7, 92(sp)
    sw      s8, 88(sp)
    sw      s9, 84(sp)
    sw      s10, 80(sp)
    sw      s11, 76(sp)
    sw      a2, 12(sp)
    mv      s10, a4
    addi    a5, a2, -1
    and     s3, a5, a2
    sw      s3, 40(sp)
    bne     s3, zero, .L20
    mv      s1, a0
    mv      s2, a1
    mv      s9, a3
    li      a3, 1
    mv      a5, a2
    li      a4, 1
    ble     a2, a3, .L44
.L21:
    addi    s3, s3, 1
    srai    a5, a5, 1
    bgt     a5, a4, .L21
    lw      a0, 12(sp)
    call    generate_twiddle_factors
    sw      a0, 20(sp)
    # Store the address of twiddle_imag
    la      a0, twiddle_imag
    sw      a0, 24(sp)
.L32:
    lw      s0, 40(sp)
.L25:
    # FIX: Use a constant 10 for bit-reverse with 1024-point FFT
    li      a1, 10       # 10 bits for 1024-point FFT
    mv      a0, s0
    call    bit_reverse
    slli    a5, a0, 2
    lw      a3, 0(s1)
    add     a4, s9, a5
    sw      a3, 0(a4)
    lw      a4, 0(s2)
    add     a5, s10, a5
    sw      a4, 0(a5)
    addi    s0, s0, 1
    addi    s1, s1, 4
    addi    s2, s2, 4
    lw      a5, 12(sp)
    bgt     a5, s0, .L25
    ble     s3, zero, .L24
    addi    a5, s3, 1
    sw      a5, 44(sp)
    li      a5, 1
    sw      a5, 36(sp)
    j       .L31
.L20:
    # Simplified error handling - just jump to finish
    j       _finish
.L44:
    lw      s0, 12(sp)
    mv      a0, s0
    call    generate_twiddle_factors
    sw      a0, 20(sp)
    # Store the address of twiddle_imag
    la      a0, twiddle_imag
    sw      a0, 24(sp)
    li      a5, 1
    beq     s0, a5, .L45
.L24:
    lw      ra, 124(sp)
    lw      s0, 120(sp)
    lw      s1, 116(sp)
    lw      s2, 112(sp)
    lw      s3, 108(sp)
    lw      s4, 104(sp)
    lw      s5, 100(sp)
    lw      s6, 96(sp)
    lw      s7, 92(sp)
    lw      s8, 88(sp)
    lw      s9, 84(sp)
    lw      s10, 80(sp)
    lw      s11, 76(sp)
    addi    sp, sp, 128
    jr      ra
.L45:
    lw      s3, 40(sp)
    j       .L32
.L28:
    lw      a5, 16(sp)
    # Replace div with shift operations for power-of-2 division
    # Instead of: div a5, s4, a5
    srai    a5, s4, 0    # Start with no shift
    lw      t3, 16(sp)   # Load the divisor
    li      t4, 2
    beq     t3, t4, .L28_div2
    li      t4, 4
    beq     t3, t4, .L28_div4
    li      t4, 8
    beq     t3, t4, .L28_div8
    li      t4, 16
    beq     t3, t4, .L28_div16
    li      t4, 32
    beq     t3, t4, .L28_div32
    li      t4, 64
    beq     t3, t4, .L28_div64
    li      t4, 128
    beq     t3, t4, .L28_div128
    li      t4, 256
    beq     t3, t4, .L28_div256
    li      t4, 512
    beq     t3, t4, .L28_div512
    j       .L28_cont    # Default case
.L28_div2:
    srai    a5, s4, 1
    j       .L28_cont
.L28_div4:
    srai    a5, s4, 2
    j       .L28_cont
.L28_div8:
    srai    a5, s4, 3
    j       .L28_cont
.L28_div16:
    srai    a5, s4, 4
    j       .L28_cont
.L28_div32:
    srai    a5, s4, 5
    j       .L28_cont
.L28_div64:
    srai    a5, s4, 6
    j       .L28_cont
.L28_div128:
    srai    a5, s4, 7
    j       .L28_cont
.L28_div256:
    srai    a5, s4, 8
    j       .L28_cont
.L28_div512:
    srai    a5, s4, 9
    j       .L28_cont

.L28_cont:
    # Continue with original code
    slli    a5, a5, 2  # Multiply by 4 instead of 8 since we have separate tables
    lw      a4, 20(sp) # twiddle_real pointer
    lw      t6, 24(sp) # twiddle_imag pointer
    add     t0, a4, a5  # Address of real part
    add     t1, t6, a5  # Address of imag part
    add     s8, s9, s0
    lw      s2, 0(s8)
    add     s7, s10, s0
    lw      s1, 0(s7)
    add     s6, s9, s3
    add     s5, s10, s3
    lw      a3, 0(t1)  # Load imag part from twiddle_imag
    lw      a2, 0(t0)  # Load real part from twiddle_real
    lw      a1, 0(s5)
    lw      a0, 0(s6)
    call    fixed_complex_multiply
    sw      a0, 56(sp)
    sw      a1, 60(sp)
    add     a3, a0, s2
    sw      a3, 0(s8)
    add     a3, a1, s1
    sw      a3, 0(s7)
    sub     s2, s2, a0
    sw      s2, 0(s6)
    sub     s1, s1, a1
    sw      s1, 0(s5)
    lw      a5, 12(sp)
    add     s4, s4, a5
    addi    s0, s0, 4
    addi    s3, s3, 4
    bne     s0, s11, .L28
.L30:
    lw      a5, 24(sp)
    lw      a4, 16(sp)
    add     a5, a5, a4
    sw      a5, 24(sp)
    lw      a4, 32(sp)
    add     s11, s11, a4
    lw      a4, 12(sp)
    ble     a4, a5, .L26
.L27:
    lw      a5, 24(sp)
    slli    s0, a5, 2
    mv      s3, s11
    li      s4, 0
    lw      a5, 28(sp)
    bgt     a5, zero, .L28
    j       .L30
.L26:
    lw      a5, 36(sp)
    addi    a5, a5, 1
    sw      a5, 36(sp)
    lw      a4, 44(sp)
    beq     a5, a4, .L24
.L31:
    li      a5, 1
    lw      a4, 36(sp)
    sll     a5, a5, a4
    sw      a5, 16(sp)
    srai    a5, a5, 1
    sw      a5, 28(sp)
    lw      a3, 12(sp)
    ble     a3, zero, .L26
    li      a3, 4
    sll     a4, a3, a4
    sw      a4, 32(sp)
    slli    s11, a5, 2
    lw      a5, 40(sp)
    sw      a5, 24(sp)
    j       .L27

## END YOU CODE HERE

# Function to print values for log
# This function correctly uses flw to ensure values appear in logs
# Input:
#   a0: Base address of the array
#   a1: Size to print
printToLog:
    li t0, 0x123                #  Identifiers used for python script to read logs
    li t0, 0x456
    mv a1, a1                   # moving size to get it from log 
    mv t0, a0                   # Copy the base address of the array to t0
    mul t1, a1, a1              # size^2 (or just size for 1D array)
    slli  t1, t1, 2             # size * 4 (total size in bytes)
    add t1, a0, t1              # Calculate the end address

    printMatrixLoop:
        bge t0, t1, printMatrixLoopEnd 
        # Use lw to load integers, but force to float register for log visibility
        lw t2, 0(t0)            # Load fixed-point value
        # Convert to float register (only for logging)
        fmv.s.x ft0, t2
        addi t0, t0, 4          # Increment address
        j printMatrixLoop
    printMatrixLoopEnd:

    li t0, 0x123                #  Identifiers used for python script to read logs
    li t0, 0x456

    jr ra


# Function: _finish
# VeeR Related function which writes to to_host which stops the simulator
_finish:
    li x3, 0xd0580000
    addi x5, x0, 0xff
    sb x5, 0(x3)
    beq x0, x0, _finish

    .rept 100
        nop
    .endr


.data
## ALL DATA IS DEFINED HERE LIKE MATRIX, CONSTANTS ETC

## DATA DEFINE START
# Keeping the original matrix for reference
.equ MatrixSize, 5
matrix:
    .float -10.0, 13.0, 10.0, -3.0, 2.0
    .float 6.0, 15.0, 4.0, 13.0, 4.0
    .float 18.0, 2.0, 9.0, 8.0, -4.0
    .float 5.0, 4.0, 12.0, 17.0, 6.0
    .float -10.0, 7.0, 13.0, -3.0, 16.0

size: .word MatrixSize
## DATA DEFINE END

# FFT data structures (using .bss for uninitialized data)
.section .bss
.align 4
input_real:
    .space 4096     # 1024 * 4 bytes for real input
input_imag:
    .space 4096     # 1024 * 4 bytes for imag input
output_real:
    .space 4096     # 1024 * 4 bytes for real output
output_imag:
    .space 4096     # 1024 * 4 bytes for imag output

# Include twiddle factor tables
.section .rodata
.include "./assembly/twiddle_real.s"
.include "./assembly/twiddle_imag.s"