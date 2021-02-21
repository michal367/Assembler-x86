; program gets zoom and text
; goes into vga mode
; displays text enlarged zoom times

; gfx_text.exe zoom text

data segment
	x dw ?		; (0-319)	values that can be displayed
	y dw ?		; (0-199)
	color db ?	; (0-255)
	
	y_temp dw ?
	
	text db 256 dup('$')
	temp db 4 dup('$')
	zoom dw ?
	
	filename db 'letters/', 5 dup('$')
	file_handle dw ?
	file_content db 80 dup('$') ; 8*(8+2) ; 2 because of enter (13,10)
	file_size dw ?
	
	enter_ch db 13,10,'$'
	
	err_code db 'Error code: $'
	err_bad_args db 'Invalid arguments were entered ', 13, 10,
					'Correct format:',13,10,
					'gfx_text.exe zoom text',13,10,'$'
	err_bad_zoom db 'Zoom should be positive integer',13,10,
					'Correct format:',13,10,
					'gfx_text.exe zoom text',13,10,'$'
	err_no_text db 'There is no text entered to display',13,10,
					'Correct format:',13,10,
					'gfx_text.exe zoom text',13,10,'$'
	err_open_file_in db 'Error while opening file $'
	err_read_file_in db 'Error while reading file',13,10,'$'
	err_close_file_in db 'Error while closing file',13,10,'$'
data ends

code segment
start:
	; stack init SS SP
	mov ax,seg top
	mov ss,ax
	mov sp, offset top
	
	; set ES
	mov ax, seg data
	mov es, ax
	
	; DS in the beggining of program is set to PSP (Program Segment Prefix)
	; that's why we don't change DS for now and we use ES
	
	; Program Segment Prefix
	; program.exe arg1 arg2 arg3
	; we can read args from DS:x
	; x:
	; 80h - number of characters
	; 81h=' '
	; 82h=arg1 arg2 arg3		; 81h-FFh - command-line tail
	
	mov si, 82h 				; si = address of program args
	xor cx, cx 					; cx = 0
	mov cl, byte ptr ds:[80h] 	; cl = number of characters
	
	; if there are chars continue
	cmp cx, 0
	jne correct
	
	; else end program with error
	mov ax, es
	mov ds, ax
	mov dx, offset err_bad_args
	call print
	jmp program_end
	
	
correct:
	dec cx
	
	mov ax, seg text
	mov es, ax
	
	; get arg1 - zoom
	mov cl, byte ptr ds:[80h] ; cl = number of characters
	mov di, offset temp
	call get_zoom
	
	push si
	push ds
	
	mov cx, 2
	mov ax, seg data
	mov ds, ax
	mov si, offset temp
	call string_to_number		; convert string to number
	mov word ptr es:[zoom], ax	; save number
	
	
	cmp ax, 0					; zoom must be != 0
	jne correct2
	mov dx, offset err_bad_zoom
	call print
	
	pop ds
	pop si
	
	jmp program_end
	

correct2:
	pop ds
	pop si

	; get arg2 - text
	mov cl, byte ptr ds:[80h] 	; cl = number of characters
	mov di, offset text
	call get_text
	
	cmp byte ptr es:[text], 0	; check if there is text
	jne vga
	
	mov ax, seg data
	mov ds, ax
	mov dx, offset err_no_text
	call print
	jmp program_end
	
	
vga:
	mov ax, seg data
	mov ds, ax
	
	; initialization of x, y, color
	mov word ptr ds:[x], 0
	mov word ptr ds:[y], 0
	mov byte ptr ds:[color], 40
	
	mov word ptr ds:[y_temp], 0

	
	mov ax, 13h ; change mode to VGA card ; graphic mode 320x200, 256 colors 
	int 10h 	; BIOS interrupt
	
	mov ax, 0a000h 	; image segment
	mov es, ax		; es = image segment


; main_loop start
;==================================================
mov si, offset text			; set si to the first char of text
mov cl, 255					; let loop run max of 255 times or up to the enter
main_loop:
	push cx

	push es
		
	; get letter from text
	mov ax, seg data
	mov es, ax
	xor ax, ax
	mov al, byte ptr ds:[si]
	inc si
	
	cmp al, 13					; check if enter
	je vga_end
	
	
	mov di, offset filename+8   ; +8, because after 'letters/'
	call save_ax_number			; save filename (ax=48 -> 'letters/48',0)
	mov byte ptr es:[di], 0		; add null-terminator
	
	
	call get_file_content		; get letter from letter file
	
	pop es
	
draw:
	push si
	call draw_char				; draw char in file_content
	pop si
	
	pop cx
	loop main_loop
	;dec cx
	;jnz main_loop
;==================================================
; main loop end


vga_end:
	xor ax, ax
	int 16h 	; wait for key
	
	mov ax, 3h 	; change VGA card mode to text mode
	int 10h 	; BIOS interrupt	
	
program_end:
	mov ax, 4c00h
	int 21h


; ================================================================================


