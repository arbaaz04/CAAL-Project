import math

FFT_SIZE = 1024
NUM_TWIDDLES = FFT_SIZE // 2  # Only N/2 unique twiddles needed
FIXED_POINT_SCALE = 65536  # Q16.16
OUTPUT_REAL_FILE = "twiddle_real.s"
OUTPUT_IMAG_FILE = "twiddle_imag.s"

def generate_twiddle_real():
    with open(OUTPUT_REAL_FILE, "w") as f:
        f.write("# Twiddle factor table (real part) for 1024-point FFT\n")
        f.write("# Generated with generate_twiddle.py\n")
        f.write("# Using Q16.16 fixed-point format\n")
        f.write(".section .rodata\n")  # FIXED: Changed from .data to .rodata
        f.write(".align 4\n")
        f.write("twiddle_real:\n")
        for k in range(NUM_TWIDDLES):  # FIXED: Loop up to 511 (N/2)
            angle = 2 * math.pi * k / FFT_SIZE
            cos_val = math.cos(angle)
            fixed_point = int(cos_val * FIXED_POINT_SCALE)
            f.write(f"    .word {fixed_point:6d}  # W_{FFT_SIZE}^{k}: cos(2π*{k}/{FFT_SIZE}) = {cos_val:.6f}\n")

def generate_twiddle_imag():
    with open(OUTPUT_IMAG_FILE, "w") as f:
        f.write("# Twiddle factor table (imaginary part) for 1024-point FFT\n")
        f.write("# Generated with generate_twiddle.py\n")
        f.write("# Using Q16.16 fixed-point format\n")
        f.write(".section .rodata\n")  # FIXED: Changed from .data to .rodata
        f.write(".align 4\n")
        f.write("twiddle_imag:\n")
        for k in range(NUM_TWIDDLES):  # FIXED: Loop up to 511 (N/2)
            angle = 2 * math.pi * k / FFT_SIZE
            sin_val = -math.sin(angle)  # Negative sine for twiddle factor
            fixed_point = int(sin_val * FIXED_POINT_SCALE)
            f.write(f"    .word {fixed_point:6d}  # W_{FFT_SIZE}^{k}: -sin(2π*{k}/{FFT_SIZE}) = {sin_val:.6f}\n")

def main():
    generate_twiddle_real()
    generate_twiddle_imag()
    print(f"Generated {OUTPUT_REAL_FILE} and {OUTPUT_IMAG_FILE}")

if __name__ == "__main__":
    main()