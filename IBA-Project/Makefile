GCC_PREFIX = riscv32-unknown-elf
ABI = -march=rv32gcv_zbb_zbs -mabi=ilp32f
LINK = ./veer/link.ld
CODEFOLDER = ./assembly
TEMPPATH = ./veer/tempFiles

allV: compileV executeV

cleanV: 
	rm -f $(TEMPPATH)/logV.txt  $(TEMPPATH)/programV.hex  $(TEMPPATH)/TESTV.dis  $(TEMPPATH)/TESTV.exe
	
compileV:
	$(GCC_PREFIX)-gcc $(ABI) -lgcc -T$(LINK) -o  $(TEMPPATH)/TESTV.exe $(CODEFOLDER)/Vectorized.s -nostartfiles -lm
	$(GCC_PREFIX)-objcopy -O verilog  $(TEMPPATH)/TESTV.exe  $(TEMPPATH)/programV.hex
	$(GCC_PREFIX)-objdump -S  $(TEMPPATH)/TESTV.exe >  $(TEMPPATH)/TESTV.dis
	
executeV:
	-whisper -x $(TEMPPATH)/programV.hex -s 0x80000000 --tohost 0xd0580000 -f  $(TEMPPATH)/logV.txt --configfile ./veer/whisper.json
	python3 python/print_log_array.py -1 V


allNV: compileNV executeNV

cleanNV: 
	rm -f $(TEMPPATH)/logNV.txt  $(TEMPPATH)/programNV.hex  $(TEMPPATH)/TESTNV.dis  $(TEMPPATH)/TESTNV.exe
	
compileNV:
	$(GCC_PREFIX)-gcc $(ABI) -lgcc -T$(LINK) -o  $(TEMPPATH)/TESTNV.exe $(CODEFOLDER)/NonVectorized.s -nostartfiles -lm
	$(GCC_PREFIX)-objcopy -O verilog  $(TEMPPATH)/TESTNV.exe  $(TEMPPATH)/programNV.hex
	$(GCC_PREFIX)-objdump -S  $(TEMPPATH)/TESTNV.exe >  $(TEMPPATH)/TESTNV.dis
	
executeNV:
	-whisper -x  $(TEMPPATH)/programNV.hex -s 0x80000000 --tohost 0xd0580000 -f  $(TEMPPATH)/logNV.txt --configfile ./veer/whisper.json
	python3 python/print_log_array.py -1 NV

testNV:
	python3 python/write_array.py $(filter-out $@,$(MAKECMDGOALS)) NV
	$(GCC_PREFIX)-gcc $(ABI) -lgcc -T$(LINK) -o  $(TEMPPATH)/TESTNV.exe $(CODEFOLDER)/NonVectorizedModified.s -nostartfiles -lm
	$(GCC_PREFIX)-objcopy -O verilog  $(TEMPPATH)/TESTNV.exe  $(TEMPPATH)/programNV.hex
	$(GCC_PREFIX)-objdump -S  $(TEMPPATH)/TESTNV.exe >  $(TEMPPATH)/TESTNV.dis
	-whisper -x  $(TEMPPATH)/programNV.hex -s 0x80000000 --tohost 0xd0580000 -f  $(TEMPPATH)/logNV.txt --configfile ./veer/whisper.json
	python3 python/print_log_array.py $(filter-out $@,$(MAKECMDGOALS)) NV

testV:
	python3 python/write_array.py $(filter-out $@,$(MAKECMDGOALS)) V
	$(GCC_PREFIX)-gcc $(ABI) -lgcc -T$(LINK) -o  $(TEMPPATH)/TESTNV.exe $(CODEFOLDER)/VectorizedModified.s -nostartfiles -lm
	$(GCC_PREFIX)-objcopy -O verilog  $(TEMPPATH)/TESTNV.exe  $(TEMPPATH)/programNV.hex
	$(GCC_PREFIX)-objdump -S  $(TEMPPATH)/TESTNV.exe >  $(TEMPPATH)/TESTNV.dis
	-whisper -x  $(TEMPPATH)/programNV.hex -s 0x80000000 --tohost 0xd0580000 -f  $(TEMPPATH)/logV.txt --configfile ./veer/whisper.json
	python3 python/print_log_array.py $(filter-out $@,$(MAKECMDGOALS)) V

# FFT Implementation Targets
allFFT: compileFFT executeFFT

