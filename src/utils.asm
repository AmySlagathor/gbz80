INCLUDE "include/hardware.inc"
	rev_Check_hardware_inc 4.0

SECTION "Utils", ROM0

DEF FONT_TILES EQU 107      ; Numero de caracteres que tiene la fuente 
DEF BYTES_PER_TILE EQU 16   ; 2 filas * 8 bytes
DEF FILECOUNT EQU 20		; Cada fila tiene $20 columnas

DEF TEXT_LENGTH EQU 18
DEF TEXT_DIR EQU $9C21 ;$9A01

;Window constants
DEF LCDC EQU $FF40
DEF WY EQU $FF4A ;  WY=0..143, indica el píxel verical de la pantalla en el que empieza la ventana
DEF WX EQU $FF4B ; WX=0..166, indica el píxel horizontal más 7

CheckPPU::
	ld a,[rSTAT]
	AND %00000010
	jr nz, CheckPPU
ret

Setup::
	call SetupWindow
	call CargarFuente
	;call BorrarLogoNintendo
	
	call InterruptSetup
ret

SetupWindow::
	push de

	;setup windows WY, WX corners
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

BorrarLogoNintendo:: ; de, b
	ld de, $9904	; Direccion donde empieza el logo de Nintendo	
	ld b, 13		; Iteraciones para el bucle
	call BorrarLinea

	ld de, $9904 + $20
	ld b, 13
	call BorrarLinea
ret

BorrarLinea:: ; de (direccion), b (numero iteraciones)
	.loop1
		call CheckPPU
		ld a, $00	; Caracter a imprimir
		ld [de], a
		inc de
		dec b
	jr nz, .loop1
ret

CargarFuente::
    ld hl, Fuente 	                    ; Cargamos la dirección donde está la fuente
    ld de, $8800	                    ; Direccion donde vamos a empezar a escribir
    ld bc, FONT_TILES*BYTES_PER_TILE	; Numero de bytes que vamos a escribir
	.cargarCaracter
		call CheckPPU
		ld a, [hl+]
		ld [de], a
		inc de
		dec bc
		ld a, b
		or c
		jr nz, .cargarCaracter
ret

EnableWindow::
	push de

	; LCDC se encuentra en $FF40
	; para activar la ventana hay que poner un 1 en el bit 5 de LCDC
	ld de, LCDC
	ld a, [de]
	add a, %00100000
	ld [de], a

	pop de
ret

DisableWindow::
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

MuestraDialogo::
	call EnableWindow

	ld de, TEXT_DIR
	call EscribeTexto

	call DisableWindow
ret

EscribeTexto:: ; hl (texto), de (direccion)
.siguienteCaracter
	ld a, [hl]
	or a
	ret z ;Return si nos hemos encontrado con un final de linea (0)

	;Comprobar si hay un salto de linea (el cual hemos marcado con un 10)
	ld a, [hl]
	ld b, 10
	xor b
	call z, CargarSiguienteLinea
	jr z, .skipCaracter

	call EscribeCaracter
	inc de
.skipCaracter
	inc hl

	call WaitVBlank
	jr .siguienteCaracter
ret

EscribeCaracter:: ; hl (texto), de (dirección)
	call CheckPPU
	ld a, [hl]
	ld [de], a
ret

CargarSiguienteLinea::

	call waitApressed

	call DesplazarLinea

	ld de, TEXT_DIR
	ld b, TEXT_LENGTH
	call BorrarLinea

	ld de, TEXT_DIR
ret

waitApressed::
	.waitApressed
		ldh a, [flancoAscendente]
		cp PADF_A
		ret z
		halt
	jr .waitApressed

DesplazarLinea::
	; Copiar tres lineas de abajo a arriba
	push hl
	push de
 
	ld de, TEXT_DIR - $60
	ld b, TEXT_LENGTH
	call BorrarLinea

	ld de, TEXT_DIR - $20
	ld hl, TEXT_DIR
	ld b, TEXT_LENGTH
	call CopiarLinea

	ld de, TEXT_DIR
	ld b, TEXT_LENGTH
	call BorrarLinea

	call WaitVBlank

	ld de, TEXT_DIR - $40
	ld hl, TEXT_DIR - $20
	ld b, TEXT_LENGTH
	call CopiarLinea

	ld de, TEXT_DIR - $20
	ld b, TEXT_LENGTH
	call BorrarLinea

	call WaitVBlank

	ld de, TEXT_DIR - $60
	ld hl, TEXT_DIR - $40
	ld b, TEXT_LENGTH
	call CopiarLinea

	ld de, TEXT_DIR - $40
	ld b, TEXT_LENGTH
	call BorrarLinea

	pop de
	pop hl
ret

CopiarLinea::
	.loop
		call CheckPPU
		ld a, [hl]
		ld [de], a

		inc de
		inc hl
		dec b
	jr nz, .loop
ret


InterruptSetup::
	ld a, %00000001
	ld [rIE], a ;Habilita la interrupción VBlank y deshabilita el resto
reti 			;Retorna y activa IME