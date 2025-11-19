jmp main

playerPos: var#1
playerPrevPos: var#1
playerOriginalPos: var#1
playerMoveDirection: var#1
playerOrientation: var#1

moveBlocked : var#1 ; flag for box pushing functions

StageData:  var#4    ; will store data for the stage /  0-3 layers to be loaded, HUD, Prop, Background, Behaviour. 4-Topology
; will be used in the loading of a new stage or level. Its used to set all of the relevant Variables



currentUILayer: var#1
currentPropLayer: var#1
currentBackgroundLayer: var#1
currentBehaviourLayer: var#1
curentTopology: var#1

; Render Data
currentScreenIndexesChanged : var#1200
currentScreenIndexesChangedIndex: var#0

; UI Data 
UIStack : var#20 ; max of 20 ui elements
UIStackPointer: var#1

; ColorData
uiLayerColor: var#1 
propLayerColor: var#1
backgroundLayerColor: var#1
currentPrintingColor: var#1

LayerProps : string "                                                                                                                                                                                                                                                                                                                                                                                       @@@@@@@                                 @     @                                 @     @                                 @     @                                 @     @                                 @     @                                 @@@@@@@                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  "
LayerBackground : string "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                "
   



main:

	;SetUp

		; Initialize the changed index pointer to start of buffer
   		 loadn r0, #currentScreenIndexesChanged
   		 store currentScreenIndexesChangedIndex, r0

		; sets current Layers

			; Initialize layer pointers
    			loadn r0, #LayerProps
				store currentPropLayer, r0
    
				loadn r0, #LayerBackground
    			store currentBackgroundLayer, r0


			loadn r2, Level1
			call LoadStage

		; positions player in level

			loadn r1, #currentPropLayer
			loadi r1, r1

			loadn r0, #119
			store playerPos, r0
	
			add r2, r1, r0
			loadn r0, "A"

			storei r2, r0


		; first Print

			call FullScreenPrint


	mainLoop:
	
		;Movement
			call movePlayer  ; must make movePlayer call checkPushMove
						     ; To alow current code to work

		;RenderLoop:
			call render


	jmp mainLoop

movePlayer:
	
	push r0
	push r1
	push r2
	push r3


	load r0, playerPos
	store playerOriginalPos, r0
	mov r1, r0
	store playerPrevPos, r1
	inchar r3

	; r0 playerPos
	; r1 playerPrevPos
	s r2 localHelper
	; r3 inchar

	;if a
		loadn r2, 'a' 
		cmp r3, r2
		jeq PlayerMvLeft
	
	;if d
		loadn r2, 'd' 
		cmp r3, r2
		jeq PlayerMvRight

	;if w
		loadn r2, 'w' 
		cmp r3, r2
		jeq PlayerMvUp

	;if s
		loadn r2, 's' 
		cmp r3, r2
		jeq PlayerMvDown

	;else
		jmp endMovePlayer

	PlayerMvLeft:
		
		call MvLeft

		loadn r2, #3
		store playerMoveDirection, r2
		
		jmp callMovementTopologyPlayer

	PlayerMvRight:

		call MvRight

		loadn r2, #1
		store playerMoveDirection, r2

		jmp callMovementTopologyPlayer

	PlayerMvUp:

		call MvUp

		loadn r2, #2
		store playerMoveDirection, r2

		jmp callMovementTopologyPlayer
	
	PlayerMvDown:
		
		call MvDown

		loadn r2, #4
		store playerMoveDirection, r2

		jmp callMovementTopologyPlayer


	callMovementTopologyPlayer:		
		call mvTopology

	; CheckPush or block
		;takes r0 = new pos
		load r1, playerPrevPos; takes r1 = prev pos
		call checkPushMovement	


	endMovePlayer:
	store playerPos, r0 
	
	;takes r0 = new pos
	load r1, playerPrevPos; takes r1 = prev sos

	call MoveInMemory ; 
	
	call SetIndexChanged
	mov r0, r1
	call SetIndexChanged


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
			jeq boxMvLeft
	
		;if r2 = 1
			loadn r3, #1 
			cmp r3, r2
			jeq boxMvRight

		;if r2 = 2
			loadn r3, #65496
			cmp r3, r2
			jeq boxMvUp

		;if r2 = 4
			loadn r3, #40
			cmp r3, r2
			jeq boxMvDown
		

		; loadn r7, #2
		; code will reach here if the boxes cross the topology bounderies

		; torus specific fix; will need to be moved to a function with a pointer in 
		; current topology manager or solver
			mov r7, r2
			
			loadn r3, #65497
			cmp r3, r2
			jeq boxMvRight

			loadn r3, #64376
			cmp r3, r2
			jeq boxMvDown

			loadn r3, #39
			cmp r3, r2
			jeq boxMvLeft

			loadn r3, #1160
			cmp r3, r2
			jeq boxMvUp


		jmp endboxmv		

		boxMvRight:
			mov r5, r0
			call MvRight ; puts new position in r0
			jmp boxmvtopology	

		boxMvUp:
			mov r5, r0
			call MvUp ; puts new position in r0
			jmp boxmvtopology

		boxMvLeft:
			mov r5, r0
			call MvLeft ; puts new position in r0
			jmp boxmvtopology

		boxMvDown:
			mov r5, r0
			call MvDown ; puts new position in r0
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
	
		call SetIndexChanged

	endboxmv:
	

	
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts

