// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_mov.s
// test cases for dissasembling opcodes related to data processing

.global _start
.balign 4
.text
_start:
mov x15, #100
mov x29, x15	// 5.6.142
mov w15, w29	// 5.6.142
mov x14, #0x3ffffff	//5.6.124 MOV (bitmask immediate)
and x10, x20, #0x4	// 5.6.11
and x15, x29, x30 // 5.6.12
eor x15, x15, 0x1ff // 5.6.64
eor x29, x19, x9 // 5.6.65
lsr x5, x15, x25	// 5.6.118
ubfm x1, x0, #4, #7	// 5.6.212
lsl x20, x15, #24

