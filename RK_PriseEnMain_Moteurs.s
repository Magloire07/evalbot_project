	;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)



		AREA    |.text|, CODE, READONLY
			
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4002.4000

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)
			
; Broches select
BROCHE_4			EQU		0x10		; led1
BROCHE_5			EQU		0x20		; led2 
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5 0b00110000

BROCHE0				EQU 	0x1		; bumper_R
BROCHE1				EQU 	0x2		; bumper_L
BROCHE0_1           EQU     0x3     ; bumperR_L
	
		ENTRY
		EXPORT	__main
				; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000030  					;; Enable clock sur GPIO E et F où sont branchés les leds (0x28 == 0b110000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
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
		
		 mov r2, #0x000       					;; pour eteindre LED
     
		; allumer la led broche 4 (BROCHE4_5)
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; pour allumer les deux leds 
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED1   
     
		ldr r4, = GPIO_PORTF_BASE + (BROCHE_4<<2)  ;; pour allumer la led4
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 

		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED2
		
		ldr r5, = GPIO_PORTF_BASE + (BROCHE_5<<2)  ;; 
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED
		
		
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Bumper0_1
		ldr r7, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r7]
		
		ldr r7, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r7]     
				
		
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher

		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration 
		
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
				; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000030  					;; Enable clock sur GPIO E et F où sont branchés les leds (0x28 == 0b110000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
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
		
		 mov r2, #0x000       					;; pour eteindre LED
     
		; allumer la led broche 4 (BROCHE4_5)
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; pour allumer les deux leds 
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED1   
     
		ldr r4, = GPIO_PORTF_BASE + (BROCHE_4<<2)  ;; pour allumer la led4
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 

		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED2
		
		ldr r5, = GPIO_PORTF_BASE + (BROCHE_5<<2)  ;; 
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED
		
		
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Bumper0_1
		ldr r7, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r7]
		
		ldr r7, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r7]     
				
		
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher

		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration 

		;; BL Branchement vers un lien (sous programme)

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   		   
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON

		; Boucle de pilotage des 2 Moteurs (Evalbot tourne sur lui même)
loop	
		; Evalbot avance droit devant
		BL	MOTEUR_DROIT_AVANT	   
		;BL	MOTEUR_GAUCHE_AVANT
		
		; Avancement pendant une période (deux WAIT)
		;BL	WAIT	; BL (Branchement vers le lien WAIT); possibilité de retour à la suite avec (BX LR)
		;BL	WAIT
		
		; Rotation à droite de l'Evalbot pendant une demi-période (1 seul WAIT)
		;BL	MOTEUR_DROIT_ARRIERE   ; MOTEUR_DROIT_INVERSE
		
		;BL	WAIT
		;ldr r10,[r8]

        b loop
		;; Boucle d'attante
WAIT	ldr r1, =0xAFFFFF 
wait1	subs r1, #1
		BL	MOTEUR_GAUCHE_ARRIERE
        bne wait1
		BX	LR


		NOP
        END
