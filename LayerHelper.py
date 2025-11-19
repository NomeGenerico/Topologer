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


UIStack : string "                    " ; len = 20
UIStackIndex: var#0

uiLayerColor: var#1 
propLayerColor: var#1
backgroundLayerColor: var#1
currentPrintingColor: var#1


Level1Props : string "                                                                                                                                                                                                                                                                                                                                                                                       @@@@@@@                                 @     @                                 @     @                                 @     @                                 @     @                                 @     @                                 @@@@@@@                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  "

Level1Background : string "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                "


main:

	;SetUp

		; Initialize the changed index pointer to start of buffer
   		 loadn r0, #currentScreenIndexesChanged
   		 store currentScreenIndexesChangedIndex, r0

		; sets current Layers
			
			; decode Level1 into currentPropLayer
			loadn r0, #Level1Props
			loadn r1, #Level1RLE
			
			call RLEDecoder

			loadn r1, #Level1Props
			store currentPropLayer, r1

			loadn r1, #Level1Background
			store currentBackgroundLayer, r1

		; positions player in level
			
			loadn r0, #120
			store posPlayer, r0
	
			loadn r1, #Level1Props  ; must be changed to curent layer later
			add r2, r1, r0
			loadn r0, "A"

			storei r2, r0

		; Main Menu:

		loadn r0, #Level1Props
		loadn r1, #Level1RLE
			
		call RLEDecoder

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

RLEDecoder:
	push r0
	push r1
	push r2
	push r3
	push r4
	; r0 is the string it will decode to. Pointer
	; r1 is the string it will decode
	
	loadn r3, #'\0'

	RLEDecoder_Loop:
		loadi r4, r1          ; Carrega no r4 o caractere apontado por r1
		cmp r4, r3            ; Compara o caractere atual com '\0'
		jeq RLEDecoder_Exit   ; Se for igual a '\0', salta para ImprimeStr_Sai, encerrando a impressão.
		

		mov r2, r4 ; loop lengh
		inc r1
		loadi r4, r1	; looped character
		inc r2 ; makes loop easier, no need to compare to zero
			CharacterDecode_Loop:
			dec r2
			jz CharacterDecode_Exit
			
				storei r0,r4
				inc r0	

				jmp CharacterDecode_Loop

			CharacterDecode_Exit:
			inc r1 
		jmp RLEDecoder_Loop    ; Volta ao início do loop para continuar imprimindo.

   RLEDecoder_Exit:	
	pop r4	; Resgata os valores dos registradores utilizados na Subrotina da Pilha
	pop r3
	pop r2
	pop r1
	pop r0
	rts

; UI Data

; Main Menu

; Title: "TOPOLOGER" with 3 blank lines on top, 1 space left margin
; Original: 200 words (5 lines × 40 chars), RLE: 79 words, saved 60.5%
TitleRLE : var #79  ; 39 runs, 79 words total

