	;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)



		AREA    |.text|, CODE, READONLY
			
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108		; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)


GPIO_PORTF_BASE		EQU		0x40025000		; GPIO Port F (APB) base: 0x4002.5000 

GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4002.4000
	
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000

; configure the corresponding pin to be an output
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)
			
; LED
BROCHE_4			EQU		0x10		; led1
BROCHE_5			EQU		0x20		; led2 
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5 0b00110000
; BUMPER
BROCHE0				EQU 	0x1			; bumper_R
BROCHE1				EQU 	0x2			; bumper_L
BROCHE0_1           EQU     0x3     	; bumperR_L
; SWITCH
BROCHE_6			EQU		0x40		; switch1
BROCHE_7			EQU		0x80		; switch2 
BROCHE6_7			EQU		0xC0		; sw1 et sw2
; blinking frequency
DUREE   			EQU     0x80000

	    ;; registres utilisés 
		;;-----------------------
		;;   R0  R2  R3  R4  R5  R6
		;;-------------------------
		ENTRY
		EXPORT	__main		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
__main	

		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO E , F  et D où sont branchés les leds (0x28 == 0b111000)
		str r0, [r6]
		;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
		
		
		
				;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED

        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5 	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r6]		
				;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Bumper0_1
		ldr r6, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r6] 		
						;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Switch6_7
		ldr r6, = GPIO_PORTD_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE6_7		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7	
        str r0, [r6] 
		
		mov r2, #0x000       					;; pour eteindre LED
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration 
;		ldr r4, = GPIO_PORTF_BASE + (BROCHE_4<<2)  ;; pour allumer la led4
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED2	
;		ldr r5, = GPIO_PORTF_BASE + (BROCHE_5<<2)  ;; 		
;		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher		
;		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   		   

		
		; pour allumer les deux leds
		mov r3, #BROCHE4_5		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		
		;mov r4, #BROCHE_6		
		ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		
		; allumage des deux leds 
		str r3, [r6]
		
;loop	
		
ReadState
		 ldr r10,[r7]
		 CMP r10,#0x00 
		 BNE  ReadState
		 B   checkAppuisLong  
Debut  
		 BL     Clignotement
		 
		 ; eteindre les deux leds 
		 ;str r2, [r6]
moteur		
		 ; Activer les deux moteurs droit et gauche
		 BL	MOTEUR_DROIT_ON
		 BL	MOTEUR_GAUCHE_ON
		 ; Evalbot avance droit devant
		 BL	MOTEUR_DROIT_AVANT	   
		 BL	MOTEUR_GAUCHE_AVANT

		 ;BL	WAIT	; BL (Branchement vers le lien WAIT); possibilité de retour à la suite avec (BX LR)
		 ;BL	WAIT
		 ;Rotation à droite de l'Evalbot pendant une demi-période (1 seul WAIT)
		 ;BL	MOTEUR_DROIT_ARRIERE   ; MOTEUR_DROIT_INVERSE
		 ;BL	WAIT
		 ;BL	WAIT




		 ; eteindre les deux leds 
		 ;ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		 
		 ;str r2, [r6]
		 
		 
		; Avancement pendant une période (deux WAIT)
		;BL	WAIT	; BL (Branchement vers le lien WAIT); possibilité de retour à la suite avec (BX LR)
		;BL	WAIT
		; Rotation à droite de l'Evalbot pendant une demi-période (1 seul WAIT)
		;BL	MOTEUR_DROIT_ARRIERE   ; MOTEUR_DROIT_INVERSE
		;BL	WAIT
		;ldr r10,[r8]

        b moteur
		
checkAppuisLong  ldr r1, =0xFF000	  ; correspond à la duree de l'appuis long 
wait0	
		ldr r10,[r7]
		CMP r10,#0x00
		BNE ReadState     ; si l'utilisateur relâche pendant le wait  ei r10=0x01 , on recommence 
		subs r1, #1		
        bne wait0
		B   Debut

Clignotement 
		ldr r4, =0x8                           ; durée de clignotement
		
        str r3, [r6]  							;; Allume LED1&2 portF broche 4&5 : 00110000 (contenu de r3)
loop
        str r2, [r6]    						;; Eteint LED car r2 = 0x00      
        ldr r1, = DUREE 						;; pour la duree de la boucle d'attente1 (wait1)

wait1	subs r1, #1
        bne wait1

        str r3, [r6]  							;; Allume LED1&2 portF broche 4&5 : 00110000 (contenu de r3)
        ldr r1, = DUREE							;; pour la duree de la boucle d'attente2 (wait2)

wait2   subs r1, #1
        bne wait2
		
        subs r4, #1	                           ; contrôle le temp de clignotement 
		bne   loop
		
        str r2, [r6]    						;; Eteint LED car r2 = 0x00      
        BX  LR

		;; Boucle d'attante
WAIT	ldr r1, =0x052000 
wait3	subs r1, #1
        bne wait3
		BX	LR


		NOP
        END
