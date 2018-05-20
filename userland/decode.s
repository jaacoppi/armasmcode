// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: decode.s
// Disassembler for 64 bit ARM (Aarch64)

.include "macros.s"
.include "globals.s"
.include "fcntl.s"
.include "fs.s"

.global decode
.balign 4

// based on an imm value, get absolute value (program counter + imm*4)
// most often this is used for memory addressing, jumps etc
// registers:
// x21 = program counter
// x12 (input) = immediate value
// x12 (output) = relative value
// x10 = temp
imm2rel:
	mov x10, #4
	mul x12, x12, x10
	add x12, x12, x21
	ret



// decode an opcode and print it
// registers:
// x25 (input) = opcode to be decoded
// x20 (input) = memory pointer
// x9, x10, x11, x12 = temp
// x13 = holds the starting address of an item in the opcode struct
// x14 = 0 = don't print ", " before this operand, 1 = print it
decode:
	m_callPrologue
	mov x14, #0	// reset boolean print_commaspace
	add x20, x20, 0x5 // reset memmory pointer. TODO: should this be here or in disarm64.s?

	// go through a series of switches to find the right opcode
	// copy  bits 31-25 of x25 to x9
	mov x9, #0
	ubfx x9,x25, #24, #31

	// loop known opcodes in x10, compare with current opcode
	ldr x13, =opcode_start
	loop_opcodes:
	// bitmask the relevant 32 bits
	mov x11, x13
	ldr x10, [x11]
	mov w10, w10
	and x9, x10, x25
	// compare to our table
	add x11, x11, #4
	ldr x10, [x11]
	mov w10, w10
	cmp x9, x10
		bne loop_next_opcode
	// Found a matching opcode
	// print mnemonic
	add x11, x11, #4 // TODO: is this assuming a 4 byte int size?)
	mov x0, x11
	bl fputs
	// find and print first operand and value
	add x11, x11, #4
	loop_operands:
	add x11, x11, #1
	ldrb w12, [x11]
	cmp x12, #0	// no more operands
		beq endloop
	try_reg64:
	cmp x12, reg64
		bne try_imms

		// next byte has the starting bit, mask it
		add x11, x11, #1
		mov x10, 0x0000001F // mask bits 0-4, reg64 is always 5 bits (bits 0-4)
		bl mask_value

		// print the register value (currently assumes it's simply x. TODO: handle w and others
		bl print_commaspace
		mov x14, #1
		m_fputs ascii_x
		m_printregi x12

		b loop_operands

	try_imms:
	cmp x12, codes_imm
		blt endloop	// last known operand, end loop
	cmp x12, codes_imm_abs	// set x15 whether or not to use imm2rel
		bge set_absolute
		blt set_relative

			set_absolute: // the immediate is an absolute value. Don't use imm2rel
				mov x15, #1
				sub x12, x12, imm_abs	// convert so the rest of the logic finds these
				b absrel_set
			set_relative: //  the immediate is relative to current program counter. use imm2rel
				mov x15, #0
				b absrel_set
		absrel_set:
		// next byte has the starting bit, mask it with amount of bits in immXX
		add x11, x11, #1
		try_imm12:
		cmp x12, imm12
			bne try_imm16
			mov x10, 0x0FFF // mask bits 0-11
			b found_bits
		try_imm16:
		cmp x12, imm16
			bne try_imm19
			mov x10, 0xFFFF // mask bits 0-15
			b found_bits
		try_imm19:
		cmp x12, imm19
			bne try_imm26
			mov x10, 0x0007FFFF // mask bits 0-18
			b found_bits
		try_imm26:
		cmp x12, imm26
			bne try_imm26	// TODO: fix this infinite loop
			mov x10, 0x3FFFFFF // mask bits 0-25
			b found_bits
		found_bits:
		bl mask_value
		cmp x15, #0
			bne imm2rel_ok
			bl imm2rel
		imm2rel_ok:
		// print the register value (currently assumes it's simply x. TODO: handle w and others
		bl print_commaspace
		m_printregh x12
		b endloop

	loop_next_opcode: // compare to next opcode if we haven't loop them all yet
	add x13, x13, opcode_s
	ldr x10, =opcode_finish
	cmp x10, x13
		ble unimplemented
	b loop_opcodes

	unimplemented:
		m_fputs unimplemented_str
		b endloop

	endloop:
	m_fputs newline
	m_callEpilogue
	ret



