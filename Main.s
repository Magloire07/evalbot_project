;------------------------------------------------------------
;#Authors
;@Kokou KOMBEDE
;@Ounissa SADAOUI
;Parcours E3FI-3I
;année 2024-2025
;-------------------------------------------------------------
; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage  Evalbot pour parcouris un labyrinthe
;--------------------------------------------------------------

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

DUREE   			EQU     0x80000  ; durée fréquence clignotement multiple  
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	    ;; registres utilisés 
		;;---------------------------------------------
		;;   R0  R1 R2  R3  R4  R5  R6  R7 R8  R9 R10 R11 , R12
		;;---------------------------------------------
	    ;; registres réservés 
		;;---------------------------------------------
		;;  R2  R5  R9 R11, R12
		;;---------------------------------------------
		;; usages courants des régistres
		;;---------------------------------------
		;; r3,r2,r6 pour lire les pins de leds et allumer puis éteindre
		;; r7,r8,r10 pour lire les pins des switchs et bumpers 
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		ENTRY
		EXPORT	__main		
		EXPORT  DEMARRAGE
		EXPORT  Clignotement
		EXPORT  GPIO_PORTD_BASE
		EXPORT  GPIO_PORTE_BASE
		EXPORT  BROCHE0
		EXPORT  BROCHE1
		EXPORT  WAIT
		EXPORT  clignoteAuClic

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
			
		IMPORT  PARCOURS_LABYRINTHE2
			
		IMPORT MOTEUR_DROIT_MIN
        IMPORT MOTEUR_GAUCHE_MIN
	    IMPORT WAIT_MIN
	    IMPORT MOTEUR_DROIT_MAX
	    IMPORT MOTEUR_GAUCHE_MAX
			
		
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
__main	

		LDR R9, =buffer        ; Charger l'adresse de buffer dans R0
		mov r2, #0x000       	; pour eteindre LED
		mov R5, #0             ; compteur de d'indice dans la tableau lors de l'écriture elle vaudra aussi pour taille du tableau 
		;mov R11,#0             ; compteur de d'indice dans la tableau lors de la lecture
		mov R12,#0             ; compteur du nombre de parcours de labyrinthe, si elle vaut deux alors c'est la toute fin , on dessine infini


		ldr r6, =SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO E , F  et D où sont branchés les leds (0x28 == 0b111000)
		str r0, [r6]
		;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
		
		
;--------------------------------------------------CONFIGURATION LED 4_5----------------------------------------------------------------------		 		

        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5 	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r6]		
;-------------------------------------------------------CONFIGURATION Bumper0_1-----------------------------------------------------------------
		ldr r6, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTE_BASE+GPIO_O_DEN ; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r6] 		
;-------------------------------------------------------CONFIGURATION Switch6_7-----------------------------------------------------------------
		ldr r6, = GPIO_PORTD_BASE+GPIO_I_PUR ; Pul_up 
        ldr r0, = BROCHE6_7		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7	
        str r0, [r6] 
		
;------------------------------------------------------------------------------------------------------------------------		 
		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   		   
;------------------------------------------------------------------------------------------------------------------------		 
		; allumage des deux leds
		mov r3, #BROCHE4_5		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r3, [r6]
		
;---------------------------------------------LECTURE DU PREMIER APPUIS LONG ----------------------------------------------------------------------		 		
ReadState
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		 ldr r10,[r7]
		 CMP r10,#0x00 
		 BNE  ReadState		 
		 B   checkAppuisLong
;----------------------------------------------DEBUIT PROGRAMMATION DES DIRECTIONS --------------------------------------------------------------------------		 
DebutProgrammation
		BL     Clignotement
ReadGauche
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)  ; affectation du switch 1 
		 ldr r10,[r7]                               ; lecture de l'état du switch 1
		 CMP r10,#0x00 								; vérifier si c'est appuyé
		 BNE  ReadDroit              ; on  branche vers le switch1( gauche) pour tester  si jamais le droit n'est pas appuyé 
		 B    checkAppuisLongGauche  ; on vérifie si l'appuis est long
;------------------------------------------------------------------------------------------------------------------------
appuisCourtGauche    
		 ; on allume la led gauche pour signaler le clic 
		 mov r3, #BROCHE_5		
		 ldr r6, = GPIO_PORTF_BASE + (BROCHE_5<<2)
		 BL clignoteAuClic ; gère l'allumage
         
		 ; on définit l'entier correspondant à la direction gauche 
		 mov r10,#1			 ; 1 pour  gauche 
		 B   ecrireDirection ; écrir dans buffer la direction 
