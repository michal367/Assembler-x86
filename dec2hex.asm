data segment
	arg db 100 dup('$')
	enter_ch db 13,10,'$'
data ends

code segment
start:
	; stack init -> SS SP
	mov ax, seg top
	mov ss, ax
	mov sp, offset top

	mov si, 82h ; si = address of program args
	mov cl, byte ptr ds:[80h] ; cl = number of characters
	dec cx
	
	mov bx, 10 ; base of source numeral system
	call string_to_number

	mov bx, 16 ; base of target numeral system
	call print_ax_number
	
program_end:
	xor ax, ax
	mov ah, 4ch
	int 21h

	
; ================

; converts string from ds:si and saves to ax
; parameters
; ds:si - address of string
; bx - base of the numeral system
string_to_number:

	xor ax, ax
	xor dx, dx
	;mov bx, 10

	str_loop:
		mul bx ; ax = ax*bx
		
		mov dl, byte ptr ds:[si]
		inc si ; si++
		
		; convert from ASCII to digit
		cmp dl, 'A'
		jge greater_eq
		sub dl, '0' 
		jmp str_next
		greater_eq:
			sub dl, 'A'
			add dl, 10
		
		str_next:
		add ax, dx		; adding next digit to ax
		
		loop str_loop  	; cx=cx-1; if cx>0 goto str_loop

	ret


; print number that is in ax
; parameters
; ax - number to print
; bx - base of the numeral system
print_ax_number:
    mov cx, 0
    ;mov bx, 16

	convert_loop:
		mov dx, 0
		div bx		; ax = ax/bx
		; ax = ax/bx	- integer result
		; dx = ax % bx	- remainder
		
		; convert digit to ASCII
		cmp dl, 9
		jg greater
		add dl, '0'
		jmp next
		greater:
			sub dl, 10
			add dl, 'A'

		next:
		push dx                     ; save letter to stack (letters are in reversed order)
		inc cx                      ; how many digits we pushed to stack

		cmp ax, 0
		jnz convert_loop
		
	; print string
	mov ah, 2						; 2 is the function number of output char in the DOS Services
	print_char_loop:
		pop dx                      ; restore digits from last to first
		int 21h                     ; calls DOS Services
		loop print_char_loop		; cx=cx-1; if cx>0 goto print_char_loop
	
	ret

	
code ends


stack segment stack
	dw 100 dup(?)
	top dw ?
stack ends


end start