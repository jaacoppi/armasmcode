// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: newfile.s
// Userland binary for testing fopen, fclose

.include "../include/macros.s"
.include "../include/globals.s"
.include "../include/fcntl.s"
.align word_s	// all instructions are word aligned.
// global functions in this file:
.global _start
.global newline

// x19-x29 are callee saved register. We can safely use them here for:// x19-x29 are callee saved register. We can safely use them here for:
// x19 = file descriptor

.text
_start:
	// open a file by creating it
	m_prints copyright
	ldr x0, =filepath
	mov x1, O_CREAT
	mov x2, #0700	// u+rwx
	bl fopen
	cmp x0, #-1
		bne success
		beq error_create
	success:
	mov x19, x0
	m_prints filecreated
	m_prints filepath
	m_prints newline

// we're done, restore the file pointer and close
close:
	mov x0, x19
	bl fclose
	cmp x0, #0
		bne error_close
		beq exit

// print a proper error string and exit
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
filecreated: .asciz "Created file: "
filepath: .asciz "filetest"
errorstr: .asciz "Error while creating file: "
errorstr2: .asciz "Error while closing file: "
