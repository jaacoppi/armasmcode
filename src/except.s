// TODO: figure out enabling & disapbling IRQ / FIQ and processor modes

// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: except.s
// Exception handling code

.include "macros.s"
.include "globals.s"
.align word_s	// all instructions 8-byte (64bit) aligned

// global functions in this file:
.global _vectorentry	// vector table needs to be at 0x0, so set _vectorentry as entrypoint in linker script


/* Theory:
	in ARM, a vector table holds the branch locations for exceptions in this order:
	Reset (1st priority)
	Undefined Instruction
	Software Interrupt (SWI)
	Prefetch Abort
	Data Abort (2nd priority, invalid memory address or no permissions)
	Not assigned
	IRQ
	FIQ

	The vector table of 8* 4 bytes contains branch addresses
	The vector table must be at location 0x0 - use a linker script.
	Note that because 0x0 has the reset exception branch, this is actually
	the first code ran if the process is started at address 0x0 instead of another entry point
*/
.text
_vectorentry:
// an unassigned handler can simply be "." for infinite loop
reset:  b _start	// reset / init a system
undefined: b except_undefined
swi:    b .	// b except_swi
abort1: b .
abort2: b .
unassigned: b .
irq:    b .
fiq:    b .
b _start

except_undefined:
	m_callPrologue
	m_fputs undefinedstr
	m_callEpilogue
	ret


// see Sloss et al, 11.2., p. 391 for a reference implementation
except_swi:
	m_callPrologue
	m_fputs swistr
	m_callEpilogue
	ret

.data
undefinedstr: .asciz "Exception: an unidentified instruction has been used!\n"
swistr: .asciz "Exception: an SWI (SVZ) instruction has been used!\n"
