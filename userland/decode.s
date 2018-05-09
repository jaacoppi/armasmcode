// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: decode.s
// Disassembler for 64 bit ARM (Aarch64)

// Acknowledgements:

.include "macros.s"
.include "globals.s"
.include "fcntl.s"
.include "fs.s"

.global decode
// ARMV8-A Architecture reference manual, chapter C3 Instruction set encoding
// from Table C3-1 A64 main encoding table
.equiv unalloc, 0x0
.equiv datapr_imm, 0x0
.equiv imm0_26, 0x03FFFFFF
.equiv imm5_23, 0x00FFFFE0
// C 3.2 Branches, exception generating and system instructions
.equiv C3_2a,	     0xA
.equiv C3_2b,	     0xB
.equiv C3_2_1, 0b011010
.equiv C3_2_2, 0b0101010
.equiv C3_2_3, 0b11010100
.equiv C3_2_4, 0b1101010100
.equiv C3_2_5, 0b011011
.equiv C3_2_6, 0b00101
.equiv C3_2_6a, 0b000101
.equiv C3_2_6b, 0b100101
.equiv C3_2_7, 0b1101011
// C3.3 Loads and stores
.equiv C3_3a,       0x4
.equiv C3_3b,       0x6
.equiv C3_3c,       0xC
.equiv C3_3d,       0xE
	.equiv C3_3_6, 0x8
	.equiv C3_3_5a, 0x18
	.equiv C3_3_5b, 0x1C
// C3.4 Data processing - immediate
.equiv C3_4a,       0x8
.equiv C3_4b,       0x9
// C3.5 Data processing - register
.equiv C3_5a,       0x5
.equiv C3_5b,       0x13
// C3.6 Data processing - SIMD and floating point
.equiv C3_6,       0x7


.equiv datapr_reg, 0x0
.equiv datapr_simd1, 0x0
.equiv datapr_simd2, 0x0



// get the immediate value and convert it to a relative value
// most often this is used for memory addressing
// registers:
// x21 = program counter
// x25 = instruction
// x26 = output result
// x27 = input: starting bit
// x28 = input: how many bits
imm2rel:
	lsr x26, x25, x27	// move to 0 bit
	mov x27, #64
	sub x28, x27, x28
	mov x27, 0xFFFFFFFFFFFFFFFF	// bitmask out unnecessary bits
	lsr x27, x27, x28
	and  x26, x26, x27
	lsl x26, x26, #2
	add x26, x26, x21
	ret



// x20 is the memory pointer
// x25 is the value to be decoded.
// x26 and x27 are temp

decode:
	add x20, x20, 0x5 // reset memmory pointer

// go through a series of switches to find the right opcode
// PASS 1: Encoding group
// compare bits 28-25 of x25
// TODO: this a-d method of masking unknown bits is messy. Figure out a better way
mov x26, #0
bfm x26,x25, #25, #28

cmp x26, C3_6
	beq switch_C3_6
cmp x26, C3_5a
	beq switch_C3_5
cmp x26, C3_5b
	beq switch_C3_5
cmp x26, C3_4a
	beq switch_C3_4
cmp x26, C3_4b
	beq switch_C3_4
cmp x26, C3_3a
	beq switch_C3_3
cmp x26, C3_3b
	beq switch_C3_3
cmp x26, C3_3c
	beq switch_C3_3
cmp x26, C3_3d
	beq switch_C3_3
cmp x26, C3_2a
	beq switch_C3_2
cmp x26, C3_2b
	beq switch_C3_2


b notfound
switch_C3_2:
	mov x26, #0
	bfm x26,x25, #22, #31
	cmp x26, C3_2_4
		beq switch_C3_2_4
	lsr x26, x26, #2
	cmp x26, C3_2_4
		beq switch_C3_2_3
	lsr x26, x26, #1
	cmp x26, C3_2_2
		beq switch_C3_2_2
	cmp x26, C3_2_7
		beq switch_C3_2_7

	mov x26, #0
	bfm x26,x25, #25, #30
	cmp x26, C3_2_5
 		beq switch_C3_2_5
	cmp x26, C3_2_1
 		beq switch_C3_2_1

	// if none of the above, must be C3_2_6
	mov x26, #0
	bfm x26,x25, #26, #30
	cmp x26, C3_2_6
		b switch_C3_2_6


	switch_C3_2_1: // Compare & branch (immediate)
	switch_C3_2_2: // Condition branch (immediate)
	switch_C3_2_3: // Exception
	switch_C3_2_4: // System
	switch_C3_2_5: // Test & Branch (immediate)
	switch_C3_2_6: // Test & Branch (immediate)
	mov x26, #0
	bfm x26,x25, #26, #31
	cmp x26, C3_2_6a
 		beq switch_C3_2_6a
	cmp x26, C3_2_6b
 		beq switch_C3_2_6b
	m_fputs found_c32
	b endloop
	switch_C3_2_6a:
	m_fputs mnemonics_b
	mov x27, #0
	mov x28, #25
	bl imm2rel
	m_printregh x26
	m_fputs newline
	b endloop
	switch_C3_2_6b:
	m_fputs mnemonics_bl
	mov x27, #0
	mov x28, #25
	bl imm2rel
	m_printregh x26
	m_fputs newline
	b endloop

	switch_C3_2_7: // Unconditional branch (register)
	b notfound
	b endloop

switch_C3_3: // C3.3 Loads and stores
	mov x26, #0
	bfm x26,x25, #24, #29
	cmp x26, C3_3_5a
 		beq switch_C3_3_5
	cmp x26, C3_3_5b
 		beq switch_C3_3_5
	b notfound
	switch_C3_3_5:
	mov x26, #0
	bfm x26,x25, #24, #31
	cmp x26, 0b01011000
		beq C3_3_5_ldr64

	b notfound
	C3_3_5_ldr64:
	m_fputs mnemonics_ldr

// TODO:	bl parse_rt:
	m_fputs ascii_x
	and x1,x25, 0x1F // 1F = 11111 -> five bits for register
	m_printregi x1 // register 31 should be called xxr, not x31!. See p. 115
	m_fputs commaspace
	mov x27, #5
	mov x28, #19
	bl imm2rel
	m_printregh x26
	m_fputs newline
	b endloop

		b endloop

	b notfound

switch_C3_4:
	m_fputs found_c34
	// movz and aliases! - D2 80  = 110100101 -> movz
	b endloop
switch_C3_5:
	m_fputs found_c35
	b endloop
switch_C3_6:
	m_fputs found_c36
	b endloop

b endloop


notfound:
m_fputs notfoundstr
endloop:
	add x21, x21, 0x04 // increase iterator
	b disassemble


found_c32: .asciz "C32!\n"
found_c33: .asciz "C33!\n"
found_c34: .asciz "C34!\n"
found_c35: .asciz "C35!\n"
found_c36: .asciz "C35!\n"
notfoundstr: .asciz "Unknown opcode!\n"
commaspace: .asciz ", "
ascii_x: .asciz "x"
mnemonics_ldr: .asciz "ldr "
mnemonics_b: .asciz "b "
mnemonics_bl: .asciz "bl "

