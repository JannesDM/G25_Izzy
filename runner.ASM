; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Geens Femke, De Mets Jannes
; date:		15/11/2020
; program:	izzysinfiniteadventure AKA G25
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;INCLUDE "keyb.inc"

; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen width
SCRHEIGHT EQU 200	; screen height

FRAMEWIDTH EQU 320
FRAMEHEIGHT EQU 200	; frame height and width (in pixels)
FRAMESIZE EQU FRAMEHEIGHT*FRAMEWIDTH

SPRITEWIDTH EQU 32  ; must be multiple of 4 becasue of render implementation
SPRITEHEIGHT EQU 64
SPRITESIZE EQU SPRITEWIDTH*SPRITEHEIGHT

TRANSPARANT = 0 ; pallette index for pixels that are transparant

; -------------------------------------------------------------------
CODESEG

; Set the video mode
PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode

; check for a specific termination keystroke.
PROC checkForTermination
	ARG 	@@key:byte
	USES 	eax

	mov	ah, 01h
	int	16h
	cmp	al,[@@key]
	
	jne	@@continue
	call terminateProcess
	
	@@continue:
	ret
ENDP checkForTermination


; wait for any key
PROC waitForKey
;	ARG 	@@key:byte
	USES 	eax

	mov	ah, 00h ; get keystroke
	int	16h
	ret
ENDP waitForKey

; ------------------------------------------------------------------------------------------------------------
; wait for Vertical Blank Interval (VBI)
; (= period during which the beam moves back to its starting position)
; copied from compendium
; DANCER VBI?
PROC awaitVBI
	uses eax, edx

	MOV DX, 03DAH 		; VGA status port
	@@waitForEnd:		; ?
		IN AL, DX		; ?
		AND AL, 8 		; third bit is set during VBI
		JNZ @@waitForEnd	; jump if ?
	@@waitForBegin:		; ?
		IN AL, DX		; ?
		AND AL, 8		; ?
		JZ @@waitForBegin	; jump if ?

		ret				; return
ENDP awaitVBI

;program to ananlyse picture to pixels pallette -> python
; advanced features (complex) power-ups,...
; collision (rectangles) then (1. rectangles then pixel per pixel (transparent))

; input handler
PROC handleInput
	uses eax

	; interrupt 16h

	ret
ENDP handleInput

; updates game status
PROC updateGameStatus
	;uses eax

	; eg move player

	ret
ENDP updateGameStatus

; updates game status
PROC redrawScreen
	;uses eax

	; eg @@obstacles ...

	ret
ENDP redrawScreen

; Game loop
; timing: synchronize gameLoop with VBI
PROC gameLoop
	@@gameLoop:
		call awaitVBI				; ?
		
		;call   		; ?
		
		;call handleInput			; handles input
		;call updateGameStatus		; updates game status
		
		;call redrawScreen			; redraw screen

		call awaitVBI				; ?
		;CMP AL, DEAD				; ?
		;JNE @@gameLoop
		jmp @@gameLoop

	;@@dead:



	;@@GAMELOOP:
		;call clearKeyboardBuffer
	
		;call wait_VBLANK
		;jmp @@GAMELOOP
	
	ret
ENDP gameLoop

;-----------------------------------------------------------------------------------------------------------
; Update the colour palette.
; 	* Ncolours: number of colours that have to be updated [word]
PROC updateColourPalette
	ARG	 	@@Ncolours: word
	USES 	eax, ecx, edx, esi

	mov esi, offset palette	; pointer to source palette
	movzx ecx, [@@Ncolours] ; amount of colors to read (movzx = zero extend)
	
	; multiply ecx by 3 (three color components per color)
	; do it efficiently (2*ecx + ecx)
	mov eax, ecx
	sal eax, 1
	add ecx, eax

	mov dx, 03C8h 	; DAC write port
	xor al, al		; index of first color to change (0)
	out dx, al		; write to IO

	inc dx
	rep outsb		; update all colors

	ret
ENDP updateColourPalette

; Terminate the program.
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

