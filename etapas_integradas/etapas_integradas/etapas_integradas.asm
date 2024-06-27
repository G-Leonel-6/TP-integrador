;
; etapas_integradas.asm
;
; Created: 6/23/2024 7:03:03 PM
; Author : leone
;


.include "m328pdef.inc"
 
; Constantes del programa
.equ	CANT = 6
.equ	IZQUIERDA_V = 0x06
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
.equ	JUEGO_TERMINADO = 3

; Alias de los registros
.def	AUX1 = r16
.def	CONT = r17
.def	DATO = r18
.def	POS = r19
.def	AUX2 = r20
.def	RESTANTES_A_SELECCIONAR = r21
.def	ESTADO = r1
.def	NUMERO_USUARIO_1 = r22
.def	NUMERO_USUARIO_2 = r23
.def	NUMERO_USUARIO_3 = r24
.def	NUMERO_USUARIO_4 = r25
.def	DATO_X = r18
.def	DATO_Y = r19
.def	LEDS_ROJOS	= r20
.def	LEDS_VERDES	= r21
.def	POS_X			=r22
.def	POS_Y			=r23
.def	MSK_VERDE		=r24
.def	MSK_ROJO		=r25
.def	CONT2 = r2
.def	NUMEROS_RECIBIDOS = r3

.dseg
; Segmento de datos en memoria de datos
.org SRAM_START
; Definicion de tablas 
posiciones_ram:	.byte	10
seleccionados:  .byte	4
usuario:			.byte	4

.cseg
.org 0x0000
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
	ldi AUX1, BUSCANDO_CONTRINCANTE
	mov ESTADO, AUX1
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
	ldi AUX1, ELIGIENDO_NUMERO
	mov ESTADO, AUX1
	ret

conf_IO:						; rutina que configura puertos de entrada y salida
	clr AUX1
	out DDRD, AUX1				; puerto D como entrada
	ldi AUX1, (1<<PD2)			 
	out PORTD, AUX1				; pull up interno para el pin 2, pin de nterrupcion int0
	ldi AUX1, BAJA
	out DDRB, AUX1				; parte baja puerto b como salida
	out DDRC, AUX1				; parte alta puerto c como salida
	
	clr AUX1
	
	out PORTB, AUX1				; sin pull up interno y valor 0 logico en las salidas
	out PORTC, AUX1				; sin pull up interno y valor 0 logico en las salidas
	ret

conf_int0:						; rutina que configura la interrupcion 0
	ldi AUX1, (2<<ISC00)		; configuro flanco de descendente como señal de disparo
	sts EICRA, AUX1

	ldi AUX1, (1<<INT0)			; habilito interrupcion deint0
	out EIMSK, AUX1

	ret

USART_conf:
	
	 ldi AUX2, 0
	 ldi AUX1, 103				; baudrate de 9600
	 sts UBRR0H, AUX2
	 sts UBRR0L, AUX1
	 
	 ldi AUX1, (1<<RXCIE0)|(1<<TXCIE0)|(1<<RXEN0)|(1<<TXEN0)		; habilito receptor y transmisor y sus interrupciones
	 sts UCSR0B,AUX1
	 
	 ldi AUX1, (3<<UCSZ00)											; formato: 8 datos, 1 bit de parada
	 sts UCSR0C,AUX1
	 ret

timer_2_conf_delay:													; rutina de configuracion de delay
	ldi AUX2, (1<<WGM00)											; modo pwm phase correcta
	sts TCCR2A, AUX2

	ldi AUX2,(1<<TOIE0)												; habilito interrupcion por overflow timer 2
	sts TIMSK2, AUX2

	ldi AUX2, (5<<CS00)												; preescaler 1024 
	sts TCCR2B, AUX2

	ret

timer1_conf_A:														; rutina de configuracion del timer 1 para rutina de match con OCR1A
	ldi AUX1, (1<<WGM12)|(1<<CS12)|(1<<CS10)						; modo CTC preescaler 1024
	sts TCCR1B, AUX1
	ldi AUX1, (1<<OCIE1A)											; habilito interrupcion de match con OCR1A
	sts TIMSK1, AUX1
	ldi AUX1, high(7812)											; configuro valor de OCR1A
	sts OCR1AH, AUX1
	ldi AUX1, low(7812)	
	sts OCR1AL, AUX1
	ldi CONT, CANT													; cargo en el contador la cantidad de veces que debe funcionar ejecutarse la interrupcion
	ret

timer1_conf_B:														; rutina que configura el timer 1 para producir ejecucion de autotrigger del adc
	ldi AUX1, high(7811)											; un valor previo al reinicio por match con OCR1A
	sts OCR1BH, AUX1
	ldi AUX1, low(7811)	
	sts OCR1BL, AUX1

	ldi AUX1, high(7812)
	sts OCR1AH, AUX1
	ldi AUX1, low(7812)	
	sts OCR1AL, AUX1

	ldi AUX1, (1<<OCIE1B);											; habilito flag de interruocion de match B
	sts TIMSK1, AUX1

	ldi AUX1, (1<<WGM12)|(1<<CS12)|(1<<CS10)						; modo CTC preescaler 1024
	sts TCCR1B, AUX1

	clr AUX1

	ret

conf_ADC:											; rutina que configura el modulo adc
	ldi AUX1, (1<<REFS0)|(1<<ADLAR)|(1<<MUX2)		; ajuste a izquierda, selecciono el adc4, utilizo capacitor entre aref y gnd
	sts ADMUX, AUX1

	ldi AUX1, (1<<ADTS2)|(1<<ADTS0)					; autotrigger señal de disparo de por match B timer 1
	sts ADCSRB, AUX1

	ldi AUX1, (1<<ADEN)|(1<<ADSC)|(1<<ADATE)|(1<<ADIE)|(1<<ADPS1)|(1<<ADPS0) ; habilito adc, inicio primer conversion, habilito autotrigger, habilito flag de interrupcion de adc, factor de preescaler de 8 
	sts ADCSRA, AUX1														 ; 
						
	ret

apuntar_inicio_posiciones:					; rutina que apunta al inicio de la tabla de posiciones en rom
	ldi ZH, high(posiciones<<1)
	ldi ZL, low(posiciones<<1)

	ldi XH, high(posiciones_ram)
	ldi XL, low(posiciones_ram)

	ret

cargar_posiciones_a_ram:					; rutina que carga las posiciones de memoria a ram
	ldi CONT, N_POSICIONES					; cargo contador con cantidad de posiciones a cargar a ram
loop:										
	lpm AUX1, Z+							
	st X+, AUX1
	dec CONT
	breq salir_cargar						
	rjmp loop
salir_cargar:								
	ret

apuntar_inicio_posiciones_ram:				; rutina que apunta al inicio de la tabla de posiciones en ram
	ldi XH, high(posiciones_ram)
	ldi XL, low(posiciones_ram)

	ldi CONT, 0								; carga el valor de 0 en el contador
	ld POS, X								; cargo el valor de pos por si esta ocupado
	ret

apuntar_final_posiciones_ram:				; rutina que apunta al final de la tabla de posiciones en ram
	ldi XH, high(posiciones_ram+N_POSICIONES-1)
	ldi XL, low(posiciones_ram+N_POSICIONES-1)
	
	ldi CONT, N_POSICIONES-1				; coloco el contador en el ultimo valor posible
	ld POS, X								; cargo el valor de pos por si esta ocupado
	ret

guardar_dato:								; rutina para guardar el numero seleccionado
	st Y+, CONT								; guardo el valor de cant en selccionados
	ldi AUX2, OCUPADO						; lo señalo como ocupado para que no pueda volver a ser seleccionado
	st X, AUX2
	ret

mover_a_derecha:
	cpi CONT, N_POSICIONES-1				; chequeo que no estoy en el final de la tabla
	brne seguir_derecha						
	rcall apuntar_inicio_posiciones_ram		; si estoy al final me muevo al principio
	cpi POS, VACIO							; verifico que el valor sea valido para ser elegido, si lo es salgo de la rutino, sino sigo
	breq salir_mover_derecha

seguir_derecha:
	ld POS, X+								; realizo incremento del puntero
	ld POS, X								; dato que realmente me interesa
	inc CONT
	cpi POS, OCUPADO
	breq mover_a_derecha
	
salir_mover_derecha:
	ret

mover_a_izquierda:
	cpi CONT, 0								; chequeo que no se encuentre al principio de la tabla
	brne seguir_izquierda					
	rcall apuntar_final_posiciones_ram		; si esta al principio me muevo al final
	cpi POS, VACIO							; el valor es valido para ser elegido, termino la rutino, sino sigo moviendo
	breq salir_mover_a_izquierda

seguir_izquierda: 
	ld POS, -X
	dec CONT
	cpi POS, OCUPADO						; si la el numero ya fue elegido su posicion en la tabla estara ocupada, entonces se salta al siguiente numero
	breq mover_a_izquierda

salir_mover_a_izquierda:
	ret

comparar_numero:
	ldi POS_X, 0							; auxiliar para pos de X
	ldi LEDS_VERDES, 0						; el que voy a poner en la luz verde
	ldi LEDS_ROJOS, 0						; el que voy a poenr en la luz roja
	ldi MSK_VERDE, 0b00000001 
	ldi MSK_ROJO, 0b00000001 

	ldi XH, high(seleccionados)
	ldi XL, low(seleccionados)
loop1:
	ld DATO_X, X+						; es el original
									
	ldi YH, high(usuario)				; vuelvo a setear Y en la posición inicial de la tabla
	ldi YL, low(usuario)
	ldi POS_Y, 0
loop2:
	ld DATO_Y, Y+						; es la tabla donde tengo 
	cp DATO_X, DATO_Y
	brne sigo_1							; Si no son iguales, sigo adelante con la comparación
	cp POS_X, POS_Y						; registros auxiliares de en qué posición de X e Y voy. si son iguales significa que nro y pos son correctas. Si son distintos, pos es incorrecta y se aumentan leds rojos
	brne rojo_0
	or LEDS_VERDES, MSK_VERDE
	lsl MSK_VERDE
	rjmp sigo_1							; si el registro que cuenta para X es igual al contador de Y, aumenta la cantidad de leds verdes, sino rojos
rojo_0:
	or LEDS_ROJOS, MSK_ROJO
	lsl MSK_ROJO
sigo_1:
	INC POS_Y
	cpi POS_Y, 4						; si esta cuenta llegó a su fin, terminé de iterar sobre Y y puedo incrementar la posición de X.
	breq fin_loop_1						; esta parte chequea que no haya terminado de iterar sobre X.
	rjmp loop2							; si no terminó, sigo iterando
fin_loop_1:
	INC POS_X
	cpi POS_X, 4						; si está en 4 y acá al final es porque terminé
	breq seteo_luces
	rjmp loop1

seteo_luces:
	cpi LEDS_VERDES, BAJA				; se detecta que se posicionaron bien todos los digitos
	breq numero_adivinado
	inc CONT2
	rjmp mostrar_leds

numero_adivinado:
	mov LEDS_ROJOS, CONT2				; se muestra en los leds rojos la cantidad de intentos empleados
	ldi AUX1, JUEGO_TERMINADO
	mov ESTADO, AUX1
mostrar_leds:
	out PORTB, LEDS_VERDES				; cantidad de digitos que pertenecen al numero secreto bien posicionados
	out PORTC, LEDS_ROJOS				; cantidad de digitos que pertenecen al numero secreto mal posicionados o cantidad de intentos usados para adivinar

	ret

adc_complete:							; interrupcion de conversion analogica digital completa
	lds AUX1, ADCH
	cpi AUX1, IZQUIERDA_V
	brlo izquierda
	cpi AUX1, DERECHA_V
	breq derecha
	rjmp salir_adc
izquierda:
	rcall mover_a_izquierda				; rutina que decrementa el contador si se detecta el jostick en la posicion izquierda
	rjmp salir_adc
derecha:
	rcall mover_a_derecha				; rutina que incrementa el contador si se detecta el jostick en la posicion derecha
salir_adc:
	out PORTB, CONT						; numero disponible para elegir
	reti 

boton:
	rcall timer_2_conf_delay			; configuro delay
salir_boton:
	reti

