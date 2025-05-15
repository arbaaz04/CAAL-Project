import math
import struct
import sys

def find_and_save_lines(filename):
    all_results = []
    result = []
    size_line = ""
    is_saving = False

    with open(filename, 'r') as file:
        prev_line = None  # Store the previous line for pattern matching

        for line in file:
            line_strip = line.strip()
            columns = line_strip.split()

            # More flexible pattern matching for 0x123 and 0x456
            if prev_line and len(columns) > 6 and len(prev_line.strip().split()) > 6:
                prev_columns = prev_line.strip().split()
                
                # Original pattern match
                if prev_columns[6] == "00000123" and columns[6] == "00000456":
                    if is_saving:  # If already saving, store result and reset
                        all_results.append(result)
                        result = []
                        is_saving = False
                    else:
                        is_saving = True
                
                # Additional pattern matcher for our FFT output
                elif "Computing 1024-point FFT" in prev_line:
                    is_saving = True
                    # Use 1024 as the default size for FFT
                    size_line = "1024"
                
                # End of FFT output marker
                elif "FFT computation complete" in prev_line:
                    if result:
                        all_results.append(result)
                        result = []
                        is_saving = False

            if is_saving:
                # Look for size information - try multiple patterns
                if "c.mv     a1" in line_strip:
                    size_line = line_strip
                elif "mv      a1" in line_strip and "moving size" in line_strip:
                    size_line = line_strip
                elif not size_line and "1024" in line_strip:
                    size_line = "1024"  # Default FFT size
                
                # Record all lines when saving
                result.append(line_strip)

            prev_line = line  # Move to the next line

    if result:
        all_results.append(result)

    return all_results, size_line


def filter_lines_by_flw(lines):
    return [line for line in lines if "flw" in line]


def filter_lines_by_vle(lines):
    return [line for line in lines if "vle32.v" in line]


def extract_7th_column(lines):
    return [line.strip().split()[6] for line in lines if len(line.strip().split()) > 6]


def extract_hex_values(lines):
    """Extract hex values from print_hex output in the log"""
    hex_values = []
    for i in range(len(lines)-1):
        # Look for lines containing print_hex output
        if "print_hex" in lines[i] and len(lines[i+1].strip().split()) > 6:
            next_cols = lines[i+1].strip().split()
            if len(next_cols) > 6:
                hex_values.append(next_cols[6])
    return hex_values


def hex_to_float(hex_array, isVectorized=False, size=None):
    result = []
    
    for hex_str in hex_array:
        if isVectorized:
            # Split into 8-character (32-bit) chunks
            chunks = [hex_str[i:i+8] for i in range(0, len(hex_str), 8)]
            # Reverse the order (as per RISC-V vector register format)
            chunks.reverse()
        else:
            chunks = [hex_str]
        
        for chunk in chunks:
            if not chunk or len(chunk) != 8:
                continue  # Skip invalid chunks
            try:
                hex_value = int(chunk, 16)
                float_value = struct.unpack('!f', struct.pack('!I', hex_value))[0]
                result.append(float_value)
            except (ValueError, struct.error):
                pass  # Ignore invalid hex values
    
    # Trim to the specified size if needed
    if size is not None:
        result = result[:size]
    
    return result


def print_matrixes_from_lines(lines, size):
    isVector = any("vle" in line for array in lines for line in array)

    # Try to extract FFT results if present
    all_values = []
    for matrix in lines:
        # Try to extract values from print_hex calls first
        hex_values = extract_hex_values(matrix)
        if hex_values:
            # Group by sets of 3 (index, real, imag)
            fft_results = []
            for i in range(1, len(hex_values), 3):
                if i+1 < len(hex_values):
                    fft_results.append(hex_values[i])  # Real part
                    fft_results.append(hex_values[i+1])  # Imag part
            
            if fft_results:
                all_values.append(hex_to_float(fft_results))
                continue

        # Fall back to standard extraction methods
        if isVector:
            values = hex_to_float(extract_7th_column(filter_lines_by_vle(matrix)), isVectorized=isVector, size=size**2)
        else:
            values = hex_to_float(extract_7th_column(filter_lines_by_flw(matrix)))
        
        if values:
            all_values.append(values)

    if not all_values:
        print("No valid data found in log")
        return

    print("Matrixes are:\n")
    for array in all_values:
        for i in range(0, len(array), size):
            print(" ".join(f"{x:12.6f}" for x in array[i:i + size]))
        print("")


if __name__ == "__main__":
    # Default size if not found
    default_size = 32
    
    # Parse command line arguments
    if len(sys.argv) < 3:
        print("Usage: python print_log_array.py <size> <type>")
        sys.exit(1)
    
    size_arg = sys.argv[1]
    type_arg = sys.argv[2]
    
    # Determine the log file to use
    if type_arg == "NV":
        log_file = "veer/tempFiles/logNV.txt"
    elif type_arg == "FFT" or type_arg == "SimFT" or type_arg == "CFFT":
        # Special case for FFT implementations
        log_file = f"veer/tempFiles/log{type_arg}.txt"
    else:
        log_file = "veer/tempFiles/logV.txt"
    
    # Find the log segments
    found_segments, size_line = find_and_save_lines(log_file)
    
    if not found_segments:
        print("Not found")
        sys.exit(1)
    
    # Determine size
    try:
        if size_arg != "-1":
            # User-specified size
            matrix_size = int(size_arg)
        elif size_line and "00000" in size_line:
            # Extract from log line
            size_parts = size_line.strip().split()
            if len(size_parts) > 6:
                matrix_size = int(size_parts[6], 16)
            else:
                matrix_size = default_size
        elif size_line.isdigit():
            # If we captured a direct digit 
            matrix_size = int(size_line)
        else:
            # FFT always uses 1024 points, so use 8 as matrix size for output
            if any("FFT" in type_arg for type_arg in sys.argv):
                matrix_size = 8  # Display 8 points for FFT
            else:
                matrix_size = default_size
    except (ValueError, IndexError):
        # If extraction fails, use defaults
        if any("FFT" in type_arg for type_arg in sys.argv):
            matrix_size = 8  # Display 8 points for FFT
        else:
            matrix_size = default_size
    
    print("matrix size is", matrix_size)
    print_matrixes_from_lines(found_segments, matrix_size)
