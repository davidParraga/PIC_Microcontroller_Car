					LIST p=16f876a
				include "p16f876a.inc"
		__CONFIG _XT_OSC & _WDT_OFF & _LVP_OFF

DV				EQU		0X20

aux				EQU		0X22
portbanterior			EQU		0X23
portbactual			EQU		0X24
	

				ORG		0
				goto 		inicio
	
				ORG		4
				goto		interrupcion
		
				ORG		5

inicio
				movf	PORTB,0
				movwf	portbanterior
				bsf	STATUS,RP0
				movlw  	b'11111111'
				movwf	TRISB
				bsf	TRISC,7 	;USART
				bcf	TRISC,6
				bsf	TRISA,2 	;entrada pontenciómetro
				bcf	ADCON1,ADFM	;nos quedamos con los 6 bits mas significativos?
			 	bcf	ADCON1,PCFG3 	;elegimos configuración buscada puerto A (Queremos RA2 analógico)
				bcf	ADCON1,PCFG2
				bcf	ADCON1,PCFG1
				bcf	ADCON1,PCFG0 	;
				bcf	TXSTA,TX9 	 ;8 bit transmisión
				bsf	TXSTA,TXEN	 ;activa transmisión
				bcf	TXSTA,SYNC 	 ;USART modo asíncrono
				bsf	TXSTA,BRGH 	 ;selecciona una de las dos tablas de baud rates
				movlw	.25
				movwf	SPBRG
				bcf	PIE1,TXIE	 ;No utilizaremos interrupción e tx

				bcf	STATUS,RP0
				bsf	RCSTA,SPEN
				bcf	ADCON0,CHS2    	;elegimos canal 2 (AN2)
				bsf	ADCON0,CHS1
				bcf	ADCON0,CHS0 	;
				bsf	ADCON0,ADON 	;Activa módulo A/D
				bsf	ADCON0,GO 	;GO se prondrá a 0 cuando termine conversión
					
				bsf	INTCON,GIE	;Activa interrupciones
				bsf	INTCON,PEIE	;Habilita interrupciones de periféricos (USART)
				bsf	INTCON,RBIE	;Activa interrupciones del puerto B
				bcf	INTCON,RBIF
				bcf	INTCON,T0IF


main
				goto	main



interrupcion
				bsf	ADCON0,GO	 ;se pondrá a 0 cuando termine conversión
bucle
				btfsc	ADCON0,GO
				goto	bucle 		;Bucle de espera conversión A/D
				movf	ADRESH,0	;ADRESH contiene el resultado conversión A/D 
				movwf	DV	
				bcf	STATUS,C	;Tendremos que desplazar 5 veces (o dividir entre 32)
				rrf	DV,1	
				bcf	STATUS,C
				rrf	DV,1
				bcf	STATUS,C
				rrf	DV,1
				bcf	STATUS,C
				rrf	DV,1
				bcf	STATUS,C
				rrf	DV,0			
				
direccion						;Vemos qué valor de PORTB ha cambiado para saber cual de los 4 bits ha cambiado RB[7:4]
				movf	PORTB,0		
				xorwf	portbanterior,1   
				btfsc	portbanterior,7
				goto   	derecha
				btfsc	portbanterior,6
				goto  	adelante
				btfsc	portbanterior,5
				goto	atras
				goto	izquierda	
				
derecha
				btfss	PORTB,7		 ;pulsar boton = poner a 0
				goto	parar  		 ;si RB7 está a 1 esque se ha despulsado así que ha que parar el coche. 
				bcf	DV,6
				bcf	DV,5		;Se ha pulsado botón, el coche tiene que moverse
				goto	terminar
adelante
				btfss	PORTB,6
				goto	parar		;se ha despulsado
				bcf	DV,6		;se ha pulsado
				bsf	DV,5
				goto 	terminar				
atras
				btfss	PORTB,5
				goto	parar		;se ha despulsado
				bsf	DV,6		;se ha pulsado
				bcf	DV,5
				goto 	terminar
				

izquierda
				btfss	PORTB,4
				goto	parar		;se ha despulsado	
				bsf	DV,6		;se ha pulsado
				bsf	DV,5
				goto 	terminar
parar
				bcf	DV,6
				bcf	DV,5
				bcf	DV,4
				;goto terminar
terminar
				movlw	b'10000001
				movwf	TXREG
				NOP	
				NOP
				NOP
				movf	DV,0
				movwf	TXREG
				movf	PORTB,0
				movwf	portbanterior
				bcf	INTCON,RBIF
				retfie
				

				END
				