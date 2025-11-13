jmp main


posPlayer: var#1
prevposPlayer: var#1
originalposPlayer: var#1

playerMoveDirection: var#1
MoveBlocked : var#1

playerOrientation: var#1

cstagetopology: var#1
curentStage:  var#1
curentTopology: var#1


currentUILayer: var#1
currentPropLayer: var#1
currentBackgroundLayer: var#1


currentScreenIndexesChanged : string "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                "

currentScreenIndexesChangedIndex: var#0
; This actes like a stack, but not realy

; Doenst actualy need the /0, the printing function can just see if it it reached:
; currentScreenIndexesChangedIndex

; ToDo: Remove unused functionality 
; Dificulty: Easy


uiLayerColor: var#1
propLayerColor: var#1
backgroundLayerColor: var#1
currentPrintingColor: var#1


Level1Props : string "                                                                                                                                                                                                                                                                                                                                                                                       @@@@@@@                                 @     @                                 @     @                                 @     @                                 @     @                                 @     @                                 @@@@@@@                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  "
Level1Background : string "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                "


main:

	;SetUp
		loadn r0, #498
		store posPlayer, r0

		; positions player in level
			loadn r1, #Level1Props  ; must be changed to curent layer later
			add r2, r1, r0
			loadn r0, "A"

			storei r2, r0

		; Initialize the changed index pointer to start of buffer
   		 loadn r0, #currentScreenIndexesChanged
   		 store currentScreenIndexesChangedIndex, r0

		; sets current Layers
	
			;loadn r1, #Level1Props
			store currentPropLayer, r1

			loadn r1, #Level1Background
			store currentBackgroundLayer, r1

	;Variables for first print
	loadn r0, #0
	loadn r1, currentPropLayer
	loadn r2, #0
	
	; first print. All subsequent prints must be made in render loop
	call ImprimeStr


	mainLoop:
	
		;Movement
			call movePlayer  ; must make movePlayer call checkPushMove
						     ; To alow current code to work

			;call checkPushMovement

		;RenderLoop:
			call render


	jmp mainLoop


movePlayer:
	
	push r0
	push r1
	push r2
	push r3


	load r0, posPlayer
	store originalposPlayer, r0
	mov r1, r0
	store prevposPlayer, r1
	inchar r3

	; r0 posPlayer
	; r1 prevposPlayer
	; r2 localHelper
	; r3 inchar

	;if a
		loadn r2, 'a' 
		cmp r3, r2
		jeq Playermvleft
	
	;if d
		loadn r2, 'd' 
		cmp r3, r2
		jeq Playermvright

	;if w
		loadn r2, 'w' 
		cmp r3, r2
		jeq Playermvup

	;if s
		loadn r2, 's' 
		cmp r3, r2
		jeq Playermvdown

	;else
		jmp endMovePlayer

	Playermvleft:
		
		call mvleft

		loadn r2, #3
		store playerMoveDirection, r2
		
		jmp callMovementTopologyPlayer

	Playermvright:

		call mvright

		loadn r2, #1
		store playerMoveDirection, r2

		jmp callMovementTopologyPlayer

	Playermvup:

		call mvup

		loadn r2, #2
		store playerMoveDirection, r2

		jmp callMovementTopologyPlayer
	
	Playermvdown:
		
		call mvdown

		loadn r2, #4
		store playerMoveDirection, r2

		jmp callMovementTopologyPlayer


	callMovementTopologyPlayer:		
		call mvTopology

	; CheckPush or block
		;takes r0 = new pos
		load r1, prevposPlayer; takes r1 = prev pos
		call checkPushMovement	


	endMovePlayer:
	store posPlayer, r0 
	
	;takes r0 = new pos
	load r1, prevposPlayer; takes r1 = prev pos

	call MoveInMemory ; 
	
	call setIndexChanged

	pop r3
	pop r2
	pop r1
	pop r0

	RTS

MoveInMemory:

	;Takes r0 and r1 as inputs for positions; 
	;you should be getting used to this by now
	
	;Also can take another register or variable like curent memory or smth. 
	;not needed now

	push r2  ;PropLayer pointed by curentPropLayer
	push r3
	push r4
	push r5

	load r2, currentPropLayer

	add r3, r1, r2 ; Index In layer of r1
	
	; r4
	loadi r4, r3 ; character in r1 of Layer
	
	loadn r5, # " "
	storei r3, r5     ; overide r1 with " "
	
	add r3, r0, r2 
	storei r3, r4 ; stores r4 into r0 of layer

	; r0 now contains what was in r1, while r1 is now " ".

	; Make sure to aways apply this from the last moved object otherwise 
	; you will thanos snap your level

	pop r5
	pop r4
	pop r3
	pop r2

	rts
	

