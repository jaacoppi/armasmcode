// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_ldr1.s
// test case for disassembling opcodes related to loads and stores

.global _start
.balign 4
.text
_start:
str x30, [sp, -0x8]!	// 5.7.178 Preindexed store
ldr x5, 0x100
ldr x20, [sp], 0x40	// 5.6.83, post index variant
ldr x10, [x20]		// 5.6.83, immediate offset, 64 bit
ldr w10, [x20]		// 5.6.83, immediate offset, 32bit
ldr w25, [x15], 0x20	// 5.6.83, post index variant
ldrb w17, [x29]
ldrb w1, [x17], -0x20
ldrb    w0, [x1,#-1]!	// 5.6.86, post index variant
ldrh    w13, [x12],#2	// 5.6.88
strb w10, [x1]		// 5.6.180, STRB (immediate). This is an offset variant, currently doesn't handle offsets
strb w10, [x1], -0x1		// 5.6.180, STRB (immediate), post index
adr x29, 4	// byte align 4
address:

