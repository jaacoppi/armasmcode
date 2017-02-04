// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: readelf.s
// Debugging ELF header parsing

// NOTE: this only supports 64bit format. In 32bit, the offsets after 0x18 are different
// Acknowledgements:
// http://www.ouah.org/RevEng/x430.htm
// https://en.wikipedia.org/wiki/Executable_and_Linkable_Format

.include "macros.s"
.include "globals.s"
.include "fcntl.s"

.align word_s	// all instructions 8-byte (64bit) aligned
// global functions in this file:
.global _start
// x19-x29 are callee saved register. We can safely use them here for:// x19-x29 are callee saved regist$
// x19 = file descriptor
// x20 = pointer to allocated memory

.text
_start:
	m_fputs copyright
	// load a file to memory with fopen and fread and memcpy
	// TODO: maybe start using macros for error checking?
	// at this point, x0 should containt the mem address
open:
	ldr x0, =filepath
	mov x1, O_RDONLY
	bl fopen
	mov x19, x0
	cmp x0, #-1
		beq error_open
		bne reservemem
// we don't have a userland malloc implementation yet
// simply use static memory
reservemem:
	ldr x20, =memarea
// read the elf file from disk to memory
// TODO: only read the required parts
read:
	mov x0, x20
	mov x1, #64
	mov x2, #1
	mov x3, x19
	bl fread
verify: // verify it's an elf file
	ldr x0, =memarea
	bl verify_elf
	cmp x0, #0
		bne error
		beq print_elfheader

print_elfheader:
/*=============================================================================
Given an elf struct is loaded to memory (with populate_elf), parse and print it
To get an elf struct to a memory address, one could malloc for it and use
memcpy(dst, src, 64)

register conventions:
	x20 = (input) memory address, pointer to offset
	x21 = temp for printing
	x22 = temp for printing
=============================================================================*/
// TODO: for each field, print the corresponding string. like we do with endianness. Study enum for assembly.
// TODO: make a macro to simplify code
// magic
	m_fputs magicstr
	ldrb w21, [x20], 1
	m_printregh x21
	m_fputs space
	ldrb w21, [x20], 1
	m_printregh x21
	m_fputs space
	ldrb w21, [x20], 1
	m_printregh x21
	m_fputs space
	ldrb w21, [x20], 1
	m_printregh x21
	m_fputs newline
// 32/64 bit - simply multiply 1 or 2 by 32
	m_fputs classstr
	ldrb w21, [x20], 1
	mov x22, #32
	mul x21, x21, x22
	m_printregi x21
	m_fputs newline
// endianness
	ldrb w21, [x20], 1
	cmp x21, #1
	beq little_endian
	bne bigendian
little_endian:
	m_fputs littlestr
	b next
bigendian:
	m_fputs bigstr

next:
	m_fputs newline
// version
	ldrb w21, [x20], 1
	m_fputs versionstr
	m_printregi x21
	m_fputs newline
// target operating system
	ldrb w21, [x20], 1
	m_fputs abistr
	m_printregi x21
	m_fputs newline

// skip e_ident[EI_ABIVERSION] and e_ident[EI_PAD]
	ldrb w21, [x20], 8
// e_type (TODO: check that this can read 2 bytes instead of 1)
	ldrb w21, [x20], 2
	m_fputs typestr
	m_printregi x21
	m_fputs newline
// e_machine (TODO: check that this can read 2 bytes instead of 1)
	ldrb w21, [x20], 2
	m_fputs machinestr
	m_printregh x21
	m_fputs newline

// e_version (TODO: check that this can read 4 bytes instead of 1)
	ldrb w21, [x20], 4
	m_fputs eversionstr
	m_printregh x21
	m_fputs newline
// e_entry (TODO: check that this can read 4 bytes instead of 1)
	ldr x21, [x20], 8
	m_fputs entrystr
	m_printregh x21
	m_fputs newline
// e_phoff
	ldr x21, [x20], 8
	m_fputs e_phoffstr
	m_printregi x21
	m_fputs newline
