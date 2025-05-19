INCLUDE "include/hardware.inc"
	rev_Check_hardware_inc 4.0

SECTION "SpriteManager", ROM0

LoadHero::
	push hl
	push de

	ld hl, Hero
	ld de, $8000
	ld b, 64 ; Bytes del sprite

.loop
	call WriteCharacter

	inc hl
	inc de

	dec b
	jr nz, .loop

	pop de
	pop hl

ret

BulkCopy::
	push de
	push hl
	push bc

	ld hl, $7F
	ld de, $9800 ; copiar un mismo caracter desde $9800 a $9FFF
	ld bc, 2048

	.loop
	call WriteCharacter

	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop

	pop bc
	pop hl
	pop de
ret