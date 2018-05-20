// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: macros.s
// Basic macros for speeding up development

.include "globals.s"
.align stack_align	// all instructions 8-byte (64bit) aligned

.ifndef MACROS	// only include once
.equiv MACROS, 1

.macro m_push reg
	str \reg, [sp, #-stack_align]!
.endm

.macro m_pop reg
	ldr \reg, [sp], #stack_align
.endm

// since it's difficult to remember that x30 is the link pointer
// used for returning from subroutine calls
// pushlink and poplink only target the link register
// callPrologue and callEpilogue push more registers
.macro m_pushlink
	str x30, [sp, #-stack_align]!
.endm
.macro m_poplink
	ldr x30, [sp], #stack_align
.endm
.macro m_callPrologue
	str x9, [sp, #-stack_align]!
	str x10, [sp, #-stack_align]!
	str x11, [sp, #-stack_align]!
	str x12, [sp, #-stack_align]!
	str x13, [sp, #-stack_align]!
	str x14, [sp, #-stack_align]!
	str x15, [sp, #-stack_align]!
	str x30, [sp, #-stack_align]!
.endm
.macro m_callEpilogue
	ldr x30, [sp], #stack_align
	ldr x15, [sp], #stack_align
	ldr x14, [sp], #stack_align
	ldr x13, [sp], #stack_align
	ldr x12, [sp], #stack_align
	ldr x11, [sp], #stack_align
	ldr x10, [sp], #stack_align
	ldr x9, [sp], #stack_align
.endm


// print macros

// call fputs
.macro m_fputs string
	ldr x0, =\string
	bl fputs
.endm

// print an int. Caveats: tmpstr length
.macro m_printi int
	m_callPrologue
	mov x0, #\int
	ldr x1, =tmpstr
	mov x2, #10
	bl itoa
	ldr x0, =tmpstr
	bl fputs
	m_callEpilogue
.endm

// print int as hex in the format 0xint. Caveats: tmpstr lengthh
.macro m_printh int
	m_callPrologue
	m_fputs hex1
	mov x0, #\int
	ldr x1, =tmpstr
	mov x2, #16
	bl itoa
	ldr x0, =tmpstr
	bl fputs
	m_callPrologue
.endm

// print any register (x0-x30) as hex

.macro m_printregi reg
	m_callPrologue
	mov x0, \reg
	ldr x1, =tmpstr
	mov x2, #10
	bl itoa
	ldr x0, =tmpstr
	bl fputs
	m_callEpilogue
.endm

.macro m_printregh reg
	m_callPrologue
	// push the register we're printing so m_fputs hex1 doesn't overwrite it
	str \reg, [sp, #-stack_align]!
	m_fputs hex1
	ldr \reg, [sp], #stack_align

	mov x0, \reg
	ldr x1, =tmpstr
	mov x2, #16
	bl itoa
	ldr x0, =tmpstr
	bl fputs
	m_callEpilogue
.endm

.macro m_memset string char count
	m_callPrologue
	ldr x0, =\string
	mov x1, \char
	mov x2, \count
	bl memset
	m_callEpilogue
.endm

.data
tmpstr: .asciz "0123456789ABCDEF"
hex1: .asciz "0x"
.endif