; draws char on screen
; parameters
; ds:[file_content] - content of the file associated with the given char
; ds:[y_temp] - position of the current line (y pos)
; ds:[zoom]
; ds:[x]
draw_char:
	; calculate zoom*8 to get x position for the next letter
	; this is usefull to check if the current letter is outside the range of 320
	mov ax, word ptr ds:[zoom]
	mov bx, 8
	mul bx
	add ax, word ptr ds:[x]
	
	cmp ax, 320					; check if it is out of range 
								; if so - go to new line
	jng draw_start
	
	mov word ptr ds:[x], 0		; set x to start
	
	; add zoom*8 to y_temp
	mov ax, word ptr ds:[zoom]
	mov bx, 8
	mul bx
	add word ptr ds:[y_temp], ax
	
	; y = y_temp
	mov ax, word ptr ds:[y_temp]
	mov word ptr ds:[y], ax
	
	
	; start of drawing char
	;============================
	draw_start:
		push word ptr ds:[x]			; save x
		
		mov cx, 80						; 80 = 8*(8+2), 8x8 - letter, +2 - enter (13,10)
		mov si, offset file_content
	draw_loop:
		mov al, byte ptr ds:[si]
		inc si
		
		cmp al, 'X'						; X - there is point so draw
		jne continue
		
		push cx
		call draw_zoom_points
		pop cx
		
		;add word ptr ds:[color], 3		; color change
		
		jmp continue2
	
	
		continue:
		cmp al, 10						; .XXXX... 13 10   - end of line at 10
		jne continue2
		
		; add zoom to y
		mov ax, word ptr ds:[zoom]
		add word ptr ds:[y], ax
		
		pop word ptr ds:[x]
		push word ptr ds:[x]
		loop draw_loop
		
		
		continue2:
		; add zoom to x
		mov ax, word ptr ds:[zoom]
		add word ptr ds:[x], ax
		
		loop draw_loop
	;=============================
	; end of drawing char
	
	pop word ptr ds:[x]
	
	; add zoom*8 to x
	mov ax, word ptr ds:[zoom]
	mov bx, 8
	mul bx
	add word ptr ds:[x], ax
	
	; y = y_temp
	mov ax, word ptr ds:[y_temp]
	mov word ptr ds:[y], ax
	
	ret




; draws a single point on screen
; parameters
; es - image segment (0a000h)
; ds:[x] - horizontal position (0-319)
; ds:[y] - vertical position (0-199)
; ds:[color] - color (0-255)
draw_point:
	; checking the correctness of the coordinates
	cmp word ptr ds:[x], 320
	jge draw_point_end
	cmp word ptr ds:[y], 200
	jge draw_point_end

	mov ax, word ptr ds:[y] ; ax = y
	mov bx, word ptr 320
	mul bx 		; pair dx:ax = ax*bx = 320*y
				; in this case, dx = 0, because the result of the multiplication is max 16-bit 
				; => ax = 320*y
	
	mov bx, word ptr ds:[x]
	add bx, ax 						; bx = 320*y + x
	mov dx, bx
	
	xor ax,ax
	mov al, byte ptr ds:[color]		; save color to al
	mov byte ptr es:[bx], al 		; draw point
	
	draw_point_end:
	ret

	
; draws a square of points of size zoomXzoom
; parameters
; ds:[zoom]
; ds:[x]
; ds:[y]
; ds:[color]
draw_zoom_points:
	push word ptr ds:[x]
	push word ptr ds:[y]

	mov cx, word ptr ds:[zoom]
	draw_zoom_points_loop:
		push cx
		
		mov cx, word ptr ds:[zoom]
		draw_zoom_points_loop2:
			
			call draw_point
		
			inc word ptr ds:[x]
		
			loop draw_zoom_points_loop2
		
		inc word ptr ds:[y]
		push ax
		mov ax, word ptr ds:[zoom]
		sub word ptr ds:[x], ax
		pop ax
		
		pop cx
		loop draw_zoom_points_loop
	
	pop word ptr ds:[y]
	pop word ptr ds:[x]
	ret

	
	

exit_VGA:
	mov ax, 3h 	; change VGA card mode to text mode
	int 10h 	; BIOS interrupt
	ret

	
; ================================================================================	

; copies chars from source to destination until it encounters a space
; parameters
; ds:si - source address
; es:di - destination address
get_zoom:
	get_zoom_loop:
		mov al, byte ptr ds:[si]
		inc si
		
		cmp al, ' '				; check if space
		je get_zoom_end
		
		mov byte ptr es:[di], al
		inc di
		loop get_zoom_loop
		ret
	get_zoom_end:
	ret	
	
	
; copies chars from source to destination
; parameters
; ds:si - source address
; es:di - destination address
get_text:
	get_argument_loop:
		mov al, byte ptr ds:[si]
		mov byte ptr es:[di], al
		inc si
		inc di
		loop get_argument_loop
	ret
	

	
; ================================================================================

