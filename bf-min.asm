filestart:

ORG 0x10000
BITS 64

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      The ELF Header      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
db 0x7f, 'E', 'L', 'F'		; magic number
db 2						; bits, 2 for 64
db 1						; endianness, 1 for little
db 1						; should be 1
db 0						; ABI, 0 for System V

; 8 unused bytes, put exit function here
exit:
mov rax, 60
syscall
db 0

dw 2						; type, 2 for executable
dw 0x3e						; ISA, 0x3e for amd64

; there should be some version info here
; but linux doesn't care apparently
strPrompt db "bf: "
strPromptLen equ $-strPrompt

dq init						; entry point
dq phdr_off					; phdr table offset

; should be shdr information, flags and
; size of elf header here, but
; linux doesn't care, again
init:
xor ebp, ebp   ; cell pointer
xor ebx, ebx    ; instruction pointer
cmp qword [rsp], 1
je repl
jne start
db 0

dw 0x38						; size of phdr entry
dw 1						; number of phdrs
; 6 bytes of shdr information here, but linux
; doesn't care so we can overlap with phdr

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    The Program Header   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
phdr_off equ $-filestart
filesize equ PROG_BUFF-filestart
memsize equ filesize + BUFF_MAX_SIZE + PP_BUFF_MAX_SIZE*2

dd 1						; type, 1 for PT_LOAD
dd 0b111					; flags, R+W+X
dq 0						; offset, load from the beginning
dq 0x10000					; virtual address to load at
dq 0						; physical address, unneeded
dq filesize					; size of segment in file
dq memsize					; size of segment in memory
; 8 bytes containing alignment here
; but apparently linux ignores invalid values


BUFF_MAX_SIZE    equ 0x10000
PP_BUFF_MAX_SIZE equ BUFF_MAX_SIZE * 8
PP_BUFF          equ PROG_BUFF + BUFF_MAX_SIZE
CELLS            equ PP_BUFF + PP_BUFF_MAX_SIZE

start:

; open file
mov eax, 2
mov rdi, [rsp + 16]
xor esi, esi
syscall
mov edi, eax
jmp readInput

repl:
	
	; print prompt
	mov eax, 1
	mov edi, 1
	mov esi, strPrompt
	mov edx, strPromptLen
	syscall
	
	xor edi, edi
	readInput:
	xor eax, eax
	mov esi, PROG_BUFF
	mov edx, BUFF_MAX_SIZE
	syscall
	
	mov r8, rax
	dec eax
	jz exit
	
	; preprocess program
	; go backwards
	ppLoop:
		cmp byte [PROG_BUFF + rax], ']'
		jne .nst
		push rax
		.nst:
		cmp byte [PROG_BUFF + rax], '['
		jne .nnd
		pop rcx
		mov qword [PP_BUFF + rax*8], rcx
		.nnd:
		dec eax
		jns ppLoop

	mov edx, 1      ; bytes to read/write
	
	execLoop:
		xor eax, eax
		xor edi, edi
		mov cl, [PROG_BUFF + rbx]
		
		cmp cl, '>'
		jne .notRight
		inc ebp
		
		.notRight:
		cmp cl, '<'
		jne .notLeft
		dec ebp
		
		.notLeft:
		lea esi, [CELLS + ebp]
		mov ch, [esi]
		cmp cl, '+'
		jne .notInc
		inc ch
		
		.notInc:
		cmp cl, '-'
		jne .notDec
		dec ch
		
		.notDec:
		mov byte [CELLS + ebp], ch
		cmp cl, '.'
		jne .notPrt
		inc eax
		inc edi
		syscall
		
		.notPrt:
		cmp cl, ','
		jne .notInp
		syscall
		
		.notInp:
		cmp cl, '['
		jne .notLBR
		test ch, ch
		jnz .notZero
		mov ebx, [PP_BUFF + rbx*8]
		jmp .next
		.notZero:
		push rbx
		
		.notLBR:
		cmp cl, ']'
		jne .next
		test ch, ch
		jz .isZero
		mov rbx, [rsp]
		jmp .next
		.isZero:
		pop rax
		
		.next:
		inc ebx
		cmp rbx, r8
		jl execLoop
	
	cmp qword [rsp], 1
	je repl

jmp exit

PROG_BUFF:
