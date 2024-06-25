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
.equ	BAJA = 0x0f
; Alias de los registros
.def	DATO = r18
.def	AUX1 = r16
.def	CONT = r17
.def	ESTADO = r19
.def	AUX2 = r20

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
;.org INT0addr
;	rjmp boton
.org OC1Aaddr
	rjmp int_timer1

.org OVF2addr
	rjmp timer2int

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
				
;	rcall conf_int0
	rcall conf_IO
	rcall USART_init
	sei


; Arranca mi loop principal que se ejecutará eternamente	
main_loop:
    rjmp main_loop

timer_2_conf_delay:
	ldi AUX2, (1<<WGM00)
	sts TCCR2A, AUX2

	ldi AUX2,(1<<TOIE0)
	sts TIMSK2, AUX2

	ldi AUX2, (5<<CS00)
	sts TCCR2B, AUX2

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

r_complete:
	ldi ESTADO, RECIBIDO
	lds DATO, UDR0
	cpi DATO, 'N'
	brne salir_r
conf_timer:
	rcall timer1_conf
salir_r:
	reti

t_complete:
	ldi ESTADO, ESPERANDO
	reti

boton:
	rcall timer_2_conf_delay
salir_boton:
	reti

timer2int:
	sbic PIND, 2
	rjmp salir_timer2_int

	rcall timer1_conf
salir_timer2_int:
	reti

; Definicion de tabla en memoria de codigo
tabla: .db	"Esto es una tabla constante", 0x00