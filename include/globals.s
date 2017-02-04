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

// some global strings used all around the project
.data
copyright: .asciz "Copyright 2016-2017 Juho Hiltunen (jaacoppi)\n"
// if we don't want to use strlen, we can get const string length like this:
copyright_len = . - copyright // copyright_len is chars (bytes) between here and copyright:
newline: .asciz "\n"
space: .asciz " "
colonspace: .asciz ": "
tab: .asciz " \t"       // wide enough. It seems \t wouldn't cut it

// this could be errno.s, errors. or something else..
err_fileopen: .asciz "Error while opening file: "
err_fileclose: .asciz "Error while closing file: "
err_fileread: .asciz "Error while reading file: "
err_filecreate: .asciz "Error while creating file: "
.endif
