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

// x19-x29 are callee saved register. We can safely use them here for:
// x19 = file descriptor

.text
_start:
	m_fputs copyright
	// open a file by creating it
	ldr x0, =filepath
	mov x1, O_CREAT
	mov x2, #0700	// u+rwx
	bl fopen
	// TODO: returns success even if the file already exists. Should it with O_CREAT?
	cmp x0, #-1
		bne success
		beq error_create
	success:
	mov x19, x0
	m_fputs filecreated
	m_fputs filepath
	m_fputs newline

// we're done, restore the file pointer and close
close:
	mov x0, x19
	bl fclose
	cmp x0, #0
		bne error_close
		beq exit

// print a proper error string and exit
error_create:
	m_fputs err_filecreate
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
filecreated: .asciz "Created file: "
filepath: .asciz "filetest"
