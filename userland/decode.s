// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: decode.s
// Disassembler for 64 bit ARM (ARMv8 / Aarch64)

.include "macros.s"
.include "globals.s"
.include "fcntl.s"
.include "fs.s"

.global decode
.balign 4
.text

// decode an opcode and print it
// registers:
// x25 (input) = opcode to be decoded
// x9 = index to array of opcode_s structs
// x10 = index to struct opcode_s
// x11: 0 = don't print ", " before this operand, 1 = print it
// x12 = hold bitmask of registers
//  x13, x14, x15  = temp
// x16 = pre index mode on/off (print [x0, #imm] instead of [x0], #imm
decode:
	m_callPrologue
	m_push x16
	mov x16, #0
	mov x11, #0	// reset boolean print_commaspace

	// loop known opcodes in x10, compare with current opcode
	ldr x9, =opcode_start
	loop_opcodes:
	// bitmask the relevant 32 bits
	mov x10, x9
	ldr x14, [x10]
	mov w14, w14	// see if you can combine ldr & mov here
	and x13, x14, x25
	// compare to our table
	add x10, x10, #4
	ldr x14, [x10]
	mov w14, w14
	cmp x13, x14
		bne loop_next_opcode
	// Found a matching opcode
	// print mnemonic followed by a space (unless this is a conditional)
	add x10, x10, #4

	// exception: if the mnemonic is ubfm, see if we want lsl instead
	ldr w13, [x10]	// TODO: register usage to avoid doing this ldr for each loop
	ldr x14, =lsl_alias_str
	ldr w14, [x14]
	cmp x13, x14
		bne not_lsl
		// ubfm 5.6.212 is alias to LSL when imms != '111111' && imms + 1 == immr (NOTE: this is64bit)
		ubfm x13, x25, #10, #15
		mov x14, 0b111111
		cmp x13, x14
			beq not_lsl
		ubfm x14, x25, #16, #21

		add x13, x13, #1
		cmp x13, x14
			bne not_lsl
		// checks failed, this is LSL. Point to a special opcode that wouldn't be looped otherwise
		ldr x9, =alias_lsl
		b loop_opcodes

	not_lsl:	// handle all other opcodes. TODO: rename
	mov x0, x10
	bl fputs
	add x10, x10, #4	// advance pointer to the last char of the mnenomic

	add x12, x10, #1	// take a peek at the next byte. If it's a conditional, don't print a space
	ldrb w12, [x12]		// TODO: combine add+ldrb into one ldrb with offset
	cmp x12, cond
		beq loop_operands
		m_fputs space

	loop_operands:
	mov x12, #0	// reset temp
	add x10, x10, #1
	ldrb w15, [x10]
	cmp x15, #0	// no more operands
		beq endloop

	cmp x15, cond_invlsb	// conditionals
		bgt try_registers
		add x10, x10, #1
		mov x14, 0x0000000F // mask bits 0-3
		m_push x15
		bl mask_value
		m_pop x14
		cmp x14, cond_invlsb	// invert lsb if using cond_invlsb, not if using cond
			bne doneinvert
			mov x14, #1
			eor x15, x15, x14
		doneinvert:
		// ascii value for condition is in =conditions + cond*3
		mov x14, #3
		mul x15, x15, x14
		ldr x14, =conditions
		add x0, x14, x15

		// print ", " if needed
		cmp x11, #0
			bne commaspace_cond
			bl fputs
			m_fputs space
			b loop_operands
		commaspace_cond:
		m_push x0
		bl print_commaspace
		mov x11, #1
		m_pop x0
		bl fputs


		b loop_operands


	try_registers:
	cmp x15, last_register
		bgt try_imms
	parse_register:
	and x12, x15, 0b111	// the last nibble contains info about the register
				//	bit 0: 32bit(w) = 0, 64bit(x) = 1
				//	bit 1: not a pointer = 0 , pointer = 1
				//	bit 2: pre index
	try_reg64:
		// next byte has the starting bit, mask it
		add x10, x10, #1
		mov x14, 0x0000001F // mask bits 0-4, reg64 is always 5 bits (bits 0-4)
		bl mask_value

		// print ", " if needed
		bl print_commaspace
		mov x11, #1

		// process the bitmap and print the register value
		// bit 2 stores pre index variant
		and x13, x12, #4
		mov x14, #0
		cmp x13, #4
		cset x14, eq
		m_push x14	// push x14 boolean

		and x13, x12, #2
		cmp x13, #2	// bit 1 stores w/x
			ldr x13, =ascii_x
			ldr x14, =ascii_w
			csel x13, x13, x14, ne
		and x12, x12, #1 // bit 0 stores ptr/nonptr
		cmp x12, #1
			bne reg_nonptr
			beq reg_ptr
			reg_nonptr:	// normal register, just print
				mov x0, x13
				bl fputs
				m_printregi x15
				m_pop x14	// not needed, pop to keep stack in order
				b loop_operands
			reg_ptr:
				m_fputs ascii_squarebr_open
				cmp x15, #31		// print sp instead of x31, otherwise use the numbers
					bne printreg
					m_fputs ascii_sp
					b check_preindex
				printreg:
				m_fputs ascii_x
				m_printregi x15

			check_preindex:
			// if this is a preindexed version, print the value first, close bracket later
			m_pop x14
			cmp x14, #1
				bne no_preindex
				mov x16, #1
				b loop_operands
			// for preindexed registers, set boolean x16
			// if next operand is immediate (it should be), it prints the value  and returns to yes_preindex, resetting x16
			yes_preindex:
				m_fputs ascii_squarebr_close
				m_fputs ascii_exclamation // TODO: call this writeback
				mov x16, #0
				b loop_operands
			no_preindex:	// exit as normal
				m_fputs ascii_squarebr_close
				b loop_operands

		b loop_operands

	try_imms:
	// Immediates can be signed or unsigned, relative or absolute. Find the proper value.
	cmp x15, last_imm
		bgt try_bitmask_imm

	// set x12 whether or not to use imm2rel
	rel_or_abs:
	cmp x15, codes_imm_abs
	cset x12, ge	// #1 = absolute, #0 = relative

	// convert x15 from immX_abs to imm so the rest of the logic finds them
	cmp x12, #1
	sub x14, x15, imm_abs
	csel x15, x14, x15, eq

		// next byte has the starting bit, mask it with amount of bits in immXX
		add x10, x10, #1
		try_imm6:
		cmp x15, imm6
			bne try_simm6_minus63
			mov x14, 0x3F
			b found_bits
		try_simm6_minus63:
		cmp x15, simm6_minus63
			bne try_simm9
			mov x14, 0x03F // mask bits 0-5
			b found_bits
		try_simm9:
		cmp x15, simm9
			bne try_imm9
			mov x14, 0x01FF // mask bits 0-8
			b found_bits
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
		m_push x15	// TODO: better register usage to avoid push/pop

		// print the register value
		bl mask_value

		bl print_commaspace
		mov x11, #1


		// handle negative absolute values (relatives don't need special treatment:
		// if type is simm9 and value gt 0x100 it's a negative in two's complement
		// if negative, xor with 1FF and add 1 to get the absolute value
		m_pop x14 // pop what used to be in x15 - operand byte from opcode_s

		cmp x14, simm6_minus63	// special case used for UBFM/LSL
			bne neg_simm9
			mov x14, #63
			sub x15, x14, x15
			b unsigned	// TODO.. or is jumping to imm2rel_ok enough?

		neg_simm9:
		cmp x14, simm9	// TODO: this would handle relatives also since _abs is stripped earlier
			bne unsigned
			cmp x15, 0x100
				ble unsigned
				eor x15, x15, 0x1FF	// remember, xor is eor (exclusive or) in arm
				add x15, x15, #1
				m_fputs ascii_minus

		unsigned: // the sign has been dealt with, print the value
		cmp x12, #0
			bne imm2rel_ok
			imm2rel:
			// based on an imm value, get absolute value (program counter + imm*4)
			// most often this is used for memory addressing, jumps etc
			lsl x15, x15, #2	// lsl #2 equals x * 4
			add x15, x15, x21	// x21 = program counter
		imm2rel_ok:
		m_printregh x15

		// x16 holds the preindex setting
		cmp x16, #1
			beq yes_preindex

		b loop_operands

	try_bitmask_imm:
	cmp x15, bitmask_imm
		bne try_unalloc
		// bitmask immediate in the forms of N:immr:imms
		// the pseudocode is in DecodeBitMasks, but we do a brute force / table lookup
		add x10, x10, #1
		mov x14, 0x001FFF // mask bits 0-12
		bl mask_value
		ldr x12, =bitmask_immediates
		bitmaskloop:
			ldrh w13, [x12],#2 // .hword
			mov x14, 0xFFFF
			cmp x13, x14
				beq unimplemented_bitmask_imm

			ldr w14, [x12], #4 // .word
			cmp x15, x13
				bne bitmaskloop

			// found the right bitmask, print it
			m_fputs commaspace
			m_printregh x14
			b loop_operands

		unimplemented_bitmask_imm:
			m_fputs space
			m_fputs unimplemented_bitmask_str
			m_fputs space
			m_printregh x15
			b loop_operands

	try_unalloc:
	cmp x15, unallocated
		bne endloop	// last known opcode
		m_fputs unallocated_str
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
	m_pop x16
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
	// TODO: could we simplify this with an ubfm x15, x15, x13, x14 or something?
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
lsl_alias_str: .asciz "ubfm"
unimplemented_str: .asciz "Unimplemented opcode"
unallocated_str: .asciz "Unallocated opcode"
unimplemented_bitmask_str: .asciz "Unimplemented bitmask immediate"
commaspace: .asciz ", "
ascii_minus: .asciz "-"
ascii_exclamation: .asciz "!"
ascii_x: .asciz "x"
ascii_w: .asciz "w"
ascii_sp: .asciz "sp"
ascii_squarebr_open: .asciz "["
ascii_squarebr_close: .asciz "]"


