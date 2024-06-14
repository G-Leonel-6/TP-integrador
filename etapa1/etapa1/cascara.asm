;
; cascara.asm
;
; Creado: 29/04/2021 08:00:00 p.m.
; Autor : Gabriel
;

.include "m328pdef.inc"
 
; Constantes del programa
.equ	ESPERANDO = 1; Numero constante
.equ	RECIBIDO = 2
.equ	CANT = 6
; Alias de los registros
.def	DATO = r18
.def	AUX1 = r16
.def	CONT = r17
.def	ESTADO = r19

.macro USART_Transmit
transmit:
	 ; Wait for empty transmit buffer
	 lds r17, UCSR0A
	 sbrs r17, UDRE0
	 rjmp transmit
	 ; Put data (r16) into buffer, sends the data
	 sts UDR0,@0
.endmacro

.dseg
; Segmento de datos en memoria de datos
.org SRAM_START
; Definicion de variable 
; Nombre .byte Tamanio_en_bytes
var1:	.byte	1

.cseg
.org 0x0000
; Segmento de datos en memoria de codigo
	rjmp	main

.org OC1Aaddr
	rjmp int_timer1

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
				
;	ldi r16, 0xc4		; configuro usart asincronico simple 8 bits de tama;o sin bit de paridad un bit de parada 
;	sts UCSR0B, r16

;	ldi r16, 0x06
;	sts UCSR0C, r16

;	ldi r16, 103		; baud rate 9600
;	sts UBRR0L, r16

;	ldi r16, 0
;	sts UBRR0H, r16

;	ldi r16, 0x20
;	sts UCSR0A, r16
	rcall timer1_conf

	rcall USART_init
	sei

	ldi r16, 'N'
	sts UDR0, r16

; Arranca mi loop principal que se ejecutará eternamente	
main_loop:
    rjmp main_loop


conf_IO:
	ldi AUX1, 0x0f
	out DDRB, AUX1
	out DDRC, AUX1
	clr AUX1
	out PORTB, AUX1
	out PORTC, AUX1
	ret

USART_Init:
	 ; Set baud rate to UBRR0
	 ldi r17, 0
	 ldi r16, 103		; baudrate de 9600
	 sts UBRR0H, r17
	 sts UBRR0L, r16
	 ; Enable receiver and transmitter
	 ldi r16, (1<<RXCIE0)|(1<<TXCIE0)|(1<<RXEN0)|(1<<TXEN0)
	 sts UCSR0B,r16
	 ; Set frame format: 8data, 1 stop bit
	 ldi r16, (3<<UCSZ00)
	 sts UCSR0C,r16
	 ret

timer1_conf:
	ldi r16, (1<<WGM12)|(1<<CS12)|(1<<CS10)
	sts TCCR1B, r16
	ldi AUX1, (1<<OCIE1A)
	sts TIMSK1, AUX1
	ldi r16, high(7812)
	sts OCR1AH, r16
	ldi r16, low(7812)	
	sts OCR1AL, r16
	ldi CONT, CANT
	ret

int_timer1:
	ldi AUX1, 0x0f
	out PINB, AUX1
	in  AUX1, PINC
	ori AUX1, 0x0f
	out PINC, AUX1

	dec CONT
	breq fin_espera
	rjmp salir_int_timer1
fin_espera:
	lds r17, UCSR0A
	sbrs r17, UDRE0
	rjmp fin_espera
	sts UDR0, DATO
	clr AUX1
	sts TCCR1B, AUX1
salir_int_timer1:
	reti

r_complete:
	ldi ESTADO, RECIBIDO
	lds DATO, UDR0
	rcall timer1_conf
	reti

t_complete:
	ldi ESTADO, ESPERANDO
	reti

; Definicion de tabla en memoria de codigo
tabla: .db	"Esto es una tabla constante", 0x00