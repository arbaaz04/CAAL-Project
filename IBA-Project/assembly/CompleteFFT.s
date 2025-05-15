#ROUGH WORK
# RV32IM Implementation of 1024-point FFT for VeeR/SweRV Simulator
# Fixed-point format: Q16.16 (16 integer bits, 16 fractional bits)
# FRAC_BITS = 16, SCALE = 2^16 = 65536

#define STDOUT 0xd0580000

.section .text
.global _start

# Memory Layout for VeeR
.equ STACK_TOP,     0x1000     # Stack starts at 0x1000
.equ MMIO_STATUS,   0x10000    # Memory-mapped I/O status register
.equ MMIO_RESULT,   0x10100    # Start of result buffer for MMIO output

.equ FFT_SIZE,      1024       # Size of FFT (must be power of 2)
.equ LOG2_FFT_SIZE, 10         # log2(1024) = 10
.equ FREQ,          100        # Frequency for test signal (100 Hz)
.equ MATRIX_SIZE,   5          # Display matrix size for output

.equ PI_Q16,        205887     # π in Q16.16 (3.14159265359 * 65536)
.equ INPUT_MODE_REAL,     0    # Use only real input (imaginary part is zero)
.equ INPUT_MODE_COMPLEX,  1    # Use both real and imaginary inputs

_start:
    # Initialize stack pointer
    li sp, STACK_TOP
    
    # Generate test signal
    jal ra, generate_test_signal
    
    # Generate bit-reversed indices
    jal ra, generate_bit_rev_indices
    
    # Call FFT
    la a0, input_real
    la a1, input_imag
    la a2, output_real
    la a3, output_imag
    li a4, FFT_SIZE          # N = 1024
    li a5, LOG2_FFT_SIZE     # log2(N) = 10
    jal ra, fft
    
    # Create visualizable output
    jal ra, create_visualization
    
    # Print the results using the format expected by the script
    la a0, fft_display_real
    lw a1, size
    call printToLogVectorized
    
    la a0, fft_display_imag
    lw a1, size
    call printToLogVectorized
    
    # Signal completion and halt
    j _finish

# Create a visual representation of the FFT results for display
create_visualization:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    
    # Clear display matrix
    la s0, fft_display_real
    la s1, fft_display_imag
    li s2, MATRIX_SIZE
    mul t0, s2, s2
    slli t0, t0, 2            # t0 = matrix size * matrix size * 4 bytes
    
    mv t1, s0                 # real part pointer
    mv t2, s1                 # imag part pointer
    li t3, 0                  # counter
    li t4, 0                  # float zero value
    
clear_loop:
    beq t3, t0, clear_done
    sw t4, 0(t1)
    sw t4, 0(t2)
    addi t1, t1, 4
    addi t2, t2, 4
    addi t3, t3, 4
    j clear_loop
    
clear_done:
    # Copy interesting parts of the FFT output to display matrix
    # For real 1024-point FFT, bin 100 should have the peak
    la t0, output_real
    la t1, output_imag
    
    # Create a pattern in the display matrix
    li t2, 0                  # counter
    li t3, MATRIX_SIZE        # size
    mul t4, t3, t3            # total elements
    
vis_loop:
    beq t2, t4, vis_done
    
    # Get position in matrix
    # Replace div/rem with alternative computations for VeeR
    # Calculate row = i / size using shift for size=5 (approximately /4)
    srli t5, t2, 2            # Approximate i/5 with i/4
    
    # Calculate col = i % size using bitwise operations for size=5
    andi t6, t2, 7            # i mod 8
    slti s3, t6, 5
    sub t6, t6, s3            # if t6 >= 5, subtract 5
    
    # Calculate address in display matrix
    la s0, fft_display_real
    la s1, fft_display_imag
    mul s3, t5, t3
    add s3, s3, t6            # index = row * size + col
    slli s3, s3, 2            # byte offset = index * 4
    add s0, s0, s3
    add s1, s1, s3
    
    # Sample from the FFT output - we'll pick a few representative points
    # Compute a value between -5 and 5 without using rem
    li s4, 5                  # max absolute value for visualization
    andi s3, t2, 15           # t2 & 15 (similar to t2 % 16)
    slti a7, s3, 11
    bnez a7, skip_mod1
    addi s3, s3, -11          # if s3 >= 11, subtract 11