// operand types
.equiv cond, 0x1	// conditional, 4 bits
.equiv cond_invlsb, 0x2	// conditional, 4 bits, lsb is inverted

// pointer bitmap:
// b1 = regular vs pointer
// b10 = 32 vs 64
// b100 = pre index
.equiv reg64, 0x10	// 64bit register "x0", 5 bits of opcode
.equiv reg64_ptr, 0x11	// 64bit register pointer "[x0]", 5 bits of opcode
.equiv reg32, 0x12	// 32bit register "w0", 5 bits of opcode
.equiv reg64_preptr, 0x15	// 64bit register pointer "[x0]", 5 bits of opcode
.equiv last_register, reg64_preptr 	// for loop/switch control

.equiv imm6, 0x20
.equiv imm9, 0x21
.equiv imm12, 0x22
.equiv imm16, 0x23
.equiv imm19, 0x24
.equiv imm26, 0x25
.equiv simm6_minus63, 0x26
.equiv simm9, 0x27
.equiv codes_imm_abs, imm6_abs
.equiv imm_abs, 0x8	// if less than 0x28, use imm2rel to get the relative memory address
.equiv imm6_abs, imm6 + imm_abs // if more, use the immediate value as it is
.equiv imm9_abs, imm9 + imm_abs
.equiv imm12_abs, imm12 + imm_abs
.equiv imm16_abs, imm16 + imm_abs
.equiv imm19_abs, imm19 + imm_abs
.equiv imm26_abs, imm26 + imm_abs
.equiv simm6_minus63_abs, simm6_minus63 + imm_abs
.equiv simm9_abs, simm9 + imm_abs
.equiv last_imm, simm9_abs	// for loop/switch control
.equiv unallocated, 0x40
.equiv bitmask_imm, 0x50



