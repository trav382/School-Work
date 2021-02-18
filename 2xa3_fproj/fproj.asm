%include "simple_io.inc"
   
global  asm_main

SECTION .data

err1: db "Incorrect number of command line arguements", 0
err2: db "Input string is too long",0
bordar: dq 0,0,0,0,0,0,0,0,0,0,0,0 ;; qword array of size 12
msg: db "Border Array: ", 0
msg2: db "Input string: ",0


ErrorArgs:
	mov rax, err1  ;; print arguement error
	call print_string
	call print_nl
	jmp asm_main_end  ;; terminate program

LenError:
	mov rax, err2
	call print_string
	call print_nl
	jmp asm_main_end
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
maxbord:
	enter 0,0
	saveregs
	mov rcx, qword 1 ;; outer loop counter
	mov r15, 0 ;; max value 
outerloop:

	cmp rcx,[rbp+32] ;; compare r with str len
	je maxbord_end

	mov rbx, 0 ;; inside loop counter
	mov rdi, 1 ;; ISBORDER value
	
innerloop:
	
	cmp rbx, rcx    ;; comparing rbx(i) to rcx(r)
	je innerloopdone
	mov r12, [rbp+24] ;; putting string into r12
	push r12 
	pop r13 ;; putting string
	mov r14, 0
	add r14, [rbp+32] ;;adding len to r14
	sub r14, rcx
	add r14, rbx ;; r14 holds l - r+i
	add r13, r14 ;; r13 holds end string
	add r12, rbx ;; adding i value to string

	mov al, byte[r12] ;; moving first char to compare
	cmp al, byte[r13] ;; comparing first char to last
	jne beforedone
			
	
	
	inc rbx ;; incrementing i 
	jmp innerloop
			
beforedone:
	mov rdi, 0 ;;  set isborder value to 0
	jmp innerloopdone

innerloopdone:
	
	cmp rdi, 1
	jne notequal ;; if isborder is not equal to 1, jump back toloop 
	cmp r15, rcx
	jae notequal
	push rcx
	pop r15
	inc rcx 	
	jmp outerloop	
notequal:
	inc rcx
	jmp outerloop
	

maxbord_end:
	mov rax, r15
	;;call print_int
	restoregs
	leave
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Len: 
	enter 0,0
	saveregs
	
	mov rax, [rbp+16]
        mov rcx, 0 
        dec rax
        count:
          inc rcx
          inc rax
          cmp byte[rax], 0
          jnz count
        dec rcx
        mov rax, rcx
        
	
	restoregs
	leave
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

simple_display:
	
	enter 0,0 
	saveregs
	
	mov rdx, [rsi+8] ;; moving string into rdx

	mov rcx, qword 0 ;; counter for loop
	mov rbx, 0 ;; moving array into rbx
	mov r9, [rbp+24] ;; moving bordar into r9
	mov r15, [rbp+32] ;; str length 
	
	LOOP:
		cmp rcx, [rbp+32]
		je preloop2
		push r15
		push rdx
		sub rsp,8
		call maxbord
		add rsp, 24		
		mov [bordar+rbx], rax

		add rbx, qword 8
 
		inc rdx
		dec r15
		inc rcx
		jmp LOOP

	 preloop2:
   	 mov rax, 0
	 mov rax, msg
	 call print_string
	 mov rcx, qword 0 ;;resetting counter
	 mov rbx, bordar ;; moving string into rbx
	 mov r15, 0 ;; counter
	 mov r14, [rbp+32] ;; set str len
	 sub r14, qword 1
	 LOOP2:

		cmp rcx, r14 ;; compare counter to len of array
		je array_end
		
		mov rax, [rbx+r15]
		call print_int
		mov al, ","
		call print_char
		mov al, " "
		call print_char

		add r15, qword 8
		inc rcx
		jmp LOOP2 		


array_end:
	mov rax, [rbx+r15]
	call print_int

	call print_nl	
	restoregs
	leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fancy_display:
	enter 0,0 
	saveregs
	mov rbx, [rbp+24] ;; move bordar into rbx
	mov r15, [rbp+32] ;; move len into r15 ;; level
	
	mov rdi, 0
	mov r13, 0	
	mov rcx, 1 ;; outer count
	
	outer_loop:
	
		mov rdx, 0 ;; inside counter
		mov r12, 0 ;; index counter
		cmp rcx, [rbp+32]
		je one_last_time
	inner_loop:
		
		cmp rdx, [rbp+32]
		je inner_loop_done
		mov rax, [rbx+r12]
		cmp rax, r15
		je equal
		jmp not_equal
	cont:
		add r12, 8 ;; add index
		inc rdx
		jmp inner_loop
		
	equal:
		mov rax, [rbx+r12]
		sub rax, 1
		mov [rbx+r12], rax
		mov al, "+"
		call print_char
		call print_char
		call print_char
		mov al, " "
		call print_char
		call print_char
		jmp cont
	not_equal:
		mov al, " "
		call print_char
		call print_char
		call print_char
		call print_char
		call print_char
		jmp cont	
		
	inner_loop_done:
		inc rcx
		dec r15
		call print_nl
		jmp outer_loop
		
	one_last_time:
		
		cmp rdx, [rbp+32]
		je fancy_display_end
		mov rax, [rbx+r12]
	
		cmp rax, 1
		jne zero_case  ;; either value of indexed array  is 0 or 1
		jmp match
		mov rax, [rbx+12]
	
	keep_going:
		add r12, 8 ;;index
		inc rdx
		jmp one_last_time

	match:
		mov al, "+"
		call print_char
		call print_char
		call print_char
		mov al, " "
		call print_char
		call print_char
		jmp keep_going
	
	zero_case:
		mov al, "."
		call print_char
		call print_char
		call print_char
		mov al, " "
		call print_char
		call print_char
		jmp keep_going
		
fancy_display_end:
	call print_nl	
	restoregs 
	leave
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
asm_main:

	enter 0,0 
	saveregs
		
	cmp rdi, qword 2  ;; arguements should be 2
	jne ErrorArgs
	mov rax, [rsi+8] ;; move string into rax 
	push rax	 ;; push string 
	call Len	;; call subroutine that should compute len of string
	add rsp,8
	
	
	cmp rax, qword 12
	jg LenError
	push rax
	mov rax, msg2 	;; gotta print out input string 
	call print_string
	mov rax, [rsi+8]
	call print_string
	call print_nl
	pop r15 

	;;mov r15, rax ;; MOVING LEN OF STR INTO R15
	
	push r15 	;; push len , should be rbp+32
	mov rax, [rsi+8] ;; move and push string input into maxboard should be rbp+24
	push rax
	sub rsp, 8	;; fake param
	call maxbord
	add rsp, 24     ;; rax holds maxbord value
	 
		

	mov rax, [rsi+8];; moving string into rax
	
	push rax	;; push rax  
	call Len        ;; need length of string again
	add rsp, 8      ;; clean stack

	push rax        ;; pushing string length, rbp+32
	pop r12
	
	push rax
	mov rax, bordar ;; moving bordar into rax
	push rax        ;; pushing bordar ;; rbp+24
	sub rsp, 8 	;; fake param
	call simple_display
	add rsp, 24

	mov rax, r12 ;; moving string/array length into stack rbp+32
	push rax
	mov rax, bordar
	push rax ;; pushing bordar(array) rbp+24 
	sub rsp, 8
	call fancy_display
	add rsp, 24	;;clean stack
	
	



  asm_main_end:

	restoregs
	leave
	ret
   
