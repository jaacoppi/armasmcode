// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: linuxsys.s
// Contains linux system calls

// The list of linux system calls can be found in the kernel sources at
// include/uapi/asm-generic/unistd.h. These are based on linux 4.1

.include "include/macros.s"
.include "include/globals.s"
.align word_s	// all instructions 8-byte (64bit) aligned
// global functions in this file:
.global exit_linux
.global write_linux

exit_linux:
/*=============================================================================
linux (arm) system call #93 - exit
We don't return from here for obvious reasons
register conventions:
        x0 = (input) return code
	x28 = temp for storing return code
=============================================================================*/
	mov x27, x0
	m_prints newline
	m_prints endmsg
	m_prints returnmsg
	mov x0, x27
	m_printregh x0
	m_prints newline
	// linux syscalls work like this:
	mov x0, x27
	mov x8, #93
	svc #0

write_linux:
/*=============================================================================
given a string, calculate strlen and use linux arm write syscall #64 for output
register conventions:
	x0 (input) start address of string, (output) number of bytes written)
	during syscall:
	x0 (standard output)
	x1 = start address of string
	x2 = nr of bytes. "Hello\n\0" is 6, not 5 bytes like strlen gives us!
	x9 = keep starting address
=============================================================================*/
	// push starting address of string and return address for subroutine
	m_pushlink
	str x0, [sp, #-stack_align]!
	bl strlen
	mov x2, x0	// strlen return value is at x0
	add x2, x2, #1	// x2 = strlen + \n
	ldr x1, [sp], #stack_align // return starting address of string
	mov x0, #0	// x0 = standard output
	mov x8, #64
	svc #0
	m_poplink
	ret