int_timer1:
	ldi AUX1, BAJA						; titilo leds de los ports
	out PINB, AUX1
	in  AUX1, PINC						; leo portc por seguridad para no interferir con el adc
	ori AUX1, BAJA
	out PINC, AUX1

	dec CONT							; decremento contador del timer para llegar a 3s
	breq fin_espera				
	rjmp salir_int_timer1		
fin_espera:								; si pasaron 3s 
	lds AUX1, UCSR0A
	sbrs AUX1, UDRE0					; verifico que el buffer este vacio 
	rjmp fin_espera				
	sts UDR0, DATO						; escribo en el buffer el valor a enviar
	clr AUX1
	sts TCCR1B, AUX1					; limpio registro de control para que el timer no siga corriendo y no dispare nuevas interrupciones

	ldi AUX1, BUSCANDO_CONTRINCANTE
	cp ESTADO, AUX1							; verifico estado general del juego
	breq salir_etapa_buscando_contrincante	; transicion entre buscando contrincante y eligiendo numero
	rjmp salir_int_timer1`

salir_etapa_buscando_contrincante:			; configuro estado inicial de la nueva etapa y los elementos usados en esta
	rcall apuntar_inicio_posiciones			
	rcall cargar_posiciones_a_ram
	rcall conf_estado_inicial_eligiendo_numero
	rcall conf_ADC
	rcall timer1_conf_B
	clr AUX1
	sts UCSR0B, AUX1						; desconecto usart para que no interfiera en las otras etapas

salir_int_timer1:
	reti

timer2int:		
	sbic PIND, 2							; verifico que el boton siga presionado sino salgo de la interrupcion
	rjmp salir_timer2_int					
	clr AUX2
	sts TCCR2B, AUX2						; limpio el registro de control para desactivar el timer
	ldi AUX2, BUSCANDO_CONTRINCANTE 
	cp ESTADO, AUX2							; verifico estado actual del juego
	breq timer2_buscando_contrincante		
	rjmp timer2_seleccion

timer2_buscando_contrincante:				; el juego se encuentra en el estado buscando contrincante
	rcall timer1_conf_A						
	ldi DATO, 'N'							; preparo el dato que sera enviado por la interfaz serial
	rjmp salir_timer2_int

timer2_seleccion:							; el juego se encuentra en el estado eligiendo numero
	rcall guardar_dato						; rutina que guarda el valor del dato en memoria ram
	rcall mover_a_derecha					; se realiza un movimiento a derecha tras selecccionar el numero
	dec RESTANTES_A_SELECCIONAR				; se reduce el valor de los digitos que faltan por ser elegidos
	ldi AUX2, N_SELECCIONADOS		
	sub AUX2, RESTANTES_A_SELECCIONAR	
	out PORTC, AUX2							; se muestran por los leds rojos el numero de digito que se elegira ahora
	cpi RESTANTES_A_SELECCIONAR, 0
	brne salir_timer2_int

salir_etapa_eligiendo_numero:				; si no faltan digitos por elegir
	rcall USART_conf				
	ldi DATO, 'J'							; cargo el valor del dato que sera enviado por la interfaz serial
	clr AUX2								; apago los leds
	out PORTC, AUX2
	out PORTB, AUX2

	clr AUX1
	sts ADCSRA, AUX1						; desactivo adc
	out EIMSK, AUX1							; desactivo interrupcion 0 por motivos de robustez de codigo, que el usuario no entre en ella estando en otra etapa

	ldi AUX1, JUEGO
	mov ESTADO, AUX1						; cambio al estado juego
	ldi AUX1, 1
	mov CONT2, AUX1
	rcall timer1_conf_A						; titilo los leds 

salir_timer2_int:
	reti

r_complete:									; se completo la recepcion de un dato via serial
	ldi AUX2, BUSCANDO_CONTRINCANTE			; verifico el estado actual del juego
	cp ESTADO, AUX2
	breq recibir_N							; si estoy buscando contrincante
	ldi AUX2, JUEGO
	cp ESTADO, AUX2
	breq recibir_numero						; si estoy en el estado de juego
	ldi AUX2, JUEGO_TERMINADO
	cp ESTADO, AUX2
	breq esperar_reset						; si el numero ya fue adivinado y el juego termino
	rjmp salir_r

recibir_N:									; estoy buscando contrincante
	lds DATO, UDR0							; leo el dato del buffer
	cpi DATO, 'N'							; si no es una N salgo termino la interrupcion
	brne salir_r
conf_timer:
	rcall timer1_conf_A						; recibi N -> titilo leds y configuro proxima etapa
	rjmp salir_r

recibir_numero:								; Estoy en el estado de juego
	lds DATO, UDR0							; leo el buffer
	
	cpi DATO, '0'							; verifico que sea un ascci valido 
	brlo error
											;entre '0' y '9'
	cpi DATO, '9'+1							
	brsh error

	subi DATO, '0'							; convierto a binario natural
	st Y+, DATO								; guardo en la tabla de numeros recibidos
	inc NUMEROS_RECIBIDOS
	ldi AUX1, N_SELECCIONADOS
	cp NUMEROS_RECIBIDOS, AUX1				; verifico si se alcanzo el maximo
	breq comparar							; comparo los numeros si se alcanzo el maximo
	rjmp salir_r

comparar:				
	ldi YH, high(usuario)
	ldi YL, low(usuario)
	ld NUMERO_USUARIO_1, Y+					; levanto los numeros de ram y verifico que no sean iguales
	ld NUMERO_USUARIO_2, Y+
	ld NUMERO_USUARIO_3, Y+
	ld NUMERO_USUARIO_4, Y

	cp NUMERO_USUARIO_1, NUMERO_USUARIO_2
	breq error
	cp NUMERO_USUARIO_1, NUMERO_USUARIO_3
	breq error
	cp NUMERO_USUARIO_1, NUMERO_USUARIO_4
	breq error
	cp NUMERO_USUARIO_2, NUMERO_USUARIO_3
	breq error
	cp NUMERO_USUARIO_2, NUMERO_USUARIO_4
	breq error
	cp NUMERO_USUARIO_4, NUMERO_USUARIO_3
	breq error

	rcall comparar_numero						; si los cuatro numeros son distintos comparo los numeros

	clr AUX1
	mov NUMEROS_RECIBIDOS, AUX1					; tras comparar limpio los numeros recibidos
	ldi YH, high(usuario)						; vuelvo a apuntar al inicio de la tabla
	ldi YL, low(usuario)
	rjmp salir_r
error:
	clr AUX1									; en caso de error espero otros 4 numeros y apunto al inicio de la tabla 
	mov NUMEROS_RECIBIDOS, AUX1
	ldi YH, high(usuario)
	ldi YL, low(usuario)
	rjmp salir_r
esperar_reset:									; si estoy en el estado de juego terminado
	lds DATO, UDR0								; leo del buffer el numero recibido
	cpi DATO, 'R'		
	breq resetear								
	rjmp salir_r
resetear:										; recibi una R mientras estaba en el estado de juego terminado
	ldi AUX1, BUSCANDO_CONTRINCANTE				; vuelvo al estado inicial 
	mov ESTADO, AUX1
	clr AUX1
	out PORTC, AUX1								; apago los leds
	out PORTB, AUX1					
	rcall conf_int0								; vuelvo a habilitar la interrupcion
salir_r:
	reti

t_complete:										; se termino de transmitir el dato del buffer
	ldi AUX1, BUSCANDO_CONTRINCANTE
	cp ESTADO, AUX1								; verifico estado del juego
	breq cambiar_eligiendo_numero
	rjmp cambiar_juego

cambiar_eligiendo_numero:						; si estaba en buscando contrincante
	ldi AUX1, ELIGIENDO_NUMERO					; cambio a estado de eligiendo numero
	mov ESTADO, AUX1
	rjmp salir_t

cambiar_juego:									; si estaba eligiendo numero
	clr AUX1									
	mov NUMEROS_RECIBIDOS, AUX1					; espero 4 numeros

	ldi YH, high(usuario)						; apunto al inicio de la tabla 
	ldi YL, low(usuario)

	ldi AUX1, JUEGO								; cambio al estado de juego
	mov ESTADO, AUX1

salir_t:
	reti

posiciones: .db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00