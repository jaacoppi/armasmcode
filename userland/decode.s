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

// decode an opcode and print it
// registers:
// x25 (input) = opcode to be decoded
// x9 = index to array of opcode_s structs
// x10 = index to struct opcode_s
// x11: 0 = don't print ", " before this operand, 1 = print it
// x12 = hold bitmask of registers
//  x13, x14, x15  = temp
decode:
	m_callPrologue
	mov x11, #0	// reset boolean print_commaspace

	// go through a series of switches to find the right opcode

	// loop known opcodes in x10, compare with current opcode
	ldr x9, =opcode_start
	loop_opcodes:
	// bitmask the relevant 32 bits
	mov x10, x9
	ldr x14, [x10]
	mov w14, w14
	and x13, x14, x25
	// compare to our table
	add x10, x10, #4
	ldr x14, [x10]
	mov w14, w14
	cmp x13, x14
		bne loop_next_opcode
	// Found a matching opcode
	// print mnemonic
	add x10, x10, #4 // TODO: is this assuming a 4 byte int size?)
	mov x0, x10
	bl fputs
	// find and print first operand and value
	add x10, x10, #4
	loop_operands:
	mov x12, #0	// reset temp
	add x10, x10, #1
	ldrb w15, [x10]
	cmp x15, #0	// no more operands
		beq endloop

	cmp x15, cond	// conditional
		bne try_registers
		add x10, x10, #1
		mov x14, 0x0000000F // mask bits 0-3
		bl mask_value
		// ascii value for condition is in =conditions + cond*3
		mov x14, #3
		mul x15, x15, x14
		ldr x14, =conditions
		add x0, x14, x15
		bl fputs
		ldr x0, =space
		bl fputs
		b loop_operands
	try_registers:
	cmp x15, reg32
		bgt try_imms
	parse_register:
	and x12, x15, #3	// the last nibble contains info about the register
				//	bit 0: 32bit(w) = 0, 64bit(x) = 1
				//	bit 1: not a pointer = 0 , pointer = 1
	try_reg64:
		// next byte has the starting bit, mask it
		add x10, x10, #1
		mov x14, 0x0000001F // mask bits 0-4, reg64 is always 5 bits (bits 0-4)
		bl mask_value

		// print ", " if needed
		bl print_commaspace
		mov x11, #1
		// print the register value (currently assumes it's simply x. TODO: handle w and others
		and x13, x12, #2
		cmp x13, #2
			ldr x13, =ascii_x
			ldr x14, =ascii_w
			csel x13, x13, x14, ne
		and x12, x12, #1
		cmp x12, #1
			bne reg_nonptr
			beq reg_ptr
			reg_nonptr:
				mov x0, x13
				bl fputs
//				m_fputs ascii_x
				m_printregi x15
				b loop_operands
			reg_ptr:
				m_fputs ascii_squarebr_open
				cmp x15, #31		// print sp instead of x31, otherwise use the numbers
					bne printreg
					m_fputs ascii_sp
					b cont2
				printreg:
				m_fputs ascii_x
					m_printregi x15
				cont2:
				m_fputs ascii_squarebr_close

				b loop_operands

		b loop_operands

	try_imms:
