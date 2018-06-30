// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_cmp.s
// test cases for dissassembling opcodes related to compares and conditionals

.global _start
.balign 4
.text
_start:
cmp x28, 0xFF		// 5.6.45, 64 bit
cmp w9, 0xAA		// 5.6.45, 32 bit
cmp x11, x21		// 5.6.46, 64 bit
cmp x10, 0xFFFFFFFFFFFFFFFD 	// -3, changes cmp disassembly to cmn
csel x12, x10, x11, le		// 5.6.50
cset x12, gt			// 5.6.51
