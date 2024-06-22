/*
 * Adc.asm
 *
 *  Created: 6/20/2024 6:16:09 PM
 *   Author: leone
 */ 

 .include "m328pdef.inc"

 
; Constantes del programa
.equ	CANT = 6 ; Numero constante
.equ	IZQUIERDA_V = 0x00
.equ	DERECHA_V = 0xff
.equ	N_POSICIONES = 10
.equ	N_SELECCIONADOS = 4
.equ	VACIO = 0
.equ	OCUPADO = 0x01
.equ	AlTA = 0xf0
.equ	BAJA = 0x0f
.equ	MEDIO = 1

; Alias de los registros
.def	AUX1 = r16
.def	CONT = r17
.def	DATO = r18
.def	POS = r19
.def	AUX2 = r20
.def	RESTANTES_A_SELECCIONAR = r21
.def	ESTADO= r22


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

	rcall apuntar_inicio_posiciones
	rcall cargar_posiciones_a_ram
	rcall apuntar_inicio_cifras
	rcall cargar_cifras_a_ram

	rcall conf_estado_inicial

	rcall conf_IO
	rcall conf_ADC
	rcall timer1_conf_B
	sei
fin:
	rjmp fin


conf_estado_inicial:

	rcall apuntar_inicio_cifras_ram
	rcall apuntar_inicio_posiciones_ram

	ldi YH, high(seleccionados)
	ldi YL, low(seleccionados)

	ldi RESTANTES_A_SELECCIONAR, N_SELECCIONADOS
	ldi DATO, 0

	ret

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
	clr DATO
	
	out PORTB, AUX1
	out PORTC, AUX1
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

apuntar_inicio_cifras:
	ldi ZH, high(cifras<<1)
	ldi ZL, low(cifras<<1)

	ldi XH, high(cifras_ram)
	ldi XL, low(cifras_ram)

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


mover_a_derecha:
	cpi CONT, N_POSICIONES-1
	brne seguir_derecha
;	rcall apuntar_inicio_cifras_ram
	rcall apuntar_inicio_posiciones_ram
	ldi DATO, 0
	cpi POS, VACIO
	breq salir_mover_derecha

seguir_derecha:
	;ld AUX1, Z+
	ld POS, X+
;	ld AUX1, Z
	ld POS, X
	inc CONT
	cpi POS, OCUPADO
	breq mover_a_derecha
	mov DATO, CONT

salir_mover_derecha:
	ret

mover_a_izquierda:
	cpi CONT, 0
	brne seguir_izquierda
;	rcall apuntar_final_cifras_ram
	rcall apuntar_final_posiciones_ram
	ldi DATO, 9
	cpi POS, VACIO
	breq salir_mover_a_izquierda

seguir_izquierda: 
	;ld AUX1, -Z
	ld POS, -X
	dec CONT
;	dec DATO
	cpi POS, OCUPADO
	breq mover_a_izquierda
	mov DATO, CONT

salir_mover_a_izquierda:
	ret

adc_complete:
mover:
	lds AUX1, ADCH
	cpi AUX1, IZQUIERDA_V
	breq izquierda
	cpi AUX1, DERECHA_V
	breq derecha
	ldi ESTADO, MEDIO
	rjmp salir_adc

izquierda:
	cpi ESTADO, MEDIO
	brne salir_adc
	rcall mover_a_izquierda
	ldi ESTADO, 0
	rjmp salir_adc
derecha:
	cpi ESTADO, MEDIO
	brne salir_adc
	rcall mover_a_derecha
	ldi ESTADO, 0
salir_adc:
	out PORTB, DATO
	reti 


cifras: .db	0x00,0x01,0x02, 0x03,0x04,0x05,0x06,0x07,0x08,0x09, 0x00, 0x00
posiciones: .db 0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00