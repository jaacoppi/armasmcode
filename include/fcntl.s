// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: fnctl.s
// Posix compliant file control stuff

.align 8	// all instructions 8-byte (64bit) aligned

.ifndef FCNTL	// only include once
.equiv O_RDONLY, 	0
.equiv O_WRONLY, 	1
.equiv O_RDWR, 		2
.equiv O_CREAT,		100
.equiv O_APPEND,	2000
.endif
