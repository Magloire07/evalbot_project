 	    ;; registres utilisés 
		;;---------------------------------------------
		;;   R0  R1  R4  R5   R7  R8  R9  R10  R11
		;;---------------------------------------------
	    ;; registres réservés 
		;;---------------------------------------------
		;;  R1  R5  R9  R11
		;;---------------------------------------------
		
		;; le tableau est toujours à la même adresse dans R9 on réécrira sur les ancienne valeur entrée manuellement 
		;; le labyrinthe doit avoir 6 virages (correspond à R0)
		
		AREA    |.text|, CODE, READONLY
			
;on  redeclare au lieu d'importer  si non (error: A1141E: Relocated expressions may only be added or subtracted)
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4002.4000
BROCHE_6			EQU		0x40		; switch1
BROCHE0				EQU 	0x1			; bumper_R
BROCHE1				EQU 	0x2			; bumper_L
		ENTRY
		
	    EXPORT PARCOURS_LABYRINTHE2


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


	    IMPORT DEMARRAGE
	    IMPORT WAIT
		IMPORT Clignotement
		IMPORT clignoteAuClic

			
		  

;---------------------------------------------------PARCOURS DU LABYRINTHE 2-------------------------------------------------------------	 
PARCOURS_LABYRINTHE2
		 mov R5,#0  ; compteur d'indice du tableau

;------------------------------------------------CLIC SUR SWITCH1 POUR COMMENCER----------------------------------------------------------------
readstate2
		 ldr r7, = GPIO_PORTD_BASE + (BROCHE_6<<2)
		 ldr r10,[r7]
		 CMP r10,#0x00 
		 BNE readstate2
		 BL  clignoteAuClic
		 BL  WAIT
avancer
    BL MOTEUR_DROIT_ON
    BL MOTEUR_GAUCHE_ON
    ; Le robot avance tout droit
    BL MOTEUR_DROIT_AVANT
    BL MOTEUR_GAUCHE_AVANT

;----------------------------------TEST DE COLLISION FRONTALE --------------------------------------------------------------------------------------

testCollisionfrontale
		
		CMP R5,#6 				; temoin de fin de parcours, (on comparera R5 et 7pour savoir si le labyrinthe est terminé )
		BEQ  fintatonnement     ;; si la condition est vrai on arrête les moteurs, passe dans le fichier Main.s pour parcourir le labyrinthe cette fois avec le code obtenu par tatonnement  
		
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2) 
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)

        ldr r10,[r8]        ; lecture de l'état du bp_0
		ldr r4,[r7] 		 ; lecture de l'état du bp_1
		
		CMP r10,#0x00      ; bumper0
		BNE  testBp_1      ; bumper1
obstaclefrontale
		BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL   Clignotement               ; on clignote à chaque collision 
		B    tourneADroite    

testBp_1 
		CMP r4,#0x00
		BNE testCollisionfrontale 
		B obstaclefrontale
;----------------------------------TOURNE A DROITE --------------------------------------------------------------------------------------
tourneADroite
		 ;on suppose que c'est vers la droite 
		 mov    r11,#2			; 2 pour  droite (c'est par defaut, au cas ou il y a abstacle plus tôt , on change en 1 c'est pourquoi le compteur d'indice n'est incrémenté qu'à la fin
         STRB    R11, [R9, R5]  ; écrire dans le tableau à l'indice indiqué par R5
		 
		 BL	MOTEUR_DROIT_ON
		 BL	MOTEUR_DROIT_ARRIERE
		 BL WAIT                   ; le WAIT et la vitesse sont réglés pour produire un angle de 90° 
		 BL  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		 
		 BL MOTEUR_DROIT_ON
		 BL MOTEUR_GAUCHE_ON
		 BL MOTEUR_DROIT_AVANT
		 BL MOTEUR_GAUCHE_AVANT
		 
		 B testCollisiondemie
		 
;----------------------------------TEST DE COLLISION  DURANT PARCOURS2 -------------------------------------------------------------------------------------

testCollisiondemie
		ldr r1, =0xFFFFF	      ; R1 correspond à 1/3 de la duree de parcours entre deux obstacle frontale, à ajuster
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2) 
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)
parcours2
		sub r1,#1
		CMP r1,#0x00        ; si la condition est vraie alors c'est un parcours normale avec obstacle frontale donc on incremenle compteur d'indice puis on clignote, continue la deuxiemme moitié du parcours 
		BEQ incrementer
		
        ldr r10,[r8]        ; lecture de l'état du bp_0
		ldr r4,[r7] 		; lecture de l'état du bp_1
		CMP r10,#0x00
		BNE  testBp12
		
obstacleAdroite		
		;si  on arrive ici alors il y a eu collision plus tôt donc c'est un obstacle à droite	
		BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL   Clignotement               ; on clignote à chaque collision 
		
		;on écrit la  direction gauche 
		MOV    r11,#1			 ; 1 pour  gauche 
        STRB   R11, [R9, R5]  ; écrire dans le tableau à l'indice indiqué par R5
	    ADD    R5,#1          ; incrémentation du compteur 		B    tourneADroite  
		 
		; on tourne alors de 180° qui correspond à tourner à tourner  dans le sens inverse 
		BL	MOTEUR_GAUCHE_ON
		BL	MOTEUR_GAUCHE_ARRIERE
		BL  WAIT                   ; le WAIT et la vitesse sont réglés pour produire un angle de 90° 
		BL  WAIT                   ; le WAIT et la vitesse sont réglés pour produire un angle de 90° 
		BL  MOTEUR_GAUCHE_OFF			; déactiver le moteur droit
		
		; on et avance normalement 
		B   avancer 		

testBp12                        
		CMP r4,#0x00        ; bumper_1
		BNE parcours2
		B obstacleAdroite
incrementer
		 ADD     R5,#1  
		 BL   Clignotement               ; on clignote pour signaler que c'est un parcours long  
		 B testCollisionfrontale         ; continue le deuxieme moitié du parcours 
fintatonnement
		 BL  WAIT
		 BL  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		 BL  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		 BL  Clignotement               ; on clignote à chaque collision
		 BL  Clignotement               ; on clignote à chaque collision

		 B DEMARRAGE                    ; on retourne dans main pour utilisé la logique le parcours en lisant dans buffer car c'est le même buffer dans R9 qui est utilisé     
		 END