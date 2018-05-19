// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_cmp.s
// test case for reading the opcde 0x58 (LDR)

.global _start
.balign 4
.text
_start:
cmp x28, 0xFF
