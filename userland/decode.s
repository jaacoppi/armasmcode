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

decode:
	m_callPrologue

	add x20, x20, 0x5 // reset memmory pointer

	// go through a series of switches to find the right opcode
	// copy  bits 31-25 of x25 to x9
	mov x9, #0
	ubfx x9,x25, #24, #31

	// loop known opcodes in x10, compare with current opcode
	ldr x13, =opcode_start
	loop_opcodes:
	mov x11, x13
	ldrb w10, [x11]
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
		m_fputs ascii_x
		m_printregi x12
		m_fputs commaspace
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
		try_imm16:
		cmp x12, imm16
			bne try_imm19
			mov x10, 0xFFFF // mask bits 0-18
			b found_bits
		try_imm19:
		cmp x12, imm19
			bne try_imm26
			mov x10, 0x0007FFFF // mask bits 0-18
			b found_bits
		try_imm26:
		cmp x12, imm26
			bne try_imm26
			mov x10, 0x3FFFFFF // mask bits 0-26
			b found_bits
		found_bits:
		bl mask_value
		cmp x15, #0
			bne imm2rel_ok
			bl imm2rel
		imm2rel_ok:
		// print the register value (currently assumes it's simply x. TODO: handle w and others
		m_printregh x12
		b endloop

	next_byte:	// is this actually used anywhere?
	add x11, x11, #1
	b loop_operands

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



// ARMV8-A Architecture reference manual, chapter C3 Instruction set encoding
// from Table C3-1 A64 main encoding table

// opcode struct
// TODO: don't use padding (see decode())
//.macro m_opcode opcode mnemonic operand1_type startbit1 operand2_type startbit2
.macro m_opcode opcode mnemonic operand1_type startbit1 operand2_type startbit2
	.int \opcode
	.asciz "\mnemonic"
	.byte \operand1_type
	.byte \startbit1
	.byte \operand2_type
	.byte \startbit2
.endm
// operand types
.equiv reg64, 0x10	// 64bit register, 5 bits of opcode
.equiv codes_imm, imm16
.equiv imm16, 0x20
.equiv imm19, 0x21
.equiv imm26, 0x22
.equiv codes_imm_abs, imm16_abs
.equiv imm_abs, 0x8	// if less than 0x28, use imm2rel to get the relative memory address
.equiv imm16_abs, imm16 + imm_abs // if more, use the immediate value as it is
.equiv imm19_abs, imm19 + imm_abs
.equiv imm26_abs, imm26 + imm_abs

.data
// strings
unimplemented_str: .asciz "Unimplemented opcode"
commaspace: .asciz ", "
ascii_x: .asciz "x"



opcode_start: // supportedopcodes are listed here

// First opcode gives us the size of the struct.
opcodestruct_start:
m_opcode 0b01011000,  "ldr ", reg64, 0, imm19, 5	//3.3.5 Load register (literal)
opcodestruct_finish:
.equiv opcode_s, opcodestruct_finish - opcodestruct_start

// rest of opcodes
m_opcode 0b10010100,  "bl  ", imm26, 0, 0, 0	// 3.2.6
m_opcode 0b00010100,  "b   ", imm26, 0, 0, 0	// 3.2.6
m_opcode 0b10010010,  "mov ", reg64, 0, imm16_abs, 5	// 3. (move wide immediate, 64bit)
opcode_finish:

// THESE ALL ARE TO BE DELETED
//.equiv C3_2a,	     0xA
//.equiv C3_2b,	     0xB
//.equiv C3_2_1, 0b011010
//.equiv C3_2_2, 0b0101010
//.equiv C3_2_4, 0b1101010100
//.equiv C3_2_5, 0b011011
//.equiv C3_2_6, 0b00101
//.equiv C3_2_6a, 0b000101
//.equiv C3_2_6b, 0b100101
//.equiv C3_2_7, 0b1101011
.equiv C3_3a,       0x4
.equiv C3_3b,       0x6
.equiv C3_3c,       0xC
.equiv C3_3d,       0xE
	.equiv C3_3_6, 0x8
	.equiv C3_3_5a, 0x18
	.equiv C3_3_5b, 0x1C
.equiv C3_4a,       0x8
.equiv C3_4b,       0x9
.equiv C3_5a,       0x5
.equiv C3_5b,       0x13
// C 3.2 Branches, exception generating and system instructions
.equiv C3_2,	0b0001010
// C3.3 Loads and stores
.equiv C3_3,	0b0000100
// C3.4 Data processing - immediate
.equiv C3_4,	0b0001000
// C3.5 Data processing - register
.equiv C3_5,	0b0000100
// C3.6 Data processing - SIMD and floating point
.equiv C3_6,	0b0001111
