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

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^DECLARATION PINS ou BROCHES ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
		;;---------------------------------------------
		;;   R0  R1 R2  R3  R4  R5  R6  R7  R9 R10
		;;---------------------------------------------
	    ;; registres réservés 
		;;---------------------------------------------
		;;  R2  R5  R9 
		;;---------------------------------------------
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

		LDR R9, =buffer        ; Charger l'adresse de buffer dans R0
		mov r2, #0x000       	; pour eteindre LED
		mov R5, #0             ; compteur de d'indice dans la tableau 


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
		

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   		   

		

		
		
		
		
		; allumage des deux leds
		mov r3, #BROCHE4_5		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r3, [r6]
		
		
ReadState
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		 ldr r10,[r7]
		 CMP r10,#0x00 
		 BNE  ReadState		 
		 B   checkAppuisLong  
Debut  
		 BL     Clignotement
		 
		 ; eteindre les deux leds 
		 ;str r2, [r6]

debutLectureProgramme
ReadGauche
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)  ; affectation du switch 1 
		 ldr r10,[r7]                               ; lecture de l'état du switch 1
		 CMP r10,#0x00 								; vérifier si c'est appuyé
		 BNE  ReadDroit              ; on  branche vers le switch1( gauche) pour tester  si jamais le droit n'est pas appuyé 
		 B    checkAppuisLongGauche  ; on vérifie si l'appuis est long
appuisCourtGauche    
		 ; on allume la led gauche pour signaler le clic 
		 mov r3, #BROCHE_4		
		 ldr r6, = GPIO_PORTF_BASE + (BROCHE_4<<2)
		 BL clignoteAuClic ; gère l'allumage
         
		 ; on définit l'entier correspondant à la direction gauche 
		 mov r10,#1			 ; 1 pour  gauche 
		 B   ecrireDirection ; écrir dans buffer la direction 

ReadDroit
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_7<<2)
		 ldr r10,[r7]
		 CMP r10,#0x00 
		 BNE  ReadGauche
		 B   checkAppuisLongDroit  ; on vérifi si l'appuis est long ou court
appuisCourtDroit                   ; si on arrive à cette étiquette alors l'appuis est court
		 ; on allume la led droite pour signaler le clic 
		 mov r3, #BROCHE_5
		 ldr r6, = GPIO_PORTF_BASE + (BROCHE_5<<2)
         BL clignoteAuClic         ; gère l'allumage
		 
		 ; on définit l'entier correspondant à la direction gauche 
		 mov r10,#2				; 2 pour  droite 
		 B   ecrireDirection	; écrir dans tableau la direction 
		 
FinProgrammation             ; le programme est enregistré maintemant on peut parcourir le labyrinthe
         ; on on clignote pour signaler fin de la programmation 
		 mov r3, #BROCHE4_5		
		 ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		 BL Clignotement
		 
debut
		 ; Activer les deux moteurs droit et gauche
		 BL	MOTEUR_DROIT_ON
		 BL	MOTEUR_GAUCHE_ON
		 ; Evalbot avance droit devant
		 BL	MOTEUR_DROIT_AVANT	   
		 BL	MOTEUR_GAUCHE_AVANT






















        b debut
		
		
		
ecrireDirection
       STRB    R10, [R9, R5]  ; écrire dans le tableau à l'indice indiqué par R5
	   ADD     R5,#1          ; incrémentation du compteur 
	   B      ReadGauche      ; on retourne à la lecture des direction 

		
checkAppuisLong  ldr r1, =0xFF000	  ;  dureé R1 correspond à la duree de l'appuis long  envirion 2seconde
wait0	
		ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		ldr r10,[r7]
		CMP r10,#0x00
		BNE ReadState     ; si l'utilisateur relâche pendant le wait  c'est à dire  r10=0x01 , on recommence 
		subs r1, #1		
        bne wait0
		B   Debut
		
		
checkAppuisLongGauche
		ldr r1, =0xFF000	  ; R1 correspond à la duree de l'appuis long 
wait01	
		ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		ldr r10,[r7]
		CMP r10,#0x00
		BNE appuisCourtGauche     ; si l'utilisateur relâche pendant le wait  c'est-à-dire  r10=0x01 , c'est un appuis court sur gauche 
		subs r1, #1		          ; sinon on continue de lire dans que durée n'est pas acroulé
        bne wait01
		B   FinProgrammation      ; si on arrive ici alor l'appuis est long donc c'est la fin de la programmation 
		
checkAppuisLongDroit  
		ldr r1, =0xFF000	  	; correspond à la duree de l'appuis long 
wait02	
		ldr r7, = GPIO_PORTD_BASE + (BROCHE_7<<2)
		ldr r10,[r7]
		CMP r10,#0x00
		BNE appuisCourtDroit     ; si l'utilisateur relâche pendant le wait  c'est-à-dire r10=0x01 , c'est un appuis court sur droit
		subs r1, #1		
        bne wait02
		B   FinProgrammation


; logique du clignote simple  à chaque touche 
clignoteAuClic
		ldr r1, =0xFFFFF                           ; durée d'allumage
		str r3, [r6]    						   ; allumer la led correspondant dans R3
wait21  subs r1, #1
        bne wait21	
        str r2, [r6]    						;; Eteint LED car r2 = 0x00      
        BX  LR                                  ;; retour à l'endroit ou clignoteAuClic est appeler 

; logique de clignotement multiple   avant et apprès le programmation 
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

;; Boucle d'attente   simple  sans rien faire 
WAIT	ldr r1, =0x052000 
wait3	subs r1, #1
        bne wait3
		BX	LR

		NOP
		
    AREA |variable|, DATA, READWRITE   
buffer     space     50                 ;   tableau de 50 octets pour contenir les instructions 
        END