MvRight:
	
	; takes and operates on r0

	push r2
	loadn r2, #1
	add r0, r0, r2

	store playerMoveDirection, r2
	
	pop r2

	rts

MvLeft:
	
	; takes and operates on r0

	push r2
	loadn r2, #1
	sub r0, r0, r2

	store playerMoveDirection, r2
	
	pop r2

	rts

MvUp:
	; takes and operates on r0

	push r2

	loadn r2, #40
	sub r0, r0, r2

	loadn r2, #2
	store playerMoveDirection, r2
	
	pop r2

	rts

MvDown:
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

		;call SetIndexChanged

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

FullScreenPrint:
    push r1
    push r2
    
    loadn r1, #0 
    loadn r2, #1199

	FullScreenRenderIndex_Loop:
    	cmp r1, r2  ; Checks if printing the end
    	jeq FullScreenRenderIndexExit
    
    	
    	call ScreenRenderIndex
    
    	inc r1
    	jmp FullScreenRenderIndex_Loop

	FullScreenRenderIndexExit:
    	; Reset pointer to beginning
    	loadn r0, #currentScreenIndexesChanged
    	store currentScreenIndexesChangedIndex, r0
    
    pop r2
    pop r1
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

		add r0, r0, r1 ; address of character in index r1	
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

SetIndexChanged:
    ; r0 = index
    
    push r2
    push r3
    
    load r2, currentScreenIndexesChangedIndex  ; Get current write pointer
    
    storei r2, r0  ; Write new position
    inc r2

    
    store currentScreenIndexesChangedIndex, r2  ; Save updated pointer
    
    pop r3
    pop r2
    rts

RLEDecoder:   ; (r0 <- r1)
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

RLEEncoder:

	rts

LoadStage:

	; StageData <HUD, Prop, Background, Layer, Topology>

	;currentUILayer: var#1
	;currentPropLayer: var#1
	;currentBackgroundLayer: var#1
	;currentBehaviourLayer: var#1
	;curentTopology: var#1

	push r0
	push r1
	push r2 ; StageData MemAddress

	load r0, currentUILayer
	loadi r1, r2

	call RLEDecoder
	inc r2

	load r0, currentPropLayer
	loadi r1, r2

	call RLEDecoder
	inc r2

	load r0, currentBackgroundLayer
	loadi r1, r2

	call RLEDecoder
	inc r2

	Load r0, currentBehaviourLayer
	loadi r1, r2

	call RLEDecoder
	inc r2

	loadi r1, r2
	store curentTopology, r1
	
	pop r2
	pop r1
	pop r0

	rts


