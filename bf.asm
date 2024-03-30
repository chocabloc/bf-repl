section .text
global _start

BUFF_MAX_SIZE    equ 0x10000
PP_BUFF_MAX_SIZE equ BUFF_MAX_SIZE * 8
PP_BUFF          equ PROG_BUFF + BUFF_MAX_SIZE
CELLS            equ PP_BUFF + PP_BUFF_MAX_SIZE

strWelcome:    db "Brainfuck Interpreter v1.0", 10, 10
strWelcomeLen equ $-strWelcome
strPrompt:     db "bf> "
strPromptLen  equ $-strPrompt

_start:

xor ebp, ebp   ; cell pointer

cmp qword [rsp], 1
je repl

; open file
mov rax, 2
mov rdi, [rsp + 16]
xor esi, esi
syscall
mov rdi, rax
jmp readInput

repl:

; say hello
mov rax, 1
mov rdi, 1
mov rsi, strWelcome
mov rdx, strWelcomeLen
syscall

mainLoop:
	
	; print prompt
	mov rax, 1
	mov rdi, 1
	mov rsi, strPrompt
	mov rdx, strPromptLen
	syscall
	
	xor edi, edi
	readInput:
	xor eax, eax
	mov rsi, PROG_BUFF
	mov rdx, BUFF_MAX_SIZE
	syscall
	
	cmp rax, 1
	je exit
	mov r8, rax
	
	; preprocess program
	; go backwards
	lea rbx, [r8 - 1]
	ppLoop:
		cmp byte [PROG_BUFF + rbx], ']'
		jne .nst
		push rbx
		jmp .nnd
		.nst:
		cmp byte [PROG_BUFF + rbx], '['
		jne .nnd
		pop rsi
		mov qword [PP_BUFF + rbx*8], rsi
		.nnd:
		dec rbx
		jns ppLoop
	
	xor ebx, ebx    ; instruction pointer
	mov rdx, 1      ; bytes to read/write
	
	execLoop:
		
		mov cl, [PROG_BUFF + rbx]
		
		cmp cl, '>'
		jne .notRight
		inc bp
		jmp .next
		
		.notRight:
		cmp cl, '<'
		jne .notLeft
		dec bp
		jmp .next
		
		.notLeft:
		cmp cl, '+'
		jne .notInc
		inc byte [CELLS + rbp]
		jmp .next
		
		.notInc:
		cmp cl, '-'
		jne .notDec
		dec byte [CELLS + rbp]
		jmp .next
		
		.notDec:
		cmp cl, '.'
		jne .notPrt
		mov rax, 1
		mov rdi, 1
		lea rsi, [CELLS + rbp]
		syscall
		jmp .next
		
		.notPrt:
		cmp cl, ','
		jne .notInp
		xor eax, eax
		xor edi, edi
		lea rsi, [CELLS + rbp]
		syscall
		jmp .next
		
		.notInp:
		cmp cl, '['
		jne .notLBR
		cmp byte [CELLS + rbp], 0
		jne .notZero
		mov rbx, [PP_BUFF + rbx*8]
		jmp .next
		.notZero:
		push rbx
		jmp .next
		
		.notLBR:
		cmp cl, ']'
		jne .next
		cmp byte [CELLS + rbp], 0
		je .isZero
		mov rbx, [rsp]
		jmp .next
		.isZero:
		pop rsi
		
		.next:
		inc rbx
		cmp rbx, r8
		jl execLoop
	
	cmp qword [rsp], 1
	je mainLoop

exit:
mov rax, 60
xor edi, edi
syscall

section .bss
PROG_BUFF:
resb 0xA0000
