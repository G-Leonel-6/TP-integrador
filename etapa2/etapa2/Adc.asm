/*
 * Adc.asm
 *
 *  Created: 6/20/2024 6:16:09 PM
 *   Author: leone
 */ 

 .include "m328pdef.inc"

 
; Constantes del programa
.equ	CANT = 6 ; Numero constante
.equ	IZQUIERDA_V = 0
.equ	DERECHA_V = 0xff
.equ	N_POSICIONES = 10
.equ	N_SELECCIONADOS = 4
.equ	VACIO = 0
.equ	OCUPADO = 1
.equ	AlTA = 0xf0
.equ	BAJA = 0x0f

; Alias de los registros
.def	AUX1 = r16
.def	CONT = r17
.def	DATO = r18
.def	POS = r19
.def	AUX2 = r20
.def	RESTANTES_A_SELECCIONAR = r21


.dseg
; Segmento de datos en memoria de datos
.org SRAM_START
; Definicion de variable 
; Nombre .byte Tamanio_en_bytes
posiciones_ram:	.byte	10
seleccionados:  .byte	4
cifras_ram:		.byte	10

.cseg
.org 0x0000
	rjmp main


.org ADCCaddr
	rjmp adc_complete

.org INT_VECTORS_SIZE
 main:

	; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global
	; RAMEND
	ldi		r16,HIGH(RAMEND)
	out		sph,r16
	ldi		r16,LOW(RAMEND)
	out		spl,r16


	rcall conf_IO
	rcall conf_ADC
	rcall timer1_conf_B
	sei
fin:
	rjmp fin


timer1_conf_B:
	ldi r16, high(7811)
	sts OCR1BH, r16
	ldi r16, low(7811)	
	sts OCR1BL, r16

	ldi r16, high(7812)
	sts OCR1AH, r16
	ldi r16, low(7812)	
	sts OCR1AL, r16

	ldi r16, (1<<OCIE1B);
	sts TIMSK1, r16

	ldi r16, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, r16

	ret

conf_ADC:
	ldi AUX1, (1<<REFS0)|(1<<ADLAR)|(1<<MUX2)
	sts ADMUX, AUX1

	ldi AUX1, (1<<ADTS2)|(1<<ADTS0)
	sts ADCSRB, AUX1

	ldi AUX1, (1<<ADEN)|(1<<ADSC)|(1<<ADATE)|(1<<ADIE)|(1<<ADPS1)|(1<<ADPS0)
	sts ADCSRA, AUX1

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

adc_complete:
	lds AUX1, ADCH
	cpi AUX1, IZQUIERDA_V
	breq izquierda
	cpi AUX1, DERECHA_V
	breq derecha
	rjmp salir_adc

izquierda:
	ldi AUX1, 8
	out PORTB, AUX1
	rjmp salir_adc

derecha:
	ldi AUX1, 1
	out PORTB, AUX1

salir_adc:
	reti 
