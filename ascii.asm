data segment
	buffer db 'ASCII:', 5 dup('$')
data ends

code segment
start:
	; stack init -> SS SP
	mov ax, seg top
	mov ss, ax
	mov sp, offset top

	
	mov ax, seg data
	mov es, ax
	mov si, 82h ; si = address of program args
	
	
	mov di, offset buffer+6  	; +6, because insert after 'ASCII:'
	xor ax, ax				 	; ax = 0
	mov al, byte ptr ds:[si]	; first letter of arg
	call save_ax_number
	
    ; print buffer
	mov ax, seg buffer
	mov ds, ax
	mov dx, offset buffer
	xor ax, ax
	mov ah, 9
	int 21h
		
		
program_end:
	xor ax,ax
	mov ah, 4ch
	int 21h


; converts number in ax to string and saves to es:di
; parameters
; ax - number
; es:di - where to save
save_ax_number:
    mov cx, 0
    mov bx, 10 ; base of the numeral system

	loop_convert:
		mov dx, 0
		div bx		; ax = ax/bx
		; ax = ax/10	- integer result
		; dx = ax % 10	- remainder

		add dl, '0'
		
		push dx                         ; save letter to stack (letters are in reversed order)
		inc cx                          ; how many digits we pushed to stack

		cmp ax, 0
		jnz loop_convert
		
	loop_save:
		pop dx                          ; restore digits from last to first
		mov byte ptr es:[di], dl		; save letter
		inc di
		loop loop_save
	
	ret

	
code ends

stack segment stack
	dw 100 dup(?)
	top dw ?
stack ends


end start