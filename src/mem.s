// aarch64 (ARM 64bit) assembly code for GNU as assembler
//
// file: mem.s
// kernel memory functions

// TODO: make sure we're not wasting a 0x1000 bytes here and there 
// with unneeded .space 0x1000 aligning

.include "macros.s"
.include "globals.s"
.align word_s
// global functions in this file:
.global kheap_init
.global kmalloc
.global kfree
.global freemem
// TODO: kmem_debug: print # of used and free list items. Test with mallocing and freeing

// heap values
.equiv heap_chunksize, 0x1000 // 4096 bytes
.equiv heap_listmax, 0x10	// number of list items = allocable chunks
.equiv heap_size, heap_chunksize * heap_listmax // 0x1000 * 0x100 = 0x100000 = 4kb * 256

// TODO: find out the difference between mov and ldr, and the maximum value there
//.equiv freelist_empty, 0xFFFFFFFFFFFFFFFF
.equiv freelist_empty, 0xFFF

/* physical memory allocator in a nutshell:
// ideas from wikipedia https://en.wikipedia.org/wiki/Dynamic_memory_allocation

a fixed size memory (aka memory pool) allocator
- every allocation is in multiples of heap_chunksize chunks (4kb at the moment)
- a linked list holds the free memory chunks
	- every list item is 8 bytes - 64 bits
	- pointer heap_list_start holds the starting list item
	- every list item contains the address to the next list item
	- every list item has a corresponding mallocable memory area
	- the last item in list holds the value freelist_empty
	- if the first item (heap_list_start) holds freelist_empty, there's no free memory
	- maximum amount of list items is set in heap_listmax.

- kmalloc returns RET_ERR if it can't give out the required memory. Thus, we can change the
memory allocator insides later while kmalloc stays the same
*/


.text

kheap_init:
/*=============================================================================
setup kernel heap start address
setup the free linked list
register conventions:
	x0 list index accumulator
	x1 address of a free list item
	x2 address of a 4kb chunk in heap
	x9 temp
	x10 temp
=============================================================================*/
	m_callPrologue
	// print heap top
	m_fputs kheaptopstr
	ldr x1, =heap_unalignedtop
	and x1, x1, 0xFFFFFFFFFFFFF000
	ldr x0, =heap_topptr
	str x1, [x0]
	ldr x0, [x0]
	m_printregh x0
	m_fputs newline

	// align pointer and print heap base address
	m_fputs kheapbottomstr
	ldr x1, =heap_unalignedbase
	and x1, x1, 0xFFFFFFFFFFFFF000
	ldr x0, =heap_bottomptr
	str x1, [x0]
	ldr x0, [x0]
	m_printregh x0
	m_fputs newline

	m_fputs kheapliststr
	ldr x0, =heap_list_start
	m_printregh x0
	m_fputs newline

	// initialize the linked list of free memory areas
	// every list item should point to the next list item
	// last should be freelist_empty
	// iterate from bottom up
	mov x2, #0 // iterator
	mov x10, #0
	kheap_init_loop:
		cmp x2, heap_listmax
		beq kheap_init_lastitem
		// get address of current listitem to x0
		ldr x0, =heap_list_start
		mov x9, #stack_align
		mul x10, x2, x9
		add x0, x0, x10

		// set value of address in x0 to the next listitem (x0 + #stack_align)
		mov x1, x0
		add x1, x1, #stack_align	// x1 now holds heap_bottom + index * heap chunk size
		str x1, [x0]

/*		// debug
		 str x0, [sp, #-stack_align]!
		 str x1, [sp, #-stack_align]!
		 str x2, [sp, #-stack_align]!
 		bl memdump
		ldr x2, [sp], #stack_align
		ldr x1, [sp], #stack_align
		ldr x0, [sp], #stack_align
*/		// debug end
		add x2, x2, #1
		b kheap_init_loop
	kheap_init_lastitem:

		// get address of current listitem to x0
		ldr x0, =heap_list_start
		mov x9, #stack_align
		mul x10, x2, x9
		add x0, x0, x10

		// set value of address in x0 to mark end of list
		ldr x1, =freelist_empty
		str x1, [x0]
// for debug	bl memdump
	bl freemem
	m_callEpilogue
	ret

mm_freelist_getlistaddr:
/*=============================================================================
Given an address to allocable memory, calculate the address of free list item
Note that this is used by free, so the item might not be part of the free list
register conventions:
	x0 (input) address of allocable memory, (output) address of free list item
	x1 temp
=============================================================================*/
	// from allocable address to allocable index:
	// index = (address - heap_bottom) / chunksize
	ldr x1, =heap_bottomptr
	ldr x1, [x1]
	sub x0, x0, x1
	mov x1, heap_chunksize
	udiv x0, x0, x1
	// from allocable index (= list index) to list address
	// address = heap_list_start + (index * listitemsize)
	mov x1, #stack_align
	mul x0, x0, x1
	ldr x1, =heap_list_start
	add x0, x1, x0
	ret

