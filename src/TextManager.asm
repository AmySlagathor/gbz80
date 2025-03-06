INCLUDE "include/hardware.inc"
	rev_Check_hardware_inc 4.0

SECTION "TextManagerVariables", WRAM0
_scrollText::
ds 1

SECTION "TextManager", ROM0

DEF TEXT_LENGTH EQU 18
DEF TEXT_DIR1 EQU $9C22
DEF TEXT_DIR2 EQU $9C62

;Window constants
DEF LCDC EQU $FF40
DEF WY EQU $FF4A ;  WY=0..143, indica el píxel verical de la pantalla en el que empieza la ventana
DEF WX EQU $FF4B ; WX=0..166, indica el píxel horizontal más 7
DEF WBORDERY EQU $9C00 ;la ventana ocupa de $9C00 a $9FFF TODO cambiar por un sprite mas tarde
DEF BORDER_TILE EQU $19

TextManagerSetup::
    call SetupWindow
ret

;---------------------------------------------------
;----------------- WINDOW HELPERS ------------------
;---------------------------------------------------

SetupWindow:: ; modifies( a,de )
	push de

	;setup window WY, WX corners
	ld a, 100
	ld [WY], a
	ld a, 0
	ld [WX], a

	; Antes de dibujar la ventana, tenemos que asignarle el segundo Tile Map, poniendo a 1 el bit 6 de LCDC.
	ld de, LCDC
	ld a, [de]
	add a, %01000000
	ld [de], a

	pop de
ret

EnableWindow:: ; modifies( a,de )
	push de

	; para activar la ventana hay que poner un 1 en el bit 5 de LCDC
	ld de, LCDC
	ld a, [de]
	add a, %00100000
	ld [de], a

	pop de
ret

DisableWindow:: ; modifies( a,b,de )
	push de
	push bc

	; para desactivar la ventana hay que poner un 0 en el bit 5 de LCDC
	ld de, LCDC
	ld a, [de]
	ld b, %00100000
	sub b
	ld [de], a
	
	pop bc
	pop de
ret

;---------------------------------------------------
;---------------- SCROLL HELPERS -------------------
;---------------------------------------------------

EnableScrollText::
	ld a, 1
	Call SetScrollText
ret

DisableScrollText::
	ld a, 0
	Call SetScrollText
ret

SetScrollText:: ; input( value[a] ), modifies( hl )
	push hl

	ld hl, _scrollText
	ld [hl], a

	pop hl
ret

ScrollText::
	; Copiar tres lineas de abajo a arriba
	push hl
	push de
 
	ld de, TEXT_DIR1
	ld b, TEXT_LENGTH
	call BorrarLinea

	call WaitVBlank

	ld de, TEXT_DIR2 - $20
	ld hl, TEXT_DIR2
	ld b, TEXT_LENGTH
	call CopyLine

	ld de, TEXT_DIR2
	ld b, TEXT_LENGTH
	call BorrarLinea

	call WaitVBlank

	ld de, TEXT_DIR2 - $40
	ld hl, TEXT_DIR2 - $20
	ld b, TEXT_LENGTH
	call CopyLine

	ld de, TEXT_DIR2 - $20
	ld b, TEXT_LENGTH
	call BorrarLinea

	pop de
	pop hl
ret

CopyLine:: ; input( origin[hl], destination[de], iterations[b] ), modifies( a,b,hl,de )
	.loop
		call CheckPPU
		ld a, [hl]
		ld [de], a

		inc de
		inc hl
		dec b
	jr nz, .loop
ret

;---------------------------------------------------
;------------------ TEXT HELPERS -------------------
;---------------------------------------------------

ResetTextManager::
	call DisableScrollText
ret

ShowDialogueBox::
	call ResetTextManager
	call EnableWindow
	call PrintDialogueBoxBounds

	ld de, TEXT_DIR1
	call EscribeTexto

	call waitApressed ; Wait for player to press A to close the window
	call DisableWindow
ret

PrintDialogueBoxBounds::
	push bc
	push hl
	push de

	; la ventana va de $9C00 a $9FFF
	ld hl, $9C01
	ld b, 20
	call PrintXLine

	ld hl, $9C21
	ld b, 4
	call PrintYLine

	ld hl, $9CA1
	ld b, 20
	call PrintXLine

	ld hl, $9C34
	ld b, 4
	call PrintYLine

	pop de
	pop hl
	pop bc
ret

PrintXLine:: ; input( destination[hl], iterations[b] )
		call CheckPPU
		ld a, $19 ; TODO need to assign a here or else will be lost
		ld [hl+], a
		dec b
		jr nz, PrintXLine
ret

PrintYLine:: ; input( destination[hl], iterations[b] )
		call CheckPPU
		ld a, $19 ; TODO need to assign a here or else will be lost
		ld [hl], a

		ld de, $0020
		add hl, de

		dec b
		jr nz, PrintYLine
ret

BorrarLinea:: ; input( address[de], iterations[b] ), modifies( a,b,de )
	.loop1
		call CheckPPU
		ld a, $00	; Caracter a imprimir
		ld [de], a
		inc de
		dec b
	jr nz, .loop1
ret

EscribeTexto:: ; input( text[hl], address[de] ), modifies( a,b,hl,de )
.nextCharacter
	ld a, [hl]
	or a
	ret z ;Return si nos hemos encontrado con un final de linea (0)

	;Comprobar si hay un salto de linea (el cual hemos marcado con un 10)
	ld a, [hl]
	ld b, 10
	xor b
	call z, LoadNextLine
	jr z, .skipCharacter

	call WriteCharacter
	inc de
.skipCharacter
	inc hl

	call WaitVBlank
	jr .nextCharacter
ret

WriteCharacter:: ; input( text[hl], address[de] ) modifies( a )
	call CheckPPU
	ld a, [hl]
	ld [de], a
ret

LoadNextLine::
	; Despues de haber cargado la segunda linea empezar a scrollear el texto
	
	call waitApressed
	
	ld a, [_scrollText] ; Comprobar _scrollText, si es 1 scrollear texto
	and a
	jr nz, .scroll

	ld de, TEXT_DIR2
	call EnableScrollText
	ret

.scroll
	call ScrollText
	ld de, TEXT_DIR2
ret