checkPushMovement:
	
	push r0 ;stores callers pos
	push r1 ;stores callers prevpos
	push r2
	push r3
	push r5
	push r4
	push r6


	;r0, new position
	;r1, previous position


	; if new position has box, push box
	
	load r6, currentPropLayer
	add r2, r6, r0 ; memory addres of r0 position in propLayer

	loadi r4, r2
	loadn r3, "@"
	cmp r4, r3

	jne endboxmv

		sub r2, r0, r1 ; playerMoveDirection ; can be infered from r0 and r1
		; r2 will become a movent direction
	
		;if r2 = 3
			loadn r3, #65535
			cmp r3, r2
			jeq boxmvleft
	
		;if r2 = 1
			loadn r3, #1 
			cmp r3, r2
			jeq boxmvright

		;if r2 = 2
			loadn r3, #65496
			cmp r3, r2
			jeq boxmvup

		;if r2 = 4
			loadn r3, #40
			cmp r3, r2
			jeq boxmvdown
		

		; loadn r7, #2
		; code will reach here if the boxes cross the topology bounderies

		; torus specific fix; will need to be moved to a function with a pointer in 
		; current topology manager or solver
			mov r7, r2
			
			loadn r3, #65497
			cmp r3, r2
			jeq boxmvright

			loadn r3, #64376
			cmp r3, r2
			jeq boxmvdown

			loadn r3, #39
			cmp r3, r2
			jeq boxmvleft

			loadn r3, #1160
			cmp r3, r2
			jeq boxmvup


		jmp endboxmv		

		boxmvright:
			mov r5, r0
			call mvright ; puts new position in r0
			jmp boxmvtopology	

		boxmvup:
			mov r5, r0
			call mvup ; puts new position in r0
			jmp boxmvtopology

		boxmvleft:
			mov r5, r0
			call mvleft ; puts new position in r0
			jmp boxmvtopology

		boxmvdown:
			mov r5, r0
			call mvdown ; puts new position in r0
			jmp boxmvtopology


		boxmvtopology:
			mov r1, r5
			call mvTopology ; puts new position in r0

		;r0, is the new position of the box, we must check if it is valid
		;r1 is the previous position of the box
		
		call checkPushMovement
		
		
		;if valid
		; MoveInMemory
		call MoveInMemory
	
		call setIndexChanged

	endboxmv:
	

	
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts

mvright:
	
	; takes and operates on r0

	push r2
	loadn r2, #1
	add r0, r0, r2

	store playerMoveDirection, r2
	
	pop r2

	rts

mvleft:
	
	; takes and operates on r0

	push r2
	loadn r2, #1
	sub r0, r0, r2

	store playerMoveDirection, r2
	
	pop r2

	rts

mvup:
	; takes and operates on r0

	push r2

	loadn r2, #40
	sub r0, r0, r2

	loadn r2, #2
	store playerMoveDirection, r2
	
	pop r2

	rts

mvdown:
	; takes and operates on r0

	push r2

	loadn r2, #40
	add r0, r0, r2

	loadn r2, #2
	store playerMoveDirection, r2
	
	pop r2
		
	rts

mvTopology:
		
		; This function with on r0 and r1 as inputs
		; and returns the value on r0.

		; it takes a movement, and makes it within the topological constraint

		;todo: Make it take a variable to chose which topology to solve for	

		;refactor code to make it elagent and good, this is trash	
		
		; r0 = curent position
		push r1 ; previous position
		push r2
		push r3
		push r4
		push r5
		push r6
		push r7
		

			
		; r0 = pos
		; r1, prevpos
		loadn r2, #40 ;local helper / Screen Size
		; r3, local helper 2
		; r4, local helper 3
		; r5, local helper 4
		; r6, local helper 5
	
		;torus
			
			; tries for horizontal wrap
			mod r4, r1, r2 ; The colum of the previous position
			mod r3, r0, r2 ; The colum of the new position
				
			add r5, r3, r4 ; if 39, we have a horizontal wrap around candidate	

			dec r2		; r2 40 -> 39
			cmp r5, r2	;checks if sum is 39,	
			inc r2  	  ;39 to 40	   	
			jne verticalTorusWrap  ; if it is not 39, skips to vertical check

			horizontaltoruswrap:
			loadn r5, #0
			;if r3 = 0     colum 39 -> 0
				cmp r3, r5
				jne horizontaltoruswrap2

				; move up  
				loadn r6, #9
				sub r0, r0, r2  ; subs 40 from new position   					

				jmp endmvTopoplogy

			horizontaltoruswrap2:
				
			;if r3 = 39     colum 0 -> 39
				loadn r5, #39	
				cmp r3, r5; 
				jne verticalTorusWrap
					
				loadn r6, #5   ; debug
				add r0, r0, r2		; correct line + 40 move down

				jmp endmvTopoplogy

			verticalTorusWrap:

			div r3, r0, r2 ; The row of the new position r2 = 40
				
			; if r3 = 30
			loadn r2, #30  ; number of rows
			cmp r3, r2
			jne verticalTorusWrap2
				
				loadn r4, #1200
				sub r0, r0, r4

				jmp endmvTopoplogy
		
			;else
			
			verticalTorusWrap2:

			; if r3 = 1637
			loadn r2, #1630
			
			mov r6, r2		
			mov r7, r3

			cmp r2, r3
			jeg endmvTopoplogy
				
				
				loadn r4, #1200
				add r0, r0, r4

				jmp endmvTopoplogy
			; vertical logic, todo:
			
		

		endmvTopoplogy:

		; r0, new positon0,

		; r1, previous position still

		;call setIndexChanged

		; marks what must be re-rendered
	
		pop r7
		pop r6
		pop r5
		pop r4
		pop r3
		pop r2
		pop r1
		

		rts