mm_freelist_getallocaddr:
/*=============================================================================
Given an address to a free list item, calculate the corresponding (mallocable) memory address
adresses are4kb aligned
register conventions:
	x0 (input) address of listitem, (output) address of memory location
	x1 temp
=============================================================================*/
	m_callPrologue
	// From list address to list index:
	// index = (address - heap_list_start) / listitemsize (8bytes)
	ldr x1, =heap_list_start
	sub x0, x0, x1
	mov x1, #stack_align
	udiv x0, x0, x1	// x0 now contains a list index
	// from list index to memory address: heap_bottom + (index * chunksize)*
	ldr x1, =heap_chunksize
	mul x1, x0, x1
	ldr x0, =heap_bottomptr
	add x0, x0, x1
	// 4kb align
	and x0, x0, 0xFFFFFFFFFFFFF000
	m_callEpilogue
	ret

mm_freelist_getlast:
/*=============================================================================
Get the addresses of second and second last items in free list
register conventions:
	x0 (output) address of last item in list
	x1 (output) address of second last item in list
=============================================================================*/
	m_callPrologue
	ldr x0, =heap_list_start
	ldr x1, =heap_list_start
	getlast_loop:
		ldr x2, [x0]
		cmp x2, freelist_empty // is this the last?
		beq getlast_lastfound
		mov x1, x0 		// last becomes second last
		ldr x0, [x0]		// follow the list
		b getlast_loop
	getlast_lastfound:
	// we've found the last (and second last item. Return
	// x1 now has the memory address of the last item
	m_callEpilogue
	ret


kmalloc:
/*=============================================================================
reserve a chunk of sizeheap_chunksize. Return the address
register conventions:
	x0 (input) size of area in 4kb chunks, (output) start address or RET_ERR
	x1, x2: temp
=============================================================================*/
	m_callPrologue
	// get the last and second last items in list
	bl mm_freelist_getlast
	// see that we have a free list item to allocate. If not, return 0
	ldr x2, =heap_list_start
	cmp x0, x2
	beq malloc_reterr
	// remove the last item from free list by making secondlast last
	mov x2, freelist_empty
	str x2, [x1]
	// return the adress to allocable memory
	bl mm_freelist_getallocaddr
	// for debug
	str x0, [sp, #-stack_align]!
	m_fputs debugmalloc
	ldr x0, [sp], #stack_align
	bl memdump
	// end debug
	// return address of memory - corresponds to last item of free list
	m_callEpilogue
	ret
	// return error, no free memory left
	malloc_reterr:
	mov  x0, RET_ERR
	bl exit
	m_callEpilogue
	ret

kfree:
/*=============================================================================
return the area to free linked list
register conventions:
	x0 (input) start address of freed memory area
	x9 temp holding address of list item
=============================================================================*/
	m_callPrologue
	// get list item equivalent to allocated memory
	bl mm_freelist_getlistaddr
	mov x9, x0
	// get last
	bl mm_freelist_getlast
	// make last secondlast by pointing it to the newly freed item
	str x9, [x1]
	// for debug - see that we allocated the right address
	mov x0, x9
	bl mm_freelist_getallocaddr
	str x0, [sp, #-stack_align]!
	m_fputs debugfree
	ldr x0, [sp], #stack_align
	bl memdump
	// end debug

	m_callEpilogue
	ret

freemem:
/*=============================================================================
Print out currently available memory
register conventions:
=============================================================================*/
	m_callPrologue
	m_fputs freememstr
	mov x0, #0 // iterator
	ldr x1, =heap_list_start
	ldr x2, =freelist_empty
	freememloop:
		cmp x1, x2
		beq freemem_finished
		ldr x1, [x1]
		add x0, x0, #1
		b freememloop
	freemem_finished:
		
	sub x0, x0, #1	// we won't be allocating the last in list
	mov x1, heap_chunksize
	mul x0, x0, x1
	m_printregh x0
	m_fputs newline
	m_callEpilogue
	ret

kheapliststr: .asciz "Kernel heap free list start: "
kheapbottomstr: .asciz "Kernel heap bottom: "
kheaptopstr: .asciz "Kernel heap top: "
debugmalloc: .asciz "kmalloc debug, just malloc'd: "
debugfree: .asciz "free debug, just freed: "
freememstr: .asciz "Currently available memory (bytes): "

	/* heap_topptr and heap_bottomptr hold the values for
	the heap. The labels heap_unaligned* are there simply for calculation
	and should not be referred to after initializing.
	I'd want to avoid this by 4kb aligning the labels for the pointers,
	but don't know how to do.
	When using pointers, remember to:
	1. load the address of the label to a register (pointer)
	2. load the contents (pointer value) of that register to the same register
	*/

.bss
heap_list_start: .space 8*heap_listmax + 8 // list should have enough room for 8byte list items 
heap_list_end: .space 0x1000
heap_bottomptr: .space 0x8
heap_topptr: .space 0x8
// .space 0x1000 are to make sure we're able to 4kb align
heap_unalignedbase:
.space 0x1000
.space heap_size
heap_unalignedtop: .space 0x1000
