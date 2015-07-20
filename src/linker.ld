/*  
when using the vector table
ENTRY(_vectorentry) 
*/
ENTRY(_start)
SECTIONS {
/* Memory map when using Qemu VIRT:
Exception vector table	: 0x0
VIRTIO UART		: 0x9000000
OS			: 0x40000000
*/

/* This would work, but the "b" opcode apparently only takes 26 bits -> 0x400000, 
one 16th of the required jump from 0 to 0x40000000. 
Thus, we forget about the vector table for now */
/*
	. = 0x0;
	.text : { 
	src/except.o(.text)
	. = 0x40000000;
	*(.text)
	}
*/
/* This works if we don't setup the vector table */
	. = 0x40000000;
	.text : { *(.text) } 


	.data : { *(.data) }
/*	.rodata : { *(.rodata) } */
	/* we need mem.o before main.o so heap will be there before stack */
	. += 0x1000;
	.bss : ALIGN(0x1000) {
	src/mem.o(.bss) 
	. += 0x1000; /* guard between heap and stack */
	src/main.o(.bss) /* TODO: set stack address with ORIGIN */
	*(.bss COMMON) 
	}
}
