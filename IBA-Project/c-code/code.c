#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

// Q16.16 fixed-point format: 16 bits for integer part, 16 bits for fractional part
#define FRAC_BITS 16      // Number of fractional bits
#define INT_BITS 16       // Number of integer bits
#define SCALE (1 << FRAC_BITS)  // 2^16 = 65536

// Structure for complex numbers in fixed-point
typedef struct {
    int real;
    int imag;
} fixed_complex;

// Convert floating point to Q16.16 fixed point
int float_to_fixed(double value) {
    return (int)(value * SCALE);
}

// Convert Q16.16 fixed point to floating point
double fixed_to_float(int value) {
    return (double)value / SCALE;
}

// Multiply two Q16.16 fixed-point numbers and scale result
int fixed_multiply(int a, int b) {
    return ((long long)a * b) >> FRAC_BITS;
}

// Multiply two complex Q16.16 fixed-point numbers
fixed_complex fixed_complex_multiply(int a_real, int a_imag, int b_real, int b_imag) {
    // (a+bi) * (c+di) = (ac-bd) + (ad+bc)i
    fixed_complex result;
    result.real = fixed_multiply(a_real, b_real) - fixed_multiply(a_imag, b_imag);
    result.imag = fixed_multiply(a_real, b_imag) + fixed_multiply(a_imag, b_real);
    return result;
}

// Generate twiddle factors as Q16.16 fixed-point complex values
fixed_complex* generate_twiddle_factors(int N) {
    fixed_complex* twiddle_factors = (fixed_complex*)malloc(N * sizeof(fixed_complex));
    if (!twiddle_factors) {
        fprintf(stderr, "Memory allocation failed for twiddle factors\n");
        exit(EXIT_FAILURE);
    }
    
    for (int k = 0; k < N; k++) {
        double angle = -2.0 * M_PI * k / N;
        twiddle_factors[k].real = float_to_fixed(cos(angle));
        twiddle_factors[k].imag = float_to_fixed(sin(angle));
    }
    return twiddle_factors;
}

// Reverse the bits of n (with specified number of bits)
int bit_reverse(int n, int bits) {
    int result = 0;
    for (int i = 0; i < bits; i++) {
        result = (result << 1) | (n & 1);
        n >>= 1;
    }
    return result;
}

// Compute FFT using Q16.16 fixed-point arithmetic
// This function implements the Cooley-Tukey FFT algorithm
// It uses a bit-reversal permutation followed by the butterfly computation
// The input is expected to be in Q16.16 fixed-point format
// N is the size of the FFT, which must be a power of 2
void fft_fixed_point(int* x_real, int* x_imag, int N, int* y_real, int* y_imag) {
    // Check if N is a power of 2
    if ((N & (N-1)) != 0) {
        fprintf(stderr, "Size of input must be a power of 2\n");
        exit(EXIT_FAILURE);
    }
    
    // Calculate number of bits
    int bits = 0;
    for (int temp = N; temp > 1; temp >>= 1) {
        bits++;
    }
    
    // Generate twiddle factors
    fixed_complex* twiddle_factors = generate_twiddle_factors(N);
    
    // Step 1: Bit-reversal permutation
    for (int i = 0; i < N; i++) {
        int rev_i = bit_reverse(i, bits);
        y_real[rev_i] = x_real[i];
        y_imag[rev_i] = x_imag[i];
    }
    
    // Step 2: Butterfly computations
    for (int stage = 1; stage <= bits; stage++) {
        int m = 1 << stage;             // 2^stage
        int half_m = m >> 1;            // m/2
        
        for (int k = 0; k < N; k += m) {
            for (int j = 0; j < half_m; j++) {
                // Get twiddle factor for butterfly
                int tf_index = (j * N) / m;
                int w_real = twiddle_factors[tf_index].real;
                int w_imag = twiddle_factors[tf_index].imag;
                
                // Get even and odd indices
                int even_idx = k + j;
                int odd_idx = k + j + half_m;
                
                // Get values
                int even_real = y_real[even_idx];
                int even_imag = y_imag[even_idx];
                int odd_real = y_real[odd_idx];
                int odd_imag = y_imag[odd_idx];
                
                // Compute product: odd * twiddle
                fixed_complex prod = fixed_complex_multiply(
                    odd_real, odd_imag, w_real, w_imag
                );
                
                // Butterfly operation
                y_real[even_idx] = even_real + prod.real;
                y_imag[even_idx] = even_imag + prod.imag;
                y_real[odd_idx] = even_real - prod.real;
                y_imag[odd_idx] = even_imag - prod.imag;
            }
        }
    }
    
    // Free twiddle factors
    free(twiddle_factors);
}

