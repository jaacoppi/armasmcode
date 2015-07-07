// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: syscalls.s
// syscalls definitions for linux/freebsd

.include "globals.s"
.align stack_align	// all instructions 8-byte (64bit) aligned

.ifndef SYSCALLS	// only include once
.equiv SYSCALLS, 1

// the choice of freebsd vs linux is made in the makefile
// make HOST=FREEBSD vs make HOST=LINUX

// The list of freebsd system calls can be found in /usr/include/sys/syscall.h.
.ifdef FREEBSD
.equiv sys_exit, 	1
.equiv sys_read, 	3
.equiv sys_write,	4
.equiv sys_open,	5
.equiv sys_close,	6
.endif

// Linux has different syscall numbers for x86 and ARM.
// These are the linux 4.1 aarch64 syscall numbers from include/uapi/asm-generic/unistd.h.
.ifdef LINUX
.equiv sys_exit, 	93
.equiv sys_read,	3
.equiv sys_write,	64
.equiv sys_open,	1024
.equiv sys_close,	6
.endif


.endif
