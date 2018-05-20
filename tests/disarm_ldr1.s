// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_ldr1.s
// test case for reading the opcde 0x58 (LDR)

.global _start
.balign 4
.text
_start:
ldr x5, 0x100
ldr x20, [sp], 0x40
