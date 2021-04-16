ENTRY(_start)

MEMORY
{
	TEXT (rx) : ORIGIN = 0x10000, LENGTH = 256k
	BSS (rwx) : ORIGIN = 0x100000, LENGTH = 256k
}

SECTIONS
{
	. = 0x10000;
	_start = .;
	.text : ALIGN(0x1000)
	{
		*(.text)
	} >TEXT
	.bss : {
		. = . + 256k;
		. = ALIGN(8);
	} >BSS
}