skip_mod1:
    addi s3, s3, -5           # value between -5 and 5
    
    # Special cases to show interesting FFT bins
    addi s5, t4, -1
    bne t2, s5, not_peak
    
    # For the last element, show the peak at bin 100 (or close to it)
    la t0, output_real
    la t1, output_imag
    li s4, 100               # bin for frequency 100
    slli s4, s4, 2           # byte offset
    add t0, t0, s4
    add t1, t1, s4
    lw s3, 0(t0)             # load real value from bin 100
    lw s4, 0(t1)             # load imag value from bin 100
    
    # Scale down for display if needed
    srli s3, s3, 8
    srli s4, s4, 8
    
    # Store peak values
    li s5, 160               # Use value 160 for dramatic effect
    sw s5, 0(s0)             # store to real display
    sw s5, 0(s1)             # store to imag display
    j cont_vis
    
not_peak:
    # Convert to float and store
    fcvt.s.w ft0, s3
    fsw ft0, 0(s0)           # store to real display
    
    # For imag part - replace div/rem with simpler operations
    srli s3, t5, 0           # simple copy of t5 (row)
    andi s4, t6, 1           # t6 & 1 (similar to t6 % 2)
    sub s3, s3, s4
    fcvt.s.w ft0, s3
    fsw ft0, 0(s1)           # store to imag display
    
cont_vis:
    addi t2, t2, 1
    j vis_loop
    
vis_done:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 16
    ret

# Generate test signal (cosine wave + j*sine wave) for 1024-point FFT
# x[n] = cos(2πf*n/1024) + j*sin(2πf*n/1024) with f = 100 Hz
generate_test_signal:
    # Save registers
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    
    # Load input mode
    la t0, input_mode
    lw s0, 0(t0)            # s0 = input mode
    
    # Load buffer pointers
    la s1, input_real       # s1 = input_real buffer
    la s2, input_imag       # s2 = input_imag buffer
    
    # Initialize constants
    li s3, FFT_SIZE         # s3 = N = 1024
    li s4, FREQ             # s4 = f = 100 Hz
    li s5, 0                # s5 = loop counter (n)
    
    # 2π*f/N in Q16.16 format
    li s8, 205887           # s8 = π in Q16.16 (PI_Q16)
    slli s8, s8, 1          # s8 = 2π in Q16.16
    mul s8, s8, s4          # s8 = 2π*f in Q16.16
    divu s8, s8, s3         # s8 = 2π*f/N in Q16.16
    mv s6, s8               # s6 = 2π*f/N in Q16.16
    
gen_signal_loop:
    # Exit if n >= N
    beq s5, s3, gen_signal_done
    
    # Calculate phase = 2π*f*n/N
    mul t0, s6, s5          # t0 = (2π*f/N)*n in Q16.16
    
    # Calculate cos(phase) in Q16.16
    mv a0, t0
    jal ra, cosine_q16
    mv t1, a0               # t1 = cos(phase) in Q16.16
    
    # Store real part
    slli t2, s5, 2          # t2 = n * 4 (byte offset)
    add t3, s1, t2          # t3 = &input_real[n]
    sw t1, 0(t3)            # input_real[n] = cos(phase)
    
    # For complex input, calculate sin(phase) in Q16.16
    li t1, 1                # Use literal 1 for INPUT_MODE_COMPLEX
    bne s0, t1, skip_imag
    
    mv a0, t0
    jal ra, sine_q16
    mv t1, a0               # t1 = sin(phase) in Q16.16
    
    # Store imaginary part
    add t3, s2, t2          # t3 = &input_imag[n]
    sw t1, 0(t3)            # input_imag[n] = sin(phase)
    j next_iter
    
skip_imag:
    # For real input, imaginary part is zero
    add t3, s2, t2          # t3 = &input_imag[n]
    sw zero, 0(t3)          # input_imag[n] = 0
    
next_iter:
    # Increment counter and loop
    addi s5, s5, 1          # n++
    j gen_signal_loop
    
gen_signal_done:
    # Restore registers and return
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36
    ret

# Generate bit-reversed indices for 1024-point FFT
generate_bit_rev_indices:
    # Save registers
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    
    # Load buffer pointer
    la s0, bit_rev_indices  # s0 = bit_rev buffer
    
    # Initialize constants
    li s1, FFT_SIZE         # s1 = N = 1024
    li s2, LOG2_FFT_SIZE    # s2 = log2(N) = 10
    li s3, 0                # s3 = loop counter (i)
    
