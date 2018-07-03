# About #
These files contain 64-bit ARM (aka A64, ARM64, aarch64) assembly code for the GNU as and ld.

The code contains snippets of:
	* standard C library (stdlib.a)
	* Bare bones OS (armv8bin) using qemu-system-aarch64
	* userland programs using linux syscalls

If there'll ever be a proper hardware target, this codebase might become an operating system.


## disarm64 ##
Disarm64 is a dissassembler for armv8 written in armv8. It doesn't support the full ISA but enough opcodes to dissamble itself.

Usage: disarm64 <file>
