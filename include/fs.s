// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: fs.s
// used for lseek definitions. In linux these are in /usr/include/linux/fs.h

.align 8	// all instructions 8-byte (64bit) aligned

.ifndef TYPES	// only include once
.equiv SEEK_SET,        0       // seek relative to beginning of file
.equiv SEEK_CUR,        1       // seek relative to current file position
.equiv SEEK_END,        2       // seek relative to end of file
.equiv SEEK_DATA,       3       // seek to the next data
.equiv SEEK_HOLE,       4       // seek to the next hole
.equiv SEEK_MAX,        SEEK_HOLE
.endif
