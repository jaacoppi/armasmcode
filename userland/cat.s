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

// x19-x29 are callee saved register. We can safely use them here for:
// x19 = file descriptor
// x20 = pointer to allocated memory
.text
_start:
	m_fputs copyright

open:
	ldr x0, =filepath
	mov x1, O_RDONLY
	bl fopen
	cmp x0, #-1
		bne success
		beq error_open
success:
	mov x19, x0
	m_fputs fileopened
	m_fputs filepath
	m_fputs newline
// since we don't have a usable malloc, use static memory in .bss
reservemem:
	ldr x20, =memarea
read:
	m_fputs readingfile
	mov x0, x20
	mov x1, #64	// read first 64 chars per element
	mov x2, #1	// read one element
	mov x3, x19
	bl fread
	cmp x0, #0
	beq error_read
display:
	// read from the memory address in x20
	ldr x0, =memarea
	bl fputs
// we're done, restore the file pointer and close
close:
	mov x0, x19
	bl fclose
	cmp x0, #0
	bne error_close
	beq exit


// print a proper error string and exit
error_read:
	m_fputs err_fileread
	b error
error_open:
	m_fputs err_fileopen
	b error
error_close:
	m_fputs err_fileclose
	b error
error:
	m_fputs filepath
	m_fputs newline
	mov x0, #1
	b exit

.data
fileopened: .asciz "Opened file: "
readingfile:  .asciz "File contents are:\n"
filepath: .asciz "filetest"
.bss
memarea:	.space 0x1000
