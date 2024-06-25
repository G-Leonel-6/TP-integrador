;
; etapas_integradas.asm
;
; Created: 6/23/2024 7:03:03 PM
; Author : leone
;


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

; Constantes del programa
.equ	CANT = 6
.equ	IZQUIERDA_V = 0
.equ	DERECHA_V = 0xff
.equ	N_POSICIONES = 10
.equ	N_SELECCIONADOS = 4
.equ	VACIO = 0
.equ	OCUPADO = 1
.equ	AlTA = 0xf0
.equ	BAJA = 0x0f
.equ	MEDIO = 1
.equ	BUSCANDO_CONTRINCANTE = 0
.equ	ELIGIENDO_NUMERO = 1
.equ	JUEGO = 2
.equ	NO_RECIBIR_MAS_DATOS = 3

; Alias de los registros
.def	AUX1 = r16
.def	CONT = r17
.def	DATO = r18
.def	POS = r19
.def	AUX2 = r20
.def	RESTANTES_A_SELECCIONAR = r21
.def	ESTADO = r22
.def	NUMERO_USUARIO_1 =
.def	NUMERO_USUARIO_2 =
.def	NUMERO_USUARIO_3 =
.def	NUMERO_USUARIO_4 = 


.dseg
; Segmento de datos en memoria de datos
.org SRAM_START
; Definicion de variable 
; Nombre .byte Tamanio_en_bytes
posiciones_ram:	.byte	10
seleccionados:  .byte	4
cifras_ram:		.byte	10
usuario			.byte	4

.cseg
.org 0x0000
; Segmento de datos en memoria de codigo
	rjmp	main

.org INT0addr
	rjmp boton

.org OVF2addr
	rjmp timer2int

.org OC1Aaddr
	rjmp int_timer1

.org ADCCaddr
	rjmp adc_complete

.org URXCaddr
	rjmp r_complete

.org UTXCaddr
	rjmp t_complete

.org INT_VECTORS_SIZE
main:

	; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global
	; RAMEND
	ldi		r16,HIGH(RAMEND)
	out		sph,r16
	ldi		r16,LOW(RAMEND)
	out		spl,r16
				
	rcall conf_int0
	rcall USART_conf
	rcall conf_IO
	ldi ESTADO, BUSCANDO_CONTRINCANTE
	sei

; Arranca mi loop principal que se ejecutará eternamente	
main_loop:
    rjmp main_loop


conf_estado_inicial_eligiendo_numero:

	rcall apuntar_inicio_posiciones_ram

	ldi YH, high(seleccionados)
	ldi YL, low(seleccionados)

	ldi RESTANTES_A_SELECCIONAR, N_SELECCIONADOS
	ldi DATO, 0
	ldi ESTADO, MEDIO
	ret

conf_IO:
	clr AUX1
	out DDRD, AUX1
	ldi AUX1, (1<<PD2)
	out PORTD, AUX1
	ldi AUX1, BAJA
	out DDRB, AUX1
	out DDRC, AUX1
	
	clr AUX1
	
	out PORTB, AUX1
	out PORTC, AUX1
	ret

conf_int0:
	ldi AUX1, (2<<ISC00)
	sts EICRA, AUX1

	ldi AUX1, (1<<INT0)
	out EIMSK, AUX1

	ret

USART_conf:
	 ; Set baud rate to UBRR0
	 ldi AUX2, 0
	 ldi AUX1, 103		; baudrate de 9600
	 sts UBRR0H, AUX2
	 sts UBRR0L, AUX1
	 ; Enable receiver and transmitter
	 ldi AUX1, (1<<RXCIE0)|(1<<TXCIE0)|(1<<RXEN0)|(1<<TXEN0)
	 sts UCSR0B,AUX1
	 ; Set frame format: 8data, 1 stop bit
	 ldi AUX1, (3<<UCSZ00)
	 sts UCSR0C,AUX1
	 ret

timer_2_conf_delay:
	ldi AUX2, (1<<WGM00)
	sts TCCR2A, AUX2

	ldi AUX2,(1<<TOIE0)
	sts TIMSK2, AUX2

	ldi AUX2, (5<<CS00)
	sts TCCR2B, AUX2

	ret

timer1_conf_A:
	ldi AUX1, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, AUX1
	ldi AUX1, (1<<OCIE1A)
	sts TIMSK1, AUX1
	ldi AUX1, high(7812)
	sts OCR1AH, AUX1
	ldi AUX1, low(7812)	
	sts OCR1AL, AUX1
	ldi CONT, CANT
	ret

