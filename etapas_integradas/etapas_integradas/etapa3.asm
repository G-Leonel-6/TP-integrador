.include "m328pdef.inc"


.macro chequear_si_ascii
	cpi @0, '0'		; 48 es el ascii para '0'
	BRLO error
					;chequeo si es mayor/same, sino brancheo a error
	cpi @0, '9'+1	;58 es el siguiente en ascii al '9'
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
    ldi r17, 0x35            ; Cargar valor ASCII '2'
    sts original_nums+1, r17 ; Almacenar en original_nums[1]
    ldi r18, 0x36            ; Cargar valor ASCII '3'
    sts original_nums+2, r18 ; Almacenar en original_nums[2]
    ldi r19, 0x32            ; Cargar valor ASCII '4'
    sts original_nums+3, r19 ; Almacenar en original_nums[3]


	rjmp chequeos

chequeos:	;Chequeo si es ascii, y si se repiten los nuemeros
	ldi YH, high(users_guess)
	ldi YL, low(users_guess)
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
	;mov r23, r16;auxiliar para pos de Y
	mov r22, r16; auxiliar para pos de X
	ldi R20, 0 ;el que voy a poner en la luz verde
	ldi R21, 0 ;el que voy a poenr en la luz roja

 
	ldi XH, high(original_nums)
	ldi XL, low(original_nums)
loop1:
	ld R18, X+ ; es el original
	;vuelvo a setear Y en la posición inicial de la tabla

	ldi YH, high(users_guess)
	ldi YL, low(users_guess)
	ldi R24, 0b00000001 ; se setea acá para que vuelva a la pos. 0 cada vez que vuelvo a iterar en Y
	ldi R23, 0
loop2:
	ld R19, Y+ ;es la tabla donde tengo 
	cp R18, R19
	brne sigo_1 ; Si no son iguales, sigo adelante con la comparación
	cp R22, R23 ; registros auxiliares de en qué posición de X e Y voy. si son iguales significa que nro y pos son correctas. Si son distintos, pos es incorrecta y se prende led rojo
	brne rojo_0
	or R20, R24
	rjmp sigo_1; si el registro que cuenta para X es igual al contador de Y, se prende el led verde, sino rojo
rojo_0:
	or R21, R24
sigo_1:
	LSL R24 ; en la primera iteración estaba en la pos. 0, en la segunda va a ser 0b00000010 y así. Para ponerlo en los leds rojo/verde
	INC R23
	cpi R23, 4 ; si esta cuenta llegó a su fin, terminé de iterar sobre Y y puedo incrementar la posición de X.
	breq fin_loop_1	; esta parte chequea que no haya terminado de iterar sobre X.
	rjmp loop2 ; si no terminó, sigo iterando
fin_loop_1:
	INC R22
	cpi R22, 4 ; si está en 4 y acá al final es porque terminé
	breq seteo_luces
	rjmp loop1

seteo_luces:
	out PORTB, R20 ; verde
	out PORTC, R21 ; rojo

rjmp fin
	
error: rjmp error ;editar para hacer algo/enviarte a algún lugar
fin: rjmp fin



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