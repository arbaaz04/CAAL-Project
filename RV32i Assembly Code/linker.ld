/* Linker script for VeeR RISC-V core */
ENTRY(_start)

MEMORY
{
  /* Define memory regions for VeeR */
  RAM (rwx)  : ORIGIN = 0x00000000, LENGTH = 0x10000000 /* 256MB RAM */
  MMIO (rw)  : ORIGIN = 0x00010000, LENGTH = 0x00100000 /* 1MB MMIO region starting at 0x10000 */
}

SECTIONS
{
  /* Code section */
  .text : 
  {
    *(.text.init)
    *(.text)
    *(.text.*)
  } > RAM

  /* Read-only data */
  .rodata : 
  {
    *(.rodata)
    *(.rodata.*)
  } > RAM

  /* Initialized data */
  .data : 
  {
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
  } > RAM

  /* BSS section (zero-initialized data) */
  .bss : 
  {
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
  } > RAM

  /* Stack section */
  .stack (NOLOAD) : 
  {
    . = ALIGN(16);
    _stack_bottom = .;
    . += 0x1000; /* 4KB stack */
    _stack_top = .;
  } > RAM

  /* Heap section */
  .heap (NOLOAD) : 
  {
    . = ALIGN(16);
    _heap_start = .;
    . += 0x100000; /* 1MB heap */
    _heap_end = .;
  } > RAM

  /* Discard unnecessary sections */
  /DISCARD/ :
  {
    *(.note.*)
    *(.comment)
    *(.eh_frame)
  }
}