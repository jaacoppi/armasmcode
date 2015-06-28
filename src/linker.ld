ENTRY(_start)
SECTIONS {
/*	. = 0x1000000; */
	/* QEMU aarch64 virt machine expects the OS to run at 1gb mark */
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