TODO:
UICall: 	
			; operates on r0, r1, r2
			; calls a UI element, and pushes the stack 
			; takes r0 as the poiter to the UI element function ; the element is resposable for reducing the uielement pointer 
			; r1 as the start position of where it will Draw
			; r2 is the elements color. 


			; r0 will be the start of the draw position	
			; r1 will be the end of the draw position
			; r2 will be the outupt   ; exemple, confirmation prompt returns either a 1 or a 0

UIRedraw: 
			; Travels the stack and reconstruncting the current UI Layer, Must be able to determine the size and all positions that must be redraw
			; takes r0 and r1, as start and end position of the ui element. assumes a retengular element


		



			







;____________________________________
	; UI Data

	; Main Menu

	; Title: "TOPOLOGER" with 3 blank lines on top, 1 space left margin
	; Original: 200 words (5 lines × 40 chars), RLE: 79 words, saved 60.5%

; Original: 1200 words, RLE: 193 words, saved 83.9%
; RLE encoded level data
TitleRLE : var #193  ; 96 runs, 193 words total

	static TitleRLE + #0, #121      ; count
	static TitleRLE + #1, #32    ; ' ' (ASCII 32)
	static TitleRLE + #2, #5      ; count
	static TitleRLE + #3, #95    ; '_' (ASCII 95)
	static TitleRLE + #4, #9      ; count
	static TitleRLE + #5, #32    ; ' ' (ASCII 32)
	static TitleRLE + #6, #1      ; count
	static TitleRLE + #7, #95    ; '_' (ASCII 95)
	static TitleRLE + #8, #25      ; count
	static TitleRLE + #9, #32    ; ' ' (ASCII 32)
	static TitleRLE + #10, #1      ; count
	static TitleRLE + #11, #124    ; '|' (ASCII 124)
	static TitleRLE + #12, #1      ; count
	static TitleRLE + #13, #95    ; '_' (ASCII 95)
	static TitleRLE + #14, #3      ; count
	static TitleRLE + #15, #32    ; ' ' (ASCII 32)
	static TitleRLE + #16, #1      ; count
	static TitleRLE + #17, #95    ; '_' (ASCII 95)
	static TitleRLE + #18, #1      ; count
	static TitleRLE + #19, #124    ; '|' (ASCII 124)
	static TitleRLE + #20, #2      ; count
	static TitleRLE + #21, #95    ; '_' (ASCII 95)
	static TitleRLE + #22, #1      ; count
	static TitleRLE + #23, #32    ; ' ' (ASCII 32)
	static TitleRLE + #24, #1      ; count
	static TitleRLE + #25, #95    ; '_' (ASCII 95)
	static TitleRLE + #26, #1      ; count
	static TitleRLE + #27, #32    ; ' ' (ASCII 32)
	static TitleRLE + #28, #2      ; count
	static TitleRLE + #29, #95    ; '_' (ASCII 95)
	static TitleRLE + #30, #1      ; count
	static TitleRLE + #31, #124    ; '|' (ASCII 124)
	static TitleRLE + #32, #1      ; count
	static TitleRLE + #33, #32    ; ' ' (ASCII 32)
	static TitleRLE + #34, #1      ; count
	static TitleRLE + #35, #124    ; '|' (ASCII 124)
	static TitleRLE + #36, #3      ; count
	static TitleRLE + #37, #95    ; '_' (ASCII 95)
	static TitleRLE + #38, #1      ; count
	static TitleRLE + #39, #32    ; ' ' (ASCII 32)
	static TitleRLE + #40, #2      ; count
	static TitleRLE + #41, #95    ; '_' (ASCII 95)
	static TitleRLE + #42, #1      ; count
	static TitleRLE + #43, #32    ; ' ' (ASCII 32)
	static TitleRLE + #44, #1      ; count
	static TitleRLE + #45, #95    ; '_' (ASCII 95)
	static TitleRLE + #46, #1      ; count
	static TitleRLE + #47, #32    ; ' ' (ASCII 32)
	static TitleRLE + #48, #3      ; count
	static TitleRLE + #49, #95    ; '_' (ASCII 95)
	static TitleRLE + #50, #1      ; count
	static TitleRLE + #51, #32    ; ' ' (ASCII 32)
	static TitleRLE + #52, #1      ; count
	static TitleRLE + #53, #95    ; '_' (ASCII 95)
	static TitleRLE + #54, #1      ; count
	static TitleRLE + #55, #32    ; ' ' (ASCII 32)
	static TitleRLE + #56, #1      ; count
	static TitleRLE + #57, #95    ; '_' (ASCII 95)
	static TitleRLE + #58, #9      ; count
	static TitleRLE + #59, #32    ; ' ' (ASCII 32)
	static TitleRLE + #60, #1      ; count
	static TitleRLE + #61, #124    ; '|' (ASCII 124)
	static TitleRLE + #62, #1      ; count
	static TitleRLE + #63, #32    ; ' ' (ASCII 32)
	static TitleRLE + #64, #1      ; count
	static TitleRLE + #65, #124    ; '|' (ASCII 124)
	static TitleRLE + #66, #1      ; count
	static TitleRLE + #67, #47    ; '/' (ASCII 47)
	static TitleRLE + #68, #1      ; count
	static TitleRLE + #69, #32    ; ' ' (ASCII 32)
	static TitleRLE + #70, #1      ; count
	static TitleRLE + #71, #95    ; '_' (ASCII 95)
	static TitleRLE + #72, #1      ; count
	static TitleRLE + #73, #32    ; ' ' (ASCII 32)
	static TitleRLE + #74, #1      ; count
	static TitleRLE + #75, #92    ; '\' (ASCII 92)
	static TitleRLE + #76, #1      ; count
	static TitleRLE + #77, #32    ; ' ' (ASCII 32)
	static TitleRLE + #78, #1      ; count
	static TitleRLE + #79, #39    ; ''' (ASCII 39)
	static TitleRLE + #80, #1      ; count
	static TitleRLE + #81, #95    ; '_' (ASCII 95)
	static TitleRLE + #82, #1      ; count
	static TitleRLE + #83, #32    ; ' ' (ASCII 32)
	static TitleRLE + #84, #1      ; count
	static TitleRLE + #85, #92    ; '\' (ASCII 92)
	static TitleRLE + #86, #1      ; count
	static TitleRLE + #87, #32    ; ' ' (ASCII 32)
	static TitleRLE + #88, #1      ; count
	static TitleRLE + #89, #47    ; '/' (ASCII 47)
	static TitleRLE + #90, #1      ; count
	static TitleRLE + #91, #32    ; ' ' (ASCII 32)
	static TitleRLE + #92, #1      ; count
	static TitleRLE + #93, #95    ; '_' (ASCII 95)
	static TitleRLE + #94, #1      ; count
	static TitleRLE + #95, #32    ; ' ' (ASCII 32)
	static TitleRLE + #96, #1      ; count
	static TitleRLE + #97, #92    ; '\' (ASCII 92)
	static TitleRLE + #98, #1      ; count
	static TitleRLE + #99, #47    ; '/' (ASCII 47)
	static TitleRLE + #100, #1      ; count
	static TitleRLE + #101, #32    ; ' ' (ASCII 32)
	static TitleRLE + #102, #1      ; count
	static TitleRLE + #103, #95    ; '_' (ASCII 95)
	static TitleRLE + #104, #1      ; count
	static TitleRLE + #105, #96    ; '`' (ASCII 96)
	static TitleRLE + #106, #1      ; count
	static TitleRLE + #107, #32    ; ' ' (ASCII 32)
	static TitleRLE + #108, #1      ; count
	static TitleRLE + #109, #47    ; '/' (ASCII 47)
	static TitleRLE + #110, #1      ; count
	static TitleRLE + #111, #32    ; ' ' (ASCII 32)
	static TitleRLE + #112, #1      ; count
	static TitleRLE + #113, #45    ; '-' (ASCII 45)
	static TitleRLE + #114, #1      ; count
	static TitleRLE + #115, #95    ; '_' (ASCII 95)
	static TitleRLE + #116, #1      ; count
	static TitleRLE + #117, #41    ; ')' (ASCII 41)
	static TitleRLE + #118, #1      ; count
	static TitleRLE + #119, #32    ; ' ' (ASCII 32)
	static TitleRLE + #120, #1      ; count
	static TitleRLE + #121, #39    ; ''' (ASCII 39)
	static TitleRLE + #122, #1      ; count
	static TitleRLE + #123, #95    ; '_' (ASCII 95)
	static TitleRLE + #124, #1      ; count
	static TitleRLE + #125, #124    ; '|' (ASCII 124)
	static TitleRLE + #126, #7      ; count
	static TitleRLE + #127, #32    ; ' ' (ASCII 32)
	static TitleRLE + #128, #1      ; count
	static TitleRLE + #129, #124    ; '|' (ASCII 124)
	static TitleRLE + #130, #1      ; count
	static TitleRLE + #131, #95    ; '_' (ASCII 95)
	static TitleRLE + #132, #1      ; count
	static TitleRLE + #133, #124    ; '|' (ASCII 124)
	static TitleRLE + #134, #1      ; count
	static TitleRLE + #135, #92    ; '\' (ASCII 92)
	static TitleRLE + #136, #3      ; count
	static TitleRLE + #137, #95    ; '_' (ASCII 95)
	static TitleRLE + #138, #1      ; count
	static TitleRLE + #139, #47    ; '/' (ASCII 47)
	static TitleRLE + #140, #1      ; count
	static TitleRLE + #141, #32    ; ' ' (ASCII 32)
	static TitleRLE + #142, #1      ; count
	static TitleRLE + #143, #46    ; '.' (ASCII 46)
	static TitleRLE + #144, #2      ; count
	static TitleRLE + #145, #95    ; '_' (ASCII 95)
	static TitleRLE + #146, #1      ; count
	static TitleRLE + #147, #47    ; '/' (ASCII 47)
	static TitleRLE + #148, #1      ; count
	static TitleRLE + #149, #95    ; '_' (ASCII 95)
	static TitleRLE + #150, #1      ; count
	static TitleRLE + #151, #92    ; '\' (ASCII 92)
	static TitleRLE + #152, #3      ; count
	static TitleRLE + #153, #95    ; '_' (ASCII 95)
	static TitleRLE + #154, #1      ; count
	static TitleRLE + #155, #47    ; '/' (ASCII 47)
	static TitleRLE + #156, #1      ; count
	static TitleRLE + #157, #92    ; '\' (ASCII 92)
	static TitleRLE + #158, #2      ; count
	static TitleRLE + #159, #95    ; '_' (ASCII 95)
	static TitleRLE + #160, #1      ; count
	static TitleRLE + #161, #44    ; ',' (ASCII 44)
	static TitleRLE + #162, #1      ; count
	static TitleRLE + #163, #32    ; ' ' (ASCII 32)
	static TitleRLE + #164, #1      ; count
	static TitleRLE + #165, #92    ; '\' (ASCII 92)
	static TitleRLE + #166, #3      ; count
	static TitleRLE + #167, #95    ; '_' (ASCII 95)
	static TitleRLE + #168, #1      ; count
	static TitleRLE + #169, #124    ; '|' (ASCII 124)
	static TitleRLE + #170, #1      ; count
	static TitleRLE + #171, #95    ; '_' (ASCII 95)
	static TitleRLE + #172, #1      ; count
	static TitleRLE + #173, #124    ; '|' (ASCII 124)
	static TitleRLE + #174, #16      ; count
	static TitleRLE + #175, #32    ; ' ' (ASCII 32)
	static TitleRLE + #176, #1      ; count
	static TitleRLE + #177, #124    ; '|' (ASCII 124)
	static TitleRLE + #178, #1      ; count
	static TitleRLE + #179, #95    ; '_' (ASCII 95)
	static TitleRLE + #180, #1      ; count
	static TitleRLE + #181, #124    ; '|' (ASCII 124)
	static TitleRLE + #182, #9      ; count
	static TitleRLE + #183, #32    ; ' ' (ASCII 32)
	static TitleRLE + #184, #1      ; count
	static TitleRLE + #185, #124    ; '|' (ASCII 124)
	static TitleRLE + #186, #3      ; count
	static TitleRLE + #187, #95    ; '_' (ASCII 95)
	static TitleRLE + #188, #1      ; count
	static TitleRLE + #189, #47    ; '/' (ASCII 47)
	static TitleRLE + #190, #893      ; count
	static TitleRLE + #191, #32    ; ' ' (ASCII 32)
	static TitleRLE + #192, #0      ; terminator		