; converts number in ax to string and saves to es:di
; parameters
; ax - number
; es:di - where to save
save_ax_number:
    mov cx, 0
    mov bx, 10 ; base of the numeral system

	loophere:
		mov dx, 0
		div bx		; ax = ax/bx
		; ax = ax/10	- integer result
		; dx = ax % 10	- remainder

		add dl, '0'
		push dx                         ; save letter to stack (letters are in reversed order)
		inc cx                          ; how many digits we pushed to stack

		cmp ax, 0
		jnz loophere
		
	loophere2:
		pop dx                          ; restore digits from last to first
		mov byte ptr es:[di], dl		; save letter
		inc di
		loop loophere2
	
	ret
	

; converts string from ds:si and saves to ax
; parameters
; ds:si - address of string
string_to_number:
	xor ax, ax
	xor dx, dx
	mov bx, 10 ; base of the numeral system

	str_loop:
		mov dl, byte ptr ds:[si]
		inc si
	
		; check if it is digit ( >= '0' && <= '9' )
		cmp dl, '0'
		jl string_to_number_end
		cmp dl, '9'
		jg string_to_number_end
	
		push dx
		mul bx			; ax *= bx
		pop dx
		
		sub dl, '0' 	; convert from ASCII to digit
		add ax, dx		; adding next digit to ax
		
		loop str_loop  	; cx--; if cx>0 goto str_loop
	string_to_number_end:
	ret
	
	
; parameters
; ds:dx - text to print (must end with a '$')	
print:
	mov ah, 9
	int 21h
	ret


print_enter:
	mov dx, offset enter_ch
	call print
	ret
	
	
	
; prints number that is in ax in hex
; parameters
; ax - number to print
print_ax_number_hex:
    mov cx, 0	; number of chars (it will increase over time)
    mov bx, 16	; base of the numeral system

	print_ax_number_loop:
		mov dx, 0
		div bx		; ax = ax/bx
		; ax = ax/bx	- integer result
		; dx = ax % bx	- remainder

		push ax
		
		; convert digit to ASCII
		cmp dl, 9
		jg print_ax_number_greater
		add dl, '0'
		jmp print_ax_number_next
		print_ax_number_greater:
			sub dl, 10
			add dl, 'A'

		print_ax_number_next:
		pop ax                          
		push dx                         ; save letter to stack (letters are in reversed order)
		inc cx                          ; how many digits we pushed to stack

		cmp ax, 0
		jnz print_ax_number_loop
		
	; print string
	mov ah, 2							; 2 is the function number of output char in the DOS Services
	print_ax_number_loop2:
		pop dx                          ; restore digits from last to first
		int 21h		                    ; print char
		loop print_ax_number_loop2
	
	; print 'h'
	mov dl, 'h'
	int 21h
	
	ret

	
	
; ================================================================================


; save content of filename file and saves it to file_content
; parameters
; filename
get_file_content:
	mov ax, seg filename
	mov ds, ax
	mov dx, offset filename
	; open, read and close file
	call open_file_in
	call read_file_in
	call close_file_in
	ret

	
; opens file and saves file handle to file_in_handle
; parameters
; ds:dx - filename
open_file_in:
	mov al, 0		; read-only
	mov ah, 3dh  	; open file ds:dx
	int 21h
	
	jc open_file_in_error1 ; info about opening the file is stored in flag (carry flag)

	mov word ptr ds:[file_handle], ax ; set var to file handle
	ret
	open_file_in_error1:
		push ax
	
		call exit_VGA
	
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_open_file_in
		call print
		mov dx, offset filename
		call print
		call print_enter
		mov dx, offset err_code
		call print
		
		pop ax
		call print_ax_number_hex	; print error code
		jmp program_end

	
; reads file from file_handle and saves its content to file_content
read_file_in:
	mov bx, word ptr ds:[file_handle]
	mov cx, 79			; read max 79 bytes  8*(8+2)-1
						
	; set ds, dx
	mov ax, seg file_content
	mov ds, ax
	mov dx, offset file_content
	
	; read file
	mov ah, 3fh 	; read
					; in ax is stored how many bytes have been read
	int 21h
	
	jc read_file_in_error1 ; info about error (carry flag)

	mov word ptr ds:[file_size], ax  ; save the number of characters loaded
	ret
	read_file_in_error1:
		push ax
		
		call exit_VGA
		
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_read_file_in
		call print
		mov dx, offset filename
		call print
		call print_enter
		mov dx, offset err_code
		call print
		
		pop ax
		call print_ax_number_hex	; print error code
		jmp program_end


; closes file in file_handle
close_file_in:
	mov bx, word ptr ds:[file_handle]
	mov ah, 3eh 	; close file
	int 21h
	
	jc close_file_in_error1 ; info about error (carry flag)
	ret
	
	close_file_in_error1:
		push ax
		
		call exit_VGA
		
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_close_file_in
		call print
		mov dx, offset filename
		call print
		call print_enter
		mov dx, offset err_code
		call print
		
		pop ax
		call print_ax_number_hex	; print error code		
		jmp program_end


code ends


stack segment stack
	dw 100 dup(?)
	top dw ?
stack ends


end start