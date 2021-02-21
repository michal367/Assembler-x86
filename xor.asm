; program reads input file
; performs xor operation on each letter with a key
; saves result to output file
; max 1kB is processed

; xor.exe in_file out_file "key"

data segment
	arg1 db 100 dup('$')
	arg2 db 100 dup('$')
	arg3 db 100 dup('$')
	
	file_in_handle dw ?
	file_out_handle dw ?
	
	file_in_content db 1024 dup('$')
	file_in_size dw ?
	
	enter_ch db 13,10,'$'
	
	info_file_in_content db 'The content of input file:',13,10,'$'
	info_file_doesnt_exist db 'Output file does not exist',13,10,
								'Creating output file',13,10,'$'
	info_file_exist db 'There is already such an output file',13,10,
						'If you want to overwrite it, press the y key',13,10,
						'If you do not want to overwrite it, press another key',13,10,'$'
	info_xor_content db 'Processed content:',13,10,'$'
	info_ok db 'Program completed successfully',13,10,'$'
	info_stop db 'Program was interrupted ',13,10,'$'
	
	info_arg_in_file db 'Input file: $'
	info_arg_out_file db 'Output file: $'
	info_arg_key db 'Key: $'
	
	err_code db 'Error code: $'
	err_bad_args db 'Invalid arguments were entered', 13, 10,
					'Correct format:',13,10,
					'xor.exe in_file out_file "key"',13,10,'$'
	err_key_quote db 'Key should start and possibly end with a quotation mark ("key")', 13, 10,
					'Correct format:',13,10,
					'xor.exe in_file out_file "key"',13,10,'$'
	err_key_no_chars db 'Key does not contain any characters ',13,10,'$'
	err_open_file_in db 'Error while opening input file ',13,10,'$'
	err_read_file_in db 'Error while reading input file',13,10,'$'
	err_close_file_in db 'Error while closing input file',13,10,'$'
	err_open_file_out db 'Error while opening output file',13,10,'$'
	err_write_file_out db 'Error while writing to output file',13,10,'$'
	err_close_file_out db 'Error while closing output file',13,10,'$'
	
data ends


code segment
start:
	; stack init SS, SP
	mov ax, seg top
	mov ss, ax
	mov sp, offset top
	
	; set ES, DI
	mov ax, seg arg1
	mov es, ax
	mov di, offset arg1
	
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
	jne continue
	
	; else end program with error
	mov ax, es
	mov ds, ax
	mov dx, offset err_bad_args
	call print
	jmp program_end
	
	
continue:
	dec cx
	
	mov ax, seg arg1
	mov es, ax
	
	; get arg1 - input file
	mov cl, byte ptr ds:[80h] ; cl = number of characters
	mov di, offset arg1
	call get_argument_file
	
	; get arg2 - output file
	mov cl, byte ptr ds:[80h] ; cl = number of characters
	mov di, offset arg2
	call get_argument_file
	
	; get arg3 - key
	mov cl, byte ptr ds:[80h] ; cl = number of characters
	mov di, offset arg3
	call get_argument_key


print_args:

	mov ax, es
	mov ds, ax		; ds = seg data
	
	; print arg1 - input file
	mov dx, offset info_arg_in_file
	call print
	mov dx, offset arg1
	call print
	call print_enter
	
	; print arg2 - output file
	mov dx, offset info_arg_out_file
	call print
	mov dx, offset arg2
	call print
	call print_enter
	
	; print arg3 - key
	mov dx, offset info_arg_key
	call print
	mov dx, offset arg3
	call print
	call print_enter
	
	
open_files:
	; set ds:dx to the name of the input file
	mov ax, seg arg1
	mov ds, ax
	mov dx, offset arg1
	
	call open_file_in	; open the file and save handle to the var file_in_handle
	call read_file_in	; load content of file into file_in_content
	call close_file_in
	
	
	; print content of file
	call print_enter
	mov dx, offset info_file_in_content
	call print
	mov dx, offset file_in_content
	call print
	call print_enter
	call print_enter
	
	; set ds:dx to the name of the output file
	mov ax, seg arg2
	mov ds, ax
	mov dx, offset arg2
	
	
	call check_if_file_exist	; check if the output file exists 
	
	mov dx, offset arg2			; set dx to the filename again (because it changed in prev procedure)
	call open_file_out			; open the file and save the handle to file_out_handle
	
