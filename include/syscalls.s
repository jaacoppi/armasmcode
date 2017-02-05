// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: syscalls.s
// syscalls definitions for linux

.include "globals.s"
.align stack_align	// all instructions 8-byte (64bit) aligned

.ifndef SYSCALLS	// only include once
.equiv SYSCALLS, 1

// Linux has different syscall numbers for x86 and ARM.
// These are the linux 4.1 aarch64 syscall numbers from include/uapi/asm-generic/unistd.h.
.equiv sys_exit, 	93
.equiv sys_lseek, 	62
.equiv sys_read,	63
.equiv sys_write,	64
.equiv sys_open,	1024
.equiv sys_close,	57



.endif
