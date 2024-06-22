/*
 * boton.asm
 *
 *  Created: 6/21/2024 10:35:18 AM
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
.equ	ESPERANDO = 0
.equ	DEBOUNCING = 1


; Alias de los registros
.def	AUX1 = r16
.def	CONT = r17
.def	DATO = r18
.def	POS = r19
.def	AUX2 = r20
.def	RESTANTES_A_SELECCIONAR = r21
.def	ESTADO = r22


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

.org INT0addr
	rjmp boton

.org OVF0addr
	rjmp seleccion

.org OC1Aaddr
	rjmp int_timer1

.org OC1Baddr
	rjmp int_timer1B
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
	rcall timer1_conf_B
	ldi RESTANTES_A_SELECCIONAR, N_SELECCIONADOS

	sei
main_loop:
	rjmp main_loop



conf_int0:
	ldi AUX1, (2<<ISC00)
	sts EICRA, AUX1

	ldi AUX1, (1<<INT0)
	out EIMSK, AUX1

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

timer_0_conf_delay:
	ldi AUX2, (1<<WGM00)
	out TCCR0A, AUX2

	; AUX1, (1<<OCF0A)
	;out TIFR0, AUX1			; limpio flag en caso de ser necesario

	ldi AUX2,(1<<TOV0)
	sts TIMSK0, AUX2

;	ldi AUX2, 255
;	sts OCR0A, AUX2

	ldi AUX2, (5<<CS00)
	out TCCR0B, AUX2

	ret

timer1_conf_B:
	ldi AUX1, high(7811)
	sts OCR1BH, AUX1
	ldi AUX1, low(7811)	
	sts OCR1BL, AUX1

	ldi AUX1, high(7811)
	sts OCR1AH, AUX1
	ldi AUX1, low(7811)	
	sts OCR1AL, AUX1

	ldi AUX1, (1<<OCIE1B);
	sts TIMSK1, AUX1

	ldi AUX1, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, AUX1

	clr AUX1

	ret

timer1_conf_A:
	ldi r16, high(7812)
	sts OCR1AH, r16
	ldi r16, low(7812)	
	sts OCR1AL, r16

	ldi AUX1, (1<<OCIE1A)
	sts TIMSK1, AUX1	
	ldi r16, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, r16
	ldi CONT, CANT
	ret

boton:
	rcall timer_0_conf_delay
salir_boton:
	reti

seleccion:
	sbic PIND, 2
	rjmp salir_seleccion

interrupcion:
	clr AUX1
	out TCCR0B, AUX1
	sbi PINC, 2
	dec RESTANTES_A_SELECCIONAR

	breq salir_etapa
	rjmp salir_seleccion

salir_etapa:
;	ldi DATO, 'J'
	clr AUX1
	out PORTC, AUX1
	out PORTB, AUX1
	rcall timer1_conf_A

;	clr AUX1
;	sts ADCSRA, AUX1	; desactivo adc
	out EIMSK, AUX1		; desactivo interrupcion 0 por motivos de robustez de codigo, que el usuario no entre en ella estando en otra etapa
	
;	rcall guardar_dato
;	rcall mover_a_derecha
;	cpi RESTANTES_A_SELECCIONAR, 0
;	brne salir_seleccion
;	rcall salir_etapa

salir_seleccion:
	reti

int_timer1B:
	ldi AUX2, N_SELECCIONADOS
	sub AUX2, RESTANTES_A_SELECCIONAR
	out PORTC, AUX2
	reti
int_timer1:
;	sbic PIND, 2
;	sbi PINC, 2
	ldi AUX1, BAJA
	out PINB, AUX1
	in  AUX1, PINC
	ori AUX1, BAJA
	out PINC, AUX1

	dec CONT
	breq fin_espera
	rjmp salir_int_timer1
fin_espera:	
;	lds AUX1, UCSR0A		
;	sbrs AUX1, UDRE0		; corroboro que el buffer este vacio 
;	rjmp fin_espera
;	sts UDR0, DATO		; envio dato por uart
;	clr AUX1
	sts TCCR1B, AUX1	; desactivo timer 1 para que no produzca nuevas interrupciones y consumir menos energia 
salir_int_timer1:
	reti