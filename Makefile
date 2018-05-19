#############################################################################
# Makefile for building: armv8bin
# Generated by hand from a qmake template
#############################################################################

####### Compiler, tools and options

## TARGET is either USER or SYS, default to USER
# see make help for details
TARGET=USER

# for linux
AS	= aarch64-linux-gnu-as
ASFLAGS = -mverbose-error -I include --defsym $(TARGET)=1
LD	= aarch64-linux-gnu-ld

# linker script for kernel
LDFLAGS = -T src/linker.ld
# for creating STDLIB
AR	= ar
ARFLAGS = -rcs

####### for Qemu
QEMU_SYSTEM_AARCH64	= qemu-system-aarch64
QEMU_AARCH64		= qemu-aarch64

####### Files

BINDIR = bin
LIBDIR = lib

HEADERS 	= include/macros.s \
	 	  include/globals.s \
		  include/fcntl.s \
		  include/fs.s
### Kernel
KERNEL = armv8bin
KERNEL_OBJS	= src/main.o \
		src/debug.o \
		src/mem.o \
		src/except.o \

### STDLIB
STDLIB = stdlib.a
STDLIB_OBJS	= src/stdio.o \
		src/string.o \
		src/stdlib.o \
		src/usermodesys.o

### userland programs
CAT 		= cat
CAT_OBJS	= userland/cat.o
DISARM64	= disarm64
DISARM64_OBJS	= userland/disarm64.o userland/elf.o userland/decode.o
HEXDUMP		= hexdump
HEXDUMP_OBJS	= userland/hexdump.o
NEWFILE 	= newfile
NEWFILE_OBJS 	= userland/newfile.o
READELF 	= readelf
READELF_OBJS 	= userland/readelf.o userland/elf.o

## compilation of all userland programs
USERLAND_PROGS = build_hook $(CAT) $(DISARM64) $(HEXDUMP) $(NEWFILE) $(READELF)
USERLAND_OBJS = $(CAT_OBJS) $(DISARM64_OBJS) $(HEXDUMP_OBJS) $(NEWFILE_OBJS) $(READELF_OBJS)


## assembly and linking
all: build_hook $(STDLIB) $(KERNEL) $(USERLAND_PROGS)

build_hook:
	mkdir -p $(BINDIR) $(LIBDIR) tests/bin


$(STDLIB): $(STDLIB_OBJS) $(HEADERS)
	$(AR) $(ARFLAGS) $(LIBDIR)/$(STDLIB) $(STDLIB_OBJS)

$(KERNEL):  $(KERNEL_OBJS) $(STDLIB) $(HEADERS)
	$(LD) $(LDFLAGS) -o $(BINDIR)/$(KERNEL) $(KERNEL_OBJS) $(LIBDIR)/$(STDLIB)

userprogs: $(USERLAND_PROGS)

$(CAT):  $(STDLIB) $(CAT_OBJS) $(HEADERS)
	$(LD) -o $(BINDIR)/$(CAT) $(CAT_OBJS) $(LIBDIR)/$(STDLIB)

$(DISARM64): $(STDLIB) $(DISARM64_OBJS) $(HEADERS)
	$(LD) -o $(BINDIR)/$(DISARM64) $(DISARM64_OBJS) $(LIBDIR)/$(STDLIB)

$(HEXDUMP):  $(STDLIB) $(HEXDUMP_OBJS) $(HEADERS)
	$(LD) -o $(BINDIR)/$(HEXDUMP) $(HEXDUMP_OBJS) $(LIBDIR)/$(STDLIB)

$(NEWFILE):  $(STDLIB) $(NEWFILE_OBJS) $(HEADERS)
	$(LD) -o $(BINDIR)/$(NEWFILE) $(NEWFILE_OBJS) $(LIBDIR)/$(STDLIB)

$(READELF):  $(STDLIB) $(READELF_OBJS) $(HEADERS)
	$(LD) -o $(BINDIR)/$(READELF) $(READELF_OBJS) $(LIBDIR)/$(STDLIB)

clean: 
	rm -f $(KERNEL_OBJS) $(STDLIB_OBJS) $(USERLAND_OBJS)
	rm -f $(KERNEL)
	rm -rf $(BINDIR) $(LIBDIR)
	rm -rf tests/*.o
	rm -rf tests/bin
	rm -rf tests/*.txt
####### Compile

main.o: src/main.s
	$(AS) $(ASFLAGS) -o @ src/main.s

except.o: src/except.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ src/except.s

stdio.o: src/stdio.s $(HEADERS)
	 $(AS) $(ASFLAGS) -o @ src/stdio.s

debug.o: src/debug.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ src/debug.s

string.o: src/string.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ src/string.s

stdlib.o: src/stdlib.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ src/stdlib.s

mem.o: src/mem.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ src/mem.s


usermodesys.o: src/usermodesys.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ src/usermodesys.s

## userland
cat.o: userland/cat.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ userland/cat.s

disarm64.o: userland/disarm64.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ userland/disarm64.s

newfile.o: userland/newfile.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ userland/newfile.s

readelf.o: userland/readelf.s $(HEADERS)
	$(AS) $(ASFLAGS) -o @ userland/readelf.s

elf.o: userland/elf.s $(HEADERS) userland/elf.o
	$(AS) $(ASFLAGS) -o @ userland/elf.s

### tests
check: build_hook disarm_ldr1.o disarm_bl1.o disarm_cmp.o
	tests/opcodes.test
	rm tests/actual.txt tests/expected.txt

disarm_ldr1.o: tests/disarm_ldr1.s
	$(AS) $(ASFLAGS) -o tests/disarm_ldr1.o tests/disarm_ldr1.s
	$(LD) -o tests/bin/disarm_ldr1 tests/disarm_ldr1.o

disarm_bl1.o: tests/disarm_bl1.s
	$(AS) $(ASFLAGS) -o tests/disarm_bl1.o tests/disarm_bl1.s
	$(LD) -o tests/bin/disarm_bl1 tests/disarm_bl1.o

disarm_cmp.o: tests/disarm_cmp.s
	$(AS) $(ASFLAGS) -o tests/disarm_cmp.o tests/disarm_cmp.s
	$(LD) -o tests/bin/disarm_cmp tests/disarm_cmp.o

####### Install

install:   FORCE
uninstall:   FORCE
FORCE:
run:	system-run

system-run:	$(KERNEL)
	@echo running in full system emulation mode. See that you make TARGET=SYS
	$(QEMU_SYSTEM_AARCH64) -machine virt -cpu cortex-a57 -nographic -smp 1 -m 512M -kernel $(KERNEL) --append "console=ttyAMA0"

help:
	@echo "possible configurations:"
	@echo "what to make:"
	@echo "make 				=> make all"
	@echo "make $(KERNEL)			=> just kernel"
	@echo "make $(STDLIB)			=> just stdlib"
	@echo "make userprogs			=> just userland programs"
	@echo "how to make:"
	@echo "make TARGET=USER	(default)   	=> using linux syscalls"
	@echo "make TARGET=SYS			=> system emulation mode, no syscalls"
	@echo "how to run:"
	@echo "make system-run		    	=> run kernel in qemu full system emulation"
