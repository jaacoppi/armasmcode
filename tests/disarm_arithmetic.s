// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_arithmetic.s
// test cases for dissasembling opcodes related to arithmetic operations

.global _start
.balign 4
.text
_start:
add x11, x21, x0	// 5.6.5 ADD (shifted register)
mul x0, x11, x21	// 5.6.119 MADD, alias mul