render:
    push r0
    push r1
    push r2
    
    loadn r0, #currentScreenIndexesChanged  ; Start pointer
    load r2, currentScreenIndexesChangedIndex  ; End pointer

	ScreenRenderIndex_Loop:
    	cmp r0, r2  ; Checks if printing the end
    	jeq ScreenRenderIndexExit
    
    	loadi r1, r0  ; Load position to render
    	call ScreenRenderIndex
    
    	inc r0
    	jmp ScreenRenderIndex_Loop

	ScreenRenderIndexExit:
    	; Reset pointer to beginning
    	loadn r0, #currentScreenIndexesChanged
    	store currentScreenIndexesChangedIndex, r0
    
    pop r2
    pop r1
    pop r0
    rts


ImprimeStr:
	push r0     ; printing position
	push r1	 ; String Address ; its now a pointer
	push r2	 ; color
	push r3
	push r4

	loadi r1, r1 ; now its the string addres
	
	loadn r3, #'\0'

	ImprimeStr_Loop:
		loadi r4, r1          ; Carrega no r4 o caractere apontado por r1
		cmp r4, r3            ; Compara o caractere atual com '\0'
		jeq ImprimeStr_Sai    ; Se for igual a '\0', salta para ImprimeStr_Sai, encerrando a impressão.
		
		add r4, r2, r4        ; Soma r2 ao valor do caractere. 
		
		outchar r4, r0         ; Imprime o caractere (r4) na posição de tela (r0).
		inc r0                 ; Incrementa a posição na tela para o próximo caractere.
		inc r1                 ; Incrementa o ponteiro da string para o próximo caractere.
		jmp ImprimeStr_Loop    ; Volta ao início do loop para continuar imprimindo.

   ImprimeStr_Sai:	
	pop r4	; Resgata os valores dos registradores utilizados na Subrotina da Pilha
	pop r3
	pop r2
	pop r1
	pop r0
	rts


AccesStringIndex:
	; too small for actual use, can just be copied and pasted
	; r0 String Addres / first character
	; r1 Index of interest

	add r0, r0, r1 ; addres of character in index r1	
	loadi r2, r0  ;returns on r2 can become a memory variable if needed
				  
	rts

ScreenRenderIndex:
	
	push r0
	push r1
	push r2
	push r3
	push r4
	; Takes r1 as the position to render
	; Takes currentPrintingColor as a color variable

	; if there is a character on the top layer, it will print it,
	; otherwise, it will check the background layer and print it, even if empty

	; functionality can be expanded to add a UI layer, on top of the prop layer

	;currentUiLayer
	;currentPropLayer
	;currentBackgroundLayer

	load r0, currentPropLayer
	; r1 = Index
	; call AccesStringIndex

		add r0, r0, r1 ; addres of character in index r1	
		loadi r2, r0  ;returns on r2 the value in the string

	; if r2, the value of the string in index r1, is not = " ":
	loadn r3, " "
	cmp r2, r3
	jeq printsecondlayer

		;; Checks if color was passed, if zero, gets default color for layer
		load r3, currentPrintingColor
		add r4, r3, r3
		jnz skipDefaultColorProps
		load r3, propLayerColor
		skipDefaultColorProps:

		add r4, r2, r3
		outchar r4, r1
	
		jmp endprintindex
	; else:
	printsecondlayer:

	load r0, currentBackgroundLayer
	; r1 = Index
	; call AccesStringIndex

		add r0, r0, r1 ; addres of character in index r1	
		loadi r2, r0  ;returns on r2 the value in the string

	; if r2, the value of the string in index r1, is not = " ":
	loadn r3, " "
	cmp r2, r3
	jeq printblank
	
	;; Checks if color was passed, if zero, gets default color for layer
		load r3, currentPrintingColor
		add r4, r3, r3
		jnz skipDefaultColorBackground
		load r3, backgroundLayerColor
		skipDefaultColorBackground:
	
		add r4, r2, r3
		outchar r4, r1
	
		jmp endprintindex
	
	printblank:
	outchar r3, r1
	endprintindex:
	
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0

	rts

setIndexChanged:
    ; r0 = new position
    ; r1 = old position
    
    push r2
    push r3
    
    load r2, currentScreenIndexesChangedIndex  ; Get current write pointer
    
    storei r2, r0  ; Write new position
    inc r2
    storei r2, r1  ; Write old position
    inc r2
    
    store currentScreenIndexesChangedIndex, r2  ; Save updated pointer
    
    pop r3
    pop r2
    rts
