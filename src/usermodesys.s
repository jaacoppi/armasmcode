// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: usermodesys.s
// Contains system calls for linux hosts
// see include/syscalls.s and Makefile for targets

.include "macros.s"
.include "globals.s"
.include "fcntl.s"
.include "syscalls.s"

.align word_s	// all instructions 8-byte (64bit) aligned
// global functions in this file:
.global exit_syscall
.global write_syscall
.global open_syscall
.global close_syscall
.global read_syscall
.global lseek_syscall

exit_syscall:
/*=============================================================================
We don't return from here for obvious reasons
register conventions:
        x0 = (input) return code
	x28 = temp for storing return code while printing
=============================================================================*/
	// TODO: check this out
	mov x8, sys_exit
	svc #0

write_syscall:
/*=============================================================================
linux syscall write
register conventions:
	x0 (output) number of bytes written)
	x1 (input) start address of string
	x2 (input) nr of bytes to write
	during syscall:
	x0 (standard output)
	x1 = start address of string
	x2 = nr of bytes. "Hello\n\0" is 6, not 5 bytes like strlen gives us!
	x3 = STREAM. #0 for stdout
=============================================================================*/
	mov x8, sys_write
	svc #0
	ret

open_syscall:
/*=============================================================================
register conventions:
        x0, (input) start address of a string to path, (output) file descriptor
        x1 (input) access mode (see fcntl.s or fcntl.h in linux)
	x2 (input) chmod permissions when using O_CREAT
=============================================================================*/
	mov x8, sys_open
	svc #0
        ret

close_syscall:
/*=============================================================================
register conventions:
        x0, (input) file descriptor
=============================================================================*/
	mov x8, sys_close
	svc #0
        ret

read_syscall:
/*=============================================================================
register conventions:
stdio fread format is:
        x0 (input) pointer to free memory
        x1 (input) size in bytes
        x2 (input) number of elements
        x3 (input) file descriptor
linux syscall read format is:
	x0 file descriptor
	x1 pointer to buffer
	x2 size in bytes
return value s:
	0 if size = 0 or end of file reached
	nonzero means number of bytes read
=============================================================================*/
	mul x2, x1, x2
	mov x1, x0
	mov x0, x3
	mov x8, sys_read
	svc #0
        ret


lseek_syscall:
/*=============================================================================
Linux system call lseek
register conventions:
        x0 (input) file descriptor
        x1 (input) offset in bytes
        x2 (input) whence
        uses registers x0, x1,x2, x9 since write uses them
=============================================================================*/
	mov x8, sys_lseek
	svc #0
        ret
