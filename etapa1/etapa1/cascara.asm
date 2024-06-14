;
; cascara.asm
;
; Creado: 29/04/2021 08:00:00 p.m.
; Autor : Gabriel
;

.include "m328pdef.inc"
 
; Constantes del programa
.equ	ESPERANDO_JUGADOR = 1; Numero constante

; Alias de los registros
.def	cont = r16

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

	rcall USART_init

	ldi r16, 'N'
	sts UDR0, r16

	sei 
; Arranca mi loop principal que se ejecutará eternamente	
main_loop:
	rcall USART_Receive
	USART_transmit r16
    rjmp main_loop


USART_Init:
	 ; Set baud rate to UBRR0
	 ldi r17, 0
	 ldi r16, 103
	 sts UBRR0H, r17
	 sts UBRR0L, r16
	 ; Enable receiver and transmitter
	 ldi r16, (1<<RXEN0)|(1<<TXEN0)
	 sts UCSR0B,r16
	 ; Set frame format: 8data, 2stop bit
	 ldi r16, (3<<UCSZ00)
	 sts UCSR0C,r16
	 ret



USART_Receive:
	 ; Wait for data to be received
	 lds r17, UCSR0A
	 sbrs r17, RXC0
	 rjmp USART_Receive
	 ; Get and return received data from buffer
	 lds r16, UDR0
	 ret

; Definicion de tabla en memoria de codigo
tabla: .db	"Esto es una tabla constante", 0x00