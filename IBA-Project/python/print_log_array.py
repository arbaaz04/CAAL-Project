#!/usr/bin/env python3
import struct
import sys

def extract_float_values(file_path):
    try:
        with open(file_path, 'rb') as f:
            raw_bytes = f.read()
    except IOError:
        print(f"Error : {file_path}")
        return []

    if len(raw_bytes) % 4 != 0:
        print(f"Warning: size of '{file_path}' ({len(raw_bytes)} bytes) is not divisible by 4")

    float_values = []
    for idx in range(0, len(raw_bytes), 4):
        chunk = raw_bytes[idx:idx+4]
        float_num = struct.unpack('<f', chunk)[0]  # decode as little-endian float
        float_values.append(float_num)

    return float_values

def display_complex_output(files_to_process):
    for file_name in files_to_process:
        numbers = extract_float_values(file_name)
        if not numbers:
            continue

        print(f"\nContents of {file_name}:")
        for i in range(0, len(numbers), 2):
            real = numbers[i]
            imaginary = numbers[i + 1]
            print(f"  [{i//2:2d}] = {real:.6f} + {imaginary:.6f}j")

def parse_arguments():
    args = sys.argv[1:]

    if args and args[0] == '-1':
        args = args[1:]

    # remove visualization flags if present
    args = [arg for arg in args if arg.upper() not in ('V', 'NV')]

    if not args:
        return ['bitreversalout.hex', 'finalout.hex']
    return args

if __name__ == "__main__":
    input_files = parse_arguments()
    display_complex_output(input_files)
