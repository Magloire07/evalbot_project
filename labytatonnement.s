parcours_labyrinthe2

avancer
    BL MOTEUR_DROIT_ON
    BL MOTEUR_GAUCHE_ON
    ; Le robot avance tout droit
    BL MOTEUR_DROIT_AVANT
    BL MOTEUR_GAUCHE_AVANT

    ; Vérifier les collisions
    B testCollisionfrontale

    ; Boucle continue d’avancée
    B avancer

;----------------------------------TEST DE COLLISION --------------------------------------------------------------------------------------

testCollisionfrontale
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2) 
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)

        ldr r10,[r8]        ; lecture de l'état du bp_0
		ldr r4,[r7] 		 ; lecture de l'état du bp_1
		CMP r10,#0x00
		BNE  testBp1
		BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL   Clignotement               ; on clignote à chaque collision 
		B    tourneADroite    


testBp1 
		CMP r4,#0x00
		BNE parcours
		BL  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL  Clignotement			    ; on clignote à chaque collision
		B   tourneADroite

;----------------------------------TOURNE A DROITE OU GAUCHE  --------------------------------------------------------------------------------------
tourneADroite
		 ;on suppose que c'est vers la droite 
		 mov   r10,#2			 ; 2 pour  droite 
         STRB    R10, [R9, R5]  ; écrire dans le tableau à l'indice indiqué par R5
		 
		 BL	MOTEUR_DROIT_ON
		 BL	MOTEUR_DROIT_ARRIERE
		 BL WAIT                   ; le WAIT et la vitesse sont réglés pour produire un angle de 90° 
		 BL  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		 
		 BL MOTEUR_DROIT_ON
		 BL MOTEUR_GAUCHE_ON
		 BL MOTEUR_DROIT_AVANT
		 BL MOTEUR_GAUCHE_AVANT
		 
		 B testCollisiondemie

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
		 
;----------------------------------TEST DE COLLISION  -DURANT PARCOURS2 -------------------------------------------------------------------------------------

testCollisiondemie
		ldr r1, =0xFF0000	      ; R1 correspond à la moitié de la duree de parcours entre deux obstacle frontale 
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0<<2) 
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2)
pourcours2
		
		CMP r1,#0x00
		BEQ continue
		
		
        ldr r10,[r8]        ; lecture de l'état du bp_0
		ldr r4,[r7] 		 ; lecture de l'état du bp_1
		CMP r10,#0x00
		BNE  testBp12
		;si  on arrive ici alors il y a eu collision plus tôt donc c'est un obstacle à droite
		
		BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL   Clignotement               ; on clignote à chaque collision 
		
		;on écrit la  direction gauche 
		mov   r10,#1			 ; 1 pour  gauche 
        STRB    R10, [R9, R5]  ; écrire dans le tableau à l'indice indiqué par R5
	    ADD     R5,#1          ; incrémentation du compteur 		B    tourneADroite  
		B   tourneAGauche	
		B   tourneAGauche
		B   avancer 		



testBp12 
		CMP r4,#0x00
		BNE parcours2
		;si  on arrive ici alors il y a eu collision plus tôt donc c'est un obstacle
		;si  on arrive ici alors il y a eu collision plus tôt donc c'est un obstacle à droite
		
		BL   MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		BL   MOTEUR_DROIT_OFF			; déactiver le moteur droit
		BL   Clignotement               ; on clignote à chaque collision 
		
		;on écrit la  direction gauche 
		mov   r10,#1			 ; 1 pour  gauche 
        STRB    R10, [R9, R5]  ; écrire dans le tableau à l'indice indiqué par R5
	    ADD     R5,#1          ; incrémentation du compteur 		B    tourneADroite  
		B   tourneAGauche	
		B   tourneAGauche
		B   avancer  