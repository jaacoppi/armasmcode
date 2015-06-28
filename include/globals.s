// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: globals.s
// Basic defines for word size etc

.align 4	// all instructions 8-byte (64bit) aligned

.ifndef GLOBALS	// only include once
.equiv GLOBALS, 1

.equiv word_s, 0x4	// aarch64 word size is 32 bits
.equiv stack_align, 0x8 // we use 64bit registers, so stack align is 65bit

// for standard return & error codes, see POSIX sysexits.h for example
// these here are not standards
.equiv RET_OK, 	0x0
.equiv RET_ERR, 0x1 
.endif