; Level Data:

EmptyRLE: var#3
	static EmptyRLE + #0, #1200; count
	static EmptyRLE + #1, #32    ; ' ' (ASCII 32)
	static EmptyRLE + #0, #0     ; terminator

Level1: var# 5

	static Level1 + #0, #EmptyRLE    ; UI
	static Level1 + #1, #Level1PropsRLE
	static Level1 + #2, #TitleRLE ;Background
	static Level1 + #3, #EmptyRLE ;Behaviour ; Will be infered from the Prop Layer and Background Layer in my game;
	static Level1 + #4, #Level1Topology      ;Topology

	; Original: 1200 words, RLE: 187 words, saved 84.4%
	; RLE encoded level data
	Level1PropsRLE : var #187  ; 93 runs, 187 words total

		static Level1PropsRLE + #0, #28      ; count
		static Level1PropsRLE + #1, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #2, #1      ; count
		static Level1PropsRLE + #3, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #4, #39      ; count
		static Level1PropsRLE + #5, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #6, #1      ; count
		static Level1PropsRLE + #7, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #8, #39      ; count
		static Level1PropsRLE + #9, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #10, #1      ; count
		static Level1PropsRLE + #11, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #12, #39      ; count
		static Level1PropsRLE + #13, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #14, #1      ; count
		static Level1PropsRLE + #15, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #16, #39      ; count
		static Level1PropsRLE + #17, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #18, #1      ; count
		static Level1PropsRLE + #19, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #20, #39      ; count
		static Level1PropsRLE + #21, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #22, #1      ; count
		static Level1PropsRLE + #23, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #24, #39      ; count
		static Level1PropsRLE + #25, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #26, #1      ; count
		static Level1PropsRLE + #27, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #28, #39      ; count
		static Level1PropsRLE + #29, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #30, #1      ; count
		static Level1PropsRLE + #31, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #32, #39      ; count
		static Level1PropsRLE + #33, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #34, #1      ; count
		static Level1PropsRLE + #35, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #36, #25      ; count
		static Level1PropsRLE + #37, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #38, #9      ; count
		static Level1PropsRLE + #39, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #40, #5      ; count
		static Level1PropsRLE + #41, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #42, #1      ; count
		static Level1PropsRLE + #43, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #44, #25      ; count
		static Level1PropsRLE + #45, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #46, #1      ; count
		static Level1PropsRLE + #47, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #48, #7      ; count
		static Level1PropsRLE + #49, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #50, #1      ; count
		static Level1PropsRLE + #51, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #52, #5      ; count
		static Level1PropsRLE + #53, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #54, #1      ; count
		static Level1PropsRLE + #55, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #56, #25      ; count
		static Level1PropsRLE + #57, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #58, #1      ; count
		static Level1PropsRLE + #59, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #60, #7      ; count
		static Level1PropsRLE + #61, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #62, #1      ; count
		static Level1PropsRLE + #63, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #64, #5      ; count
		static Level1PropsRLE + #65, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #66, #1      ; count
		static Level1PropsRLE + #67, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #68, #25      ; count
		static Level1PropsRLE + #69, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #70, #1      ; count
		static Level1PropsRLE + #71, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #72, #7      ; count
		static Level1PropsRLE + #73, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #74, #1      ; count
		static Level1PropsRLE + #75, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #76, #5      ; count
		static Level1PropsRLE + #77, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #78, #1      ; count
		static Level1PropsRLE + #79, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #80, #25      ; count
		static Level1PropsRLE + #81, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #82, #1      ; count
		static Level1PropsRLE + #83, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #84, #7      ; count
		static Level1PropsRLE + #85, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #86, #1      ; count
		static Level1PropsRLE + #87, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #88, #5      ; count
		static Level1PropsRLE + #89, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #90, #1      ; count
		static Level1PropsRLE + #91, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #92, #25      ; count
		static Level1PropsRLE + #93, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #94, #1      ; count
		static Level1PropsRLE + #95, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #96, #7      ; count
		static Level1PropsRLE + #97, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #98, #1      ; count
		static Level1PropsRLE + #99, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #100, #5      ; count
		static Level1PropsRLE + #101, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #102, #1      ; count
		static Level1PropsRLE + #103, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #104, #25      ; count
		static Level1PropsRLE + #105, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #106, #1      ; count
		static Level1PropsRLE + #107, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #108, #7      ; count
		static Level1PropsRLE + #109, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #110, #1      ; count
		static Level1PropsRLE + #111, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #112, #5      ; count
		static Level1PropsRLE + #113, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #114, #1      ; count
		static Level1PropsRLE + #115, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #116, #25      ; count
		static Level1PropsRLE + #117, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #118, #1      ; count
		static Level1PropsRLE + #119, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #120, #7      ; count
		static Level1PropsRLE + #121, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #122, #1      ; count
		static Level1PropsRLE + #123, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #124, #5      ; count
		static Level1PropsRLE + #125, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #126, #1      ; count
		static Level1PropsRLE + #127, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #128, #25      ; count
		static Level1PropsRLE + #129, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #130, #9      ; count
		static Level1PropsRLE + #131, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #132, #5      ; count
		static Level1PropsRLE + #133, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #134, #1      ; count
		static Level1PropsRLE + #135, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #136, #39      ; count
		static Level1PropsRLE + #137, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #138, #1      ; count
		static Level1PropsRLE + #139, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #140, #39      ; count
		static Level1PropsRLE + #141, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #142, #1      ; count
		static Level1PropsRLE + #143, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #144, #39      ; count
		static Level1PropsRLE + #145, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #146, #1      ; count
		static Level1PropsRLE + #147, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #148, #39      ; count
		static Level1PropsRLE + #149, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #150, #1      ; count
		static Level1PropsRLE + #151, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #152, #39      ; count
		static Level1PropsRLE + #153, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #154, #1      ; count
		static Level1PropsRLE + #155, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #156, #25      ; count
		static Level1PropsRLE + #157, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #158, #15      ; count
		static Level1PropsRLE + #159, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #160, #39      ; count
		static Level1PropsRLE + #161, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #162, #1      ; count
		static Level1PropsRLE + #163, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #164, #39      ; count
		static Level1PropsRLE + #165, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #166, #1      ; count
		static Level1PropsRLE + #167, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #168, #39      ; count
		static Level1PropsRLE + #169, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #170, #1      ; count
		static Level1PropsRLE + #171, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #172, #39      ; count
		static Level1PropsRLE + #173, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #174, #1      ; count
		static Level1PropsRLE + #175, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #176, #39      ; count
		static Level1PropsRLE + #177, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #178, #1      ; count
		static Level1PropsRLE + #179, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #180, #39      ; count
		static Level1PropsRLE + #181, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #182, #1      ; count
		static Level1PropsRLE + #183, #64    ; '@' (ASCII 64)
		static Level1PropsRLE + #184, #11      ; count
		static Level1PropsRLE + #185, #32    ; ' ' (ASCII 32)
		static Level1PropsRLE + #186, #0      ; terminator

	Level1Topology: var#1
