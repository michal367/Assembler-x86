data segment
	arg1 db 100 dup('$')
	arg2 db 100 dup('$')
	arg3 db 100 dup('$')
	
	bad_args db 'Invalid arguments were entered', 13, 10,
				'There must be 3 args separated by spaces', '$'
	enter_ch db 13,10,'$'
data ends


code segment
start:
	; stack init -> SS SP
	mov ax, seg top
	mov ss, ax
	mov sp, offset top
	
	; in the beggining of program DS is set to PSP (Program Segment Prefix)
	; that's why we don't change DS for now and we use ES
	
	; Program Segment Prefix
	; program.exe arg1 arg2 arg3
	; we can read args from DS:x
	; x:
	; 80h - number of characters
	; 81h=' '
	; 82h=arg1 arg2 arg3
	
	mov si, 82h 				; si = address of program args
	xor cx, cx 					; cx = 0
	mov cl, byte ptr ds:[80h] 	; cl = number of characters
	
	
	; if no chars then jmp bad_args_l
	cmp cx, 0
	jz bad_args_l
	
	; skip spaces that are before arg1
	skip_spaces:
	mov al, byte ptr ds:[si]
	inc si
	dec cx
	cmp al, ' '
	je skip_spaces
	dec si
	
	
	mov ax, seg arg1
	mov es, ax
	
	; get arg1
	mov di, offset arg1
	call get_arg
	
	; check if there is arg2
	cmp cx, 0
	jz bad_args_l
	
	; get arg2
	mov di, offset arg2
	call get_arg
	
	; check if there is arg3
	cmp cx, 0
	jz bad_args_l
	
	; get arg3
	mov di, offset arg3
	call get_arg


	
	mov ax, es
	mov ds, ax
	
	; print arg1
	mov dx, offset arg1
	mov ah, 9
	int 21h
	call print_enter
	
	; print arg2
	mov dx, offset arg2
	mov ah, 9
	int 21h
	call print_enter

	; print arg3
	mov dx, offset arg3
	mov ah, 9
	int 21h
	
	
program_end:
	mov ax, 4c00h
	int 21h

bad_args_l:
	mov ax, seg bad_args
	mov ds, ax
	mov dx, offset bad_args
	mov ah, 9
	int 21h
	jmp program_end


; copies chars from source to destination until it encounters a space that it will skip
; parameters
; cx - max number of characters
; ds:si - source address
; es:di - destination address
get_arg:
	get_arg_loop:
	mov al, byte ptr ds:[si]
	inc si
	
	cmp al, ' '
	je get_arg_end
	cmp al, 13
	je get_arg_end
	
	mov byte ptr es:[di], al
	
	inc di
	loop get_arg_loop  	; cx=cx-1; if cx>0 goto get_arg_loop
	ret
	
	get_arg_end:
	; skip spaces
	mov al, byte ptr ds:[si]
	inc si
	dec cx
	cmp al, ' '
	je get_arg_end
	dec si
	
	mov byte ptr es:[di], 0
	ret

	
print_enter:
	mov dx, offset enter_ch
	mov ah, 9
	int 21h
	ret
	
code ends



stack segment stack
	dw 100 dup(?)
	top dw ?
stack ends


end start