// ARMV8-A Architecture reference manual, chapter C3 Instruction set encoding
// from Table C3-1 A64 main encoding table
// opcode struct
.macro m_opcode bitmask opcode mnemonic operand1_type startbit1 operand2_type startbit2 operand3_type startbit3 operand4_type startbit4
	.word \bitmask		// bits used by the opcode
	.int \opcode		// values of bits in bitmask
	.asciz "\mnemonic"
	.byte \operand1_type	// leftmost operand
	.byte \startbit1	// startbit of the leftmost operand
	.byte \operand2_type	// next operand..
	.byte \startbit2
	.byte \operand3_type	// next operand..
	.byte \startbit3
	.byte \operand4_type	// next operand..
	.byte \startbit4
.endm

opcode_start: // supported opcodes are listed here

opcodestruct_start:
m_opcode 0xFF000000, 0x58000000,  "ldr\0", reg64, 0, imm19, 5, 0, 0, 0, 0	//3.3.5 Load register (literal)
opcodestruct_finish:
// First opcode gives us the size of the struct.
.equiv opcode_s, opcodestruct_finish - opcodestruct_start

// rest of opcodes
m_opcode 0xFFE00000, 0x91000000,  "add\0", reg64, 0, reg64, 5, imm12_abs, 10, 0, 0 	// 5.6.5 ADD (immediate)
m_opcode 0xFFE00000, 0x8B000000,  "add\0", reg64, 0, reg64, 5, reg64, 16, 0, 0		// 5.6.5 ADD (shifted register). TODO: shift
m_opcode 0xFF000000, 0x10000000,  "adr\0", reg64, 0, imm19, 5,0, 0, 0, 0		// 5.6.9 ADR
m_opcode 0xFFC00000, 0x92400000,  "and\0", reg64, 0, reg64, 5, bitmask_imm, 10, 0, 0		// 5.6.11 AND (immediate)
m_opcode 0xFFE00000, 0x8A000000,  "and\0", reg64, 0, reg64, 5, reg64, 16, 0, 0		// 5.6.12 AND (shifted register). TODO: shift
m_opcode 0xFF000010, 0x54000000,  "b.\0\0", cond, 0, imm19, 5, 0, 0, 0, 0		// 5.6.19 B.cond
m_opcode 0xFC000000, 0x14000000,  "b\0\0\0", imm26, 0, 0, 0, 0, 0, 0, 0			// 5.6.20
m_opcode 0xFC000000, 0x94000000,  "bl\0\0", imm26, 0, 0, 0, 0, 0, 0, 0			// 5.6.26
m_opcode 0xFFE00C00, 0xF8000C00,  "str\0", reg64, 0, reg64_preptr, 5, simm9_abs, 12, 0, 0 // 5.6.178 STR, store register, immediate offset, pre-index
m_opcode 0xFFE00400, 0xF8400400,  "ldr\0", reg64, 0, reg64_ptr, 5, imm9_abs, 12, 0, 0	// 5.6.83 LDR (immediate), post index variant
m_opcode 0xFFC00400, 0xF9400000,  "ldr\0", reg64, 0, reg64_ptr, 5, 0, 0, 0, 0	// 5.6.83 LDR (immediate), immediate offset variant
m_opcode 0xFFC00400, 0xB9400000,  "ldr\0", reg32, 0, reg64_ptr, 5, 0, 0, 0,0 	// 5.6.83 LDR (immediate), immediate offset
m_opcode 0xFFC00400, 0xB8400400,  "ldr\0", reg32, 0, reg64_ptr, 5, imm9_abs, 12, 0,0 	// 5.6.83 LDR (immediate), post index variant
m_opcode 0xFFE00C00, 0x38400400,  "ldrb", reg32, 0, reg64_ptr, 5, simm9_abs, 12, 0, 0	// 5.6.86 LDRB (immediate), post index variant
m_opcode 0xFFE00C00, 0x38400C00,  "ldrb", reg32, 0, reg64_preptr, 5, simm9_abs, 12, 0, 0	// 5.6.86 LDRB (immediate), pre index variant
m_opcode 0xFFC00400, 0x39400000,  "ldrb", reg32, 0, reg64_ptr, 5, 0, 0, 0, 0	// 5.6.86 LDRB (immediate), no index variant
m_opcode 0xFFC00400, 0x78400400,  "ldrh", reg32, 0, reg64_ptr, 5, imm9_abs, 12, 0, 0	// 5.6.88 LDRH (immediate), post index
m_opcode 0xFF00001F, 0xB100001F,  "cmn\0", reg64, 5, imm12_abs, 10, 0, 0, 0, 0 // 5.6.42. This is ADDS, but alias to cmn.
m_opcode 0xF100001F, 0x7100001F,  "cmp\0", reg32, 5, imm12_abs, 10, 0, 0, 0, 0 // 5.6.45. This is SUBS, but alias to cmp. 32 bit variant
m_opcode 0xF100001F, 0xF100001F,  "cmp\0", reg64, 5, imm12_abs, 10, 0, 0, 0, 0 // 5.6.45. This is SUBS, but alias to cmp. 64 bit variant
m_opcode 0xFF00001F, 0xEB00001F,  "cmp\0", reg64, 5, reg64, 16, 0, 0, 0, 0	 // 5.6.46. This is SUBS, but alias to cmp. 64 bit variant
m_opcode 0xFFE00C00, 0x9A800000,  "csel", reg64, 0, reg64, 5, reg64, 16, cond, 12	 // 5.6.50 CSEL
m_opcode 0xFFFF0FE0, 0x9A9F07E0,  "cset", reg64, 0, cond_invlsb, 12, 0, 0, 0, 0	 // 5.6.51 CSET
m_opcode 0xFFE00000, 0xD2400000,  "eor\0", reg64, 0, reg64, 5, bitmask_imm, 10, 0, 0 	// 5.6.64 EOR (immediate)
m_opcode 0xFFE0FC00, 0xCA000000,  "eor\0", reg64, 0, reg64, 5, reg64, 16, 0, 0 	// 5.6.65 EOR (shifted register). TODO: shift
m_opcode 0xFFE0FC00, 0x9AC02400,  "lsr\0", reg64, 0, reg64, 5, reg64, 16, 0, 0	// 5.6.118 LSRV
m_opcode 0xFFE0FC00, 0x9B007C00,  "mul\0", reg64, 0, reg64, 5, reg64, 16, 0, 0 	// 5.6.119. This is MADD, but alias to muk.
m_opcode 0xFFE00000, 0xD2800000,  "mov\0", reg64, 0, imm16_abs, 5, 0, 0, 0, 0 	// 5.6.123. This is MOVZ, but alias to mov. TODO: 32/64bit, shift
m_opcode 0xFFE00000, 0xB2400000,  "mov\0", reg64, 0, bitmask_imm, 5, 0, 0, 0, 0 	// 5.6.124 MOV (bitmask immediate)
m_opcode 0xFFE08000, 0x9B008000,  "msub", reg64, 0, reg64, 5, reg64, 16, reg64, 10 	// 5.6.132 MSUB - multiply-subtract
m_opcode 0xFFE0FFE0, 0x2A0003E0,  "mov\0", reg32, 0, reg32, 16, 0, 0, 0, 0 	// 5.6.142. This is ORR, but alias to mov.
m_opcode 0xFF0003E0, 0xAA0003E0,  "mov\0", reg64, 0, reg64, 16, 0, 0, 0, 0 	// 5.6.142. This is ORR, but alias to mov.
m_opcode 0xD65F03C0, 0xD65F03C0,  "ret\0", 0, 0, 0, 0, 0, 0, 0, 0 	// 5.6.148. RET. This only handles x30 as the return address
m_opcode 0xFFE00C00, 0x39000000,  "strb", reg32, 0, reg64_ptr, 5, 0, 0, 0, 0	// 5.6.180 STRB (immediate), no index variant. TODO: add possibility to have an offset
m_opcode 0xFFE00C00, 0x38000400,  "strb", reg32, 0, reg64_ptr, 5, simm9_abs, 12, 0, 0	// 5.6.180 STRB (immediate), post index variant
m_opcode 0xFFC00000, 0xD1000000,  "sub\0", reg64, 0, reg64, 5, imm12_abs, 10, 0, 0	// 5.6.195 SUB (immediate)
m_opcode 0xFFE0FC00, 0xCB000000,  "sub\0", reg64, 0, reg64, 5, reg64, 16, 0, 0	// 5.6.196 SUB (shifted register). TODO: shift
// lsl is an alias to ubfm. The conditions is complicated so it's handled in code
m_opcode 0xFF800000, 0xD3000000,  "ubfm", reg64, 0, reg64, 5, imm6_abs, 16, imm6_abs, 10	// 5.6.212 UBFM, alias to LSL
m_opcode 0xFFE0FA00, 0x9AC00800,  "udiv", reg64, 0, reg64, 5, reg64, 16, 0, 0	// 5.6.214 UDIV (immediate)
m_opcode 0x18000000, 0x00000000,  "\0\0\0\0", unallocated, 0, 0, 0, 0, 0, 0, 0	// unallocated. TODO: search the symbol table
opcode_finish:

alias_lsl:
m_opcode 0xFF800000, 0xD3000000,  "lsl\0", reg64, 0, reg64, 5, simm6_minus63_abs, 10, 0, 0	// 5.6.114 LSL (alias of UBFM)

bitmask_immediates: // TODO: replace these with an implementation of DecodeBitmasks
.hword 0x1008
.word 0x1FF
.hword 0x33F
.word 0x3FFFFFF
.hword 0x25F
.word 0x7FFFF
.hword 0x1FC0
.word 2
.hword 0x1F80
.word 4
.hword 0x1002
.word 7
.hword 0x1000
.word 1
.hword 0xFFFF
.word 0