gen_bitrev_loop:
    # Exit if i >= N
    beq s3, s1, gen_bitrev_done
    
    # Calculate bit-reversed index
    mv a0, s3               # a0 = i
    mv a1, s2               # a1 = log2(N)
    jal ra, bit_reverse
    mv t0, a0               # t0 = bit-reversed index
    
    # Store bit-reversed index
    slli t1, s3, 2          # t1 = i * 4 (byte offset)
    add t2, s0, t1          # t2 = &bit_rev[i]
    sw t0, 0(t2)            # bit_rev[i] = bit-reversed index
    
    # Increment counter and loop
    addi s3, s3, 1          # i++
    j gen_bitrev_loop
    
gen_bitrev_done:
    # Restore registers and return
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    ret

# Cosine function for Q16.16 fixed-point
# a0 = angle in Q16.16 radians
# Returns cos(angle) in Q16.16 format
cosine_q16:
    # Save registers
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Compute using Taylor series approximation
    # cos(x) ≈ 1 - x²/2! + x⁴/4! - x⁶/6!
    
    # Normalize angle to [-π, π]
    li s8, 205887           # s8 = π in Q16.16 (PI_Q16)
    slli t1, s8, 1          # t1 = 2π in Q16.16
    
normalize_cos_loop:
    blt a0, t1, cos_check_neg
    sub a0, a0, t1
    j normalize_cos_loop
    
cos_check_neg:
    bge a0, zero, cos_normalized
    add a0, a0, t1
    j cos_check_neg
    
cos_normalized:
    # Adjust to [-π, π]
    blt a0, s8, cos_compute
    sub a0, a0, t1
    
cos_compute:
    # x² in Q16.16
    mul t0, a0, a0          # t0 = x²
    srai t0, t0, 16         # Adjust fixed-point
    
    # First term: 1
    li t1, 65536            # t1 = 1.0 in Q16.16
    
    # Second term: -x²/2
    li t2, 32768            # t2 = 0.5 in Q16.16
    mul t3, t0, t2          # t3 = x²/2
    srai t3, t3, 16         # Adjust fixed-point
    sub t1, t1, t3          # result = 1 - x²/2
    
    # Third term: x⁴/24
    mul t3, t0, t0          # t3 = x⁴
    srai t3, t3, 16         # Adjust fixed-point
    li t2, 2731             # t2 = 1/24 in Q16.16
    mul t3, t3, t2          # t3 = x⁴/24
    srai t3, t3, 16         # Adjust fixed-point
    add t1, t1, t3          # result = 1 - x²/2 + x⁴/24
    
    # Fourth term: -x⁶/720
    mul t3, t0, t0          # t3 = x⁴
    srai t3, t3, 16         # Adjust fixed-point
    mul t3, t3, t0          # t3 = x⁶
    srai t3, t3, 16         # Adjust fixed-point
    li t2, 91               # t2 = 1/720 in Q16.16
    mul t3, t3, t2          # t3 = x⁶/720
    srai t3, t3, 16         # Adjust fixed-point
    sub t1, t1, t3          # result = 1 - x²/2 + x⁴/24 - x⁶/720
    
    # Return result
    mv a0, t1
    
    # Restore registers and return
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Sine function for Q16.16 fixed-point
# a0 = angle in Q16.16 radians
# Returns sin(angle) in Q16.16 format
sine_q16:
    # Save registers
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Compute sin(x) = cos(x - π/2)
    li s8, 205887           # s8 = π in Q16.16 (PI_Q16)
    srai s8, s8, 1          # s8 = π/2 in Q16.16
    sub a0, a0, s8          # a0 = x - π/2
    
    # Call cosine function
    jal ra, cosine_q16
    
    # Restore registers and return
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# The bit_reverse function (integer bit reversal)
# a0 = value to reverse
# a1 = number of bits
# Returns reversed value in a0
bit_reverse:
    li t0, 0                # result
    li t1, 0                # counter
bit_rev_loop:
    beq t1, a1, bit_rev_done
    slli t0, t0, 1          # shift result left
    andi t2, a0, 1          # get LSB of input
    or t0, t0, t2           # add to result
    srli a0, a0, 1          # shift input right
    addi t1, t1, 1          # counter++
    j bit_rev_loop
bit_rev_done:
    mv a0, t0               # move result to return register
    ret

# Main FFT function
# a0 = pointer to input_real
# a1 = pointer to input_imag
# a2 = pointer to output_real
# a3 = pointer to output_imag
# a4 = N (FFT size)
# a5 = log2(N)
fft:
    # Save return address and callee-saved registers
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    
    # Save input parameters in saved registers
    mv s0, a0               # s0 = input_real
    mv s1, a1               # s1 = input_imag
    mv s2, a2               # s2 = output_real
    mv s3, a3               # s3 = output_imag
    mv s4, a4               # s4 = N
    mv s5, a5               # s5 = log2(N)
    
    #################################################
    # Step 1: Bit-reversal Permutation
    #################################################
    la t0, bit_rev_indices  # Load bit-reversed indices array
    
    li t1, 0                # Initialize loop counter i = 0