do_xor:
	; set vars for xor_encrypt
	mov di, offset file_in_content
	mov si, offset arg3
	mov ax, ds
	mov es, ax
	mov cx, word ptr ds:[file_in_size]
	
	call xor_encrypt	; encrypt data in file_in_content with xor
	
	; print encrypted data
	mov dx, offset info_xor_content
	call print
	mov dx, offset file_in_content
	call print
	call print_enter
	
save_result:
	call write_file_out	; save file_in_content to file 
	call close_file_out
	
	; print ok status
	call print_enter
	mov dx, offset info_ok
	call print
	

program_end:
	mov ah, 4ch
	int 21h

	
; ================================================================================

; copies chars from source to destination until it encounters a space that it will skip
; parameters
; cx - max number of characters
; ds:si - source address
; es:di - destination address
get_argument_file:
	get_argument_file_loop:
		mov al, byte ptr ds:[si]
		inc si
		
		cmp al, ' '					; check if space
		je get_argument_file_end
		cmp al, 13					; check if enter
		je get_argument_file_end
		
		mov byte ptr es:[di], al
		
		inc di
		loop get_argument_file_loop  	; cx--; if cx>0 goto get_argument_file_loop
		ret
	get_argument_file_end:
		dec cx
		mov byte ptr es:[di], 0
		ret


; copies chars from source to destination until it encounters a second quote or end of chars
; parameters
; cx - max number of characters
; ds:si - source address
; es:di - destination address
get_argument_key:
	
	mov al, byte ptr ds:[si]
	cmp al, '"'
	jne get_argument_key_error1
	inc si
	
	; check if the key has at least 1 character
	mov al, byte ptr ds:[si]
	cmp al, '"'					; check if "
	je get_argument_key_error2
	cmp al, 13					; check if enter
	je get_argument_key_error2

	
	get_argument_key_loop:
		mov al, byte ptr ds:[si]
		inc si
		
		cmp al, '"'					; check if "
		je get_argument_key_end
		cmp al, 13					; check if enter
		je get_argument_key_end
		
		mov byte ptr es:[di], al
		
		inc di
		loop get_argument_key_loop  	; cx--; if cx>0 goto get_argument_key_loop
		ret
	get_argument_key_end:
		dec cx
		ret
	get_argument_key_error1:
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_key_quote
		call print
		jmp program_end
	get_argument_key_error2:
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_key_no_chars
		call print
		jmp program_end
		

; ================================================================================		

; xor encrypt text in ds:dx with key in es:si
; parameters
; ds:dx - text to xor encrypt
; cx - length ot text
; es:si - key
xor_encrypt:
	mov dx, si	; save address of beggining of key
	
	xor_encrypt_loop:
		mov al, byte ptr ds:[di] 	; get char from text
		
		mov bl, byte ptr es:[si] 	; get char from key
		cmp bl, '$'					; check if key is over
		jne xor_encrypt_loop_cont
		mov si, dx					; set si to beginning of key
		mov bl, byte ptr es:[si]	; get char from key again
		
	xor_encrypt_loop_cont:
		xor al, bl					; xor encrypt
		
		mov byte ptr es:[di], al 	; save xored char
		
		inc si
		inc di
		loop xor_encrypt_loop  	; cx--; if cx>0 goto xor_encrypt_loop

	ret
		
		
; ================================================================================		
	
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

	
; ================================================================================

; opens file and saves file handle to file_in_handle
; parameters
; ds:dx - filename
open_file_in:
	mov al, 0		; read-only
	mov ah, 3dh  	; open file ds:dx
	int 21h
	
	jc open_file_in_error1 ; info about opening the file is stored in flag (carry flag)

	mov word ptr ds:[file_in_handle], ax ; set var to file handle
	ret
	open_file_in_error1:
		push ax
	
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_open_file_in
		call print
		mov dx, offset err_code
		call print
		
		pop ax
		call print_ax_number_hex	; print error code
		jmp program_end