// TODO: if post index offset is #0, don't show it
	cmp x15, codes_imm
		blt endloop	// last known operand, end loop
	cmp x15, codes_imm_abs	// set x12 whether or not to use imm2rel
	cset x12, ge	// #1 = absolute, #0 = relative

	cmp x12, #1	// if absolute, use x10 as temp to convert abs to rel so the rest of the logic finds them
	sub x14, x15, imm_abs
	csel x15, x14, x15, eq

		// next byte has the starting bit, mask it with amount of bits in immXX
		add x10, x10, #1
		try_imm9:
		cmp x15, imm9
			bne try_imm12
			mov x14, 0x01FF // mask bits 0-8
			b found_bits
		try_imm12:
		cmp x15, imm12
			bne try_imm16
			mov x14, 0x0FFF // mask bits 0-11
			b found_bits
		try_imm16:
		cmp x15, imm16
			bne try_imm19
			mov x14, 0xFFFF // mask bits 0-15
			b found_bits
		try_imm19:
		cmp x15, imm19
			bne try_imm26
			mov x14, 0x0007FFFF // mask bits 0-18
			b found_bits
		try_imm26:
		cmp x15, imm26
			bne try_imm26	// TODO: fix this infinite loop
			mov x14, 0x3FFFFFF // mask bits 0-25
			b found_bits
		found_bits:
		bl mask_value
		cmp x12, #0
			bne imm2rel_ok
			imm2rel:
			// based on an imm value, get absolute value (program counter + imm*4)
			// most often this is used for memory addressing, jumps etc
			lsl x15, x15, #2	// lsl #2 equals x * 4
			add x15, x15, x21	// x21 = program counter
		imm2rel_ok:
		// print the register value (currently assumes it's simply x. TODO: handle w and others
		bl print_commaspace
		m_printregh x15
		b endloop

	loop_next_opcode: // compare to next opcode if we haven't loop them all yet
	add x9, x9, opcode_s
	ldr x14, =opcode_finish
	cmp x14, x9
		ble unimplemented
	b loop_opcodes

	unimplemented:
		m_fputs unimplemented_str
		b endloop

	endloop:
	m_fputs newline
	m_callEpilogue
	ret



// mask a value at x10 with bitmask in x14
// note that this doesn't follow register conventions, supposed to be called inside decode()
// x10 (input) = pointer to starting 64 bits
// x14 (input) = bitmask
// x25 (input) = opcode
// x15 (output) = value
// x13 = temp
mask_value:
	mov x15, x25 	// opcode to be masked
	ldrb w13, [x10]  // starting bit
	lsr x15, x15, x13 // move starting bit to be 0
	and x15, x15, x14

	ret // note we haven't pushed the link register..



// print ", " if the previous operand requires it
// basically, if it was a register
// x11 = holds the value, 1 = print, 0 = don't print
print_commaspace:
	m_pushlink
	cmp x11, #1	// print commaspace if needed
		bne cont
		mov x11, #0
		m_fputs commaspace
	cont:
	m_poplink
	ret

// ARMV8-A Architecture reference manual, chapter C3 Instruction set encoding
// from Table C3-1 A64 main encoding table

// opcode struct
.macro m_opcode bitmask opcode mnemonic operand1_type startbit1 operand2_type startbit2 operand3_type startbit3
	.word \bitmask		// bits used by the opcode
	.int \opcode		// values of bits in bitmask
	.asciz "\mnemonic"
	.byte \operand1_type	// leftmost operand
	.byte \startbit1	// startbit of the leftmost operand
	.byte \operand2_type	// next operand..
	.byte \startbit2
	.byte \operand3_type	// next operand..
	.byte \startbit3
.endm

// operand types
.equiv cond, 0x1	// conditional, 4 bits

.equiv reg64, 0x10	// 64bit register "x0", 5 bits of opcode
.equiv reg64_ptr, 0x11	// 64bit register pointer "[x0]", 5 bits of opcode
.equiv reg32, 0x12	// 32bit register "w0", 5 bits of opcode

.equiv codes_imm, imm9
.equiv imm9, 0x20
.equiv imm12, 0x21
.equiv imm16, 0x22
.equiv imm19, 0x23
.equiv imm26, 0x24
.equiv codes_imm_abs, imm9_abs
.equiv imm_abs, 0x8	// if less than 0x28, use imm2rel to get the relative memory address
.equiv imm9_abs, imm9 + imm_abs // if more, use the immediate value as it is
.equiv imm12_abs, imm12 + imm_abs // if more, use the immediate value as it is
.equiv imm16_abs, imm16 + imm_abs // if more, use the immediate value as it is
.equiv imm19_abs, imm19 + imm_abs
.equiv imm26_abs, imm26 + imm_abs

