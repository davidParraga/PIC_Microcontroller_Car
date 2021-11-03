				List p = 16f876a
			include	"p16f876a.inc"
	__CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF

				ORG 	0
				goto	inicio
		
				ORG 	4
				goto	interrupcion

				ORG		5


PORTCactual			EQU		0X20
V				EQU		0X21				
Vactual				EQU		0X22
zero				EQU		0X23
sentido				EQU		0X24
Toff				EQU		0X25
dos				EQU		0X26
id				EQU		0X27
idcheck				EQU		0X28


inicio
				clrf	zero
				movlw	.2
				movwf	dos
				movlw	b'10000001'
				movwf	idcheck
				bsf	STATUS,RP0		;Subimos al banco 1
				clrf	TRISC			;TX hacia el puerto serie				
				bsf 	TRISC,7			;Rx desde el puerto serie
				

				bcf	OPTION_REG,T0CS		;TMR0 usará el reloj del MICRO
				bcf	OPTION_REG,PSA		;Preescaler en rango de TMR0
				bcf	OPTION_REG,PS2		;Selecciones escala 1:2 para TMR0
				bcf	OPTION_REG,PS1
				bcf	OPTION_REG,PS0		;
				bsf	TXSTA,BRGH		;High Speed
				movlw   .25			;9600 baudios
				movwf	SPBRG
				bcf	TXSTA,TX9		;8 bits de transmisión
				bcf	TXSTA,SYNC		;conexión asíncron
				bsf	PIE1,RCIE		;Habilitamos interrupción de recepción
				bcf	STATUS,RP0					
				
				bsf	RCSTA,SPEN		;Habilitamos puerto series
				bcf	RCSTA,RX9		;8 bit de recepción
				bsf	RCSTA,CREN		;habilitamos recepción continua
				movlw	.7
				movwf	TMR0
				bsf	INTCON,GIE  		;Activa interrupciones	
				bsf	INTCON,PEIE		;Activa interrupciones del PEIE
				bcf	INTCON,T0IE		;Comenzamos con la interrupción de TMR0 desactiva
				bcf	INTCON,T0IF			

main
				goto 	main

interrupcion
				btfss	PIR1,RCIF		;Compruebo si he recibido
				goto	motor			;Ha saltado TMR0, voy a ver si toca motor encendido o apagado
				decfsz	dos,1			;Compruebo si estoy recibiendo el dato 
				goto	idrx			;Va a ver si es su identificador
              			movlw	.2
				movwf	dos
				movf	id,0
				xorwf	idcheck,0
				btfss	STATUS,Z
				retfie				;Lo recibido no es de otro coche
				movf	RCREG,0			;Leemos lo recibio porque el id era el suyo
				movwf	sentido			;Variable para comprobar sentido de movimiento
				movwf	V			;Nos quedamos con los bits de velocidad 
				bcf	V,7			;Y borramos los de sentido
				bcf	V,6
				bcf	V,5
				bcf	V,4
				movf	V,0			;
				movwf	Vactual				
				sublw	.32					
				movwf	Toff			;Aquí guardamos 32-V para saber cuanto tiempo está el motor encendido
				btfsc	sentido,6
				goto	atroizq			;Si sentido,6 vale 1 es atras o izquierda
				btfsc	sentido,5		;Si sentido,5 vale 0 es adelante o derecha
				goto	adelante			
				goto	derecha
atroizq
				btfsc	sentido,5
				goto	izquierda
				goto	atras
						
derecha
				movlw	b'10001010'		;Conservamos RC7 a 1 por ser la linea de RX del USART
				goto	terminar		
adelante
				movlw	b'10001011'			
				goto	terminar
atras
				movlw	b'10000111'
				goto	terminar	
izquierda
				movlw	b'10000001'
				goto 	terminar
parado
				movlw   b'10000000'
				goto 	terminar

terminar
				movwf	PORTC
				movwf	PORTCactual
				bsf	INTCON,T0IE
				goto	prepararTMR0

motor								;Venimos aquí cuando salta el TMR0
				movf	Vactual,0
				xorwf	zero,0				
				btfsc	STATUS,Z
				goto	off			;Si Vactual es 0 apagamos motor
				decfsz	Vactual,1		;Si Vactual no es 0 decrementamos y seguimos con el motor ON
				retfie
				movlw   b'10000000'		;Dejo el motor parado para ir decrementando Toff en las siguientes interrupciones
				movwf	PORTC
				goto	prepararTMR0
				retfie
				
off
				decfsz	Toff,1
				goto	prepararTMR0
				movf	V,0
				movwf	Vactual
				sublw	.32
				movwf	Toff
				;goto	prepararTMR0

prepararTMR0
				movlw	.7
				movwf	TMR0
				bcf	INTCON,T0IF	;Bajamos flag T0IF
				return


idrx							;Aquí venimos cuando salta RCREG por haber recibido el identificador
				movf	RCREG,0
				movwf	id
				retfie

				END