; reads file from file_in_handle and saves its content (max 1kB) to file_in_content and its size to file_in_size
read_file_in:
	mov bx, word ptr ds:[file_in_handle]
	mov cx, 1024		; read max 1024 bytes
						; (if the file contains less than 1024 chars, it will read only as many chars as the file has)
	
	; set ds, dx
	mov ax, seg file_in_content
	mov ds, ax
	mov dx, offset file_in_content
	
	; read file
	mov ah, 3fh 	; read
					; in ax is stored how many bytes have been read
	int 21h
	
	jc read_file_in_error1 ; info about error (carry flag)

	mov word ptr ds:[file_in_size], ax  ; save the number of characters loaded
	ret
	read_file_in_error1:
		push ax
		
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_read_file_in
		call print
		
		pop ax
		call print_ax_number_hex	; print error code
		jmp program_end


; closes file in file_in_handle
close_file_in:
	mov bx, word ptr ds:[file_in_handle]
	mov ah, 3eh 	; close file
	int 21h
	
	jc close_file_in_error1 ; info about error (carry flag)
	ret
	
	close_file_in_error1:
		push ax
		
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_close_file_in
		call print
		
		pop ax
		call print_ax_number_hex	; print error code	
		jmp program_end

	
; ================================================================================

; opens file and saves file handle to file_out_handle
; parameters
; ds:dx - filename
open_file_out:
	mov al, 1		; write-only
	mov ah, 3ch  	; open file in ds:dx
	int 21h
	
	jc open_file_out_error1 ; info about opening the file is stored in flag (carry flag)

	mov word ptr ds:[file_out_handle], ax ; set var to file handle
	ret
	open_file_out_error1:
		push ax
		
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_open_file_out
		call print
		
		pop ax
		call print_ax_number_hex	; print error code		
		jmp program_end


; writes file_in_size chars from file_in_content to file_out_handle file
write_file_out:
	mov bx, word ptr ds:[file_out_handle]
	mov cx, word ptr ds:[file_in_size]
	
	; set ds, dx
	mov ax, seg file_in_content
	mov ds, ax
	mov dx, offset file_in_content
	
	mov ah, 40h 	; save to file from ds:dx
					; in ax is stored how many bytes have been written	
	int 21h
	
	jc write_file_out_error1 ; info about error (carry flag)
	ret
	
	write_file_out_error1:
		push ax
		
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_write_file_out
		call print
		
		pop ax
		call print_ax_number_hex	; print error code
		jmp program_end


; closes file in file_out_handle
close_file_out:
	mov bx, word ptr ds:[file_out_handle]
	mov ah, 3eh 	; close file
	int 21h
	
	jc close_file_out_error1 ; info about error (carry flag)
	ret
	
	close_file_out_error1:
		push ax
		
		mov ax, seg data
		mov ds, ax
		mov dx, offset err_close_file_out
		call print
		
		pop ax
		call print_ax_number_hex	; print error code		
		jmp program_end


		
; checks if file with ds:dx filename exists	and asks if user wants to overwrite it
; parameters
; ds:dx - filename
check_if_file_exist:
	mov al, 1		; write-only
	mov ah, 3dh  	; open file ds:dx
	int 21h
	
	jc file_doesnt_exist 	; info about opening the file is stored in flag (carry flag)
							; if flaga => file does not exist
	
	
	; if file exists
	mov bx, ax		; set handle to be closed
	xor ax, ax		; ax = 0
	mov ah, 3eh 	; close file
	int 21h
	
	mov dx, offset info_file_exist
	call print
	
	xor ax, ax
	int 16h			; wait for key
					; returns:
					; AH = Scan code of the key pressed down
					; AL = ASCII character of the button pressed
	
	call print_enter
	
	; yes
	cmp al, 'y'
	je check_yes
	cmp al, 'Y'
	je check_yes
	
	; no
	mov dx, offset info_stop
	call print
	jmp program_end
	
	check_yes:
		ret
	
	; if file does not exist
	file_doesnt_exist:
		mov dx, offset info_file_doesnt_exist
		call print
		call print_enter
		ret

		
		
	
; ================================================================================

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
	
	
code ends


stack segment stack
	dw 100 dup(?)
	top dw ?
stack ends


end start