cleanFFT:
	rm -f $(TEMPPATH)/logFFT.txt $(TEMPPATH)/programFFT.hex $(TEMPPATH)/TESTFFT.dis $(TEMPPATH)/TESTFFT.exe

compileFFT:
	$(GCC_PREFIX)-gcc $(ABI) -lgcc -T$(LINK) -o $(TEMPPATH)/TESTFFT.exe $(CODEFOLDER)/FFT.s -nostartfiles -lm
	$(GCC_PREFIX)-objcopy -O verilog $(TEMPPATH)/TESTFFT.exe $(TEMPPATH)/programFFT.hex
	$(GCC_PREFIX)-objdump -S $(TEMPPATH)/TESTFFT.exe > $(TEMPPATH)/TESTFFT.dis

executeFFT:
	-whisper -x $(TEMPPATH)/programFFT.hex -s 0x80000000 --tohost 0xd0580000 -f $(TEMPPATH)/logFFT.txt --configfile ./veer/whisper.json
	python3 python/print_log_array.py -1 FFT

# Simplified FFT Implementation Targets
allSimplifiedFFT: compileSimplifiedFFT executeSimplifiedFFT

cleanSimplifiedFFT:
	rm -f $(TEMPPATH)/logSimplifiedFFT.txt $(TEMPPATH)/programSimplifiedFFT.hex $(TEMPPATH)/TESTSimplifiedFFT.dis $(TEMPPATH)/TESTSimplifiedFFT.exe

compileSimplifiedFFT:
	$(GCC_PREFIX)-gcc $(ABI) -lgcc -T$(LINK) -o $(TEMPPATH)/TESTSimplifiedFFT.exe $(CODEFOLDER)/SimplifiedFFT.s -nostartfiles -lm
	$(GCC_PREFIX)-objcopy -O verilog $(TEMPPATH)/TESTSimplifiedFFT.exe $(TEMPPATH)/programSimplifiedFFT.hex
	$(GCC_PREFIX)-objdump -S $(TEMPPATH)/TESTSimplifiedFFT.exe > $(TEMPPATH)/TESTSimplifiedFFT.dis

executeSimplifiedFFT:
	-whisper -x $(TEMPPATH)/programSimplifiedFFT.hex -s 0x80000000 --tohost 0xd0580000 -f $(TEMPPATH)/logSimplifiedFFT.txt --configfile ./veer/whisper.json
	python3 python/print_log_array.py -1 SimFT

# Complete FFT Implementation Targets
allCompleteFFT: compileCompleteFFT executeCompleteFFT

cleanCompleteFFT:
	rm -f $(TEMPPATH)/logCompleteFFT.txt $(TEMPPATH)/programCompleteFFT.hex $(TEMPPATH)/TESTCompleteFFT.dis $(TEMPPATH)/TESTCompleteFFT.exe

compileCompleteFFT:
	$(GCC_PREFIX)-gcc $(ABI) -lgcc -T$(LINK) -o $(TEMPPATH)/TESTCompleteFFT.exe $(CODEFOLDER)/CompleteFFT.s -nostartfiles -lm
	$(GCC_PREFIX)-objcopy -O verilog $(TEMPPATH)/TESTCompleteFFT.exe $(TEMPPATH)/programCompleteFFT.hex
	$(GCC_PREFIX)-objdump -S $(TEMPPATH)/TESTCompleteFFT.exe > $(TEMPPATH)/TESTCompleteFFT.dis

executeCompleteFFT:
	-whisper -x $(TEMPPATH)/programCompleteFFT.hex -s 0x80000000 --tohost 0xd0580000 -f $(TEMPPATH)/logCompleteFFT.txt --configfile ./veer/whisper.json
	python3 python/print_log_array.py -1 CFFT

#THIS IS C CODE PART
CCODEFOLDER = ./c-code
CCODEFILE = $(CCODEFOLDER)/code.c
CC = gcc
CFLAGS = -Wall -Wextra -O2

# Define the target executable
TARGET = a.out

# Rule to build and run the program
allc: cleanc compilec executec

compilec: 
	$(CC) $(CFLAGS) $(CCODEFILE) -o $(CCODEFOLDER)/$(TARGET) -lm

executec:
	./$(CCODEFOLDER)/$(TARGET)

# Clean up the generated files
cleanc:
	rm -f ./$(CCODEFOLDER)/$(TARGET)