; wait for @@framecount frames
proc wait_VBLANK
	ARG @@framecount: word
	USES eax, ecx, edx
	mov dx, 03dah 					; Wait for screen refresh
	movzx ecx, [@@framecount]
	
		@@VBlank_phase1:
		in al, dx 
		and al, 8
		jnz @@VBlank_phase1
		@@VBlank_phase2:
		in al, dx 
		and al, 8
		jz @@VBlank_phase2
	loop @@VBlank_phase1
	
	ret 
endp wait_VBLANK

; -------------------------------------------------------------------
; FILE HANDLING: BASED ON DANCER.ASM FROM EXAMPLES (some parts heavily edited by now)
; opens file, returns file handle in ax
PROC openFile
	ARG	@@offset_of_filename: dword
	USES eax, ebx, ecx, edx
	mov al, 0 ; read only
	mov edx, [@@offset_of_filename]
	mov ah, 3dh
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset openErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	mov [filehandle], ax
	ret
ENDP openFile

; reads full sized frame to buffer (used to be readChunk...)
PROC readBytes
	ARG	@@offset_of_packedframe: dword
	ARG	@@nbr_bytes_to_read: dword
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov ecx, [@@nbr_bytes_to_read] ; actually only needs cx but dword argument
	mov edx, [@@offset_of_packedframe]
	mov ah, 3fh
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset readErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	ret
ENDP readBytes

; closes file
PROC closeFile
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov ah, 3Eh
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset closeErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	ret
ENDP closeFile

; -------------------------------------------------------------------

; Expand the packed frame
PROC expandPackedFrame
	ARG	 	@@destptr: dword	; destination buffer
	ARG	 	@@packedframe: dword	;  source frame
	USES 	eax, ebx, ecx, edx, edi, esi

	mov ebx, [@@packedframe]	    ; source pointer
	mov edi, [@@destptr]			; destination pointer
	
	mov ecx, FRAMEHEIGHT	
	@@scangroup:
	push ecx
		; expand scanline
		mov ecx, FRAMEWIDTH/4 ; 1 pixel = 1 byte, 1 dword  = 4 pixels 
		@@unpackline:   ; unpack double word into 4 pixels
		mov eax, [ebx]	; read 4 consecutive pixels (=4 bytes) from source image loaded from file
		stosd           ; store 4 consecutive pixels in video memory
		add ebx, 4	    ; handle next 4 pixels (bytes) from source image
		loop @@unpackline
	pop ecx
	loop @@scangroup

	ret
ENDP expandPackedFrame



; -------------------------------------------------------------------

; Render sprite 
PROC renderSprite
	ARG	 	@@destptr: dword	; destination buffer
	ARG	 	@@sprite_data: dword	;  source sprite data
	ARG	 	@@row_index: dword	;  row index
	ARG	 	@@col_index: dword	;  col index

	USES 	eax, ebx, ecx, edx, edi, esi

	mov ebx, [@@sprite_data]	    ; source pointer
	mov edi, [@@destptr]			; destination pointer
	
	; move destination point according to row_index and col_index
	add edi, [@@col_index]
	mov ecx, [@@row_index]
	cmp ecx, 0
	jz @@end_of_move_one_scanline_down_loop
	@@move_one_scanline_down:
		add edi, FRAMEWIDTH
		loop @@move_one_scanline_down
	@@end_of_move_one_scanline_down_loop:
	
	mov ecx, SPRITEHEIGHT	
	@@scangroup:
	push ecx
		; render single line from sprite data
		mov ecx, SPRITEWIDTH ; 1 pixel = 1 byte
		@@copy_sprite_line:
		mov al, [ebx]	; read 1 pixel (=1 bytes) from sprite data
		cmp al, TRANSPARANT
		jz @@pixel_is_transparant
		; here we handle a standard non transparant pixel
		stosb           ; store 1 pixel (= 1 byte)
		jmp @@transparancy_handling_done
@@pixel_is_transparant:
		inc edi ; skip this byte in the copy because the current pixel is transparant

@@transparancy_handling_done:		
		inc ebx  	    ; handle next pixel (bytes) from source image
		loop @@copy_sprite_line
		
		; move to correct location in framebuffer for next line in sprite
		add edi, FRAMEWIDTH
		sub edi, SPRITEWIDTH
		
	pop ecx
	loop @@scangroup

	ret
