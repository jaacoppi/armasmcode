// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: debug.s
// subroutines for debugging stack and register states

.include "macros.s"
.include "globals.s"
.align word_s
// global functions in this file:
.global regdump
.global strace
.global memdump

regdump:
/*=============================================================================
Dump all register values in hex
register conventions:
	// TODO: save all registers
	uses x0, x1, x2, x9 and x10
=============================================================================*/
	// push every register so it's not overwritten by pritn functions
	// restore one by one to x0 and print it
	// alternative implementation with gnu as would be with the .irp directive
	str x30, [sp, #-stack_align]! // push link pointer twice so it can be used for returning
	str x30, [sp, #-stack_align]!
	str x29, [sp, #-stack_align]!
	str x28, [sp, #-stack_align]!
	str x27, [sp, #-stack_align]!
	str x26, [sp, #-stack_align]!
	str x25, [sp, #-stack_align]!
	str x24, [sp, #-stack_align]!
	str x23, [sp, #-stack_align]!
	str x22, [sp, #-stack_align]!
	str x21, [sp, #-stack_align]!
	str x20, [sp, #-stack_align]!
	str x19, [sp, #-stack_align]!
	str x18, [sp, #-stack_align]!
	str x17, [sp, #-stack_align]!
	str x16, [sp, #-stack_align]!
	str x15, [sp, #-stack_align]!
	str x14, [sp, #-stack_align]!
	str x13, [sp, #-stack_align]!
	str x12, [sp, #-stack_align]!
	str x11, [sp, #-stack_align]!
	str x10, [sp, #-stack_align]!
	str x9, [sp, #-stack_align]!
	str x8, [sp, #-stack_align]!
	str x7, [sp, #-stack_align]!
	str x6, [sp, #-stack_align]!
	str x5, [sp, #-stack_align]!
	str x4, [sp, #-stack_align]!
	str x3, [sp, #-stack_align]!
	str x2, [sp, #-stack_align]!
	str x1, [sp, #-stack_align]!
	str x0, [sp, #-stack_align]!
	// push & pop enough register, then print them one by one
	// avoiding overwriting registers in subroutines
	m_fputs regdumpstr
	mov x9, #0
	.equiv REGSPERLINE, 4
	mov x10, REGSPERLINE
	regdump_loop:
		// push tab/newline and accumulator, they'll be overwritten by subroutines
		str x10, [sp, #-stack_align]!	// push tab / newline loop
		str x9, [sp, #-stack_align]!	// push accumulator
		mov x0, x9
		ldr x1, =tmpstr
		mov x2, #10
		bl itoa
		ldr x0, =tmpstr
		bl fwrite
		m_fputs colonspace
		// the original register value is 3rd in stack - get it and push rest back
		// TODO: access sp mem directly without changing index: ldr x0, [sp, #24]?
		ldr x9, [sp], #stack_align
		ldr x10, [sp], #stack_align
		ldr x0, [sp], #stack_align
		str x9, [sp, #-stack_align]!
		str x10, [sp, #-stack_align]!
		bl regdump_print	// call print routine
		// write a tab or a newlineon every successive run
		ldr x10, [sp], #stack_align
		cmp x10, #0
			beq regdump_newline
				// not equal, print a tab
				str x10, [sp, #-stack_align]!
				m_fputs tab
				ldr x10, [sp], #stack_align
				sub x10, x10, #1
				b regdump_tabready
			regdump_newline:
				m_fputs newline
				mov x10, REGSPERLINE
		regdump_tabready:
		// see  if we need to loop again
		ldr x9, [sp], #stack_align
		cmp x9, #30
			beq regdump_finished
			add x9, x9, #1
			b regdump_loop
	regdump_finished:
		m_fputs newline
		ldr x30, [sp], #stack_align
	ret

regdump_print:
/*=============================================================================
Dump register x0 in hex, format "0x[value]"
register conventions:
	x0 (input) register value
	x1, x2 (temp)
=============================================================================*/
	m_callPrologue
	str x0, [sp, #-stack_align]!
        m_fputs hex1
	ldr x0, [sp], #stack_align
        ldr x1, =tmpstr
        mov x2, #16
        bl itoa
        ldr x0, =tmpstr
        bl fwrite
	m_callEpilogue
	ret


strace:
/*=============================================================================
Print out everything in stack
register conventions:
	x0 stack address iterator
	x1 
top of stack
=============================================================================*/
	m_fputs stracestr
  	mov x0, sp      
	ldr x1, =STACK_TOP
        m_callPrologue // don't show return address of this subroutine in strace
	// loop until we've reahed STACK_TOP
        strace_loop:
                cmp x1, x0
		beq strace_endloop
			str x1, [sp, #-stack_align]!
			str x0, [sp, #-stack_align]!
			bl memdump
			ldr x0, [sp], #stack_align
			ldr x1, [sp], #stack_align
                        add x0, x0, #stack_align // iterate next word - 8 bytes
			b strace_loop
        strace_endloop:
                m_callEpilogue
                ret

memdump:
/*=============================================================================
Print out the address and value of a memory address in x0
register conventions:
	x0 a memory address (thus a pointer)
	x1 temp
=============================================================================*/
	m_callPrologue
	str x0, [sp, #-stack_align]!
	str x1, [sp, #-stack_align]!
	// print address
	str x0, [sp, #-stack_align]!
	m_printregh x0
	m_fputs colonspace
	// print value
	ldr x0, [sp], #stack_align
	ldr x0, [x0]
	m_printregh x0
	m_fputs newline
	ldr x1, [sp], #stack_align
	ldr x0, [sp], #stack_align
	m_callEpilogue
	ret		// end of memdump

.data
regdumpstr: .asciz "Register dump:\n"
stracestr: .asciz "Stack trace (FILO):\n"

// for debug: try out stack trace & memdump
/*
	mov x0, 0x1001
	mov x1, 0xFFFF
	mov x2, 0x8000
	mov x3, 0x0001
	str x0, [sp, #-stack_align]!
	str x1, [sp, #-stack_align]!
	str x2, [sp, #-stack_align]!
	str x3, [sp, #-stack_align]!
	bl strace
	ldr x0, [sp], #stack_align
	ldr x0, [sp], #stack_align
	ldr x0, [sp], #stack_align
	ldr x0, [sp], #stack_align
*/