static TitleRLE + #0, #120      ; count
static TitleRLE + #1, #32    ; ' ' (ASCII 32)
static TitleRLE + #2, #1      ; count
static TitleRLE + #3, #32    ; ' ' (ASCII 32)
static TitleRLE + #4, #5      ; count
static TitleRLE + #5, #95    ; '_' (ASCII 95)
static TitleRLE + #6, #9      ; count
static TitleRLE + #7, #32    ; ' ' (ASCII 32)
static TitleRLE + #8, #1      ; count
static TitleRLE + #9, #95    ; '_' (ASCII 95)
static TitleRLE + #10, #16      ; count
static TitleRLE + #11, #32    ; ' ' (ASCII 32)
static TitleRLE + #12, #1      ; count
static TitleRLE + #13, #32    ; ' ' (ASCII 32)
static TitleRLE + #14, #1      ; count
static TitleRLE + #15, #124    ; '|' (ASCII 124)
static TitleRLE + #16, #1      ; count
static TitleRLE + #17, #95    ; '_' (ASCII 95)
static TitleRLE + #18, #3      ; count
static TitleRLE + #19, #32    ; ' ' (ASCII 32)
static TitleRLE + #20, #1      ; count
static TitleRLE + #21, #95    ; '_' (ASCII 95)
static TitleRLE + #22, #1      ; count
static TitleRLE + #23, #124    ; '|' (ASCII 124)
static TitleRLE + #24, #1      ; count
static TitleRLE + #25, #95    ; '_' (ASCII 95)
static TitleRLE + #26, #1      ; count
static TitleRLE + #27, #95    ; '_' (ASCII 95)
static TitleRLE + #28, #1      ; count
static TitleRLE + #29, #32    ; ' ' (ASCII 32)
static TitleRLE + #30, #1      ; count
static TitleRLE + #31, #114    ; 'r' (ASCII 114)
static TitleRLE + #32, #1      ; count
static TitleRLE + #33, #124    ; '|' (ASCII 124)
static TitleRLE + #34, #1      ; count
static TitleRLE + #35, #95    ; '_' (ASCII 95)
static TitleRLE + #36, #1      ; count
static TitleRLE + #37, #95    ; '_' (ASCII 95)
static TitleRLE + #38, #1      ; count
static TitleRLE + #39, #32    ; ' ' (ASCII 32)
static TitleRLE + #40, #3      ; count
static TitleRLE + #41, #95    ; '_' (ASCII 95)
static TitleRLE + #42, #1      ; count
static TitleRLE + #43, #32    ; ' ' (ASCII 32)
static TitleRLE + #44, #1      ; count
static TitleRLE + #45, #95    ; '_' (ASCII 95)
static TitleRLE + #46, #1      ; count
static TitleRLE + #47, #95    ; '_' (ASCII 95)
static TitleRLE + #48, #1      ; count
static TitleRLE + #49, #32    ; ' ' (ASCII 32)
static TitleRLE + #50, #1      ; count
static TitleRLE + #51, #95    ; '_' (ASCII 95)
static TitleRLE + #52, #1      ; count
static TitleRLE + #53, #95    ; '_' (ASCII 95)
static TitleRLE + #54, #1      ; count
static TitleRLE + #55, #95    ; '_' (ASCII 95)
static TitleRLE + #56, #1      ; count
static TitleRLE + #57, #32    ; ' ' (ASCII 32)
static TitleRLE + #58, #1      ; count
static TitleRLE + #59, #95    ; '_' (ASCII 95)
static TitleRLE + #60, #2      ; count
static TitleRLE + #61, #32    ; ' ' (ASCII 32)
static TitleRLE + #62, #2      ; count
static TitleRLE + #63, #32    ; ' ' (ASCII 32)
static TitleRLE + #64, #1      ; count
static TitleRLE + #65, #124    ; '|' (ASCII 124)
static TitleRLE + #66, #2      ; count
static TitleRLE + #67, #32    ; ' ' (ASCII 32)
static TitleRLE + #68, #1      ; count
static TitleRLE + #69, #124    ; '|' (ASCII 124)
static TitleRLE + #70, #1      ; count
static TitleRLE + #71, #47    ; '/' (ASCII 47)
static TitleRLE + #72, #1      ; count
static TitleRLE + #73, #32    ; ' ' (ASCII 32)
static TitleRLE + #74, #1      ; count
static TitleRLE + #75, #95    ; '_' (ASCII 95)
static TitleRLE + #76, #1      ; count
static TitleRLE + #77, #32    ; ' ' (ASCII 32)
static TitleRLE + #78, #1      ; count
static TitleRLE + #79, #92    ; '\' (ASCII 92)
static TitleRLE + #80, #1      ; count
static TitleRLE + #81, #32    ; ' ' (ASCII 32)
static TitleRLE + #82, #1      ; count
static TitleRLE + #83, #95    ; '_' (ASCII 95)
static TitleRLE + #84, #1      ; count
static TitleRLE + #85, #32    ; ' ' (ASCII 32)
static TitleRLE + #86, #1      ; count
static TitleRLE + #87, #92    ; '\' (ASCII 92)
static TitleRLE + #88, #1      ; count
static TitleRLE + #89, #47    ; '/' (ASCII 47)
static TitleRLE + #90, #1      ; count
static TitleRLE + #91, #32    ; ' ' (ASCII 32)
static TitleRLE + #92, #1      ; count
static TitleRLE + #93, #95    ; '_' (ASCII 95)
static TitleRLE + #94, #1      ; count
static TitleRLE + #95, #96    ; '`' (ASCII 96)
static TitleRLE + #96, #1      ; count
static TitleRLE + #97, #32    ; ' ' (ASCII 32)
static TitleRLE + #98, #1      ; count
static TitleRLE + #99, #47    ; '/' (ASCII 47)
static TitleRLE + #100, #1      ; count
static TitleRLE + #101, #32    ; ' ' (ASCII 32)
static TitleRLE + #102, #1      ; count
static TitleRLE + #103, #45    ; '-' (ASCII 45)
static TitleRLE + #104, #1      ; count
static TitleRLE + #105, #41    ; ')' (ASCII 41)
static TitleRLE + #106, #1      ; count
static TitleRLE + #107, #32    ; ' ' (ASCII 32)
static TitleRLE + #108, #2      ; count
static TitleRLE + #109, #32    ; ' ' (ASCII 32)
static TitleRLE + #110, #1      ; count
static TitleRLE + #111, #124    ; '|' (ASCII 124)
static TitleRLE + #112, #1      ; count
static TitleRLE + #113, #32    ; ' ' (ASCII 32)
static TitleRLE + #114, #1      ; count
static TitleRLE + #115, #124    ; '|' (ASCII 124)
static TitleRLE + #116, #1      ; count
static TitleRLE + #117, #47    ; '/' (ASCII 47)
static TitleRLE + #118, #1      ; count
static TitleRLE + #119, #32    ; ' ' (ASCII 32)
static TitleRLE + #120, #1      ; count
static TitleRLE + #121, #95    ; '_' (ASCII 95)
static TitleRLE + #122, #1      ; count
static TitleRLE + #123, #32    ; ' ' (ASCII 32)
static TitleRLE + #124, #1      ; count
static TitleRLE + #125, #92    ; '\' (ASCII 92)
static TitleRLE + #126, #1      ; count
static TitleRLE + #127, #32    ; ' ' (ASCII 32)
static TitleRLE + #128, #1      ; count
static TitleRLE + #129, #95    ; '_' (ASCII 95)
static TitleRLE + #130, #1      ; count
static TitleRLE + #131, #95    ; '_' (ASCII 95)
static TitleRLE + #132, #1      ; count
static TitleRLE + #133, #32    ; ' ' (ASCII 32)
static TitleRLE + #134, #1      ; count
static TitleRLE + #135, #92    ; '\' (ASCII 92)
static TitleRLE + #136, #1      ; count
static TitleRLE + #137, #47    ; '/' (ASCII 47)
static TitleRLE + #138, #1      ; count
static TitleRLE + #139, #32    ; ' ' (ASCII 32)
static TitleRLE + #140, #1      ; count
static TitleRLE + #141, #95    ; '_' (ASCII 95)
static TitleRLE + #142, #1      ; count
static TitleRLE + #143, #95    ; '_' (ASCII 95)
static TitleRLE + #144, #1      ; count
static TitleRLE + #145, #92    ; '\' (ASCII 92)
static TitleRLE + #146, #1      ; count
static TitleRLE + #147, #47    ; '/' (ASCII 47)
static TitleRLE + #148, #1      ; count
static TitleRLE + #149, #32    ; ' ' (ASCII 32)
static TitleRLE + #150, #1      ; count
static TitleRLE + #151, #95    ; '_' (ASCII 95)
static TitleRLE + #152, #1      ; count
static TitleRLE + #153, #96    ; '`' (ASCII 96)
static TitleRLE + #154, #1      ; count
static TitleRLE + #155, #32    ; ' ' (ASCII 32)
static TitleRLE + #156, #1      ; count
static TitleRLE + #157, #47    ; '/' (ASCII 47)
static TitleRLE + #158, #1      ; count
static TitleRLE + #159, #32    ; ' ' (ASCII 32)
static TitleRLE + #160, #1      ; count
static TitleRLE + #161, #45    ; '-' (ASCII 45)
static TitleRLE + #162, #1      ; count
static TitleRLE + #163, #95    ; '_' (ASCII 95)
static TitleRLE + #164, #1      ; count
static TitleRLE + #165, #41    ; ')' (ASCII 41)
static TitleRLE + #166, #1      ; count
static TitleRLE + #167, #32    ; ' ' (ASCII 32)
static TitleRLE + #168, #1      ; count
static TitleRLE + #169, #39    ; ''' (ASCII 39)
static TitleRLE + #170, #1      ; count
static TitleRLE + #171, #95    ; '_' (ASCII 95)
static TitleRLE + #172, #1      ; count
static TitleRLE + #173, #124    ; '|' (ASCII 124)
static TitleRLE + #174, #1      ; count
static TitleRLE + #175, #39    ; ''' (ASCII 39)
static TitleRLE + #176, #2      ; count
static TitleRLE + #177, #32    ; ' ' (ASCII 32)
static TitleRLE + #178, #1      ; count
static TitleRLE + #179, #124    ; '|' (ASCII 124)
static TitleRLE + #180, #1      ; count
static TitleRLE + #181, #32    ; ' ' (ASCII 32)
static TitleRLE + #182, #1      ; count
static TitleRLE + #183, #124    ; '|' (ASCII 124)
static TitleRLE + #184, #1      ; count
static TitleRLE + #185, #47    ; '/' (ASCII 47)
static TitleRLE + #186, #1      ; count
static TitleRLE + #187, #32    ; ' ' (ASCII 32)
static TitleRLE + #188, #1      ; count
static TitleRLE + #189, #95    ; '_' (ASCII 95)
static TitleRLE + #190, #1      ; count
static TitleRLE + #191, #95    ; '_' (ASCII 95)
static TitleRLE + #192, #1      ; count
static TitleRLE + #193, #95    ; '_' (ASCII 95)
static TitleRLE + #194, #1      ; count
static TitleRLE + #195, #47    ; '/' (ASCII 47)
static TitleRLE + #196, #1      ; count
static TitleRLE + #197, #32    ; ' ' (ASCII 32)
static TitleRLE + #198, #1      ; count
static TitleRLE + #199, #46    ; '.' (ASCII 46)
static TitleRLE + #200, #1      ; count
static TitleRLE + #201, #95    ; '_' (ASCII 95)
static TitleRLE + #202, #1      ; count
static TitleRLE + #203, #46    ; '.' (ASCII 46)
static TitleRLE + #204, #1      ; count
static TitleRLE + #205, #32    ; ' ' (ASCII 32)
static TitleRLE + #206, #1      ; count
static TitleRLE + #207, #92    ; '\' (ASCII 92)
static TitleRLE + #208, #1      ; count
static TitleRLE + #209, #95    ; '_' (ASCII 95)
static TitleRLE + #210, #1      ; count
static TitleRLE + #211, #95    ; '_' (ASCII 95)
static TitleRLE + #212, #2      ; count
static TitleRLE + #213, #44    ; ',' (ASCII 44)
static TitleRLE + #214, #1      ; count
static TitleRLE + #215, #92    ; '\' (ASCII 92)
static TitleRLE + #216, #1      ; count
static TitleRLE + #217, #95    ; '_' (ASCII 95)
static TitleRLE + #218, #1      ; count
static TitleRLE + #219, #95    ; '_' (ASCII 95)
static TitleRLE + #220, #1      ; count
static TitleRLE + #221, #124    ; '|' (ASCII 124)
static TitleRLE + #222, #1      ; count
static TitleRLE + #223, #95    ; '_' (ASCII 95)
static TitleRLE + #224, #1      ; count
static TitleRLE + #225, #124    ; '|' (ASCII 124)
static TitleRLE + #226, #10      ; count
static TitleRLE + #227, #32    ; ' ' (ASCII 32)
static TitleRLE + #228, #1      ; count
static TitleRLE + #229, #124    ; '|' (ASCII 124)
static TitleRLE + #230, #1      ; count
static TitleRLE + #231, #95    ; '_' (ASCII 95)
static TitleRLE + #232, #1      ; count
static TitleRLE + #233, #124    ; '|' (ASCII 124)
static TitleRLE + #234, #9      ; count
static TitleRLE + #235, #32    ; ' ' (ASCII 32)
static TitleRLE + #236, #1      ; count
static TitleRLE + #237, #124    ; '|' (ASCII 124)
static TitleRLE + #238, #1      ; count
static TitleRLE + #239, #95    ; '_' (ASCII 95)
static TitleRLE + #240, #1      ; count
static TitleRLE + #241, #124    ; '|' (ASCII 124)
static TitleRLE + #242, #0      ; terminator
	


