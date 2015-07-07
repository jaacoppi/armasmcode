// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: stdio.s
// input/output routines

.include "macros.s"
.include "globals.s"

.align word_s
// global functions in this file:
.global write
.global putc
.global puts
.global fopen
.global fclose
.global fread

.equiv DISPLAY_BASE, 	0x09000000 // Qemu VIRTIO UART - in qemu sources /hw/arm/virt.c

.text

write:
/*=============================================================================
a stub to control output destination
when in linux user mode, branch to write_linux
when in qemu-system-aarch64 full system emulation, branch to puts
=============================================================================*/
	m_pushlink
// SYS and USER are defined at compile time in the Makefile. TARGET=SYS or TARGET=USER
.ifdef	SYS
	bl puts
.endif
.ifdef	USER
	bl write_syscall
.endif
	m_poplink
	ret

fopen:
/*=============================================================================
a stub to call linux syscall fopen
NOTE: posix wants x1 to be a string (r,w and so on). We use ACCESSMODE
register conventions:
	x0, (input) start address of a string to path, (output) file descriptor
	x1 (input) ACCESSMODE
	x2 (input) accessmode permissions flags if it's O_CREATE
=============================================================================*/
	m_pushlink
	bl open_syscall
	m_poplink
	ret


fclose:
/*=============================================================================
a stub to call linux syscall fclose
register conventions:
	x0 (input) file descriptor
=============================================================================*/
	m_pushlink
	bl close_syscall
	m_poplink
	ret

fread:
/*=============================================================================
a stub to call linux syscall fread
register conventions:
	x0 (input) pointer to free memory (output) number of bytes read
	x1 (input) size in bytes
	x2 (input) number of elements
	x3 (input) file descriptor
=============================================================================*/
	m_pushlink
	bl read_syscall
	m_poplink
	ret
putc:
/*=============================================================================
print a character to the display device set by =DISPLAY_BASE
register conventions:
	x0 (input) ASCII char
	x3 holds cursor position
=============================================================================*/
	ldr x3, =DISPLAY_BASE
	// print and advance pointer
	str x0, [x3]	// TODO: is this post indexing or pre-indexing?
	ret

puts:
/*=============================================================================
print a string to screen starting from ccurrent cursor position
register conventions:
	x0 (input) start address of \0 terminated string
	x1 holds the index of string
	x2 temp
=============================================================================*/
	m_pushlink
	mov x1, x0
	prints_loop:
		ldrb w0, [x1], 1
		bl putc
		cmp x0, #0 // null terminator
		beq prints_exit
		bne prints_loop
	prints_exit:
	m_poplink
	ret

write_int:
/*=============================================================================
convert an int to a string using itoa and print it using write
register conventions:
	x0 (input) int
	x2 (input)  base (#10 or #16)
	uses registers x0, x1,x2, x9 since write uses them
=============================================================================*/
	// store calling subroutine return address
	m_pushlink
	// we could either use a caller defined string in x1, or suply a local one
	ldr x1, =writeint_tmp
	bl itoa
	m_prints writeint_tmp
	m_poplink
	ret


.data
writeint_tmp: .asciz "1234567890"
