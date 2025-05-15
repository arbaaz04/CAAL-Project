#FFT Python Code
import numpy as np
import matplotlib.pyplot as plt
import time

#Q16.16 fixed-point format: 16 bits for integer part, 16 bits for fractional part (for conversion to assembly language)
FRAC_BITS = 16  #Number of fractional bits
INT_BITS = 16   #Number of integer bits
SCALE = 1 << FRAC_BITS  #2^16 = 65536

#Convert floating point to Q16.16 fixed point.
def float_to_fixed(value):
    return int(value * SCALE)

#Convert Q16.16 fixed point to floating point.
def fixed_to_float(value):
    return value / SCALE

#Multiply two Q16.16 fixed-point numbers and scale result.
def fixed_multiply(a, b):
    return (a * b) >> FRAC_BITS

#Multiply two complex Q16.16 fixed-point numbers.
def fixed_complex_multiply(a_real, a_imag, b_real, b_imag):
    #(a+bi) * (c+di) = (ac-bd) + (ad+bc)i
    real = fixed_multiply(a_real, b_real) - fixed_multiply(a_imag, b_imag)
    imag = fixed_multiply(a_real, b_imag) + fixed_multiply(a_imag, b_real)
    return real, imag

#Generate twiddle factors as Q16.16 fixed-point tuples (real, imag).
def generate_twiddle_factors(N):
    twiddle_factors = []
    for k in range(N):
        angle = -2.0 * np.pi * k / N
        real = float_to_fixed(np.cos(angle))
        imag = float_to_fixed(np.sin(angle))
        twiddle_factors.append((real, imag))
    return twiddle_factors

#Reverse the bits of n (with specified number of bits).
def bit_reverse(n, bits):
    result = 0
    for i in range(bits):
        result = (result << 1) | (n & 1)
        n >>= 1
    return result


#Computer FFT using Q16.16 fixed-point arithmetic.
#This function implements the Cooley-Tukey FFT algorithm.
#It uses a bit-reversal permutation followed by the butterfly computation.
#The input is expected to be in Q16.16 fixed-point format. N is the size of the FFT, which must be a power of 2.
#The output is a tuple of two lists: the real and imaginary parts of the FFT result.
def fft_fixed_point(x_real, x_imag, N):
    #Check if N is a power of 2
    if N & (N-1) != 0:
        raise ValueError("Size of input must be a power of 2")
    
    bits = int(np.log2(N))
    
    #Generate twiddle factors
    twiddle_factors = generate_twiddle_factors(N)
    
    #Step 1: Bit-reversal permutation
    y_real = [0] * N
    y_imag = [0] * N
    
    for i in range(N):
        rev_i = bit_reverse(i, bits)
        y_real[rev_i] = x_real[i]
        y_imag[rev_i] = x_imag[i]
    
    #Step 2: Butterfly computations
    for stage in range(1, bits + 1):
        m = 2 ** stage
        half_m = m // 2
        
        for k in range(0, N, m):
            for j in range(half_m):
                #Get twiddle factor for butterfly
                tf_index = (j * N) // m
                w_real, w_imag = twiddle_factors[tf_index]
                
                #Get even and odd indices
                even_idx = k + j
                odd_idx = k + j + half_m
                
                #Get values
                even_real = y_real[even_idx]
                even_imag = y_imag[even_idx]
                odd_real = y_real[odd_idx]
                odd_imag = y_imag[odd_idx]
                
                #Compute product: odd * twiddle
                prod_real, prod_imag = fixed_complex_multiply(
                    odd_real, odd_imag, w_real, w_imag
                )
                
                #Butterfly operation
                y_real[even_idx] = even_real + prod_real
                y_imag[even_idx] = even_imag + prod_imag
                y_real[odd_idx] = even_real - prod_real
                y_imag[odd_idx] = even_imag - prod_imag
    
    return y_real, y_imag

#Test 1024-point FFT with fixed-point arithmetic using complex input.
def test_1024point_fixed(save_results=True):
    #Generate complex input signal
    N = 1024
    f = 100  #Frequency Hz
    t = np.arange(N)
    signal_real = np.cos(2 * np.pi * f * t / N)
    signal_imag = np.sin(2 * np.pi * f * t / N)
    
    #Convert to fixed-point
    x_real = [float_to_fixed(val) for val in signal_real]
    x_imag = [float_to_fixed(val) for val in signal_imag]
    
    #Compute FFT
    print("\nComputing 1024-point FFT with Q16.16 fixed-point arithmetic")
    start_time = time.time()
    y_real, y_imag = fft_fixed_point(x_real, x_imag, N)
    fixed_time = time.time() - start_time
    
    #Convert back to floating point
    y_real_float = [fixed_to_float(val) for val in y_real]
    y_imag_float = [fixed_to_float(val) for val in y_imag]
    
    #Compute NumPy FFT for comparison
    signal_complex = signal_real + 1j * signal_imag
    start_time = time.time()
    y_numpy = np.fft.fft(signal_complex)
    numpy_time = time.time() - start_time
    
    #Save results to file
    if save_results:
        with open("fft_results.txt", "w") as f:
            f.write("# 1024-point FFT Results (Q16.16 fixed-point)\n")
            f.write("# Format: Index, Real, Imag\n")
            f.write(f"# FFT Size: {N}\n")
            for i in range(N):
                f.write(f"{i},{y_real[i]},{y_imag[i]}\n")
        print("Results saved to 'fft_results.txt' for comparison with assembly output")
    
    #Print results
    print("\nFixed-Point FFT Results (first 8 bins):")
    print("Index | Input Real | Input Imag | Fixed-Point FFT (Float) | Fixed-Point FFT (Q16.16) | NumPy FFT")
    print("-" * 90)
    
    for i in range(8):
        print(f"{i:5d} | {signal_real[i]:10.4f} | {signal_imag[i]:10.4f} | "
              f"{y_real_float[i]:8.4f} + {y_imag_float[i]:8.4f}j | "
              f"{y_real[i]:10d} + {y_imag[i]:10d}j | "
              f"{y_numpy[i].real:8.4f} + {y_numpy[i].imag:8.4f}j")
    
    print(f"\nFixed-point FFT time: {fixed_time:.6f}s")
    print(f"NumPy FFT time: {numpy_time:.6f}s")
    
    plt.figure(figsize=(12, 10))
    
    #Original signal (first 64 samples)
    plt.subplot(3, 1, 1)
    plt.plot(t[:64], signal_real[:64], label="Real")
    plt.plot(t[:64], signal_imag[:64], label="Imag")
    plt.title("Original Signal (First 64 Samples)")
    plt.xlabel("Sample Index")
    plt.ylabel("Amplitude")
    plt.legend()
    
    #Fixed-point FFT magnitude (~100 Hz)
    plt.subplot(3, 1, 2)
    magnitude = [np.sqrt(r**2 + i**2) for r, i in zip(y_real_float, y_imag_float)]
    freq_bins = np.arange(90, 110)
    plt.stem(freq_bins, [magnitude[i] for i in freq_bins])
    plt.title("Fixed-Point FFT Magnitude (Around 100 Hz)")
    plt.xlabel("Frequency Bin")
    plt.ylabel("Magnitude")
    
    #NumPy FFT magnitude (~100 Hz)
    plt.subplot(3, 1, 3)
    plt.stem(freq_bins, np.abs(y_numpy)[90:110])
    plt.title("NumPy FFT Magnitude (Around 100 Hz)")
    plt.xlabel("Frequency Bin")
    plt.ylabel("Magnitude")
    
    plt.tight_layout()
    plt.show()

#Main
if __name__ == "__main__":
    test_1024point_fixed()