// Test 1024-point FFT with fixed-point arithmetic using complex input
void test_1024point_fixed(int save_results) {
    // Generate complex input signal
    int N = 1024;
    int f = 100;  // Frequency Hz
    double* signal_real = (double*)malloc(N * sizeof(double));
    double* signal_imag = (double*)malloc(N * sizeof(double));
    
    if (!signal_real || !signal_imag) {
        fprintf(stderr, "Memory allocation failed for signals\n");
        exit(EXIT_FAILURE);
    }
    
    for (int t = 0; t < N; t++) {
        signal_real[t] = cos(2 * M_PI * f * t / N);
        signal_imag[t] = sin(2 * M_PI * f * t / N);
    }
    
    // Convert to fixed-point
    int* x_real = (int*)malloc(N * sizeof(int));
    int* x_imag = (int*)malloc(N * sizeof(int));
    int* y_real = (int*)malloc(N * sizeof(int));
    int* y_imag = (int*)malloc(N * sizeof(int));
    
    if (!x_real || !x_imag || !y_real || !y_imag) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(EXIT_FAILURE);
    }
    
    for (int i = 0; i < N; i++) {
        x_real[i] = float_to_fixed(signal_real[i]);
        x_imag[i] = float_to_fixed(signal_imag[i]);
    }
    
    // Compute FFT
    printf("\nComputing 1024-point FFT with Q16.16 fixed-point arithmetic\n");
    clock_t start_time = clock();
    fft_fixed_point(x_real, x_imag, N, y_real, y_imag);
    double fixed_time = (double)(clock() - start_time) / CLOCKS_PER_SEC;
    
    // Convert back to floating point for display
    double* y_real_float = (double*)malloc(N * sizeof(double));
    double* y_imag_float = (double*)malloc(N * sizeof(double));
    
    if (!y_real_float || !y_imag_float) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(EXIT_FAILURE);
    }
    
    for (int i = 0; i < N; i++) {
        y_real_float[i] = fixed_to_float(y_real[i]);
        y_imag_float[i] = fixed_to_float(y_imag[i]);
    }
    
    // Save results to file
    if (save_results) {
        FILE* f = fopen("fft_results_C_code.txt", "w");
        if (f) {
            fprintf(f, "# 1024-point FFT Results (Q16.16 fixed-point)\n");
            fprintf(f, "# Format: Index, Real, Imag\n");
            fprintf(f, "# FFT Size: %d\n", N);
            for (int i = 0; i < N; i++) {
                fprintf(f, "%d,%d,%d\n", i, y_real[i], y_imag[i]);
            }
            fclose(f);
            printf("Results saved to 'fft_results_C_code.txt' for comparison with assembly output\n");
        } else {
            fprintf(stderr, "Failed to open file for writing\n");
        }
    }
    
    // Print results
    printf("\nFixed-Point FFT Results (first 8 bins):\n");
    printf("%-5s | %-10s | %-10s | %-29s | %-32s\n", 
           "Index", "Input Real", "Input Imag", "Fixed-Point FFT (Float)", "Fixed-Point FFT (Q16.16)");
    printf("---------------------------------------------------------------------------------------------\n");
    
    for (int i = 0; i < 8; i++) {
        printf("%-5d | %-10.4f | %-10.4f | %-8.4f + %-8.4fj | %-10d + %-10dj\n", 
               i, signal_real[i], signal_imag[i], 
               y_real_float[i], y_imag_float[i],
               y_real[i], y_imag[i]);
    }
    
    printf("\nFixed-point FFT time: %.6fs\n", fixed_time);
    
    // Free memory
    free(signal_real);
    free(signal_imag);
    free(x_real);
    free(x_imag);
    free(y_real);
    free(y_imag);
    free(y_real_float);
    free(y_imag_float);
}

int main() {
    test_1024point_fixed(1);  // 1 = save results to file
    return 0;
}