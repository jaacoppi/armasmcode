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
.macro m_pushlink
	str x30, [sp, #-stack_align]!
.endm
.macro m_poplink
	ldr x30, [sp], #stack_align
.endm


// print macros

// print a string "string"
.macro m_prints string
	m_pushlink
	ldr x0, =\string
	bl write
	m_poplink
.endm

// print an int. Caveats: tmpstr length
.macro m_printi int
	m_pushlink
	mov x0, #\int
	ldr x1, =tmpstr
	mov x2, #10
	bl itoa
	ldr x0, =tmpstr
	bl write
	m_poplink
.endm

// print int as hex in the format 0xinth
.macro m_printh int
	m_pushlink
	m_prints hex1
	mov x0, #\int
	ldr x1, =tmpstr
	mov x2, #16
	bl itoa
	ldr x0, =tmpstr
	bl write
	m_prints hex2
	m_pushlink
.endm

// print any register (x0-x30) as hex

.macro m_printregi reg
	m_pushlink
	mov x0, \reg
	ldr x1, =tmpstr
	mov x2, #10
	bl itoa
	ldr x0, =tmpstr
	bl write
	m_poplink
.endm

.macro m_printregh reg
	m_pushlink
	// push the register we're printing so m_prints hex1 doesn't overwrite it
	str \reg, [sp, #-8]!
	m_prints hex1
	ldr \reg, [sp], #8
	mov x0, \reg
	ldr x1, =tmpstr
	mov x2, #16
	bl itoa
	ldr x0, =tmpstr
	bl write
	m_prints hex2
	m_poplink
.endm



.data
tmpstr: .asciz "0123456789"
hex1: .asciz "0x"
hex2: .asciz "h"
.endif