timer1_conf_B:
	ldi AUX1, high(7811)
	sts OCR1BH, AUX1
	ldi AUX1, low(7811)	
	sts OCR1BL, AUX1

	ldi AUX1, high(7812)
	sts OCR1AH, AUX1
	ldi AUX1, low(7812)	
	sts OCR1AL, AUX1

	ldi AUX1, (1<<OCIE1B);
	sts TIMSK1, AUX1

	ldi AUX1, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, AUX1

	clr AUX1

	ret

conf_ADC:
	ldi AUX1, (1<<REFS0)|(1<<ADLAR)|(1<<MUX2)
	sts ADMUX, AUX1

	ldi AUX1, (1<<ADTS2)|(1<<ADTS0)
	sts ADCSRB, AUX1

	ldi AUX1, (1<<ADEN)|(1<<ADSC)|(1<<ADATE)|(1<<ADIE)|(1<<ADPS1)|(1<<ADPS0)
	sts ADCSRA, AUX1

	ret

apuntar_inicio_posiciones:
	ldi ZH, high(posiciones<<1)
	ldi ZL, low(posiciones<<1)

	ldi XH, high(posiciones_ram)
	ldi XL, low(posiciones_ram)

	ret

cargar_posiciones_a_ram:
	ldi CONT, N_POSICIONES
loop:
	lpm AUX1, Z+
	st X+, AUX1
	dec CONT
	breq salir_cargar
	rjmp loop
salir_cargar:	
	ret

apuntar_inicio_posiciones_ram:
	ldi XH, high(posiciones_ram)
	ldi XL, low(posiciones_ram)

	ldi CONT, 0
	ld POS, X
	ret

apuntar_final_posiciones_ram:
	ldi XH, high(posiciones_ram+N_POSICIONES-1)
	ldi XL, low(posiciones_ram+N_POSICIONES-1)
	
	ldi CONT, N_POSICIONES-1
	ld POS, X
	ret

guardar_dato:
	st Y+, DATO
	ldi AUX2, OCUPADO
	st X, AUX2
	ret

mover_a_derecha:
	cpi CONT, N_POSICIONES-1
	brne seguir_derecha
	rcall apuntar_inicio_posiciones_ram
	cpi POS, VACIO
	breq salir_mover_derecha

seguir_derecha:
	ld POS, X+		; realizo incremento del puntero
	ld POS, X		; dato que realmente me interesa
	inc CONT
	cpi POS, OCUPADO
	breq mover_a_derecha
	
salir_mover_derecha:
	mov DATO, CONT
	ret

mover_a_izquierda:
	cpi CONT, 0
	brne seguir_izquierda
	rcall apuntar_final_posiciones_ram
	cpi POS, VACIO
	breq salir_mover_a_izquierda

seguir_izquierda: 
	ld POS, -X
	dec CONT
	cpi POS, OCUPADO
	breq mover_a_izquierda

salir_mover_a_izquierda:
	mov DATO, CONT
	ret

comparar_numero:
;pongo en 0 el registro para enviar a luz verde y a luz roja


	ldi R16, 0 
	;mov r23, r16;auxiliar para pos de Y
	mov r22, r16; auxiliar para pos de X
	ldi R20, 0 ;el que voy a poner en la luz verde
	ldi R21, 0 ;el que voy a poenr en la luz roja

 
	ldi XH, high(seleccionados)
	ldi XL, low(seleccionados)
loop1:
	ld R18, X+			; es el original
						;vuelvo a setear Y en la posición inicial de la tabla

	ldi YH, high(users_guess)
	ldi YL, low(users_guess)
	ldi R24, 0b00000001 ; se setea acá para que vuelva a la pos. 0 cada vez que vuelvo a iterar en Y
	ldi R23, 0
loop2:
	ld R19, Y+			;es la tabla donde tengo 
	cp R18, R19
	brne sigo_1			; Si no son iguales, sigo adelante con la comparación
	cp R22, R23			; registros auxiliares de en qué posición de X e Y voy. si son iguales significa que nro y pos son correctas. Si son distintos, pos es incorrecta y se prende led rojo
	brne rojo_0
	or R20, R24
	rjmp sigo_1			; si el registro que cuenta para X es igual al contador de Y, se prende el led verde, sino rojo
rojo_0:
	or R21, R24
sigo_1:
	LSL R24				; en la primera iteración estaba en la pos. 0, en la segunda va a ser 0b00000010 y así. Para ponerlo en los leds rojo/verde
	INC R23
	cpi R23, 4			; si esta cuenta llegó a su fin, terminé de iterar sobre Y y puedo incrementar la posición de X.
	breq fin_loop_1		; esta parte chequea que no haya terminado de iterar sobre X.
	rjmp loop2			; si no terminó, sigo iterando