// mask a value starting at bit x11 with mask at x10
// note that this doesn't follow register conventions, supposed to be called inside decode()
// x10 (input) = bitmask
// x11 (input) = pointer to starting 64 bits
// x11 (output) = value of 1st byte of the 64 bits
// x25 (input) = opcode
// x12 (output) = value
// x14 = temp, restored
mask_value:
	m_push x14
	mov x12, x25 	// opcode to be masked
	ldrb w14, [x11]  // starting bit
	lsr x12, x12, x14 // move starting bit to be 0
	and x12, x12, x10

	m_pop x14
	ret // note we haven't pushed the link register..



// print ", " if the previous operand requires it
// basically, if it was a register
// x14 = holds the value, 1 = print, 0 = don't print
print_commaspace:
	m_pushlink
	cmp x14, #1	// print commaspace if needed
		bne cont
		mov x14, #0
		m_fputs commaspace
	cont:
	m_poplink
	ret

// ARMV8-A Architecture reference manual, chapter C3 Instruction set encoding
// from Table C3-1 A64 main encoding table

// opcode struct
.macro m_opcode bitmask opcode mnemonic operand1_type startbit1 operand2_type startbit2
	.word \bitmask		// bits used by the opcode
	.int \opcode		// values of bits in bitmask
	.asciz "\mnemonic"
	.byte \operand1_type	// leftmost operand
	.byte \startbit1	// startbit of the leftmost operand
	.byte \operand2_type	// next operand..
	.byte \startbit2
.endm

// operand types
.equiv reg64, 0x10	// 64bit register, 5 bits of opcode
.equiv codes_imm, imm12
.equiv imm12, 0x20
.equiv imm16, 0x21
.equiv imm19, 0x22
.equiv imm26, 0x23
.equiv codes_imm_abs, imm12_abs
.equiv imm_abs, 0x8	// if less than 0x28, use imm2rel to get the relative memory address
.equiv imm12_abs, imm12 + imm_abs // if more, use the immediate value as it is
.equiv imm16_abs, imm16 + imm_abs // if more, use the immediate value as it is
.equiv imm19_abs, imm19 + imm_abs
.equiv imm26_abs, imm26 + imm_abs

.data
// strings
unimplemented_str: .asciz "Unimplemented opcode"
commaspace: .asciz ", "
ascii_x: .asciz "x"

opcode_start: // supported opcodes are listed here

// First opcode gives us the size of the struct.
opcodestruct_start:
m_opcode 0xFF000000, 0x58000000,  "ldr ", reg64, 0, imm19, 5	//3.3.5 Load register (literal)
opcodestruct_finish:
.equiv opcode_s, opcodestruct_finish - opcodestruct_start

// rest of opcodes
m_opcode 0xFC000000, 0x94000000,  "bl  ", imm26, 0, 0, 0	// 3.2.6
m_opcode 0xFC000000, 0x14000000,  "b   ", imm26, 0, 0, 0	// 3.2.6
m_opcode 0xF100001F, 0xF100001F,  "cmp ", reg64, 5, imm12_abs, 10 // 5.6.45. This is SUBZ, but alias to cmp. TODO: 32/64bit, shift
m_opcode 0xFF0003E0, 0xAA0003E0,  "mov ", reg64, 0, reg64, 16 	// 5.6.142. This is ORR, but alias to cmp. TODO: 32/64bit, shift
opcode_finish:
