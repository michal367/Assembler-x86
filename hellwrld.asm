data segment
	text db "Hello World!",13,10, '$'
data ends

code segment
start:
	; stack init -> SS SP
	mov ax, seg top
	mov ss, ax
	mov sp, offset top

	; set ds, dx to text
	mov ax, seg text
	mov ds, ax
	mov dx, offset text
	
	; print
	mov ah, 9
	int 21h
	
	; end program
	mov ax, 4c00h
	int 21h

code ends

stack segment stack
	dw 100 dup(?)
	top dw ?
stack ends

end start




