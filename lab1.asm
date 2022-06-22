code_seg segment
    assume  CS:code_seg, DS:code_seg, ES:code_seg
	org	100h
	.386

CR		EQU		13
LF		EQU		10
Space	EQU		20h

print_letter	macro	letter   ; печать символа
		push	AX
		push	DX
	
		mov	DL, letter
		mov	AH,	02
		int	21h
	
		pop	DX
		pop	AX
endm

PRINT_CRLF		macro      ; первевод каретки на новую строку
		push    AX
		push    DX
	
		mov DL, 13
		mov AH, 02
		int 21h ; print CR
		mov DL, 10
		mov AH, 02
		int 21h ; print LF
		
		pop    DX
		pop    AX
endm

Print_Word		macro	src		;	выводит на экран источник src в hex виде
		local	next, print_DL, print_hex, print_
		push	AX
		push	BX
		push	CX
		push	DX
		
		mov		BX,	src
		mov 	AH, 02
		mov     DL, BH
		call 	print_DL
		mov 	DL, BL
		call 	print_DL

		pop		DX
		pop		CX
		pop		BX
		pop		AX
		jmp	next

print_DL	 proc	near
		push	DX
		rcr		DL, 4
		call 	print_hex
		pop		DX
		call	print_hex
		ret
print_DL	endp		

print_hex	proc	near
		and		DL,	0Fh
		add		DL,	30h
		cmp		DL,	3Ah
		jl		print_
		add		DL,	07h
	
print_:	
		int		21H
		ret
print_hex	endp	

next:
endm

print_mes	macro	message		; печать строки
		local	msg, nxt
		push	AX
		push	DX
	
		mov		DX, offset msg
		mov		AH,	09h
		int		21h
	
		pop		DX
		pop		AX
		jmp 	nxt
		msg		DB message,'$'
nxt:
endm

ReadFile	macro	Handler,	Buffer,	Counter, RealRead
		local	read_error,	nx,m1
;
; RealRead     number of bytes actually read
;
		clc
		pusha
	
		mov 	BX,	Handler  	;                             }
		mov		CX,	Counter		; number reading bytes        } for READ_FILE
		lea 	DX,	Buffer     
		mov		AH, 3Fh		    ; function - read file
		int		21h		     
		jnc		m1
		jmp		read_error
m1:
		mov		RealRead, AX
		jmp		nx
read_error:
		PRINT_CRLF
		print_mes	'ReadError'
		print_word	AX	
		
nx:		popa
endm
;====================================================================
main:
		PRINT_CRLF
;------- check string of parameters -------------------------
		mov 	si,	80h      		; addres of length parameter in psp
		mov 	al,	byte ptr[si] 	; is it 0 in buffer?
		cmp 	AL,	0
		jne 	cont4        		; yes
;----------------------------------------------------------------------------
		print_mes	'Please, input file name > '
		mov		AH,	0Ah
		mov		DX,	offset	FileName
		int		21h
		xor		BH,	BH
		mov		BL,  FileName[1]
		mov		FileName[BX+2],	0
		mov		AX,	3D02h		    ; Open file for read/write
		mov		DX, offset FileName+2
		int		21h
		jc 		m	
		jmp 	openOK
m:
		PRINT_CRLF
		PRINT_CRLF
		print_mes	'ERROR. No file exists' 
		int		20h
		print_letter	CR
		int		20h
;----------------------------------------------------------------------------
cont4:
		xor		BH,	BH
		mov		BL, ES:[80h]		;  а вот так -> mov	BL, [80h]нельзя!!!!  
		mov		byte ptr [BX+81h],	0
		mov 	CL,	ES:80h    		; Длина хвоста в PSP
		xor 	CH,	CH       		; CX=CL= длина хвоста
		cld             			; DF=0 - флаг направления вперед
		mov 	DI, 81h     		; ES:DI-> начало хвоста в PSP
		mov 	AL, ' '        		; Уберем пробелы из начала хвоста
		repe    scasb   			; Сканируем хвост пока пробелы
									; AL - (ES:DI) -> флаги процессора
									; повторять пока элементы равны
		dec DI        				; DI-> на первый символ после пробелов