ENDP renderSprite




; -------------------------------------------------------------------

; Read image from disk
PROC readImage
	ARG	 	@@filename_frame: dword	      ; address of filename
	ARG	 	@@packedframe: dword	      ; address of buffer to store read bytes
	ARG	 	@@nbr_of_bytes_to_read: dword ; number of bytes to read

	call openFile, [@@filename_frame]
	call readBytes, [@@packedframe], [@@nbr_of_bytes_to_read]
	call closeFile	

	ret
ENDP readImage


PROC main
	sti
	cld
	
	push ds
	pop	es

	call setVideoMode, 13h
	call updateColourPalette, 66

	call readImage, offset filename_frame, offset packedframe, FRAMESIZE
	call readImage, offset filename_frame_2, offset packedframe_2, FRAMESIZE
	call readImage, offset filename_sprite_1, offset sprite_1_data, SPRITESIZE

	call expandPackedFrame, VMEMADR, offset packedframe
	call waitForKey
	
	call renderSprite, VMEMADR, offset sprite_1_data, 0, 0
	call waitForKey

	call renderSprite, VMEMADR, offset sprite_1_data, 50, 160
	call waitForKey

	call expandPackedFrame, VMEMADR, offset packedframe_2
	call waitForKey

	call expandPackedFrame, VMEMADR, offset packedframe
	call waitForKey

;		call wait_VBLANK, 30 ;currently not used, but will come in handy as soon as we implement movement for sprites

	call terminateProcess
		

ENDP main

; -------------------------------------------------------------------
DATASEG

	palette		db 0, 0, 0	
				db 1, 1, 1
				db 2, 2, 2
				db 3, 3, 3
				db 4, 4, 4
				db 5, 5, 5
				db 6, 6, 6 
				db 7, 7, 7
				db 8, 8, 8
				db 9, 9, 9
				db 10, 10, 10
				db 11, 11, 11
				db 12, 12, 12
				db 13, 13, 13
				db 14, 14, 14
				db 15, 15, 15
				db 16, 16, 16
				db 17, 17, 17
				db 18, 18, 18
				db 19, 19, 19
				db 20, 20, 20
				db 21, 21, 21
				db 22, 22, 22
				db 23, 23, 23
				db 24, 24, 24
				db 25, 25, 25
				db 26, 26, 26
				db 27, 27, 27
				db 28, 28, 28
				db 29, 29, 29
				db 30, 30, 30
				db 31, 31, 31
				db 32, 32, 32
				db 33, 33, 33
				db 34, 34, 34
				db 35, 35, 35
				db 36, 36, 36
				db 37, 37, 37
				db 38, 38, 38
				db 39, 39, 39
				db 40, 40, 40
				db 41, 41, 41
				db 42, 42, 42
				db 43, 43, 43
				db 44, 44, 44
				db 45, 45, 45
				db 46, 46, 46
				db 47, 47, 47
				db 48, 48, 48
				db 49, 49, 49
				db 50, 50, 50
				db 51, 51, 51
				db 52, 52, 52
				db 53, 53, 53
				db 54, 54, 54
				db 55, 55, 55
				db 56, 56, 56
				db 57, 57, 57
				db 58, 58, 58
				db 59, 59, 59
				db 60, 60, 60
				db 61, 61, 61
				db 62, 62, 62
				db 63, 63, 63
				db 0 ,  63, 0   ; index 64
				db 0, 0, 63   ; index 65

				
	filename_frame db "test.bin", 0
	filename_frame_2 db "test2.bin", 0
	filename_sprite_1 db "izzy.bin", 0
	
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
	

; -------------------------------------------------------------------
UDATASEG
	filehandle dw ?  ; reused by different 'open' calls so ensure to alwtas close before next open
	
	packedframe db FRAMESIZE dup (?)
	packedframe_2 db FRAMESIZE dup (?)
	sprite_1_data db SPRITESIZE dup (?)

; -------------------------------------------------------------------
STACK 100h

END main