;------------------------------------------------------------------------------------------------------------------------
ReadDroit
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_7<<2)
		 ldr r10,[r7]
		 CMP r10,#0x00 
		 BNE  ReadGauche
		 B   checkAppuisLongDroit  ; on vérifi si l'appuis est long ou court
;------------------------------------------------------------------------------------------------------------------------
appuisCourtDroit                   ; si on arrive à cette étiquette alors l'appuis est court
		 ; on allume la led droite pour signaler le clic 
		 mov r3, #BROCHE_4
		 ldr r6, = GPIO_PORTF_BASE + (BROCHE_4<<2)
         BL clignoteAuClic         ; gère l'allumage
		 
		 ; on définit l'entier correspondant à la direction gauche 
		 mov r10,#2				; 2 pour  droite 
		 B   ecrireDirection	; écrir dans tableau la direction 
		 
;------------------------------------------------FIN PROGRAMMATION DES DIRECTIONS----------------------------------------------------------------
; le programme est enregistré maintemant
; on peut parcourir le labyrinthe
FinProgrammation   
         ; on on clignote pour signaler fin de la programmation 
		 mov r3, #BROCHE4_5		
		 ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		 BL Clignotement
		 
;------------------------------------------------CLIC SUR SWITCH1 POUR COMMENCER----------------------------------------------------------------
DEMARRAGE
		 mov R11,#0             ; compteur de d'indice dans la tableau lors de la lecture
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		 ldr r10,[r7]
		 CMP r10,#0x00 
		 BNE DEMARRAGE
		 BL  clignoteAuClic
		 BL  WAIT
;---------------------------------------------------PARCOURS DU LABYRINTHE 1-------------------------------------------------------------	 
         ADD  R12,#1                                ; On incrément  le compteur de parcours 




parcours
		 ; Activer les deux moteurs droit et gauche
		 BL	MOTEUR_DROIT_ON
		 BL	MOTEUR_GAUCHE_ON
		 ; Evalbot avance droit devant
		 BL	MOTEUR_DROIT_AVANT	   
		 BL	MOTEUR_GAUCHE_AVANT

         B testCollision 

         b parcours
		 
		 
		 
		 
;-----------------------------------------------FIN PARCOURS DU LABYRINTHE-------------------------------------------------------------------------		

ecrireDirection
       STRB    R10, [R9, R5]  ; écrire dans le tableau à l'indice indiqué par R5
	   ADD     R5,#1          ; incrémentation du compteur 
	   B      ReadGauche      ; on retourne à la lecture des direction 
	   
;-----------------------------------------------DEBUT LOGIQUE APUIS LONG -------------------------------------------------------------------------	
;dureé R1 correspond à la duree 
;de l'appuis long  envirion 2seconde
checkAppuisLong  ldr r1, =0xFF000	  
wait0	
		ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		ldr r10,[r7]
		CMP r10,#0x00
		BNE ReadState     ; si l'utilisateur relâche pendant le wait  c'est à dire  r10=0x01 , on recommence 
		subs r1, #1		
        bne wait0
		B   DebutProgrammation 
		
;------------------------------------------------------------------------------------------------------------------------
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
;------------------------------------------------------------------------------------------------------------------------
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
;------------------------------------------------DEBUT LOGIQUES DE CLIGNOTEMENTS ------------------------------------------------------------------------
; logique du clignote simple  à chaque touche 
clignoteAuClic
		ldr r1, =0xFFFFF                           ; durée d'allumage
		str r3, [r6]    						   ; allumer la led correspondant dans R3
wait21  subs r1, #1
        bne wait21	
        str r2, [r6]    						;; Eteint LED car r2 = 0x00      
        BX  LR                                  ;; retour à l'endroit ou clignoteAuClic est appeler 
;------------------------------------------------------------------------------------------------------------------------
; logique de clignotement multiple   avant et apprès le programmation 
Clignotement 
		ldr r4, =0x8                           ; durée de clignotement
		mov r3, #BROCHE4_5		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
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
;------------------------------------------------------------------------------------------------------------------------
;; Boucle d'attente   simple  sans rien faire 
WAIT	ldr r1, =0xA00000 
wait3	subs r1, #1
        bne wait3
		BX	LR
;----------------------------------TEST DE COLLISION --------------------------------------------------------------------------------------

