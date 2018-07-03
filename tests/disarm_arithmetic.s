// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_arithmetic.s
// test cases for dissasembling opcodes related to arithmetic operations

.global _start
.balign 4
.text
_start:
add x20, x30, #128	// 5.6.5 ADD (immediate)
add x11, x21, x0	// 5.6.5 ADD (shifted register)
mul x0, x11, x21	// 5.6.119 MADD, alias mul
sub x21, x0, #5		// 5.6.195 SUB (immediate)
sub x21, x29, x11	// 5.6.195 SUB (shited register)
udiv x21, x15, x9	// 5.6.214 UDIV
msub x20, x11, x21, x9	// 5.6.132 MSUB (multiply-subtract)
