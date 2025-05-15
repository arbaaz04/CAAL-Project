# VEER ISS Compatible FFT Implementation
# Uses pre-computed twiddle factors from twiddle_real.s and twiddle_imag.s

# Memory-mapped IO addresses
.equ STDOUT, 0xd0580000

.section .text
.global _start

_start:
    # Run the FFT test
    call test_1024point_fixed
    
    # Write to to_host to finish simulation
    li x3, STDOUT
    li x5, 0xff
    sb x5, 0(x3)
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

# Print a string to STDOUT (VEER ISS compatible)
print_string:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    
    mv s0, a0          # Save string address
    
.print_loop:
    lb a1, 0(s0)       # Load byte from string
    beqz a1, .print_done  # If null terminator, we're done
    
    li a0, STDOUT      # STDOUT address
    sb a1, 0(a0)       # Output character
    
    addi s0, s0, 1     # Move to next character
    j .print_loop
    
.print_done:
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# Print hex value to STDOUT
print_hex:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    
    mv s0, a0          # Save value to print
    li s1, 8           # Counter for 8 hex digits
    
.print_hex_loop:
    addi s1, s1, -1    # Decrement counter
    
    # Extract current hex digit
    srl s2, s0, 28     # Extract top 4 bits
    
    # Convert to ASCII
    li a0, 48          # '0'
    add a0, a0, s2
    
    # If digit >= 10, convert to A-F
    li a1, 58          # '9' + 1
    blt a0, a1, .print_digit
    addi a0, a0, 7     # Adjust for A-F (57 + 8 = 65 = 'A')
    
.print_digit:
    # Print the digit
    li a1, STDOUT
    sb a0, 0(a1)
    
    # Shift for next digit
    slli s0, s0, 4
    
    # Continue if more digits
    bnez s1, .print_hex_loop
    
    # Print newline
    li a0, 10
    li a1, STDOUT
    sb a0, 0(a1)
    
    lw s2, 16(sp)
    lw s1, 20(sp)
    lw s0, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
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
    mv      a1, s3
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
    # Size not power of 2, print error and exit
    la      a0, msg_size_error
    call    print_string
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
    div     a5, s4, a5
    # Changed to use twiddle_real and twiddle_imag directly
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

# Test function to generate input and run FFT
test_1024point_fixed:
    addi    sp, sp, -48
    sw      ra, 44(sp)
    sw      s0, 40(sp)
    sw      s1, 36(sp)
    sw      s2, 32(sp)
    sw      s3, 28(sp)
    sw      s4, 24(sp)
    sw      s5, 20(sp)
    sw      s6, 16(sp)
    sw      s7, 12(sp)
    sw      s8, 8(sp)
    sw      s9, 4(sp)
    
    # Use static arrays instead of malloc
    la      s0, input_real
    la      s1, input_imag
    la      s2, output_real
    la      s3, output_imag
    
    # Initialize input signal with proper Q16.16 values
    li      s4, 0                # counter
    li      s5, 1024             # size
    
.gen_input_loop:
    # Instead of using index, use a proper Q16.16 signal
    # For simplicity, we'll use a fixed value (1.0 in Q16.16 = 0x00010000)
    # For first element, and 0 for others to create an impulse
    beqz    s4, .set_impulse
    sw      zero, 0(s0)          # input_real[i] = 0 
    j       .set_imag
    
.set_impulse:
    li      t0, 0x00010000       # 1.0 in Q16.16
    sw      t0, 0(s0)            # input_real[0] = 1.0
    
.set_imag:
    sw      zero, 0(s1)          # input_imag[i] = 0
    
    addi    s0, s0, 4
    addi    s1, s1, 4
    addi    s4, s4, 1
    bne     s4, s5, .gen_input_loop
    
    # Print message about FFT computation
    la      a0, msg_computing_fft
    call    print_string
    
    # Run the FFT
    la      a0, input_real
    la      a1, input_imag
    li      a2, 1024
    la      a3, output_real
    la      a4, output_imag
        call    fft_fixed_point
    
    # Add detection pattern as in the working Vectorized.s file
    addi sp, sp, -4
    sw a0, 0(sp)

    li t0, 0x123       # Pattern for help in python script
    li t0, 0x456       # Pattern for help in python script
    mv a1, a1          # moving size to get it from log 
    
    # Print results header
    la      a0, msg_results
    call    print_string
    
    # Print first 8 results
    la      s0, output_real
    la      s1, output_imag
    li      s2, 0           # counter
    li      s3, 8           # limit
    
.print_results_loop:
    # Print index
    mv      a0, s2
    call    print_hex
    
    # Print real value
    lw      a0, 0(s0)
    call    print_hex
    
    # Print imag value
    lw      a0, 0(s1)
    call    print_hex
    
    addi    s0, s0, 4
    addi    s1, s1, 4
    addi    s2, s2, 1
    bne     s2, s3, .print_results_loop
    
    # Print FFT complete message
    la      a0, msg_complete
    call    print_string
    
    # Add the second detection pattern as in working file
    li t0, 0x123       # Pattern for help in python script
    li t0, 0x456       # Pattern for help in python script
	
    lw a0, 0(sp)
    addi sp, sp, 4

    lw      ra, 44(sp)
    lw      s0, 40(sp)
    lw      s1, 36(sp)
    lw      s2, 32(sp)
    lw      s3, 28(sp)
    lw      s4, 24(sp)
    lw      s5, 20(sp)
    lw      s6, 16(sp)
    lw      s7, 12(sp)
    lw      s8, 8(sp)
    lw      s9, 4(sp)
    addi    sp, sp, 48
    jr      ra

_finish:
    li x3, STDOUT
    li x5, 0xff
    sb x5, 0(x3)
    j _finish

# ======================================
# Data Section
# ======================================
.section .data
# Messages
msg_computing_fft:
    .string "Computing 1024-point FFT...\n"
msg_results:
    .string "FFT Results (first 8 bins):\nIndex  Real      Imag\n"
msg_complete:
    .string "FFT computation complete.\n"
msg_size_error:
    .string "Size of input must be a power of 2\n"

# Static arrays for FFT
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
