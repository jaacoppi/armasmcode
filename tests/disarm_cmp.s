// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: disarm_cmp.s
// test cases for dissassembling opcodes related to mnemonic CMP

.global _start
.balign 4
.text
_start:
cmp x28, 0xFF
cmp x10, 0xFFFFFFFFFFFFFFFD 	// -3, changes cmp disassembly to cmn