; Level Data:

; Original: 1200 words, RLE: 187 words, saved 84.4%
; RLE encoded level data
Level1RLE : var #187  ; 93 runs, 187 words total

static Level1RLE + #0, #28      ; count
static Level1RLE + #1, #32    ; ' ' (ASCII 32)
static Level1RLE + #2, #1      ; count
static Level1RLE + #3, #64    ; '@' (ASCII 64)
static Level1RLE + #4, #39      ; count
static Level1RLE + #5, #32    ; ' ' (ASCII 32)
static Level1RLE + #6, #1      ; count
static Level1RLE + #7, #64    ; '@' (ASCII 64)
static Level1RLE + #8, #39      ; count
static Level1RLE + #9, #32    ; ' ' (ASCII 32)
static Level1RLE + #10, #1      ; count
static Level1RLE + #11, #64    ; '@' (ASCII 64)
static Level1RLE + #12, #39      ; count
static Level1RLE + #13, #32    ; ' ' (ASCII 32)
static Level1RLE + #14, #1      ; count
static Level1RLE + #15, #64    ; '@' (ASCII 64)
static Level1RLE + #16, #39      ; count
static Level1RLE + #17, #32    ; ' ' (ASCII 32)
static Level1RLE + #18, #1      ; count
static Level1RLE + #19, #64    ; '@' (ASCII 64)
static Level1RLE + #20, #39      ; count
static Level1RLE + #21, #32    ; ' ' (ASCII 32)
static Level1RLE + #22, #1      ; count
static Level1RLE + #23, #64    ; '@' (ASCII 64)
static Level1RLE + #24, #39      ; count
static Level1RLE + #25, #32    ; ' ' (ASCII 32)
static Level1RLE + #26, #1      ; count
static Level1RLE + #27, #64    ; '@' (ASCII 64)
static Level1RLE + #28, #39      ; count
static Level1RLE + #29, #32    ; ' ' (ASCII 32)
static Level1RLE + #30, #1      ; count
static Level1RLE + #31, #64    ; '@' (ASCII 64)
static Level1RLE + #32, #39      ; count
static Level1RLE + #33, #32    ; ' ' (ASCII 32)
static Level1RLE + #34, #1      ; count
static Level1RLE + #35, #64    ; '@' (ASCII 64)
static Level1RLE + #36, #25      ; count
static Level1RLE + #37, #32    ; ' ' (ASCII 32)
static Level1RLE + #38, #9      ; count
static Level1RLE + #39, #64    ; '@' (ASCII 64)
static Level1RLE + #40, #5      ; count
static Level1RLE + #41, #32    ; ' ' (ASCII 32)
static Level1RLE + #42, #1      ; count
static Level1RLE + #43, #64    ; '@' (ASCII 64)
static Level1RLE + #44, #25      ; count
static Level1RLE + #45, #32    ; ' ' (ASCII 32)
static Level1RLE + #46, #1      ; count
static Level1RLE + #47, #64    ; '@' (ASCII 64)
static Level1RLE + #48, #7      ; count
static Level1RLE + #49, #32    ; ' ' (ASCII 32)
static Level1RLE + #50, #1      ; count
static Level1RLE + #51, #64    ; '@' (ASCII 64)
static Level1RLE + #52, #5      ; count
static Level1RLE + #53, #32    ; ' ' (ASCII 32)
static Level1RLE + #54, #1      ; count
static Level1RLE + #55, #64    ; '@' (ASCII 64)
static Level1RLE + #56, #25      ; count
static Level1RLE + #57, #32    ; ' ' (ASCII 32)
static Level1RLE + #58, #1      ; count
static Level1RLE + #59, #64    ; '@' (ASCII 64)
static Level1RLE + #60, #7      ; count
static Level1RLE + #61, #32    ; ' ' (ASCII 32)
static Level1RLE + #62, #1      ; count
static Level1RLE + #63, #64    ; '@' (ASCII 64)
static Level1RLE + #64, #5      ; count
static Level1RLE + #65, #32    ; ' ' (ASCII 32)
static Level1RLE + #66, #1      ; count
static Level1RLE + #67, #64    ; '@' (ASCII 64)
static Level1RLE + #68, #25      ; count
static Level1RLE + #69, #32    ; ' ' (ASCII 32)
static Level1RLE + #70, #1      ; count
static Level1RLE + #71, #64    ; '@' (ASCII 64)
static Level1RLE + #72, #7      ; count
static Level1RLE + #73, #32    ; ' ' (ASCII 32)
static Level1RLE + #74, #1      ; count
static Level1RLE + #75, #64    ; '@' (ASCII 64)
static Level1RLE + #76, #5      ; count
static Level1RLE + #77, #32    ; ' ' (ASCII 32)
static Level1RLE + #78, #1      ; count
static Level1RLE + #79, #64    ; '@' (ASCII 64)
static Level1RLE + #80, #25      ; count
static Level1RLE + #81, #32    ; ' ' (ASCII 32)
static Level1RLE + #82, #1      ; count
static Level1RLE + #83, #64    ; '@' (ASCII 64)
static Level1RLE + #84, #7      ; count
static Level1RLE + #85, #32    ; ' ' (ASCII 32)
static Level1RLE + #86, #1      ; count
static Level1RLE + #87, #64    ; '@' (ASCII 64)
static Level1RLE + #88, #5      ; count
static Level1RLE + #89, #32    ; ' ' (ASCII 32)
static Level1RLE + #90, #1      ; count
static Level1RLE + #91, #64    ; '@' (ASCII 64)
static Level1RLE + #92, #25      ; count
static Level1RLE + #93, #32    ; ' ' (ASCII 32)
static Level1RLE + #94, #1      ; count
static Level1RLE + #95, #64    ; '@' (ASCII 64)
static Level1RLE + #96, #7      ; count
static Level1RLE + #97, #32    ; ' ' (ASCII 32)
static Level1RLE + #98, #1      ; count
static Level1RLE + #99, #64    ; '@' (ASCII 64)
static Level1RLE + #100, #5      ; count
static Level1RLE + #101, #32    ; ' ' (ASCII 32)
static Level1RLE + #102, #1      ; count
static Level1RLE + #103, #64    ; '@' (ASCII 64)
static Level1RLE + #104, #25      ; count
static Level1RLE + #105, #32    ; ' ' (ASCII 32)
static Level1RLE + #106, #1      ; count
static Level1RLE + #107, #64    ; '@' (ASCII 64)
static Level1RLE + #108, #7      ; count
static Level1RLE + #109, #32    ; ' ' (ASCII 32)
static Level1RLE + #110, #1      ; count
static Level1RLE + #111, #64    ; '@' (ASCII 64)
static Level1RLE + #112, #5      ; count
static Level1RLE + #113, #32    ; ' ' (ASCII 32)
static Level1RLE + #114, #1      ; count
static Level1RLE + #115, #64    ; '@' (ASCII 64)
static Level1RLE + #116, #25      ; count
static Level1RLE + #117, #32    ; ' ' (ASCII 32)
static Level1RLE + #118, #1      ; count
static Level1RLE + #119, #64    ; '@' (ASCII 64)
static Level1RLE + #120, #7      ; count
static Level1RLE + #121, #32    ; ' ' (ASCII 32)
static Level1RLE + #122, #1      ; count
static Level1RLE + #123, #64    ; '@' (ASCII 64)
static Level1RLE + #124, #5      ; count
static Level1RLE + #125, #32    ; ' ' (ASCII 32)
static Level1RLE + #126, #1      ; count
static Level1RLE + #127, #64    ; '@' (ASCII 64)
static Level1RLE + #128, #25      ; count
static Level1RLE + #129, #32    ; ' ' (ASCII 32)
static Level1RLE + #130, #9      ; count
static Level1RLE + #131, #64    ; '@' (ASCII 64)
static Level1RLE + #132, #5      ; count
static Level1RLE + #133, #32    ; ' ' (ASCII 32)
static Level1RLE + #134, #1      ; count
static Level1RLE + #135, #64    ; '@' (ASCII 64)
static Level1RLE + #136, #39      ; count
static Level1RLE + #137, #32    ; ' ' (ASCII 32)
static Level1RLE + #138, #1      ; count
static Level1RLE + #139, #64    ; '@' (ASCII 64)
static Level1RLE + #140, #39      ; count
static Level1RLE + #141, #32    ; ' ' (ASCII 32)
static Level1RLE + #142, #1      ; count
static Level1RLE + #143, #64    ; '@' (ASCII 64)
static Level1RLE + #144, #39      ; count
static Level1RLE + #145, #32    ; ' ' (ASCII 32)
static Level1RLE + #146, #1      ; count
static Level1RLE + #147, #64    ; '@' (ASCII 64)
static Level1RLE + #148, #39      ; count
static Level1RLE + #149, #32    ; ' ' (ASCII 32)
static Level1RLE + #150, #1      ; count
static Level1RLE + #151, #64    ; '@' (ASCII 64)
static Level1RLE + #152, #39      ; count
static Level1RLE + #153, #32    ; ' ' (ASCII 32)
static Level1RLE + #154, #1      ; count
static Level1RLE + #155, #64    ; '@' (ASCII 64)
static Level1RLE + #156, #25      ; count
static Level1RLE + #157, #32    ; ' ' (ASCII 32)
static Level1RLE + #158, #15      ; count
static Level1RLE + #159, #64    ; '@' (ASCII 64)
static Level1RLE + #160, #39      ; count
static Level1RLE + #161, #32    ; ' ' (ASCII 32)
static Level1RLE + #162, #1      ; count
static Level1RLE + #163, #64    ; '@' (ASCII 64)
static Level1RLE + #164, #39      ; count
static Level1RLE + #165, #32    ; ' ' (ASCII 32)
static Level1RLE + #166, #1      ; count
static Level1RLE + #167, #64    ; '@' (ASCII 64)
static Level1RLE + #168, #39      ; count
static Level1RLE + #169, #32    ; ' ' (ASCII 32)
static Level1RLE + #170, #1      ; count
static Level1RLE + #171, #64    ; '@' (ASCII 64)
static Level1RLE + #172, #39      ; count
static Level1RLE + #173, #32    ; ' ' (ASCII 32)
static Level1RLE + #174, #1      ; count
static Level1RLE + #175, #64    ; '@' (ASCII 64)
static Level1RLE + #176, #39      ; count
static Level1RLE + #177, #32    ; ' ' (ASCII 32)
static Level1RLE + #178, #1      ; count
static Level1RLE + #179, #64    ; '@' (ASCII 64)
static Level1RLE + #180, #39      ; count
static Level1RLE + #181, #32    ; ' ' (ASCII 32)
static Level1RLE + #182, #1      ; count
static Level1RLE + #183, #64    ; '@' (ASCII 64)
static Level1RLE + #184, #11      ; count
static Level1RLE + #185, #32    ; ' ' (ASCII 32)
static Level1RLE + #186, #0      ; terminator
