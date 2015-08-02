// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: fnctl.s
// Posix compliant file control stuff

.align 8	// all instructions 8-byte (64bit) aligned

.ifndef FCNTL	// only include once
.equiv FNCTL, 1
.ifdef FREEBSD
.equiv O_RDONLY, 	0x0000
.equiv O_WRONLY, 	0x0001
.equiv O_RDWR, 		0x0002
.equiv O_CREAT,		0x0200
.equiv O_APPEND,	0x0008
.endif
.ifdef LINUX
.equiv O_RDONLY, 	1
.equiv O_WRONLY, 	2
.equiv O_RDWR, 		3
.equiv O_CREAT,		100
.equiv O_APPEND,	1000
.endif
.endif