;-------------------------------------------------------------------------
		mov		AX,	3D02h		; Open file for read/write
		mov		DX, DI
		int		21h
		jnc		openOK
		print_mes	'ERROR. No file exists'
		int		20h
;===========================================================================
openOK:
		mov	handler,	AX
		PRINT_CRLF
		print_mes	'UP ARROW - scroll up, DOWN ARROW - scroll down, Enter - exit'
go:
		jmp		read
		letters	db	'ABCDEFGHIJKLMNOPQRSTUVWXYZ$'
		tmp		db	26 dup (0)
		
read:	
		xor		al, al
		xor 	cx, cx
		ReadFile handler, Bufin, 50, RealRead
		mov  	si, offset bufin
		
		cmp		RealRead, 0			; если Enter заканчиваем ввод
		jne		cont
		
		xor 	si, si
		PRINT_CRLF
		;jmp ender
		call print_gistogram
		jmp		scroll
		
cont:   
		mov 	al, [si]
		cmp		al, 65			; если не буква латинского алфавита, то пропускаем символ
		jl		inc_       
		cmp		al, 90
		jg		upREG
		sub		al, 65
		jmp		add_count
		
upREG:	
		cmp 	al, 97
		jl		inc_
		cmp		al, 122
		jg		inc_
		sub		al, 97
		jmp 	add_count
		
inc_:
		inc 	si
		inc 	cx
		cmp 	cx, RealRead
		jle	 	cont
		jmp 	read
		
add_count:	
		xor		bh,	bh
		mov		bl, al
		inc		tmp[bx] 
		jmp		inc_

read_error:
		PRINT_CRLF
		print_mes	'ReadError'
		print_word	AX

print_gistogram proc near
		push 	cx
		mov 	cl, 23d
loop_:	
		print_letter ' '
		mov 	ah, 02h
		mov 	dl, letters[si]
		int 	21h
		print_letter ' '
		push 	cx

		mov 	cl, tmp[si]	; сколько раз напечать символ
		mov		ah, 09h		; номер функции
		mov		al, ' '		; символ
		mov		bh, 00h		; страница?
		mov		bl, 0B0h	; цвет символа
		int		10h
		
		pop 	cx
		PRINT_CRLF
		inc 	si
		loop 	loop_
		
		sub 	si, 23
		pop 	cx
		ret
print_gistogram endp

PRINT_CRLF     macro    
		push    AX
		push    DX
	
		mov DL, 13
		mov AH, 02
		int 21h ; print CR
		mov DL,10
		mov AH,02
		int 21h ; print LF
	
		pop    	DX
		pop    	AX
endm

scroll:
		mov 	ah, 10h
		int 	16h
		cmp 	ah, 48h  ; сравниваем со стрелкой вверх
		je 		up
		cmp 	ah, 50h  ; сравниваем со стрелкой вниз
		je 		down
		cmp 	al, 13
		je 		ender
		jmp 	scroll

up:
		dec 	si
		cmp 	si, 0
		jl 		lower
		jmp 	printing
		
lower:  
		mov 	si, 0
		jmp 	scroll

down:
		inc 	si
		cmp 	si, 3
		jg		higher
		jmp 	printing
		
higher:
		mov 	si, 3
		jmp 	scroll

printing:
		print_mes 'UP ARROW - scroll up, DOWN ARROW - scroll down, Enter - exit'
		PRINT_CRLF
		call 	print_gistogram
		jmp 	scroll

ender:	
		mov		ax, 4C00h
		int		21h	

		handler		DW	?
		RealRead	DW	?
		RealWrite	DW	?
		bufin		DB	50 dup (' ')
		FileName	DB	14,0,14 dup (0)

code_seg ends        
end main