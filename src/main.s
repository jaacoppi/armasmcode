// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: main.s
// Main program flow

.include "include/macros.s"
.include "include/globals.s"
.align word_s	// all instructions are word aligned.
// global functions in this file:
.global _start
.global newline
.global STACK_TOP
.global STACK_BASE

.text
_start:
	bl stack_init
	bl stack_msg
	bl kheap_init

// try out memory functions
	bl kmalloc
	bl kfree
	bl kmalloc
	bl kmalloc
	bl kmalloc
	bl freemem
	mov x0, #0
	bl exit
// this is here just in case
halt:
	b halt


// set up stack
stack_init:
	ldr x0, =STACK_TOP
	mov sp, x0 // set stack at stack_start
	mov x29, #0 // set frame pointer to 0 - TODO: understand
	ret

// we want to print this after the copyright notice so it's not in stack_init
// print out stack location and size
stack_msg:
	m_prints stackaddrmsg
	// m_printregh only accepts x registers, not sp
	mov x0, sp
	m_printregh x0
	m_prints newline
	m_prints stacksizemsg
	mov x0, STACK_SIZE
	m_printregh x0
	m_prints newline
	ret

.data
copyright: .asciz "Copyright 2015 Juho Hiltunen (jaacoppi)\n"
// if we don't want to use strlen, we can get const string length like this:
// copyright_len = . - copyright // copyright_len is chars (bytes) between here and copyright:
newline: .asciz "\n"
stackaddrmsg: .asciz "Stack address: "
stacksizemsg: .asciz "Stack size: "

// reserve stacksize bytes for the stack starting from stack_base
// TODO: use a linker script to store this in a known address
.bss
// TODO: use a linker script to relocate STACK
// TODO: stack protection with paging
.equiv STACK_SIZE, 0x1000
STACK_BASE:
.space STACK_SIZE
STACK_TOP:
.word 0x1	// here's our stack
