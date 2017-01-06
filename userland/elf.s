// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: elf.s
// Contains library functions for reading elf headers

// info about the elf header can be found from 
// https://en.wikipedia.org/wiki/Executable_and_Linkable_Format#File_header

.include "macros.s"
.include "globals.s"
.align word_s	// all instructions 8-byte (64bit) aligned
// global functions in this file:
.global verify_elf

.text
verify_elf:
/*=============================================================================
Given a file or elf struct is loaded to memory, verify it is an elf file
register conventions:
	x0 = (input) memory address of file
	x1 = temp
=============================================================================*/
	// check for magic "7F E L F"
	ldrb w1, [x0], 1
	cmp x1, 0x7F
	bne invalid_elf

	ldrb w1, [x0], 1
	cmp x1, 0x45
	bne invalid_elf
	ldrb w1, [x0], 1
	cmp x1, 0x4C
	bne invalid_elf
	ldrb w1, [x0], 1
	cmp x1, 0x46
	bne invalid_elf
	// check for size. We only support 64bit
	ldrb w1, [x0], 1
	cmp x1, #2
	bne invalid_elf
// return ok
valid_elf:
        mov x0, #0
        ret
invalid_elf:
	mov x0, #1
	ret
