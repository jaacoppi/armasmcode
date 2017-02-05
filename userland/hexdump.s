// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: hexdump.s
// behave like GNU hexdump -C

.include "../include/macros.s"
.include "../include/globals.s"
.include "../include/fcntl.s"
.align word_s	// all instructions are word aligned.
// global functions in this file:
.global _start

// x19-x29 are callee saved register. We can safely use them here for:
// x19 = file descriptor
// x20 = offset counter for line numbering
// x21 = iteration counter for viewing 16 bytes per line
// x22 = pointer for memory load & store

.text
_start:
	m_fputs copyright
open: // open the file to be read
// TODO: take a command line argument
	ldr x0, =filepath
	mov x1, O_RDONLY
	bl fopen
	cmp x0, #-1
		bne success
		beq error_open
success:
	mov x19, x0
	m_fputs fileopened
	m_fputs filepath
	m_fputs newline
	m_fputs readingfile
// loop:
// 1. print offset
// 2. read 16 hexes = 256 bits = 4*64 bits
// 3. display the bits as hexes and ASCII
mov x20, 0x0
readloop:
// since we're using the static memory location memarea, it needs to be cleaned before every iteration
m_memset memarea, #0, 0x40 // TODO: is count 0x40 okay? Should be for a 64 bit register..

readfromfile:
	// since we don't have a usable malloc, use static memory in .bss
	ldr x22, =memarea
	mov x0, x22
	mov x1, 0x10	// read first 16 chars per element
	mov x2, #1	// read one element
	mov x3, x19
	bl fread
	cmp x0, #0
	beq error_read
display:
	// display and increment offset
	m_printregh x20
	add x20, x20, 0x10
	m_fputs tab
	// loop for 16 hexes
	ldr x22, =memarea
	mov x21, #0
	displayhexloop:
		cmp x21, #16 	// quit loop if we need the next line
		beq donehexloop
		cmp x22, #0	// quit loop if there's a \0
		beq donehexloop
		// convert the hex value to an ascii string
		ldrb w0, [x22]	// load the value stored in x22
		// add a leading 0 if value is single digit (< 0x10)
			m_push x0
			m_push x1
			cmp x0, 0xF
			bgt nopadding
			ldr x0, =tmpstr
			mov x1, #'0'
			strb w1, [x0]
			mov x1, #0
			bl fputc
			m_pop x1
			m_pop x0
		nopadding:
		ldr x1, =tmpstr
		mov x2, #16
		bl itoa
		ldr x0, =tmpstr
 		bl fputs
		m_fputs space
		add x21, x21, #1
		add x22, x22, #1
		b displayhexloop
	donehexloop:
	// loop for 16 hexes
	m_fputs tab
	ldr x22, =memarea
	mov x21, #0
	displayasciiloop:
		cmp x21, #16
		beq doneasciiloop
		cmp x22, #0
		beq doneasciiloop

		// load the char to be compared
		ldrb w0, [x22]

		cmp x0, 0x21
		blt notprintable
		cmp x0, 0x7E
		bgt notprintable
		mov x0, x22
		mov x1, #0
		bl fputc
		b cont

		// print '.' if the char is unprinable (printables are in range of 0x21-0x7E
		notprintable:
			m_push x0
			m_push x1
			ldr x0, =tmpstr
			mov x1, #'.'
			strb w1, [x0]
			mov x1, #0
			bl fputc
			m_pop x1
			m_pop x0

		cont:
		add x21, x21, #1
		add x22, x22, #1
		b displayasciiloop
	doneasciiloop:

// loop a new line
m_fputs newline
b readloop
// we're done, restore the file pointer and close
close:
	m_fputs newline
	mov x0, x19
	bl fclose
	cmp x0, #0
	bne error_close
	beq exit


// print a proper error string and exit
error_read:
// TODO: implement and use feof and ferror
	m_fputs err_fileread
	b error
error_open:
	m_fputs err_fileopen
	b error
error_close:
	m_fputs err_fileclose
	b error
error:
	m_fputs filepath
	m_fputs newline
	mov x0, #1
	b exit

.data
fileopened: .asciz "Opened file: "
readingfile:  .asciz "File contents are:\n"
filepath: .asciz "filetest"
.bss
memarea:	.space 0x1000
