// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: stdlib.s
// description

.include "macros.s"
.include "globals.s"
.align word_s
// global functions in this file:
.global itoa
.global exit
.global malloc
.global returnmsg
.global endmsg
.text

malloc:
/*=============================================================================
stub for calling kernel malloc implementation
register conventions:
        x0 = (input) size of memory
=============================================================================*/
	b exit_syscall

free:
/*=============================================================================
stub for calling kernel free implementation
register conventions:
        x0 = (input) pointer to memory
=============================================================================*/
	b exit_syscall

exit:
/*=============================================================================
stub for calling linux exit system call
TODO: implement your own
register conventions:
        x0 = (input) return code
=============================================================================*/
	b exit_syscall


itoa:
/*=============================================================================
note that this is a nonstandard C function
convert int in base 10 to a null terminated string string of base 10 or 16
register conventions:
	x0 (input) int, (output) return #0
 	x1 (input & output) address to string start
	x2 (input) destination number base
	x9 = start value of getting digit*10^loop
	x10 = divider
	x11 = modulo, temp in loop2
	x12 = accumulator
=============================================================================*/
	mov x9, x0
	mov x12, #0
	// first get digits in reverse
	itoa_loop:	// modulo: divide by base, subtract from original value
		udiv x10, x9, x2	// divide
		msub x11, x10, x2, x9	// modulo to x11
		str x11, [sp, #-stack_align]!	// push to stack, increase stack
		mov x9, x10		// next digit for iteration
		add x12, x12, #1
		cmp x10, #0
		bgt itoa_loop
	// at this point, all our numbers are in stack
	// get them one by one, type cast from int to char and store to x1
	itoa_loop2:
		cmp x12, #0
		beq itoa_return
		ldr x11, [sp], #stack_align	// load from stack, decrease stack
		// convert number to ascii value
		// if we're dealing with base 10 it's simple:
		cmp x2, #10
		beq base10
		base16: // in hex, account for nunmbers
			cmp x11, 9
			bgt add_letter
			add x11, x11, #'0'
			b itoa_cont
			add_letter:
			add x11, x11, #'7' // actually add ('A' - 10), but this is '7'
			b itoa_cont
		base10:
			add x11, x11, #'0'
	itoa_cont:
		strb w11, [x1], #1
		sub x12, x12, #1
		b itoa_loop2
	itoa_return:
		// add \0
		mov x11, #0
		strb w11, [x1]
		mov x0, #0	// always return 0
	// x1 still stores the pointer to string start address
	ret


.data
endmsg: .asciz "Thank you for using this software!\n"
returnmsg: .asciz "Return code is: "
