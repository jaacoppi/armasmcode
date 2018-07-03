// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm64.s
// Disassembler for 64 bit ARM (Aarch64)

.include "macros.s"
.include "globals.s"
.include "fcntl.s"
.include "fs.s"

// ARMV8-A Architecture reference manual, chapter C3 Instruction set encoding
// from Table C3-1 A64 main encoding table
.equiv unalloc, 0x0
.equiv datapr_imm, 0x0






.align word_s	// all instructions 8-byte (64bit) aligned
// global functions in this file:
.global _start
.global disassemble
// x19-x29 are callee saved register. We can safely use them here for:// x19-x29 are callee saved regist$
// x19 = file descriptor
// x20 = pointer to allocated memory


.macro m_fread pointer size stream
	ldr x20, =\pointer
	mov x0, x20
	mov x1, #\size
	mov x2, #1
	mov x3, \stream
	bl fread
.endm

.macro m_fseek fdreg offsetreg whenceint
	mov x0, \fdreg
	mov x1, \offsetreg
	mov x2, #\whenceint
	bl fseek
.endm

// result of last cmp is beq if valuereg contains bitmask, bne if not
.macro m_bitmask valuereg bitmaskreg tempreg2 bitmask
	mov \bitmaskreg, \bitmask
	and \tempreg2, \valuereg, \bitmaskreg
	cmp \bitmaskreg, \tempreg2
//-> is this always true?
.endm

.text
_start:
// get command line arguments
// argc
m_pop x0
cmp x0, #1
	ble missing_argument
	m_pop x0	// argv[0], name of executable
	m_pop x0	// argv[1], first command line argument
	mov x18, x0	// hold the pointer to the argument
	b open
missing_argument:
	m_fputs missingargument
	b exit

	// load a file to memory with fopen and fread and memcpy
	// TODO: maybe start using macros for error checking?
	// at this point, x0 should containt the mem address
open:
	mov x1, O_RDONLY
	bl fopen
	mov x19, x0
	cmp x0, 0xFFFFFFFFFFFFFFFE // -1, but #-1 is not accepted for some reason
		beq error_open
	// TODO: see if this works if the file doesn't exist
// we don't have a userland malloc implementation yet
// simply use static memory
read_fhdr: // read the elf file header from disk to memory
	m_fread EI_MAG0, 64, x19
verify: // verify it's an elf file, 64 bits little endian and Aarch64 instruction set
	ldr x0, =EI_MAG0
	bl verify_elf
	cmp x0, #0
		bne verify_error

	ldr x0, =EI_CLASS
	ldrb w1, [x0]
	cmp x1, #2
		bne verify_error
	ldr x0, =EI_DATA
	ldrb w1, [x0]
	cmp w1, #1
		bne verify_error
	ldr x0, =e_machine
	ldrb w1, [x0]
	cmp w1, 0xB7
		bne verify_error

	// at this point, store e_entry for later use
	ldr x0, =e_entry
	ldr x21, [x0]
	b find_proghdr
verify_error:
	m_fputs verifystr
	b close

find_proghdr:
read_phdr: // read the elf program header from disk to memory
// TODO: macro all reads
	// fseek to start of program header
	ldr x2, =e_phoff
	ldrb w1, [x2]
	m_fseek x19, x1, SEEK_SET

	// read the size of prog header to memory starting at p_type. TODO: e_phentsize instead of 64
	m_fread p_type, 64, x19
	// this program segment ends at p_vaddrd + p_filesz
	adr x0, p_vaddr
	ldr x0, [x0] //p_filesz now at x3
	mov x22, x0
	adr x0, p_filesz
	ldr x0, [x0]
	add x22, x22, x0

	// starting address for 1st program segment = size of file header + nr of prog hdrs * size of prog hdr
	ldr x0, =e_phentsize
	ldrb w1, [x0]
	ldr x0, =e_phnum
	ldrb w2, [x0]
	mul x1,x1,x2
	ldr x2, =e_ehsize
	ldrb w0, [x2]
	add x1,x0,x1 // x1 now contains starting address of first prog segment

// now, read x1 bytes starting at x0 to get the actual file contents
	m_fseek x19, x1, SEEK_SET
	// read the size of prog header to memory starting SEEK_CUR. TODO: p_filesz instead of 0x1000
	m_fread memarea, 0x1000, x19


