
INCLUDE "include/hardware.inc"
	rev_Check_hardware_inc 4.0

DEF TEXTSPEED EQU 8

SECTION "Variables", WRAM0
vblankFlag:
ds 1

SECTION "Interrupts", ROM0[$40]
;$40 VBlank
jp vblankHandler
ds 5, 0 ;Deja 5 bytes de espacio vacíos
ret

SECTION "Header", ROM0[$100]

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	di
	jp EntryPoint

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0

SECTION "Entry point", ROM0

vblankHandler:
	push hl
	push af
	ld hl, vblankFlag
	ld a, 1
	ld [hl], a
	pop af
	pop hl
reti

WaitVBlank::
	push hl
	push bc

	ld hl, vblankFlag ; hl = pointer to vblankFlag
	xor a ; a = 0
	ld [hl], a ; pone vblankFlag a 0
	ld b, TEXTSPEED
	.loop
		.wait
			halt
			cp a, [hl] ; si vblankFlag es 0
			jr z, .wait ; vuelve a esperar
			dec b
	jr nz, .loop

	pop bc
	pop hl
ret

EntryPoint:
	ld a, [rLY] 	;\ This seems to check PPU state ??? 
	cp 144			;|
jr nz, EntryPoint	;|

call Setup

ld hl, textoLargo
call MuestraDialogo
jr @

; -----------------
	;jr EntryPoint
	;jr @ ; Salta sobre esta misma línea
