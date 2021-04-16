;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       Brainfuck  Interpreter    ;;
;;        written by chocabloc     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Map (relative to PROG_BUFF):
;
; 0x0000 to 0x4000: Input Buffer
; 0x4000 to 0x8000: Preprocessor
; 0x8000 to 0x10000: Cells

BITS 64
ORG 0x10000
jmp entry

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;        Program Data          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_ADDR     equ 0x10000
SYSCALL_READ  equ 0	
SYSCALL_WRITE equ 1
SYSCALL_BRK   equ 12
SYSCALL_EXIT  equ 60

STDIN  equ 0
STDOUT equ 1

PROG_BUFF        equ 0x100000
BUFF_MAX_SIZE    equ 0x4000
PP_BUFF_MAX_SIZE equ 0x4000 * 8
PP_BUFF          equ PROG_BUFF + PP_BUFF_MAX_SIZE
CELLS            equ PP_BUFF + BUFF_MAX_SIZE

strWelcome:    db "Brainfuck Interpreter v1.0", 10, 10
strWelcomeLen equ 28
strPrompt:     db "bf> "
strPromptLen  equ 4

entry:
	; say hello
	mov rax, SYSCALL_WRITE
	mov rdi, STDOUT
	mov rsi, strWelcome
	mov rdx, strWelcomeLen
	syscall

	; the main loop
	mainLoop: 
	
	; print prompt
	mov rax, SYSCALL_WRITE
	mov rdi, STDOUT
	mov rsi, strPrompt
	mov rdx, strPromptLen
	syscall
	
	; get input
	mov rax, SYSCALL_READ
	mov rdi, STDIN
	mov rsi, PROG_BUFF
	mov rdx, BUFF_MAX_SIZE
	syscall
	mov r15, rax
	cmp rax, 0
	je exit
	
	; preprocess program
	; go backwards
	mov rdi, r15
	dec rdi
	ppLoopBk:
		cmp byte [rdi + PROG_BUFF], ']'
		jne .nst
		push rdi
		.nst:
		cmp byte [rdi + PROG_BUFF], '['
		jne .nnd
		pop rdx
		mov rax, rdi
		shl rax, 3
		mov qword [rax + PP_BUFF], rdx
		.nnd:
		dec rdi
		cmp rdi, -1
		jne ppLoopBk
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Start execution of program ;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; clear memory
	mov al, 0
	mov rcx, 0x8000
	mov rdi, CELLS
	rep stosb
	
	; execute
	xor rdi, rdi    ; instruction pointer
	xor rbx, rbx    ; cell pointer
	execLoop:
		mov cl, [rdi + PROG_BUFF]
		
		cmp cl, '>'
		jne .notRight
		inc rbx
		jmp .elEnd
		
		.notRight:
		cmp cl, '<'
		jne .notLeft
		dec rbx
		jmp .elEnd
		
		.notLeft:
		cmp cl, '+'
		jne .notInc
		inc byte [rbx + CELLS]
		jmp .elEnd
		
		.notInc:
		cmp cl, '-'
		jne .notDec
		dec byte [rbx + CELLS]
		jmp .elEnd
		
		.notDec:
		cmp cl, '.'
		jne .notPrt
		mov rsi, rbx
		call putchar
		jmp .elEnd
		
		.notPrt:
		cmp cl, ','
		jne .notInp
		mov rsi, rbx
		call getchar
		jmp .elEnd
		
		.notInp:
		cmp cl, '['
		jne .notLBR
		cmp byte [rbx + CELLS], 0
		jne .notLBRZ
		mov rax, rdi
		shl rax, 3
		mov rdi, [rax + PP_BUFF]
		jmp .elEnd
		.notLBRZ:
		push rdi
		jmp .elEnd
		
		.notLBR:
		cmp cl, ']'
		jne .elEnd
		cmp byte [rbx + CELLS], 0
		je .yesLBRZ
		mov rdi, [rsp]
		jmp .elEnd
		.yesLBRZ:
		pop rax
		
		.elEnd:
		inc rdi
		cmp rdi, r15
		jl execLoop
	
	jmp mainLoop
	
	exit:
	mov rax, SYSCALL_EXIT
	xor rdi, rdi
	syscall

; pointer to char should be in rsi
putchar:
	push rax
	push rdi
	push rdx
	mov rax, SYSCALL_WRITE
	mov rdi, STDOUT
	add rsi, CELLS
	mov rdx, 1
	syscall
	pop rdx
	pop rdi
	pop rax
	ret

; cell index should be in rsi
getchar:
	push rax
	push rdi
	push rdx
	mov rax, SYSCALL_READ
	mov rdi, STDIN
	add rsi, CELLS
	mov rdx, 1
	syscall
	pop rdx
	pop rdi
	pop rax
	ret
