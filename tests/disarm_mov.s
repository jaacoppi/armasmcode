// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_mov.s
// test cases for dissasembling opcodes related to mnemonic MOV

.global _start
.balign 4
.text
_start:
mov x15, #100
mov x29, x15	// 5.6.142
mov w15, w29	// 5.6.142
