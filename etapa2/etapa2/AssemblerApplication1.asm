;
; cascara.asm
;
; Creado: 29/04/2021 08:00:00 p.m.
; Autor : Leonel Gonzalez y Julieta Gonzalez Kratz
;

.include "m328pdef.inc"

 
; Constantes del programa
.equ	CANT = 1 ; Numero constante
.equ	IZQUIERDA_V = 0
.equ	DERECHA_V = 0xff
.equ	N_POSICIONES = 10
.equ	N_SELECCIONADOS = 4

; Alias de los registros
.def	AUX1 = r16
.def	CONT = r17
.def	DATO = r18
.def	POS = r19
.def	CONT


.dseg
; Segmento de datos en memoria de datos
.org SRAM_START
; Definicion de variable 
; Nombre .byte Tamanio_en_bytes
posiciones_ram:	.byte	10
seleccionados: .byte	4

.cseg
.org 0x0000
; Segmento de datos en memoria de codigo
	rjmp	main

.org INT0addr
	rjmp boton

.org ADCCaddr
	rjmp adc_complete

.org OC0Aaddr
	rjmp seleccion

.org INT_VECTORS_SIZE
main:

	; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global
	; RAMEND
	ldi		r16,HIGH(RAMEND)
	out		sph,r16
	ldi		r16,LOW(RAMEND)
	out		spl,r16
	
	rcall conf_IO
	rcall conf_int0
	rcall apuntar_inicio_posiciones
	rcall cargar_posiciones_a_ram

	ldi YH, high(seleccionados)
	ldi YL, low(seleccionados)

; Arranca mi loop principal que se ejecutará eternamente	
main_loop:
	;ldi16 cont, r17, 1024 	; uso de la macro
	rjmp main_loop

conf_estado_inicial:
	ldi CONT, N_POSICIONES

	ldi XH, high(posiciones_ram)
	ldi XL, low(posiciones_ram)

valor_inicial:
	ldi ZH, high(cifras<<1)
	ldi ZL, low(cifras<<1)

	lpm DATO, Z+
	lds POS, X+

	cpi POS, OCUPADO
	breq valor_inicial
	

	ret

conf_int0:
	ldi AUX1, (2<<ISC0)
	out EICRA, AUX1

	ldi AUX1, (1<<INT0)
	out EIMSK, AUX1

	ret

conf_IO:
	clr AUX1
	out DDRD, AUX1
	ldi AUX1, (1<<PD2)

	ldi AUX1, 0x0f
	out DDRB, AUX1
	out DDRC, AUX1
	
	clr AUX1
	
	out PORTB, AUX1
	out PORTC, AUX1
	ret

timer1_conf_B:
	ldi r16, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, r16

	ldi r16, high(7812)
	sts OCR1BH, r16
	ldi r16, low(7812)	
	sts OCR1BL, r16

	ret

conf_ADC:
	ldi AUX1, (1<<REFS0)|(1<<ADLAR)|(4<<MUX0)
	sts ADMUX, AUX1

	ldi AUX1, (5<<ADTS0)
	sts ADCSRB, AUX1

	ldi AUX1, (1<<ADEN)|(1<<ADSC)|(1<<ADATE)|(1<<ADIE)|(3<<ADPS0)
	sts ADCSRA, AUX1

	ret

adc_complete:
	lds AUX1, ADCH
	cpi AUX1, IZQUIERDA_V
	breq izquierda
	cpi AUX1, DERECHA_V
	breq derecha

izquierda:
	lds DATO, -Z
	lds POS, -X
	rjmp salir_adc

derecha:
	lds DATO, +Z
	lds POS, +X

salir_adc:
	reti 

apuntar_inicio_posiciones:
	ldi ZH, high(posiciones<<1)
	ldi ZL, low(posiciones<<1)

	ldi XH, high(posiciones_ram)
	ldi XL, low(posiciones_ram)

	ret

cargar_posiciones_a_ram:
	ldi cont, N_POSICIONES
loop:
	lds AUX1, Z+
	sts X+, AUX1
	dec cont
	breq salir_cargar
	rjmp loop
salir_cargar:	
	ret

timer_0_conf_delay:
	ldi AUX1, (2<<WGM0)
	out TCCR0A

	ldi AUX1, (1<<OCF0A)
	out TIFR0, AUX1			; limpio flag en caso de ser necesario

	ldi AUX1,(1<<OCIE0A)
	out TIMSK0, AUX1

	ldi AUX, 255
	sts OCR0A, AUX1

	ldi AUX1, (5<<CS0)
	out TCCR0B
	ret

guardar_dato:
	sts Y+, DATO
	ldi AUX1, 1
	sts X+, AUX1
	dec seleccionados_restantes

	ret

boton:
	rcall timer_0_conf_delay
	reti

seleccion:
	sbis PIND, 2
	rjmp salir_seleccion

	clr AUX1
	out TIMSK0, aux1

	rcall guardar_dato

salir_seleccion:
	reti
; Definicion de tabla en memoria de codigo
cifras: .db	'0','1','2','3','4','5','6','7','8','9'
posiciones: .db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00