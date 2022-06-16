[org 0x100]

section .text

jmp start

start:
		call clear_screen
		lea ax, [12 * 80 * 2 + 40]
		push text
		push ax
		call print_string
	.begin:
		mov ah, 0x7
		int 0x21 ; read char without echoing it

		cmp al, 'q'
		je exit

		cmp al, 'k'
		jne .down_check
		call scroll_up
		jmp .after
	.down_check:
		cmp al, 'j'
		jne .after
		call scroll_down
	.after:
		jmp .begin

clear_screen: ; () -> void
		push ax
		push es
		push di
		push cx

		mov ax, 0xb800
		mov es, ax
		xor di, di
		mov ax, 0x0720
		mov cx, 2000
		rep stosw

		pop cx
		pop di
		pop es
		pop ax
		ret

print_string: ; (string, screen_offset) -> void
		push bp
		mov bp, sp
		push ax
		push es
		push si
		push bx
		push di
		push dx

		mov di, [bp + 4] ; screen_offset
		mov bx, [bp + 6] ; string

		push bx
		call strlen
		mov dx, ax

		mov ax, 0xb800
		mov es, ax

		mov ah, 0x07
		xor si, si
	.begin:
		cmp si, dx
		jz .end
		mov al, [bx + si]
		mov [es:di], ax
		add di, 2
		inc si
		jmp .begin
	.end:
		pop dx
		pop di
		pop bx
		pop si
		pop es
		pop ax
		pop bp
		ret 4

strlen:; (char *) -> ax
		push bp
		mov bp, sp
		push bx
		push si

		xor si, si
		mov bx, [bp + 4]
	.begin:
		mov cl, [bx + si]
		cmp cl, 0x0 ; if '\0' then stop
		je .end
		inc si
		jmp .begin
	.end:
		mov ax, si
		pop si
		pop bx
		pop bp
		ret 2

scroll_up: ; () -> void
		push es
		push ds
		push si
		push di
		push ax
		push cx

		; shift down_buffer by one row
		push down_buffer
		call shift_array_down

		; place last row of screen at first row of down_buffer
		lea si, [24 * 80 * 2]
		xor di, di
		mov ax, 0xb800
		mov ds, ax
		mov ax, down_buffer
		mov es, ax
		mov cx, 80
		rep movsw

		; shift screen down by one row
		push 0xb800
		call shift_array_down

		; place last row of up_buffer at first row of screen
		lea si, [24 * 80 * 2] ; last row
		xor di, di
		mov ax, 0xb800
		mov es, ax
		mov ax, up_buffer
		mov ds, ax
		mov cx, 80
		rep movsw

		; shift up_buffer down by one row
		push up_buffer
		call shift_array_down
	.exit:
		pop cx
		pop ax
		pop di
		pop si
		pop ds
		pop es
		ret

scroll_down: ; () -> void
		push es
		push ds
		push si
		push di
		push ax
		push cx

		; shift up_buffer up by one row
		push up_buffer
		call shift_array_up

		; place first row of screen at last row of up_buffer
		lea di, [24 * 80 * 2] ; last row
		xor si, si
		mov ax, 0xb800
		mov ds, ax
		mov ax, up_buffer
		mov es, ax
		mov cx, 80
		rep movsw

		; shift screen up by one row
		push 0xb800
		call shift_array_up

		; place first row of down_buffer at last row of screen
		lea di, [24 * 80 * 2] ; last row
		xor si, si
		mov ax, 0xb800
		mov es, ax
		mov ax, down_buffer
		mov ds, ax
		mov cx, 80
		rep movsw

		; shift down_buffer up by one row
		push down_buffer
		call shift_array_up
	.exit:
		pop cx
		pop ax
		pop di
		pop si
		pop ds
		pop es
		ret

shift_array_down: ; (array) -> void
		push bp
		mov bp, sp
		push ax
		push cx
		push dx
		push si
		push di
		push es
		push ds

		mov ax, [bp + 4]
		mov es, ax
		mov ds, ax

		lea si, [25 * 80 * 2 - 80 * 4] ; second last row
		lea di, [25 * 80 * 2 - 80 * 2] ; last row
		mov dx, 24
	.begin:
		cmp dx, 0
		jz .end
		mov cx, 80
		rep movsw
		sub si, 320
		sub di, 320
		dec dx
		jmp .begin
	.end:
		pop ds
		pop es
		pop di
		pop si
		pop dx
		pop cx
		pop ax
		pop bp
		ret 2

shift_array_up: ; (array) -> void
		push bp
		mov bp, sp
		push ax
		push cx
		push dx
		push si
		push di
		push es
		push ds

		mov ax, [bp + 4]
		mov es, ax
		mov ds, ax

		xor di, di ; first row
		lea si, [80 * 2] ; second row
		mov dx, 24
	.begin:
		cmp dx, 0
		jz .end
		mov cx, 80
		rep movsw
		dec dx
		jmp .begin
	.end:
		pop ds
		pop es
		pop di
		pop si
		pop dx
		pop cx
		pop ax
		pop bp
		ret 2

exit:
		mov ax, 0x4c00
		int 0x21

section .rodata
	text: db "k - Scroll up | j - Scroll Down | q - Quit", 0

section .data
	up_buffer: times 2000 dw 0
	down_buffer: times 2000 dw 0
