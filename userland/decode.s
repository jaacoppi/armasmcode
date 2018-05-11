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


// get the immediate value and convert it to a relative value
// most often this is used for memory addressing, jumps etc
// registers:
// x21 = program counter
// x25 = instruction
// x26 = output result
// x27 = input: starting bit
// x28 = input: how many bits
imm2rel:
	lsr x26, x25, x27	// move to 0 bit (TODO: assuming a value for x27..)
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
// copy  bits 31-25 of x25 to x26
mov x26, #0
ubfx x26,x25, #24, #31

// loop known opcodes in x27, compare with current opcode
ldr x28, =opcode_start
loop_opcodes:
ldrb w27, [x28]
and x29, x26, x27
cmp x29, x27
	bne loop_next_opcode //remember byte align 4
	// print mnemonic
	add x28, x28, #4
	mov x0, x28
	bl fputs
	// find and print first operand
	add x28, x28, #4
	ldr x29, [x28]
	lsr x29, x29, #8
	cmp x29, #0	// no more operands
		beq phase2
	cmp x29, reg64
		bne phase2
		m_fputs ascii_x
		// next byte has the starting bit
		add x28, x28, #4
		mov x29, x25 	// opcode to be masked
		ldrb w28, [x28]  // starting bit
		lsl x29, x29, x28 // move starting bit to be 0
		mov x27, 0x0000001F // mask bits 0-4, reg64 is always 5 bits (31-5)
		and x29, x29, x27
		m_printregi x29
		m_fputs commaspace

	b phase2
loop_next_opcode: // compare to next opcode if we haven't loop them all yet
add x28, x28, #19	// TODO: use equiv or something for the size of the struct
ldr x27, =opcode_finish

cmp x27, x28
	blt phase2
	add x27, x27, #128
	b loop_opcodes

phase2: //TODO: what is phase2 exactly?

m_fputs newline
endloop:
	add x21, x21, 0x04 // increase iterator
	b disassemble // TODO: ret should be enough, remember to push link






// ARMV8-A Architecture reference manual, chapter C3 Instruction set encoding
// from Table C3-1 A64 main encoding table

// opcode struct
// TODO: don't use padding (see decode())
.macro m_opcode opcode mnemonic operand_type startbit
	.int \opcode
	.asciz "\mnemonic"
	.byte \operand_type
	.byte \startbit
	.space 8
.endm

// operand types
.equiv reg64, 0x10	// 64bit register, 5 bits of opcode
.equiv imm19, 0x20

.data
opcode_start: // supportedopcodes are listed here
m_opcode 0b01011000,  "ldr ", reg64, 0	//3.3.5 Load register (literal)
m_opcode 0b10010100,  "bl  ", 0, 0	// 3.2.6
m_opcode 0b00000000,  "NOT IMPLEMENTED"	// NOT FOUND -> NOT IMPLEMENTED. DISPLAY ERROR
opcode_finish:

// strings
commaspace: .asciz ", "
ascii_x: .asciz "x"


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
