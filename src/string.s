// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: string.s
// description

.include "macros.s"
.include "globals.s"
.align word_s
// global functions in this file:
.global memcpy
.global memset
.global strlen
.global strcmp
.global strncmp
.global strcpy
.global strncpy
.text

memcpy:
/*=============================================================================
copy n amount of bytes from one address to another
NOTE that the caller is responsible for not overlapping these memory areas
register conventions:
	x0 (input) start address of dst, (output) start address of dst
	x1 (input) start address of src
	x2 (input) amout of bytes to copy
	x9 = temp
=============================================================================*/
	memcpy_loop:
		// loop with x2 until you've copied enough chars
		cmp x2, #0
		beq memcpy_end
		// get a byte from src and increment it
		ldrb w9, [x1],1
		// copy the byte to dst and increment it
		strb w9, [x0], 1 

		// iterate and loop
		sub x2, x2, #1 
		b memcpy_loop
	memcpy_end:
		ret

memset:
/*=============================================================================
fill a memory area with chars
register conventions:
	x0 (input & output ) start address of memarea to be written to
	x1 (input) char to be written
	x2 (input) amount of chars to write
=============================================================================*/
	memset_loop:
		// loop with x2 until you've copied enough chars
		cmp x2, #0
		beq memset_end
		// copy the byte to dst and increment it
		strb w1, [x0], 1

		// iterate and loop
		sub x2, x2, #1
		b memset_loop
	memset_end:
		ret

strlen:
/*=============================================================================
calculate nr of chars from start address to first \0 or \n encountered
note the value returned is without \n (or \0), so "abc\n" returns 3
register conventions:
	x0 = (input) start address, (output) return char count
	x9 = addr to string start and offset while looping
	x10 = comparison for single byte
=============================================================================*/
	mov x9, x0
	mov x0, #0	// x0 is now a counter, x9 the address
	strlen_loop:
		ldrb w10, [x9],1 // read from x9 and post index to next byte
		cmp w10, #10	// exit loop with both \n and \0
		beq strlen_exitloop
		cmp w10, #0
		beq strlen_exitloop
		add x0, x0, #1
		b strlen_loop
	strlen_exitloop:
		ret
strcmp:
/*=============================================================================
compare two strings and return 0 if equal
NOTE that this currently only support equal, not less or greater than
register conventions:
	x0 (input) start address of string #0, (output) = result
	x1 (input) start address of string #1
	x9 = temp
	x10 = temp
=============================================================================*/
	// loop until a difference is found, or both give a \0
	strcmp_loop:
		ldrb w9, [x0], 1
		ldrb w10, [x1], 1
		cmp w9, w10
		bne return_1
		cmp w9, #0
		beq return_0	// if we're here, both w9 and w10 are 0	
		b strcmp_loop

strncmp:
/*=============================================================================
compare first n chars of two strings and return 0 if equal
NOTE that this currently only supports equal, not less or greater than
register conventions:
	x0 (input) start address of string #0, (output) = result
	x1 (input) start address of string #1
	x2 (input) how many chars
	x9 = temp
	x10 = temp
=============================================================================*/
	// almost same as strcmp
	// loop until a difference is found, or both give a \0
	strncmp_loop:
		cmp x2, #0		// we haven't quit so far, so the strings are the same
		beq return_0
		ldrb w9, [x0], 1
		ldrb w10, [x1], 1
		cmp w9, w10
		bne return_1
		cmp w9, #0
		beq return_0	// if we're here, both w9 and w10 are 0	
		sub x2, x2, #1
		b strncmp_loop


strcpy:
/*=============================================================================
copy a string from one address to another
NOTE that the strings are allowed to overlap, can cause buffer overflows
register conventions:
	x0 (input) start address of dst, (output) start address of dst
	x1 (input) start address of src
	x9 = temp
	x10 = temp
=============================================================================*/
	// loop until a difference is found, or both give a \0
	strcpy_loop:
		// increase x1 here, but x0 only after the store later
		ldrb w9, [x0]
		ldrb w10, [x1], 1
		// return if either string ends
		cmp w9, #0
		beq return_addnullbyte
		cmp w10, #0
		beq return_addnullbyte
		// copy the char
		strb w10, [x0], 1
		b strcpy_loop


strncpy:
/*=============================================================================
copy n chars of a string from one address to another
NOTE that the strings are allowed to overlap, can cause buffer overflows
register conventions:
	x0 (input) start address of dst, (output) start address of dst
	x1 (input) start address of src
	x2 (input) nr of chars
	x9 = temp
	x10 = temp
=============================================================================*/
	// loop until a difference is found, or both give a \0
	strncpy_loop:
		cmp x2, #0		// no quit so far, assume it's similar
		beq return_addnullbyte
		// increase x1 here, but x0 only after the store later
		ldrb w9, [x0]
		ldrb w10, [x1], 1
		// return if either string ends
		cmp w9, #0
		beq return_addnullbyte
		cmp w10, #0
		beq return_addnullbyte
		// copy the char
		strb w10, [x0],1
		sub x2, x2, #1
		b strncpy_loop





// these could be used by any subroutine
	// requires x0 to hold the current address
	return_addnullbyte:
		mov w10, #0
		strb w10, [x0]
		ret
	return_0:
		mov x0, #0
		ret
	return_1:
		mov x0, #1
		ret


// for debug and testing
/*	// test strcmp
	ldr x0, =copyright
	ldr x1, =copyright
	bl strcmp

	// test strncmp
	ldr x0, =msg
	ldr x1, =copyright
	mov x2, #5
	bl strncmp

	// test str(n)cpy
	ldr x0, =copyright
	ldr x1, =msg
	mov x2, #3
	bl strncpy
	ldr x0, =copyright
	bl fwrite
*/

