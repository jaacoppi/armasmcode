// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_ldr1.s
// test case for reading the opcodes at C3.2.6, Unconditional branch (immediate)
// b (0x14)
// bl (0x94)

.global _start
.balign 4
.text
_start:
b  0b11111111111111111111111100
bgt next
ble _start	// B.cond to a negative value
next:
bl 0x4205F0
bl next
ret		// C5.6.148, return to address held in x30 (default)
