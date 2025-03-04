INCLUDE "include/hardware.inc"
	rev_Check_hardware_inc 4.0

SECTION "Utils", ROM0

DEF FONT_TILES EQU 110      ; Numero de caracteres que tiene la fuente 
DEF BYTES_PER_TILE EQU 16   ; 2 filas * 8 bytes
DEF FILECOUNT EQU 20		; Cada fila tiene $20 columnas

CheckPPU::
	ld a,[rSTAT]
	AND %00000010
	jr nz, CheckPPU
ret

Setup::
	call CargarFuente
	;call BorrarLogoNintendo
	call InterruptSetup
	call TextManagerSetup
ret


BorrarLogoNintendo:: ; de, b
	ld de, $9904	; Direccion donde empieza el logo de Nintendo	
	ld b, 13		; Iteraciones para el bucle
	call BorrarLinea

	ld de, $9904 + $20
	ld b, 13
	call BorrarLinea
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

InterruptSetup::
	ld a, %00000001
	ld [rIE], a ;Habilita la interrupción VBlank y deshabilita el resto
reti 			;Retorna y activa IME