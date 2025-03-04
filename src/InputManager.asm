INCLUDE "include/hardware.inc"
	rev_Check_hardware_inc 4.0

SECTION "Input variables", HRAM
estadoBotones::
ds 1
flancoAscendente::
ds 1

SECTION "InputManager", ROM0

;Registros modificados: A, F, B
LeerBotones::
	push af
	push bc
	
	ld a, $20
	ldh [rP1], a ;Selecciona direcciones
	ldh a, [rP1] ;
	ldh a, [rP1] ;Espera algunos ciclos
	ldh a, [rP1] ;Guarda direcciones en a
	cpl ;Invierte bits (1 = seleccionado; 0 = no seleccionado)
	and $0F ;Borra los bits que no indican el estado de los botones
	swap a ;Mueve los bits al nibble superior
	ld b, a ;Guarda el resultado
	ld a, $10 ;Repite para los botones
	ldh [rP1], a
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	cpl
	and $0F
	or b ;Recupera el estado de las direcciones
	;En este punto A contiene el estado de los botones
	;A = [D|U|L|R|St|Se|B|A]
	ld b, a
	ldh a, [estadoBotones] ;Recupera el estado en el frame anterior
	xor b
	and b ;Obtiene el flanco ascendente en A
	ldh [flancoAscendente], a
	ld a, b
	ldh [estadoBotones], a
	ld a, $30
	ldh [rP1], a ;Deselecciona todos los botones

	pop bc
	pop af
ret

waitApressed::
	.waitApressed
		ldh a, [flancoAscendente]
		cp PADF_A
		ret z
		halt
	jr .waitApressed