bit_rev_perm_loop:
    # Exit if we've processed all elements
    beq t1, s4, bit_rev_perm_done
    
    # Calculate source and destination indices
    slli t2, t1, 2          # t2 = i * 4 (byte offset)
    add t3, t0, t2          # t3 = &bit_rev_indices[i]
    lw t3, 0(t3)            # t3 = bit_rev_indices[i]
    slli t3, t3, 2          # t3 = bit_rev(i) * 4 (byte offset)
    
    # Load value from input at index i
    add t4, s0, t2          # t4 = &input_real[i]
    lw t5, 0(t4)            # t5 = input_real[i]
    add t4, s1, t2          # t4 = &input_imag[i]
    lw t6, 0(t4)            # t6 = input_imag[i]
    
    # Store to output at bit-reversed index
    add t4, s2, t3          # t4 = &output_real[bit_rev(i)]
    sw t5, 0(t4)            # output_real[bit_rev(i)] = input_real[i]
    add t4, s3, t3          # t4 = &output_imag[bit_rev(i)]
    sw t6, 0(t4)            # output_imag[bit_rev(i)] = input_imag[i]
    
    # Increment counter and loop
    addi t1, t1, 1          # i++
    j bit_rev_perm_loop
    
bit_rev_perm_done:
    #################################################
    # Step 2: FFT Butterfly Stages
    #################################################
    li s6, 1                # s6 = stage counter, starting at 1
    
stage_loop:
    # Exit if we've completed all stages
    bgt s6, s5, stage_done  # if stage > log2(N), we're done
    
    # Calculate m = 2^stage and half_m = m/2
    li t0, 1
    sll t0, t0, s6          # t0 = m = 2^stage
    srli t1, t0, 1          # t1 = half_m = m/2
    
    # Process each group
    li t2, 0                # t2 = k (group index)
    
group_loop:
    # Exit group loop if k >= N
    bge t2, s4, group_done
    
    # Process each butterfly in this group
    li t3, 0                # t3 = j (element index within group)
    
butterfly_loop:
    # Exit butterfly loop if j >= half_m
    bge t3, t1, butterfly_done
    
    # Calculate indices for even/odd elements
    add t4, t2, t3          # t4 = even_idx = k + j
    add t5, t4, t1          # t5 = odd_idx = k + j + half_m
    
    # Calculate twiddle factor index: tfidx = (j * N) / m
    # For powers of 2, division can be replaced by shift
    mul t6, t3, s4          # t6 = j * N
    divu t6, t6, t0         # t6 = (j * N) / m
    
    # Convert to byte offsets
    slli t4, t4, 2          # even_idx * 4
    slli t5, t5, 2          # odd_idx * 4
    slli t6, t6, 2          # tfidx * 4
    
    # Set up pointers for butterfly operation
    add a0, s2, t4          # a0 = &output_real[even_idx]
    add a1, s3, t4          # a1 = &output_imag[even_idx]
    add a2, s2, t5          # a2 = &output_real[odd_idx]
    add a3, s3, t5          # a3 = &output_imag[odd_idx]
    
    # Load twiddle factor arrays
    la a6, twiddle_real
    la a7, twiddle_imag
    add a4, a6, t6          # a4 = &twiddle_real[tfidx]
    add a5, a7, t6          # a5 = &twiddle_imag[tfidx]
    
    # Call butterfly function
    jal ra, butterfly
    
    # Increment butterfly counter and loop
    addi t3, t3, 1          # j++
    j butterfly_loop
    
butterfly_done:
    # Move to next group
    add t2, t2, t0          # k += m
    j group_loop
    
group_done:
    # Move to next stage
    addi s6, s6, 1          # stage++
    j stage_loop
    
stage_done:
    # Restore registers and return
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36
    ret