// e_shoff
	ldr x21, [x20], 8
	m_fputs e_shoffstr
	m_printregi x21
	m_fputs newline
// e_flags
	ldrb w21, [x20], 4
	m_fputs e_flagsstr
	m_printregh x21
	m_fputs newline
// e_ehsize
	ldrb w21, [x20], 2
	m_fputs e_ehsizestr
	m_printregi x21
	m_fputs newline
// e_phentsize
	ldrb w21, [x20], 2
	m_fputs e_phentsizestr
	m_printregi x21
	m_fputs newline
// e_phnum
	ldrb w21, [x20], 2
	m_fputs e_phnumstr
	m_printregi x21
	m_fputs newline
// e_shentsize
	ldrb w21, [x20], 2
	m_fputs e_shentsizestr
	m_printregi x21
	m_fputs newline
// e_shnumize
	ldrb w21, [x20], 2
	m_fputs e_ehsizestr
	m_printregi x21
	m_fputs newline
// e_shstrmdx
	ldrb w21, [x20], 2
	m_fputs e_shstrmdxstr
	m_printregi x21
	m_fputs newline


close:
	mov x0, x19
	bl fclose
	cmp x0, #0
	bne error
	beq exit

error_open:
error:
	m_fputs errorstr
	m_fputs filepath
//       m_fputs newline
        mov x0, #1
        b exit


.data
filepath: .asciz "readelf"
magicstr: .asciz "ELF Magic:\t\t"
classstr: .asciz "Header format:\t\t"
littlestr: .asciz "Header endianness:\tLittle endian"
bigstr: .asciz "Header endianness:\tBig endian"
versionstr: .asciz "Version:\t\t"
abistr: .asciz "Target OS/ABI:\t\t"
typestr: .asciz "Type:\t\t\t"
machinestr: .asciz "Machine:\t\t"
eversionstr: .asciz "E_Version:\t\t"
entrystr: .asciz "Entry point address:\t"
e_phoffstr: .asciz "Start of program headers (bytes into file):\t"
e_shoffstr: .asciz "Start of section headers (bytes into file):\t"
e_flagsstr: .asciz "Flags:\t\t\t"
e_ehsizestr: .asciz "Size of this header:\t"
e_phentsizestr: .asciz "Size of program headers:\t"
e_phnumstr: .asciz "Number of program headers:\t"
e_shentsizestr: .asciz "Size of section headers:\t"
e_shnumstr: .asciz "Number of section headers:\t"
e_shstrmdxstr: .asciz "Section header string table index:\t"

errorstr: .asciz "An error has occurred reading elf headers for file: "

// the elf header from https://en.wikipedia.org/wiki/Executable_and_Linkable_Format#File_header
// NOTE: this only supports 64bit format. In 32bit, the offsets after 0x18 are different
// TODO: instead of reserving 64 bytes, make this dynamic
// it could be done with .ifdef ELF .. and .equiv for offsets (.equiv e_type 0x10)
// using base addr label + e_type would be okay then
.bss
memarea: .space 0x1000
// 0x0, e_ident
El_MAG0: .space 0x1	// must contain magic 0x7F 0x45 0x4C 0x56 (0x7F ELF)
El_MAG3: .space 0x3
El_CLASS: .space 0x1	// 1 for 32bit, 2 for 64bit format
El_DATA: .space 0x1	// 1 for little endian, 2 for big endian
El_VERSION: .space 0x1	// 1 for "original version of ELF"
El_OSABI: .space 0x1	// 0x03 = Linux. Currently we don't check for others
El_ABIVERSION: .space 0x1 // Os specific
El_PAD:	.space 0x7	// unused 7 bytes
// 0x10, e_type
e_type: .space 0x2	// 1 = reloc, 2 = exec, 3 = shared, 4 = core
e_machine: .space 0x2	// 0x03 = x86, 0xB7 = AArch64
e_version: .space 0x1	// set to 1
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

