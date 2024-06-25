/*
 * etapa2_V2.asm
 *
 *  Created: 6/21/2024 10:15:29 PM
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
.equ	MEDIO = 1
.equ	BUSCANDO_CONTRINCANTE = 0
.equ	ELIGIENDO_NUMERO = 1
.equ	JUEGO = 2

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

.org OVF2addr
	rjmp timer2int

.org OC1Aaddr
	rjmp int_timer1


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

	rcall conf_IO
	rcall conf_int0
	rcall USART_conf
	rcall conf_ADC
	rcall timer1_conf_B
	rcall conf_estado_inicial

	sei
main_loop:
	rjmp main_loop

USART_conf:
	 ; Set baud rate to UBRR0
	 ldi AUX1, 0
	 sts UBRR0H, AUX1
	 ldi AUX1, 103		; baudrate de 9600
	 sts UBRR0L, AUX1
	 ; Enable receiver and transmitter
	 ldi r16, (1<<RXCIE0)|(1<<TXCIE0)|(1<<RXEN0)|(1<<TXEN0)
	 sts UCSR0B,r16
	 ; Set frame format: 8data, 1 stop bit
	 ldi r16, (3<<UCSZ00)
	 sts UCSR0C,r16
	 ret

conf_estado_inicial:

	rcall apuntar_inicio_posiciones_ram

	ldi YH, high(seleccionados)
	ldi YL, low(seleccionados)

	ldi RESTANTES_A_SELECCIONAR, N_SELECCIONADOS
	ldi DATO, 0
	ldi ESTADO, MEDIO
	ret


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

timer_2_conf_delay:
	ldi AUX2, (1<<WGM00)
	sts TCCR2A, AUX2

	ldi AUX2,(1<<TOIE0)
	sts TIMSK2, AUX2


	ldi AUX2, (5<<CS00)
	sts TCCR2B, AUX2

	ret

timer1_conf_A:
	ldi AUX2, high(7812)
	sts OCR1AH, AUX2
	ldi AUX2, low(7812)	
	sts OCR1AL, AUX2

	ldi AUX2, (1<<OCIE1A)
	sts TIMSK1, AUX2	
	ldi AUX2, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, AUX2
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

adc_complete:
	lds AUX1, ADCH
	cpi AUX1, IZQUIERDA_V
	breq izquierda
	cpi AUX1, DERECHA_V
	breq derecha
	ldi ESTADO, MEDIO
	rjmp salir_adc
izquierda:
	cpi ESTADO, MEDIO		; el estado anterior del jostick debe ser el medio por motivos de robustez 
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

boton:
	rcall timer_2_conf_delay
salir_boton:
	reti

timer2int:
	sbic PIND, 2
	rjmp salir_seleccion

interrupcion:
	clr AUX2
	sts TCCR2B, AUX2

	rcall guardar_dato
	rcall mover_a_derecha
	dec RESTANTES_A_SELECCIONAR
	ldi AUX2, N_SELECCIONADOS
	sub AUX2, RESTANTES_A_SELECCIONAR
	out PORTC, AUX2
	cpi RESTANTES_A_SELECCIONAR, 0
	brne salir_seleccion

salir_etapa:
	ldi DATO, 'J'		; codigo tentativo para cuando se solucione el rebote
	clr AUX2
	out PORTC, AUX2
	out PORTB, AUX2

	clr AUX1
	sts ADCSRA, AUX1	; desactivo adc
	out EIMSK, AUX1		; desactivo interrupcion 0 por motivos de robustez de codigo, que el usuario no entre en ella estando en otra etapa

	rcall timer1_conf_A

salir_seleccion:
	reti

int_timer1:
	ldi AUX2, BAJA
	out PINB, AUX2
	in  AUX2, PINC
	ori AUX2, BAJA
	out PINC, AUX2

	dec CONT
	breq fin_espera
	rjmp salir_int_timer1
fin_espera:	
	lds AUX1, UCSR0A		
	sbrs AUX1, UDRE0		; corroboro que el buffer este vacio 
	rjmp fin_espera
	sts UDR0, DATO		; envio dato por uart
	clr AUX2
	sts TCCR1B, AUX2	; desactivo timer 1 para que no produzca nuevas interrupciones y consumir menos energia 
salir_int_timer1:
	reti

posiciones: .db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00