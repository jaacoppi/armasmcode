// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: cat.s
// Read a file and print contents on screen

.include "../include/macros.s"
.include "../include/globals.s"
.include "../include/fcntl.s"
.align word_s	// all instructions are word aligned.
// global functions in this file:
.global _start
.global newline

// x19-x29 are callee saved register. We can safely use them here for:// x19-x29 are callee saved regist$
// x19 = file descriptor
// x20 = pointer to allocated memory
.text
_start:
	m_prints copyright
	m_prints newline
open:
	ldr x0, =filepath
	mov x1, O_RDONLY
	bl fopen
	cmp x0, #-1
		beq error_create
		bne success
success:
	mov x19, x0
	m_prints fileopened
	m_prints filepath
	m_prints newline
// since we don't have a usable malloc, use static memory in .bss
reservemem:
	ldr x20, =memarea

read:
	m_prints readingfile
	mov x0, x20	
	mov x1, #64	// read first 64 chars per element
	mov x2, #1	// read one element
	mov x3, x19
	bl fread
	cmp x0, #0
	beq error_read
display:
//	TODO: a memdump to see if read works
	// read from the memory address in x20
	// TODO: check for null termination of string by comparing the last char (x0) +1
	ldr x0, =memarea
	bl write

// we're done, restore the file pointer and close
close:
	mov x0, x19
	bl fclose
	cmp x0, #0
	bne error_close
	beq exit


// print a proper error string and exit
error_read:
	m_prints errorstr3
	b error
error_create:
	m_prints errorstr
	b error
error_close:
	m_prints errorstr2
	b error
error:
	m_prints filepath
	m_prints newline
	mov x0, #1
	b exit

.data
copyright: .asciz "Copyright 2015 Juho Hiltunen (jaacoppi)\n"
newline: .asciz "\n"
fileopened: .asciz "Opened file: "
readingfile: .asciz "File contents are:\n"
filepath: .asciz "filetest"
errorstr: .asciz "Error while opening file: "
errorstr2: .asciz "Error while closing file: "
errorstr3: .asciz "Error while reading file: "

.bss
memarea:	.space 0x1000