// iterator
// x21 = entry point (same as readelf)
// x22 = program segment end point (entry point + p_filesz)
disassemble:
/*=============================================================================
Read 32 bits (=one opcde) at a time and disassemble it
register conventions:
	x21: iterator (starts at e_entry + size of file hdr + nr of prog hdrs * size of prog hdr)
	x22: iterator end point (x21 + p_filesz)
	x23 and x24: hex loop temps
	x25: stores value for decoding
=============================================================================*/
// Loop 32 bits at a time:
// - cmp iterator to section length
// - TODO: cmp iterator to symbol table, see if there's a match
// - bit manipulate the 32 bits to identify the instruction (switch statements)
// - then identify Rn, Rd and so on
// - increase iterator and loop
	cmp x21, x22
		beq close

	m_printregh x21 // display iterator state
	m_fputs colonspace

	// store the actual 32 bits for decoding use later on
	ldr w25, [x20]
	// display the hex codes for each byte
	mov x24, #4
	add x20, x20, 0x3 // adjust memory pointer, we'll be reading little endian
	displayloop:
		ldrb w23, [x20],-0x01

               // convert the hex value to an ascii string
                // add a leading 0 if value is single digit (< 0x10)
			mov x0, x23
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

		// decode every 32 bits
		sub x24, x24, #1
		cmp x24, #0
			bne displayloop
		bl decode
	        add x20, x20, 0x5 // reset memmory pointer
	       add x21, x21, 0x04 // increase iterator
		b disassemble


close:
	mov x0, x19
	bl fclose
	cmp x0, #0
	bne error
	beq exit

error_open:
error:
	m_fputs errorstr
	mov x0, x18
	bl fputs
	m_fputs newline
        mov x0, #1
        b exit



.data
missingargument: .asciz "Missing file operand.\n"

verifystr: .asciz "This is not a 64 bit ELF file for Aarch64 machines\n"
errorstr: .asciz "An error has occurred reading elf headers for file: "

// the elf header from https://en.wikipedia.org/wiki/Executable_and_Linkable_Format#File_header
// NOTE: this only supports 64bit format. In 32bit, the offsets after 0x18 are different
// TODO: instead of reserving 64 bytes, make this dynamic
// it could be done with .ifdef ELF .. and .equiv for offsets (.equiv e_type 0x10)
// using base addr label + e_type would be okay then





.bss
// 0x0, e_ident
EI_MAG0: .space 0x1	// must contain magic 0x7F 0x45 0x4C 0x56 (0x7F ELF)
EI_MAG3: .space 0x3
EI_CLASS: .space 0x1	// 1 for 32bit, 2 for 64bit format
EI_DATA: .space 0x1	// 1 for little endian, 2 for big endian
EI_VERSION: .space 0x1	// 1 for "original version of ELF"
EI_OSABI: .space 0x1	// 0x03 = Linux. Currently we don't check for others
EI_ABIVERSION: .space 0x1 // Os specific
EI_PAD:	.space 0x7	// unused 7 bytes
// 0x10, e_type
e_type: .space 0x2	// 1 = reloc, 2 = exec, 3 = shared, 4 = core
e_machine: .space 0x2	// 0x03 = x86, 0xB7 = AArch64
e_version: .space 0x4	// set to 1
e_entry: .space 0x8	// executable entry point
e_phoff: .space 0x8	// start of program header table
e_shoff: .space 0x8	// start of section header table
e_flags: .space 0x4	// target arch specific flags
e_ehsize: .space 0x2	// size of this header. Should be 64 bytes for 64bit format
e_phentsize: .space 0x2 // size of program header table
e_phnum: .space 0x2 	// amount of program header tables
e_shentsize: .space 0x2 // size of section header table
e_shnum: .space 0x2 	// amount of section header tables
e_shstrmdx: .space 0x2	// index of section header table containing section names
// prog header table
p_type: .space 0x4
p_flags: .space 0x4
p_offset: .space 0x8
p_vaddr: .space 0x8
p_paddr: .space 0x8 // note that this is undefined for SYSTEM V
p_filesz: .space 0x8
p_memsz: .space 0x8
p_align: .space 0x8
memarea:
.space 0x1000
