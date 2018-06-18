// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: stdio.s
// input/output routines

.include "macros.s"
.include "globals.s"

.align word_s
// global functions in this file:
.global fwrite
.global fputc
.global fputs
.global fopen
.global fclose
.global fread
.global fseek

// Use this for qemu-system-aarch64 where we don't have syscalls:
.equiv DISPLAY_BASE, 	0x09000000  // Qemu VIRTIO UART - in qemu sources /hw/arm/virt.c

.text

fwrite:
/*=============================================================================
a stub to control output destination
when in linux user mode, branch to write_linux
write syscall parameters: *fd, *buf, count
when in qemu-system-aarch64 full system emulation, branch to puts
=============================================================================*/
	m_callPrologue
// SYS and USER are defined at compile time in the Makefile. TARGET=SYS or TARGET=USER
.ifdef	SYS
	ldr x3, =DISPLAY_BASE
	bl write_syscall
.endif
.ifdef	USER
	// write syscall parameters: *fd, *buf, count
	bl write_syscall
.endif
	m_callEpilogue
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
	m_callPrologue
	bl open_syscall
	m_callEpilogue
	ret


fclose:
/*=============================================================================
a stub to call linux syscall fclose
register conventions:
	x0 (input) file descriptor
=============================================================================*/
	m_callPrologue
	bl close_syscall
	m_callEpilogue
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
	m_callPrologue
	bl read_syscall
	m_callEpilogue
	ret
fputc:
/*=============================================================================
print a character => actually just call fwrite
register conventions:
	x0 (input) start address of an ascii string (=> a char)
	x1 (input) stream, always use #1
	output (linux write syscall)
	 write syscall parameters: *fd, *buf, count
=============================================================================*/
	m_callPrologue
	// arrange the parameters for fwrite
	mov x1, x0
	mov x2, #1
	mov x0, #1
	bl fwrite
	m_callEpilogue
	// print and advance pointer
//	str x0, [x3]	// TODO: is this post indexing or pre-indexing?
	ret

fputs:
/*=============================================================================
print a string to screen starting from current cursor position
this is done char at a time via fputc and finally fwrite
register conventions:
	x0 (input) start address of \0 terminated string
	x1 holds the index of string
	x2 temp
=============================================================================*/
	m_callPrologue
	mov x1, x0
	ldrb w0, [x1]
	// if the char pointer is not \0, fputc it and loop
	fputs_loop:
		cmp x0, #0 // null terminator
		beq fputs_nullexit
		m_push x0
		m_push x1
		mov x0, x1
		bl fputc
		m_pop x1
		m_pop x0
		ldrb w0, [x1, 1]!
		b fputs_loop
	fputs_nullexit: // null found, exit
	m_callEpilogue
	ret

fseek:
/*=============================================================================
Wrapper to lseek
=============================================================================*/
	m_callPrologue
	bl lseek_syscall
	m_callEpilogue
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
	m_callPrologue
	// we could either use a caller defined string in x1, or suply a local one
	ldr x1, =writeint_tmp
	bl itoa
	m_fputs writeint_tmp
	m_callEpilogue
	ret


.data
writeint_tmp: .asciz "1234567890"