testCollision
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2) 
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)

        ldr r10,[r8]        ; lecture de l'état du bp_0
		ldr r4,[r7] 		 ; lecture de l'état du bp_1
		CMP r10,#0x00
		BNE  testBp1
		BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL   Clignotement               ; on clignote à chaque collision 
		B    lectureMemoire


testBp1 
		CMP r4,#0x00
		BNE parcours
		BL  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL  Clignotement			    ; on clignote à chaque collision

		B    lectureMemoire
;----------------------------------LECTURE  MEMOIRE --------------------------------------------------------------------------------------
lectureMemoire
		LDRB    R4, [R9, R11]    ; Charger l'octet suivant dans R4 (buffer[R11])
		CMP     R4, #1          
		BEQ     tourneAGauche    ; sinon tourne à gauche  R4 vaut 1 dans ce cas
		CMP     R4, #2          
		BEQ     tourneADroite    ; si 2 tourne à droite R4 vaut 2 dans ce cas 

		
;----------------------------------TOURNE A DROITE OU GAUCHE  --------------------------------------------------------------------------------------
tourneADroite
		 BL	MOTEUR_DROIT_ON
		 BL	MOTEUR_DROIT_ARRIERE
		 BL WAIT                   ; le WAIT et la vitesse sont réglés pour produire un angle de 90° 
		 BL  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		 ADD R11,#1						; incrémentation pour la prochaine direction 
		 CMP R11,R5				   ; on vérifie si tout le programme a été lu 
		 BEQ fin                   ; c'est la fin si oui 
		 B   parcours              ; on continue le parcours si non 
tourneAGauche
		 BL	MOTEUR_GAUCHE_ON
		 BL	MOTEUR_GAUCHE_ARRIERE
		 BL WAIT                   ; le WAIT et la vitesse sont réglés pour produire un angle de 90° 
		 BL  MOTEUR_GAUCHE_OFF			; déactiver le moteur droit
		 ADD R11,#1						; incrémentation pour la prochaine direction 
		 CMP R11,R5				   ; on vérifie si tout le programme a été lu 
		 BEQ fin                   ; c'est la fin si oui 
		 B   parcours              ; on continue le parcours si non 

fin   
		 BL	MOTEUR_DROIT_ON
		 BL	MOTEUR_GAUCHE_ON
 		 BL	MOTEUR_DROIT_AVANT
		 BL	MOTEUR_GAUCHE_AVANT
		 BL WAIT 
		 BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		 BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
		 BL Clignotement
		 BL Clignotement
		 
;------------------------------------------------------PARCOURS DU DEUXIEME LABYRINTHE  PAR TATONNEMENT ------------------------------------------------------------------
		
		CMP R12,#2                
		BEQ INFINI
	    B PARCOURS_LABYRINTHE2         ; on va dans le fichier labytatonnement.s 
		
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------

INFINI

	BL MOTEUR_DROIT_ON
	BL MOTEUR_GAUCHE_ON
    ; Faire un arc de cercle vers la gauche (virage à gauche)
    ; Moteur droit à pleine vitesse, moteur gauche réduit
    BL MOTEUR_DROIT_AVANT
    BL MOTEUR_GAUCHE_MIN
    BL WAIT
    BL WAIT
    BL WAIT
    BL WAIT

    ; Effectuer un virage vers la droite pour revenir à la ligne droite
    ; Moteur gauche à pleine vitesse, moteur droit réduit

	
	BL MOTEUR_DROIT_MAX
	BL MOTEUR_GAUCHE_MAX
    BL WAIT


    ; Répéter l'arc de cercle vers la gauche (virage à gauche)
    BL MOTEUR_GAUCHE_AVANT
    BL MOTEUR_DROIT_MIN
    BL WAIT
	BL WAIT
    BL WAIT

    ; Répéter le virage vers la droite


	BL MOTEUR_DROIT_MAX
	BL MOTEUR_GAUCHE_MAX
    BL MOTEUR_DROIT_AVANT
    BL MOTEUR_GAUCHE_AVANT

    BL WAIT
                                                                                               
	BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
	BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
	
	BL Clignotement
	BL Clignotement
	BL Clignotement

    ; Fin de INFINI

END
;--------------------------------------------------------------------------------------------------------------------------------------------------------------


;--------------------------------------------------DECLARATION TABLEAU CONTENANT LE PROGRAMME ------------------------------------------------------------------------------

		NOP
		
    AREA |variable|, DATA, READWRITE   
buffer     space     50                 ;   tableau de 50 octets pour contenir les instructions 
        END
