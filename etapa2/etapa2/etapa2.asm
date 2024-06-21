;
; cascara.asm
;
; Creado: 29/04/2021 08:00:00 p.m.
; Autor : Leonel Gonzalez y Julieta Gonzalez Kratz
;

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
; Segmento de datos en memoria de codigo
	rjmp	main

.org INT0addr
	rjmp boton

.org ADCCaddr
	rjmp adc_complete

.org OC1Aaddr
	rjmp int_timer1

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
	rcall apuntar_inicio_cifras
	rcall cargar_cifras_a_ram
	rcall apuntar_inicio_posiciones
	rcall cargar_posiciones_a_ram


	rcall conf_estado_inicial

	in AUX1, PORTB
	andi AUX1, ALTA
	or AUX1, DATO
	out PORTB, AUX1

	in AUX1, PORTC
	andi AUX1, ALTA
	or AUX1, POS
	out PORTC, AUX1

	rcall conf_ADC
	rcall timer1_conf_B
	sei
; Arranca mi loop principal que se ejecutará eternamente	
main_loop:
	;ldi16 cont, r17, 1024 	; uso de la macro
	rjmp main_loop




conf_estado_inicial:

	rcall apuntar_inicio_cifras_ram
	rcall apuntar_inicio_posiciones_ram

	ldi YH, high(seleccionados)
	ldi YL, low(seleccionados)

	ldi RESTANTES_A_SELECCIONAR, N_SELECCIONADOS

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

timer1_conf_A:
	lds AUX1, TIMSK1
	ori AUX1, (1<<OCIE1A)
	sts TIMSK1, AUX1	
	ldi CONT, CANT
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

timer_0_conf_delay:
	ldi AUX2, (2<<WGM00)
	out TCCR0A, AUX1

;	ldi AUX1, (1<<OCF0A)
;	out TIFR0, AUX1			; limpio flag en caso de ser necesario

	ldi AUX2,(1<<OCIE0A)
	sts TIMSK0, AUX1

	ldi AUX2, 255
	sts OCR0A, AUX1

	ldi AUX2, (5<<CS00)
	out TCCR0B, AUX1
	ret

conf_ADC:
	ldi AUX1, (1<<REFS0)|(1<<ADLAR)|(4<<MUX0)
	sts ADMUX, AUX1

	ldi AUX1, (1<<ADEN)|(1<<ADATE)|(1<<ADIE)|(1<<ADPS1)|(1<<ADPS0)
	sts ADCSRA, AUX1
	
	ldi AUX1, (5<<ADTS0)
	sts ADCSRB, AUX1

	ret
;-----------------------------------------------*****-------------------------------------------------------------------
mover_a_izquierda:
	cpi CONT, 0
	brne seguir_izquierda
	rcall apuntar_final_cifras_ram
	rcall apuntar_final_posiciones_ram

	cpi POS, OCUPADO
	brne salir_mover_a_izquierda

seguir_izquierda: 
	ld AUX1, -Z
	ld POS, -X
	dec CONT
	cpi POS, OCUPADO
	breq mover_a_izquierda
	mov DATO, AUX1
	rjmp salir_adc

salir_mover_a_izquierda:
	ret

mover_a_derecha:
	cpi CONT, N_POSICIONES
	brne seguir_derecha
	rcall apuntar_inicio_cifras_ram
	rcall apuntar_inicio_posiciones_ram

	cpi POS, OCUPADO
	brne salir_mover_derecha

seguir_derecha:
	adiw ZH:ZL, 1
	adiw XH:XL, 1
	ld AUX1, Z
	ld POS, X
	inc CONT
	cpi POS, OCUPADO
	breq mover_a_derecha
	mov DATO, AUX1

salir_mover_derecha:
	ret
;-----------------------------------------------------------****-----------------------------------------------------
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

cargar_cifras_a_ram:
	ldi CONT, N_POSICIONES
loop_cifras:
	lpm AUX1, Z+
	st X+, AUX1
	dec CONT
	breq salir_cargar_cifras
	rjmp loop_cifras
salir_cargar_cifras:	
	ret

apuntar_inicio_posiciones_ram:
	ldi XH, high(posiciones_ram)
	ldi XL, low(posiciones_ram)

	ld POS, X
	ret

apuntar_final_posiciones_ram:
	ldi XH, high(posiciones_ram+N_POSICIONES)
	ldi XL, low(posiciones_ram+N_POSICIONES)
	
	ld POS, X
	ret

apuntar_inicio_cifras_ram:
	ldi ZH, high(cifras_ram)
	ldi ZL, low(cifras_ram)

	ldi CONT, 0
	ld DATO, Z
	ret

apuntar_final_cifras_ram:
	ldi ZH, high(cifras_ram+N_POSICIONES)
	ldi ZL, low(cifras_ram+N_POSICIONES)
	
	ldi CONT, N_POSICIONES
	ld DATO, Z
	ret

;------------------------------------------------------****--------------------------------------------------------------


guardar_dato:
	st Y+, DATO
	ldi AUX1, OCUPADO
	st X, AUX1
	dec RESTANTES_A_SELECCIONAR

	ret

salir_etapa:
	ldi DATO, 'J'
	rcall timer1_conf_A

	clr AUX1
	sts ADCSRA, AUX1	; desactivo adc
	out EIMSK, AUX1		; desactivo interrupcion 0 por motivos de robustez de codigo, que el usuario no entre en ella estando en otra etapa


	ret

adc_complete:
	ldi AUX1, (1<<OCF0B)
	out TIFR0, AUX1	

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
	andi DATO, BAJA
	in AUX1, PORTB
	andi AUX1, ALTA
	or AUX1, DATO
	out PORTB, AUX1

	ldi AUX2, N_SELECCIONADOS
	sub AUX2, RESTANTES_A_SELECCIONAR
	in AUX1, PORTC
	andi AUX1, ALTA
	or AUX1, AUX2
	out PORTC, AUX1

	reti 

boton:
	rcall timer_0_conf_delay
	reti

seleccion:
	sbic PIND, 2
	rjmp salir_seleccion

	rcall guardar_dato
	rcall mover_a_derecha
	cpi RESTANTES_A_SELECCIONAR, 0
	brne salir_seleccion
;	rcall salir_etapa

salir_seleccion:
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
	lds r17, UCSR0A		
	sbrs r17, UDRE0		; corroboro que el buffer este vacio 
	rjmp fin_espera
	sts UDR0, DATO		; envio dato por uart
	clr AUX1
	sts TCCR1B, AUX1	; desactivo timer 1 para que no produzca nuevas interrupciones y consumir menos energia 
salir_int_timer1:
	reti
	
; Definicion de tabla en memoria de codigo
cifras: .db	0x00,0x01,0x02, 0x03,0x04,0x05,0x06,0x07,0x08,0x09, 0x00, 0x00
posiciones: .db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00