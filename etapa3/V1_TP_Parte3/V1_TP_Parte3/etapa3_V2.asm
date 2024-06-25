.include "m328pdef.inc"


.macro chequear_si_ascii
	cpi @0, '0' ; 48 es el ascii para '0'
	BRLO error
	;chequeo si es mayor/same, sino brancheo a error
	cpi @0, '9'+1 ;58 es el siguiente en ascii al '9'
	BRSH error
.endmacro

.macro chequear_si_igual
	cp @0, @1
	BREQ error
	cp @0, @2
	BREQ error
	cp @0, @3
	BREQ error
	cp @1, @2
	BREQ error
	cp @1, @3
	BREQ error
	cp @3, @2
	BREQ error
.endmacro

; Alias de los registros
.def	out_leds_rojos	= r20
.def	out_leds_verdes	= r21
.def	pos_x			=r22
.def	pos_y			=r23


.dseg
; Segmento de datos en memoria de datos
.org SRAM_START
; Definición de variables en la RAM
original_nums: .byte 5     ; Reserva 50 bytes para original_nums
users_guess:   .byte 5      ; Reserva 4 bytes para users_guess

.cseg
.org 0x0000
; Segmento de datos en memoria de codigo
	rjmp	main 


.org INT_VECTORS_SIZE
main:

	; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global
	; RAMEND
	ldi		r16,HIGH(RAMEND)
	out		sph,r16
	ldi		r16,LOW(RAMEND)
	out		spl,r16

rcall	inicializar_registros
rjmp	leer_numero_serial ; El número se guarda en el registro R20
	;rcall	comparar_numero		;chequea los bits que tiene de iguales


inicializar_registros:   
	ldi		r20,0x0F	
	out		ddrb,r20
	ldi		r20,0x0F	
	out		ddrc,r20
   out		portc,r20 ; seteo port C y port B como entradas, excepto del 0 al 3 que son las luces - 0b00001111
   
	clr		r20
	;sts		entrada,r20
	;sts		salida,r20
ret 
leer_numero_serial: ; esto debería incluir también la verificación de si los caracteres son válidos.
;Si algun caracter no es ascii del 0 al 9 se devuelve a leer serial. 
	;RECIBIR NUMERO AAA

   ; Cargar valores ASCII en users_guess
    ldi r16, 0x31            ; Cargar valor ASCII '1'
    sts users_guess, r16     ; Almacenar en users_guess[0]
    ldi r16, 0x32            ; Cargar valor ASCII '2'
    sts users_guess+1, r16   ; Almacenar en users_guess[1]
    ldi r16, 0x33            ; Cargar valor ASCII '3'
    sts users_guess+2, r16   ; Almacenar en users_guess[2]
    ldi r16, 0x34            ; Cargar valor ASCII '4'
    sts users_guess+3, r16   ; Almacenar en users_guess[3]

    ; Cargar valores ASCII en original_nums
    ldi r16, 0x31            ; Cargar valor ASCII '1'
    sts original_nums, r16   ; Almacenar en original_nums[0]
    ldi r17, 0x32            ; Cargar valor ASCII '2'
    sts original_nums+1, r17 ; Almacenar en original_nums[1]
    ldi r18, 0x33            ; Cargar valor ASCII '3'
    sts original_nums+2, r18 ; Almacenar en original_nums[2]
    ldi r19, 0x34            ; Cargar valor ASCII '4'
    sts original_nums+3, r19 ; Almacenar en original_nums[3]


rjmp chequeos

chequeos:	;Chequeo si es ascii, y si se repiten los nuemeros
	ldi 	   YH, high(users_guess)
	ldi 	   YL, low(users_guess)
	ld R22, Y+
	ld R23, Y+
	ld R24, Y+
	ld R25, Y
	chequear_si_ascii R22
	chequear_si_ascii R23
	chequear_si_ascii R24
	chequear_si_ascii R25

	chequear_si_igual R22, R23, R24, R25

;el R18, 19, 20, 21 son el número original, R22, 23, 24, y 25 son el número recibido.
rjmp comparar_numero
comparar_numero:
;pongo en 0 el registro para enviar a luz verde y a luz roja


ldi R16, 0 
mov pos_x, r16; auxiliar para pos de X
ldi out_leds_verdes, 0 ;el que voy a poner en la luz verde
ldi out_leds_rojos, 0 ;el que voy a poenr en la luz roja

 
	ldi 	   XH, high(original_nums)
	ldi 	   XL, low(original_nums)
loop1:
	ld R18, X+ ; es el original
	;vuelvo a setear Y en la posición inicial de la tabla

	ldi 	   YH, high(users_guess)
	ldi 	   YL, low(users_guess)
	ldi pos_y, 0
	loop2:
		ld R19, Y+ ;es la tabla donde tengo 
		cp R18, R19
		brne sigo_1 ; Si no son iguales, sigo adelante con la comparación
		cp pos_x, pos_y ; registros auxiliares de en qué posición de X e Y voy. si son iguales significa que nro y pos son correctas. Si son distintos, pos es incorrecta y se aumentan leds rojos
		brne rojo_0
		INC out_leds_verdes
		rjmp sigo_1; si el registro que cuenta para X es igual al contador de Y, aumenta la cantidad de leds verdes, sino rojos
		rojo_0:
			INC out_leds_rojos
		sigo_1:
		INC pos_y
		cpi pos_y, 4 ; si esta cuenta llegó a su fin, terminé de iterar sobre Y y puedo incrementar la posición de X.
		breq fin_loop_1	; esta parte chequea que no haya terminado de iterar sobre X.
		rjmp loop2 ; si no terminó, sigo iterando
	fin_loop_1:
	INC pos_x
	cpi pos_x, 4 ; si está en 4 y acá al final es porque terminé
	breq seteo_luces
	rjmp loop1

seteo_luces:
	out PORTB, out_leds_verdes ; verde
	out PORTC, out_leds_rojos ; rojo

rjmp fin
	

	



error: rjmp error ;editar para hacer algo/enviarte a algún lugar
fin: rjmp fin