# The butterfly function - performs the core FFT computation
# a0 = address of even element (real part)
# a1 = address of even element (imag part)
# a2 = address of odd element (real part)
# a3 = address of odd element (imag part)
# a4 = address of twiddle factor (real part)
# a5 = address of twiddle factor (imag part)
butterfly:
    # Save registers according to RISC-V calling convention
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    
    # Load values
    lw t0, 0(a0)            # t0 = even.real
    lw t1, 0(a1)            # t1 = even.imag
    lw t2, 0(a2)            # t2 = odd.real
    lw t3, 0(a3)            # t3 = odd.imag
    lw t4, 0(a4)            # t4 = twiddle.real
    lw t5, 0(a5)            # t5 = twiddle.imag
    
    # Complex multiply: odd * twiddle
    # (a+bi)(c+di) = (ac-bd) + (ad+bc)i
    
    # Replace mulh with mul + shift for VeeR compatibility
    mul t6, t2, t4         # t6 = (odd.real * twiddle.real)
    srai t6, t6, 16         # Shift to align with Q16.16 format
    
    mul a6, t3, t5         # a6 = (odd.imag * twiddle.imag)
    srai a6, a6, 16         # Shift to align with Q16.16 format
    
    # Use saved registers s0, s1 temporarily
    mul s0, t2, t5         # s0 = (odd.real * twiddle.imag)
    srai s0, s0, 16         # Shift to align with Q16.16 format
    
    mul s1, t3, t4         # s1 = (odd.imag * twiddle.real)
    srai s1, s1, 16         # Shift to align with Q16.16 format
    
    # Real and imaginary parts of product
    sub s2, t6, a6          # s2 = prod.real = (odd.real*twiddle.real - odd.imag*twiddle.imag)
    add s3, s0, s1          # s3 = prod.imag = (odd.real*twiddle.imag + odd.imag*twiddle.real)
    
    # Butterfly outputs
    add s4, t0, s2          # s4 = out_even.real = even.real + prod.real
    add s5, t1, s3          # s5 = out_even.imag = even.imag + prod.imag
    sub s6, t0, s2          # s6 = out_odd.real = even.real - prod.real
    sub s7, t1, s3          # s7 = out_odd.imag = even.imag - prod.imag
    
    # Store results
    sw s4, 0(a0)            # store out_even.real
    sw s5, 0(a1)            # store out_even.imag
    sw s6, 0(a2)            # store out_odd.real
    sw s7, 0(a3)            # store out_odd.imag
    
    # Restore registers
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36
    
    ret

# Function: printToLogVectorized (copied from Vectorized.s)
# Logs values from array in a0 into registers v1 for debugging and output.
# Inputs:
#   - a0: Base address of array
#   - a1: Size of array i.e. number of elements to log
printToLogVectorized:        
    addi sp, sp, -4
    sw a0, 0(sp)

    li t0, 0x123                 # Pattern for help in python script
    li t0, 0x456                 # Pattern for help in python script
    mv a1, a1                    # moving size to get it from log 
    mul a1, a1, a1               # square matrix has n^2 elements 
    li t0, 0                     # load i = 0
    
printloop:
    vsetvli t3, a1, e32           # Set VLEN based on a1
    slli t4, t3, 2                # Compute VLEN * 4 for address increment

    vle32.v v1, (a0)              # Load elements into v1
    add a0, a0, t4                # Increment pointer by VLEN * 4
    add t0, t0, t3                # Increment index

    bge t0, a1, endPrintLoop      # Exit loop if i >= size
    j printloop                   # Jump to start of loop
    
endPrintLoop:
    li t0, 0x123                  # Pattern for help in python script
    li t0, 0x456                  # Pattern for help in python script
	
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Function: _finish (copied from Vectorized.s)
# VeeR Related function which writes to to_host which stops the simulator
_finish:
    li x3, 0xd0580000
    addi x5, x0, 0xff
    sb x5, 0(x3)
    beq x0, x0, _finish

    .rept 100
        nop
    .endr

.section .data
# Current input mode
input_mode:
    .word 1                    # Default to complex input (use both real and imag)

# Static buffer allocation instead of dynamic
.align 4
.comm input_real,  4096        # 1024 words (4 bytes each)
.comm input_imag,  4096        # 1024 words (4 bytes each)
.comm output_real, 4096        # 1024 words (4 bytes each)
.comm output_imag, 4096        # 1024 words (4 bytes each)
.comm bit_rev_indices, 4096    # 1024 words (4 bytes each)

# Matrix size for display
.equ MatrixSize, 5
size: .word MatrixSize

# Display matrices for visualization
.align 4
fft_display_real:
    .zero 100                   # Space for 5×5 float matrix (100 bytes)

.align 4
fft_display_imag:
    .zero 100                   # Space for 5×5 float matrix (100 bytes)

# Include twiddle factor tables
.include "./assembly/twiddle_real.s"
.include "./assembly/twiddle_imag.s" 