fin_loop_1:
	INC R22
	cpi R22, 4			; si está en 4 y acá al final es porque terminé
	breq seteo_luces
	rjmp loop1

seteo_luces:
	out PORTB, R20 ; verde
	out PORTC, R21 ; rojo

	ret

adc_complete:
	lds AUX1, ADCH
	cpi AUX1, IZQUIERDA_V
	breq izquierda
	cpi AUX1, DERECHA_V
	breq derecha
	rjmp salir_adc
izquierda:
	rcall mover_a_izquierda
	rjmp salir_adc
derecha:
	rcall mover_a_derecha
salir_adc:
	out PORTB, DATO 
	reti 

boton:
	rcall timer_2_conf_delay
salir_boton:
	reti

int_timer1:
	ldi AUX1, BAJA
	out PINB, AUX1
	in  AUX1, PINC
	ori AUX1, BAJA
	out PINC, AUX1

	dec CONT
	breq fin_espera
	rjmp salir_int_timer1
fin_espera:
	lds AUX1, UCSR0A
	sbrs AUX1, UDRE0
	rjmp fin_espera
	sts UDR0, DATO
	clr AUX1
	sts TCCR1B, AUX1

	cpi ESTADO, BUSCANDO_CONTRINCANTE
	breq salir_etapa_buscando_contrincante
	cpi ESTADO, ELIGIENDO_NUMERO
	breq salir_etapa_eligiendo_numero
	rjmp salir_int_timer1

salir_etapa_buscando_contrincante:
	rcall apuntar_inicio_posiciones
	rcall cargar_posiciones_a_ram
	rcall conf_estado_inicial_eligiendo_numero
	rcall conf_ADC
	rcall timer1_conf_B
	rjmp salir_int_timer1

salir_etapa_eligiendo_numero
	ldi CONT, N_SELECCIONADOS]

	ldi YH, high(usuario)
	ldi YL, low(usuario)

salir_int_timer1:
	reti

timer2int:
	sbic PIND, 2
	rjmp salir_timer2_int
	clr AUX2
	sts TCCR2B, AUX2
	cpi ESTADO, BUSCANDO_CONTRINCANTE
	breq timer2_buscando_contrincante
	rjmp timer2_seleccion

timer2_buscando_contrincante:
	rcall timer1_conf_A
	ldi DATO, 'N'
	rjmp salir_timer2_int

timer2_seleccion:

	rcall guardar_dato
	rcall mover_a_derecha
	dec RESTANTES_A_SELECCIONAR
	ldi AUX2, N_SELECCIONADOS
	sub AUX2, RESTANTES_A_SELECCIONAR
	out PORTC, AUX2
	cpi RESTANTES_A_SELECCIONAR, 0
	brne salir_timer2_int

salir_etapa_eligiendo_numero:
	ldi DATO, 'J'		
	clr AUX2
	out PORTC, AUX2
	out PORTB, AUX2

	clr AUX1
	sts ADCSRA, AUX1	; desactivo adc
	out EIMSK, AUX1		; desactivo interrupcion 0 por motivos de robustez de codigo, que el usuario no entre en ella estando en otra etapa

	ldi ESTADO, JUEGO
	rcall timer1_conf_A

salir_timer2_int:
	reti

r_complete:
	cpi ESTADO, BUSCANDO_CONTRINCANTE
	breq recibir_N
	cpi ESTADO, JUEGO
	breq recibir_numero
	rjmp salir_r

recibir_N:
	lds DATO, UDR0
	cpi DATO, 'N'
	brne salir_r
conf_timer:
	rcall timer1_conf_A
	rjmp salir_r
recibir_numero:
	lds DATO, UDR0
	chequear_si_ascii DATO
	st Y+, DATO
	dec CONT
	breq comparar
	rjmp salir_r

comparar:
	ldi YH, high(usuario)
	ldi YL, low(usuario)
	ld R22, Y+
	ld R23, Y+
	ld R24, Y+
	ld R25, Y

	chequear_si_igual R22, R23, R24, R25
	ldi ESTADO, NO_RECIBIR_MAS_DATOS
	rcall comparar_numero
	rjmp salir_r
error:
	ldi CONT, N_SELECCIONADOS	 
	ldi YH, high(usuario)
	ldi YL, low(usuario)
salir_r:
	reti

t_complete:
	cpi ESTADO, BUSCANDO_CONTRINCANTE
	breq cambiar_eligiendo_numero
	rjmp cambiar_juego

cambiar_eligiendo_numero:
	ldi ESTADO, ELIGIENDO_NUMERO
	rjmp salir_t

cambiar_juego:
	ldi ESTADO, JUEGO

salir_t:
	reti

posiciones: .db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00