.data
// C1.1 Condition table
// 3-byte Null terminated strings, use conditions + value*3 to find out the correct offset
conditions:
.asciz "eq"
.asciz "ne"
.asciz "cs"
.asciz "cc"
.asciz "mi"
.asciz "pl"
.asciz "vs"
.asciz "vc"
.asciz "hi"
.asciz "ls"
.asciz "ge"
.asciz "lt"
.asciz "gt"
.asciz "le"
.asciz "al"

// strings
unimplemented_str: .asciz "Unimplemented opcode"
commaspace: .asciz ", "
ascii_x: .asciz "x"
ascii_w: .asciz "w"
ascii_sp: .asciz "sp"
ascii_squarebr_open: .asciz "["
ascii_squarebr_close: .asciz "]"

opcode_start: // supported opcodes are listed here

// First opcode gives us the size of the struct.
opcodestruct_start:
m_opcode 0xFF000000, 0x58000000,  "ldr ", reg64, 0, imm19, 5, 0, 0	//3.3.5 Load register (literal)
opcodestruct_finish:
.equiv opcode_s, opcodestruct_finish - opcodestruct_start

// rest of opcodes
m_opcode 0xFFE00000, 0x8B000000,  "add ", reg64, 0, reg64, 5, reg64, 16	// 5.6.5 ADD (shifted register). TODO: shift
m_opcode 0xFF000000, 0x10000000,  "adr ", reg64, 0, imm19, 5,0, 0	// 5.6.9 ADR. TODO: recognise immhi:immlo instead of imm19
m_opcode 0xFF000010, 0x54000000,  "b.\0\0", cond, 0, imm19, 5, 0, 0	// 5.6.19 B.cond
m_opcode 0xFFE00400, 0xF8400400,  "ldr ", reg64, 0, reg64_ptr, 5, imm9_abs, 12	// 5.6.83 LDR (immediate), post index variant
m_opcode 0xFFC00400, 0xF9400000,  "ldr ", reg64, 0, reg64_ptr, 5, 0, 0	// 5.6.83 LDR (immediate), immediate offset variant. TODO: offset like "ldr x0, [x1, offset]"
m_opcode 0xFFC00400, 0x39400000,  "ldrb", reg32, 0, reg64_ptr, 5, 0, 0	// 5.6.86 LDRB (immediate), no index variant
m_opcode 0xFC000000, 0x94000000,  "bl  ", imm26, 0, 0, 0, 0, 0	// 3.2.6
m_opcode 0xFC000000, 0x14000000,  "b   ", imm26, 0, 0, 0, 0, 0	// 3.2.6
m_opcode 0xFF00001F, 0xB100001F,  "cmn ", reg64, 5, imm12_abs, 10, 0, 0 // 5.6.42. This is ADDS, but alias to cmn.
m_opcode 0xF100001F, 0x7100001F,  "cmp ", reg32, 5, imm12_abs, 10, 0, 0 // 5.6.45. This is SUBS, but alias to cmp. 32 bit variant
m_opcode 0xF100001F, 0xF100001F,  "cmp ", reg64, 5, imm12_abs, 10, 0, 0 // 5.6.45. This is SUBS, but alias to cmp. 64 bit variant
m_opcode 0xFF00001F, 0xEB00001F,  "cmp ", reg64, 5, reg64, 16, 0, 0 // 5.6.46. This is SUBS, but alias to cmp. 64 bit variant
m_opcode 0xFFE0FC00, 0x9B007C00,  "mul ", reg64, 0, reg64, 5, reg64, 16 	// 5.6.119. This is MADD, but alias to muk.
m_opcode 0xFFE00000, 0xD2800000,  "mov ", reg64, 0, imm16_abs, 5, 0, 0 	// 5.6.123. This is MOVZ, but alias to mov. TODO: 32/64bit, shift
m_opcode 0xFF0003E0, 0xAA0003E0,  "mov ", reg64, 0, reg64, 16, 0, 0 	// 5.6.142. This is ORR, but alias to mov. TODO: 32/64bit, shift
opcode_finish:
