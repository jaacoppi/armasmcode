// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: lean.s
// LEAN filesystem implementation. See http://freedos-32.sourceforge.net/lean/

.include "macros.s"
.include "globals.s"
.align word_s
// global functions in this file:


// currently LEAN is debugged in linux user space since
// other methods of accessing hard disks are unavailable
