// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: freebsdsys.s
// Contains freebsd system calls
// These are mostly the same than with linux syscalls, but with different syscall numbers
// The list of freebsd system calls can be found in /usr/include/sys/syscall.h. 

.include "macros.s"
.include "globals.s"
.include "fcntl.s"

.align word_s	// all instructions 8-byte (64bit) aligned
// global functions in this file:
.global exit_syscall
.global write_syscall
.global open_syscall
.global close_syscall
.global read_syscall

exit_syscall:
/*=============================================================================
freebsd (arm) system call #1 - exit
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
	// freebsd syscalls work like this:
	mov x0, x27
	mov x8, #1
	svc #0

write_syscall:
/*=============================================================================
given a string, calculate strlen and use freebsd arm write syscall #4 for output
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
	mov x8, #4
	svc #0
	m_poplink
	ret

open_syscall:
/*=============================================================================
freebsd system call #5 - open
register conventions:
        x0, (input) start address of a string to path, (output) file descriptor
        x1 (input) access mode
	x2 (input) chmod permissions when using O_CREAT
=============================================================================*/
// freebsd access mode definitions can be found from include/uapi/asm-generic/fcntl.h
// and so on. Ours are in include/fcntl.s
	mov x8, #5
	svc #0
        ret

close_syscall:
/*=============================================================================
freebsd system call #6 - close
register conventions:
        x0, (input) file descriptor
=============================================================================*/
// freebsd access mode definitions can be found from include/uapi/asm-generic/fcntl.h
// and so on. Ours are in include/fcntl.s
	mov x8, #6
	svc #0
        ret

read_syscall:
/*=============================================================================
freebsd system call #3 - read
a stub to call freebsd syscall fread
register conventions:
        x0 (input) pointer to free memory
        x1 (input) size in bytes
        x2 (input) number of elements
        x3 (input) file descriptor
freebsd read format is:
	x0 file descriptor
	x1 pointer to buffer
	x2 size in bytes
return value from freebsd is:
	0 if size = 0 or end of file reached
	nonzero means number of bytes read
	
=============================================================================*/
	// setup freebsd read format
	mul x2, x1, x2
	mov x1, x0
	mov x0, x3
	mov x8, #3
	svc #0
        ret


