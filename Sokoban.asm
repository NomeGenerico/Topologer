jmp main

; Reserved For future Object functions Declarations,  Objects will have a sprite 7 bits (0-127), and a function 8 bits(0-255) (127 Functions) ; Label:
																																			  ; jmp ActualFunction    // jump takes two words in memory 


; TODO
; TODO    Falling dust background for title
; TODO    Using memory more efficient USE Bit Operations
; TODO


; MiscDeclarations


	playerPos: var #1
	playerPrevPos: var #1
	playerOriginalPos: var #1
	playerMoveDirection: var #1
	playerOrientation: var #1

	moveBlocked : var #1 ; flag for box pushing functions

	StageData:  var #4    ; will store data for the stage /  0-3 layers to be loaded, HUD, Prop, Background, Behaviour. 4-Topology
	; will be used in the loading of a new stage or level. Its used to set all of the relevant Variables

	; Important Pointers
	currentUILayer: var #1
	currentPropLayer: var #1
	currentBackgroundLayer: var #1
	currentBehaviourLayer: var #1
	curentTopology: var #1

	; Render Data
	currentScreenIndexesChanged : var #1210
	currentScreenIndexesChangedIndex: var #1


	; UI Data 
	UIStack : var #20 ; max of 20 ui elements
	UIStackPointer: var #1
	UICurentlySelectedElement: var #1 ;<ID>
	UIPreviousSelectedElement: var #3 ;<ID>
	UICurentlySelectedElementChanged: var #1 ; bool
	UISignal: var #1

	; ColorData
	uiLayerColor: var #1 
	propLayerColor: var #1
	backgroundLayerColor: var #1
	currentPrintingColor: var #1 ; 0 is the value for white, USE 1 FOR NO COLOR

	static uiLayerColor, #0     
	static propLayerColor, #0
	static backgroundLayerColor, #0

	static currentPrintingColor + #0 , 0

	LayerProps : string "                                                                                                                                                                                                                                                                                                                                                                                       @@@@@@@                                 @     @                                 @     @                                 @     @                                 @     @                                 @     @                                 @@@@@@@                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  "
	LayerBackground : string "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                "
	LayerUI : var #1200
	LayerBehavior: var #1200

	InputedChar: var #1
	InputedCharBuffered: var #1

	ISUIActive: var #1 
	static ISUIActive + #0, #0

	inputDelay: var #1
	currentInputDelay: var #1
	static inputDelay, #10

	uIHighlightColor: var #1
	static uIHighlightColor, #64512

	LevelList: var #4 
	static LevelList, #Level1
	static LevelList + #1,  #Level2

	CurrentLevel: var #1
	static CurrentLevel, #0

	NumLevels: var#1
	static NumLevels, #2


	RLETraverserBuffer: var #40           ;  [index, shift]
	CurrentRLETraverserBufferPosition: var #1
	static CurrentRLETraverserBufferPosition , #RLETraverserBuffer

	BehaviorJumpDict: var #128

	; defining the functions

		static BehaviorJumpDict  + #0  , #DoNothing
		static BehaviorJumpDict  + #32 , #DoNothing
		static BehaviorJumpDict  + #35 , #BlockMovement
		static BehaviorJumpDict  + #64 , #checkPushMovement


main:

	;SetUp

		; initilize currentScreenIndexesChangedIndex
		loadn r0, #currentScreenIndexesChanged
		store currentScreenIndexesChangedIndex, r0


		; Initialize layer pointers
    		loadn r0, #LayerProps
			store currentPropLayer, r0    
			loadn r0, #LayerBackground
    		store currentBackgroundLayer, r0

			loadn r0, #LayerBehavior
			store currentBehaviourLayer, r0

			loadn r0, #LayerUI
    		store currentUILayer, r0
			
		;Initialize UI Data

			load r0, currentUILayer
			loadn r1, #ZeroRLE
			call RLEDecoder ; (r0, r1)

			loadn r0, #UIStack
			store UIStackPointer, r0

		; positions player in level

			loadn r1, #currentPropLayer
			loadi r1, r1

			loadn r0, #80
			store playerPos, r0
	
			add r2, r1, r0
			loadn r0, #'A'

			storei r2, r0

		; call MainMenu

			loadn r0, #MainMenu
			call UICall

			;call FullScreenUIPrint

			;call FullScreenPrint

	mainLoop:

		; Input
		call InputHandler

		; TODO: move delay logic outside input
	
		Delay

		;GameUpdate



			call movePlayer  ;TODO: put checkPushMovement in a BehaviourLayer; and check if UI is active or not. 


			;call CheckWin


			call UIHandeler
			
		; call UIHandler ; Checks if ui is active

						     
		;RenderLoop:
			call render   ; makes it skip zeros in the UI Buffer, instead of the spaces

		jmp mainLoop

InputHandler:                        ; TODO: Make Buffer hold more than one input, and execute on proper timing

	push r0
	push r1
	push r2


	; Handles Input InputDelay
		loadn r0, #0
		load r1, currentInputDelay
		cmp r0, r1
		jne InputHandler_skipInput


	load r0, InputedCharBuffered
	store InputedChar, r0

	loadn r1, #0
	store InputedCharBuffered, r1
	
	load r0, inputDelay
	store currentInputDelay, r0

	jmp InputHandler_inputValid

	; Delay In Progress

		; Decrement Delay
			InputHandler_skipInput:
			load r1, currentInputDelay
			dec r1
			store currentInputDelay, r1

		; Resets Inputed Char

			loadn r0, #0
			store InputedChar, r0

		; Gets Buffered Input
			inchar r0
			loadn r1, #0
			cmp r0, r1
			jeq InputHandler_SkipBufferUpdate

				store InputedCharBuffered, r0

			InputHandler_SkipBufferUpdate:

	InputHandler_inputValid:

	pop r2
	pop r1
	pop r0
	rts

movePlayer:
	
	push r0
	push r1
	push r2
	push r3

	; check if Ui is active

	; if 1, skip everything
		load r0, ISUIActive
		loadn r1, #1
		cmp r0, r1
		jeq MovePlayerUiSkip

	; reset moveBlocked

		loadn r0, #0
		store moveBlocked, r0

	load r0, playerPos
	store playerOriginalPos, r0
	mov r1, r0
	store playerPrevPos, r1

	load r3, InputedChar

	; r0 playerPos
	; r1 playerPrevPos
	; r2 localHelper
	; r3 InputedChar

	;if a
		loadn r2, #'a' 
		cmp r3, r2
		jeq PlayerMvLeft
	
	;if d
		loadn r2, #'d' 
		cmp r3, r2
		jeq PlayerMvRight

	;if w
		loadn r2, #'w' 
		cmp r3, r2
		jeq PlayerMvUp

	;if s
		loadn r2, #'s' 
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
		


		; Get character at player's new position
		loadn r3, #LayerProps
		add r3, r3, r0
		loadi r3, r3       ; r3 = character at position

		; Look up behavior function
		loadn r2, #BehaviorJumpDict
		add r2, r2, r3     ; r2 = address of function pointer
		loadi r2, r2       ; r2 = function address

		; Call through IndirectCall
		push r0            ; Save position
		push r1            ; Save prev position
		mov r7, r2
		call IndirectCall
		pop r1
		pop r0



		
		;call checkPushMovement	


	; check move blocked
	load r3, moveBlocked
	loadn r2, #1
	cmp r3, r2
	jeq MovePlayer_moveBlocked
		endMovePlayer:
		store playerPos, r0 
	
		;takes r0 = new pos
		load r1, playerPrevPos; takes r1 = prev sos

		call MoveInMemory ; 
	
		call SetIndexChanged
		mov r0, r1
		call SetIndexChanged

	MovePlayer_moveBlocked:

	MovePlayerUiSkip:
	pop r3
	pop r2
	pop r1
	pop r0

	rts

CheckWin:
    push r0
    push r1
    push r2

    load r0, currentPropLayer
    load r1, playerPos
    add r0, r0, r1  ; Get address of player position in prop layer
    loadi r0, r0    ; Load the CHARACTER at that position
    
    loadn r2, #'P'  ; Goal character
    cmp r0, r2
    jne CheckWin_PlayerNotOnGoal

        call NextLevel

    CheckWin_PlayerNotOnGoal:

    pop r2
    pop r1
    pop r0
    rts

NextLevel:

	push r1
	push r2
	push r3

	load r2, #LevelList
	load r1, CurrentLevel

	inc r1
	load r3, NumLevels
	cmp r1, r3
	jne NextLevel_DidNotFinishGame

		pop r3
		pop r2
		pop r1

		jmp main

		NextLevel_DidNotFinishGame:


	store CurrentLevel, r1

	add r2, r2, r1
	loadi r2, r2

	call LoadStage  ; takes r2

	pop r3
	pop r2
	pop r1

	rts

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
	
	loadn r5, #' '
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
					
				loadn r6, #5 
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
	push r3

	; DEBUG: Force display ISUIActive value at position 0
		load r0, ISUIActive
		loadn r1, #48  ; ASCII '0'
		add r0, r0, r1
		loadn r1, #0
		outchar r0, r1

	; if ui active skip normal rendering
		load r0, ISUIActive
		loadn r1, #1
		cmp r0, r1
		jeq ScreenRenderIndexUI
    
	; normal screen rendering
		loadn r0, #currentScreenIndexesChanged  	; Start pointer
		load r2, currentScreenIndexesChangedIndex   ; End pointer

		ScreenRenderIndex_Loop:
			cmp r0, r2  ; Checks if printing the end
			jeq ScreenRenderIndexExit
		
			loadi r1, r0  ; Load position to render
			call ScreenRenderIndex
		
			inc r0
			jmp ScreenRenderIndex_Loop
		jmp ScreenRenderIndexExit

	jmp ScreenRenderIndexExit

	; render UI ; workds the same as normal loop, but calls ScreenRenderUIIndex instead
	ScreenRenderIndexUI:

		loadn r0, #currentScreenIndexesChanged  	; Start address
		load r2, currentScreenIndexesChangedIndex   ; End adddres

		ScreenRenderIndexUI_loop:
			cmp r0, r2
			jeq ScreenRenderIndexExit ; if start and end are equal, exit the loop

			loadi r1, r0 ; gets index to render
			call ScreenRenderUIIndex

			inc r0
			jmp ScreenRenderIndexUI_loop


	ScreenRenderIndexExit:

	; Unset Printing Color
		loadn r0, #0 
		store currentPrintingColor, r0

    ; Reset pointer to beginning
		loadn r0, #currentScreenIndexesChanged
		store currentScreenIndexesChangedIndex, r0
		
	pop r3
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
	push r0
    push r1
    push r2
    
    loadn r0, #0 
    loadn r2, #1199

	FullScreenRenderIndex_Loop:
    	cmp r0, r2  ; Checks if printing the end
    	jeq FullScreenRenderIndexExit
    
    	call SetIndexChanged
    
    	inc r0
    	jmp FullScreenRenderIndex_Loop

	FullScreenRenderIndexExit:
    
    pop r2
    pop r1
	pop r0

    rts

FullScreenUIPrint:   ; Prints what is in the UIBuffer
	push r0
    push r1
    push r2
	push r3
	push r4
    
    loadn r0, #0 
    loadn r2, #1199
	load r3, currentUILayer

	FullScreenRenderUIIndex_Loop:
    	cmp r0, r2  ; Checks if printing the end
    	jeq FullScreenRenderUIIndexExit
    
		loadi r4, r3
		outchar r4, r0
		

		inc r3
    	inc r0
    	jmp FullScreenRenderUIIndex_Loop

	FullScreenRenderUIIndexExit:

	pop r4
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

ScreenRenderIndex:   ; < , ScreenIndex>
	
	push r0
	push r1
	push r2
	push r3	;r0 = UICurentlySelectedElement: 
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
	loadn r3, #' '
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

ScreenRenderUIIndex:   ; < ,ScreenIndex>        ; need to take a look

	push r0
	push r1
	push r2
	push r3

	;load r0, currentUILayer
	;r1 index to render
	; current printing color can be set 

	; checks printing color

		load r2, currentPrintingColor
		loadn r0, #1
		cmp r0, r2
		jne ScreenRenderUIIndex_UsePassedColor

			ScreenRenderUIIndex_UseDefaultColor:

				load r2, uiLayerColor

		ScreenRenderUIIndex_UsePassedColor:

	load r0, currentUILayer

	add r0, r0, r1 ; 
	loadi r0, r0   ; gets value in the ui layer at index r1

	; check if char = 0. 
	; loadn r3, #0
	; cmp r3, r0
	; jeq ScreenRenderUIIndex_SkipZero

	add r0, r0, r2 ; gets colored character
	outchar r0, r1 ; outputs character r0 in position r1 ; must check if it is a zero

	ScreenRenderUIIndex_SkipZero:

	pop r3
	pop r2
	pop r1
	pop r0

	rts

ScreenRenderUIChanged: 

	push r0
	push r1
	push r2

	loadn r0, #currentScreenIndexesChanged  	; Start address
	load r2, currentScreenIndexesChangedIndex   ; End adddres

		ScreenRenderUIChanged_loop:
			cmp r0, r2
			jeq ScreenRenderUIChanged_Exit ; if start and end are equal, exit the loop

			loadi r1, r0 ; gets index to render
			call ScreenRenderUIIndex

			inc r0
			jmp ScreenRenderUIChanged_loop

	ScreenRenderUIChanged_Exit:

	loadn r0, #currentScreenIndexesChanged
	store currentScreenIndexesChangedIndex, r0


	pop r2
	pop r1
	pop r0

	rts

ScreenRenderChanged: 

	push r0
	push r1
	push r2

	loadn r0, #currentScreenIndexesChanged  	; Start address
	load r2, currentScreenIndexesChangedIndex   ; End adddres

		ScreenRenderChanged_loop:
			cmp r0, r2
			jeq ScreenRenderChanged_Exit ; if start and end are equal, exit the loop

			loadi r1, r0 ; gets index to render
			call ScreenRenderIndex

			inc r0
			jmp ScreenRenderChanged_loop

	ScreenRenderChanged_Exit:

	loadn r0, #currentScreenIndexesChanged
	store currentScreenIndexesChangedIndex, r0


	pop r2
	pop r1
	pop r0

	rts

SetIndexChanged: ; <index>
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

SquareFinderSetIndexChanged: ; < , index>
    ; r1 = index
    
    push r2
    push r3
    
    load r2, currentScreenIndexesChangedIndex  ; Get current write pointer
    
    storei r2, r1  ; Write new position
    inc r2

    store currentScreenIndexesChangedIndex, r2  ; Save updated pointer
    
    pop r3
    pop r2
    rts

RLEDecoder:   ; (r0 <- <r1>)
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

IndirectCall:  ; <r7 = Function Address>
    push r7
    rts

;TODO:
RLEEncoder:

	rts

RLETraverser:   <target index, index in UI stack>
				; needs to traverse the rle string looking for a single char eficiently if called multiple times in sequence
	
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7

	; r0 is the target index
	; r1 is the target RLE   [index In Ui stack] 

	mov r3, r1
	;mov r7, r1

	; load r1, RLE
		loadn r2, #UIStack
		add r1, r2, r1
		loadi r1, r1    ; UIobject
		loadn r2, #4	
		add r1, r2, r1
		loadi r1, r1    ; RLE

	; Gets Buffered Data
		add r2, r3, r3   ; r0 * 2 = index in RLETraverserBuffer
		loadn r3, #RLETraverserBuffer
		add r3, r3, r2     ; Buffered Data for UI in index of the UIStack

		mov r5, r3

		loadi r2, r3       ; Index in screen of the buffered data
		inc r3
		loadi r3, r3       ; How many counts were traversed
		dec r3

	; r0 = target index, r1 = RLE, r2 = buffered index, r3 = shift in RLE

	; Check which strategy to use. Increasing or Decreasing

		cmp r0, r2
		jeg RLETraverser_Increasing    ; r0 >= r2

		jmp RLETraverser_Decreasing    ; r0 < r2

	RLETraverser_Increasing:

		mov r4, r2

		RLETraverser_Increasing_Loop:

			mov r2, r4      ; new buffered
			inc r3 ; char
			mov r6, r3
			inc r3 ; count
			add r4, r1, r3
			loadi r4, r4   ; Count of the next char
			add r4, r4, r2 ; Index of the next char

			cmp r0, r4
			jeg RLETraverser_Increasing_Loop    
				; r2 < r0 < r4   -> get char from r6

				; buffer new data
					storei r5, r2
					loadn r7, #2
					div r3, r3, r7
					inc r5
					storei r5, r3

				; get char
					add r1, r1, r6
					loadi r0, r1
					; r0 = char

		jmp RLETraverser_Continue

	RLETraverser_Decreasing:

		mov r4, r2

		RLETraverser_Decreasing_Loop:

			mov r2, r4      ; new buffered
			dec r3 ; char
			mov r6, r3
			dec r3 ; count
			add r4, r1, r3
			loadi r4, r4   ; Count of the next object
			sub r4, r4, r2 ; count of the next char

			cmp r0, r4
			jle RLETraverser_Decreasing_Loop    
				; r2 > r0 > r4   -> get char from r6

				; buffer new data
					storei r5, r2
					loadn r7, #2
					div r3, r3, r7
					inc r5
					storei r5, r3

				; get char
					add r1, r1, r6
					loadi r0, r1
					; r0 = char

		jmp RLETraverser_Continue


	RLETraverser_Continue:


	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	; r0 = char in target index of the decoded RLE

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

	load r0, currentBehaviourLayer
	loadi r1, r2

	call RLEDecoder
	inc r2

	loadi r1, r2
	store curentTopology, r1
	
	pop r2
	pop r1
	pop r0

	rts

;------- UI
SquareFinder: ;<Start, End> ; function must be an ID because there is no indirect call. Same for Behaviour *sad emoji*
	; given two positions, can apply a function in every square marked by these positions in a specific buffer

	push r0 ; Start
	push r1 ; 
	push r2 ; const 40; Screen With
	push r3 ; End
	push r4 ; start x
	push r5 ; start y
	push r6 ; end x
	push r7 ; end y


	; find x and y of start and end ; y will overide the start and end positions in r0 and r1 

		loadn r2, #40
		mod r4, r0, r2 ; x start pos
		div r5, r0, r2 ; y start pos

		mod r6, r1, r2 ; x end pos
		div r7, r1 ,r2 ; y end pos

	; r0 and r1 are now free

	SquareFinder_loop:

		; set x to start
		mov r0, r4 
		
		SquareFinder_xloop:
		cmp r0, r6
		jgr SquareFinder_xloop_exit

			; set y to start
			mov r3, r5

			SquareFinder_yloop:
			cmp r3, r7
			jgr SquareFinder_yloop_exit

				mul r1, r3, r2 ; Row times 40
				add r1, r1, r0   ; + colum
				;r1 must is the screen index
				call SquareFinderSetIndexChanged

				inc r3
				jmp SquareFinder_yloop

			SquareFinder_yloop_exit:
			
			inc r0 ; next X
			jmp SquareFinder_xloop

		SquareFinder_xloop_exit:


	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts

UICall: 	; <UI element>  Pushes element in stack, Calls: UIDrawToBuffer, SquareFinder<0> ; sets the screen SetIndexChanged.  
			; calls a UI element, and pushes the stack 
			; takes r0 as the poiter to the UI element

			push r0
			push r1
			push r2
			push r3
			push r4
			push r5  ; <UIElement>

			; UI object : Var #5  <FunctionID, StartPos, EndPos, Color, RLE>
			mov r5, r0 ;UI Element address; saved to r5

			; Prepare DATA

					; Start Pos - r0
						inc r5   ; UI Element second Address
						loadi r0, r5   ; gets start pos from second address

					; travel UIObject data
						inc r5 ; end pos
						inc r5 ; default color of element
						inc r5 ; Pointer to the Addres of the RLE 

					; RLE Addres - r1
						loadi r1, r5  ; r0, contains the address (first value) of the RLE

					; color - r2
						load r2,  currentPrintingColor

			; first drawing of the element

				;; r0 = Start index
				;; r1 = RLE address
				call UIDrawToBuffer ; <StartIndex, <UIElemenent_RLE>>  

				;; r0 is still the start Index as UIDrawToBuffer preserves it
				;; r1 must be end pos

				dec r5 ; default color of element
				dec r5 ; end pos

				loadi r1, r5

				loadn r3, #0
				call SquareFinder  ; Updates currentScreenIndexesChanged

				call FullScreenUIPrint

			; Pushing the element into the stack

				load r1, UIStackPointer
				inc r1   ; gets next addres in the stack

				; gets UI element to add ; r5 is already the addres of the UIElement
				dec r5  ; default color
				dec r5  ; UIAddress
				mov r0, r5

				storei r1, r0
				store UIStackPointer, r1

			loadn r0, #1
			store ISUIActive, r0

			; DEBUG
				loadn r0, #currentScreenIndexesChanged
				load r1, currentScreenIndexesChangedIndex
				call Stack_getLength

			loadn r0, #0
			store UICurentlySelectedElement, r0
			store UIPreviousSelectedElement, r0

			pop r5
			pop r4
			pop r3
			pop r2
			pop r1
			pop r0

	rts

UIClose:

	push r0
	push r1
	push r2

	loadn r0, #0
	loadn r1, #UICurentlySelectedElement
	storei r1, r0 ; reset id
	inc r1 
	storei r1, r0 ; reset start
	inc r1 
	storei r1, r0 ; reset end

	load r2, UIStackPointer
	mov r0, r2
	dec r0
	store UIStackPointer, r0	

	loadn r1, #UIStack
	cmp r0, r1 ; IS the stack in the end?
	jne UIClose_UIIsStillActive

		loadn r0, #0
		store ISUIActive, r0

		; marks area for redraw

		; r2 = stack Pointer
		loadi r2, r2  ; UIObject
		inc r2

		loadi r0, r2
		inc r2

		loadi r1, r2

		call SquareFinder

		call ScreenRenderChanged


		jmp UIClose_end

	UIClose_UIIsStillActive:

		; redraw UI Buffer


		; Marks Area for redraw

		; r2 = stack Pointer
		loadi r2, r2  ; UIObject
		inc r2

		loadi r0, r2
		inc r2

		loadi r1, r2

		loadn r0, #574
		loadn r1, #667

		call SquareFinder

		call ScreenRenderChanged


	UIClose_end:
	
	pop r2
	pop r1
	pop r0

	rts

UIInteractibleElementComputeShift:  ;<Shift> 

    push r1
    push r2
    push r3
    push r4

    load r1, UICurentlySelectedElement
    store UIPreviousSelectedElement, r1 

    load r2, UIStackPointer
    loadi r2, r2
    loadn r3, #5 
    add r2, r2, r3
    loadi r2, r2 ; r2 = InteractibleElementsNum

    add r1, r1, r0 ; r1 = current + shift

    ; check underflow
    loadn r4, #65535
    cmp r1, r4
    jne UIElementComputeShift_Continue
        mov r1, r2  ; r1 = InteractibleElementsNum - 1
		dec r1

    UIElementComputeShift_Continue:
        mod r1, r1, r2 
        store UICurentlySelectedElement, r1

    pop r4
    pop r3
    pop r2
    pop r1
    rts

UIInteractibleElementHighLightRender:   ; <UIElement>
 
    push r0 ; UIElement
	push r1 
	push r2
	push r3


    ; get InteractibleElementsList

		loadn r2, #6
		add r0, r0, r2
		loadi r0, r0 ; list of interactible elements

	; Get Selected Element

		load r1, UICurentlySelectedElement

	push r0
	; render

		; Find Selected Element
		
			add r2, r0, r1 
			loadi r2, r2    ; Selected Interactible Element   <Start, END, Func>
			mov r5, r2

			; render highlight

				; set highlight color
		
					load r3, uIHighlightColor
					store currentPrintingColor, r3

				; Set currentScreenIndexesChanged

					push r0
					push r1

					mov r2, r5
					loadi r0, r2 ; start pos
					inc r2
					loadi r1, r2 ; end pos

					mov r7, r1
					mov r6, r0

					call SquareFinder

					pop r1
					pop r0 

				call ScreenRenderUIChanged

	pop r0

	; Repeat For UIPreviousSelectedElement

		; Get Previous Selected Element

			load r1, UIPreviousSelectedElement

		; Find Selected Element
			
			add r2, r0, r1 
			loadi r2, r2    ; Selected Interactible Element   <Start, END, Func>

			; render highlight

				; set Printing color
		
					load r3, uiLayerColor
					store currentPrintingColor, r3

				; Set currentScreenIndexesChanged

					push r0
					push r1

					loadi r0, r2 ; start pos
					inc r2
					loadi r1, r2 ; end pos

					call SquareFinder

					pop r1
					pop r0 

				call ScreenRenderUIChanged




	pop r3
	pop r2
	pop r1
	pop r0

	rts

UISelectedInteractibleElementInteract: ; <UIElement>

	push r0  ; UIElement
	push r1
	push r2

	; get InteractibleElementsList

		loadn r2, #6   
		add r0, r0, r2
		loadi r0, r0 ; list of interactible elements

	; Get Selected Element

		load r1, UICurentlySelectedElement

	;  Find Selected Element
		add r2, r0, r1 
		loadi r2, r2    ; Selected Interactible Element   <Start, END, Func>

	; GET Function 

		loadn r0, #2
		add r2, r2, r0
		loadi r0, r2 ; Function

		push r7
		mov r7, r0
		call IndirectCall  ; Call Function
		pop r7
	
	pop r2
	pop r1
	pop r0

	rts

UIDrawToBuffer:   ; <StartIndex, UIElemenent_RLE> 
					
	; prints to the buffer. But values of zero do not overide what was there	
	; takes r1 as the Adderss the RLE of the UI element 

	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	; r1 is the string it will decode

	load r3, currentUILayer ; addres the first position of the ui leayer
	add r0, r0, r3 ; where in memeory to write
	
	loadn r3, #0

	UIDrawToBuffer_Loop:

		loadi r4, r1    ;  r1 is the address to the fisrt string character ;count
		mov r2, r4 ; loop lengh ; count

		cmp r2, r3 ; if count zero exit 
		jeq UIDrawToBuffer_Exit

		inc r1   ; next string address
		loadi r4, r1	; looped character
		inc r1 ; sets r1 to the next count

		UIDrawToBufferDecode_Loop:     
			
			cmp r2, r3   ; checks if remaining lengh is 0
			jeq UIDrawToBufferDecode_Exit
			
				cmp r4, r3;  ; r3 = 0 , r4 is char
				jeq UI_Draw_SkipUIOveride

				storei r0, r4  ; stores char in index memory r0 ; addres of the UILayer

				UI_Draw_SkipUIOveride:
				inc r0
				dec r2; decrements loop lenght
				
				jmp UIDrawToBufferDecode_Loop ; in loop exit, needs to get chew count and char
	
			UIDrawToBufferDecode_Exit:   ; jumps here if count is zero

		jmp UIDrawToBuffer_Loop    ; Volta ao início do loop para continuar imprimindo.



    UIDrawToBuffer_Exit:
	pop r5	
	pop r4	; Resgata os valores dos registradores utilizados na Subrotina da Pilha
	pop r3
	pop r2
	pop r1
	pop r0
	rts			

UIHandeler:

	push r7
	push r1

	loadn r7, #0
	load r1, ISUIActive
	cmp r7, r1
	jeq UIHandeler_notActive

	; UI is active

		load r7, UIStackPointer 
		loadi r7, r7 ; Ui element addres
		loadi r7, r7 ; UIFunction

		call IndirectCall

		jmp UIHandler_exit

	UIHandeler_notActive:

		; if input is esc
			load r7, InputedChar
			loadn r1, #27 ; ESC
			cmp r7, r1
			jne UIHandeler_ESCUIcall

			loadn r7, #UIConfirmationPrompt
			call UICall

			UIHandeler_ESCUIcall:

	UIHandler_exit:

	pop r1
	pop r7

	rts

Stack_getLength: ;     Gets the diference between the stack start and the pointer

	; r0 stack
	; r1 stack pointer

	sub r0, r1, r0

	rts

TODO:
UIRedraw:   ; <> Rebuilds UI Buffer from the stack  
			; Travels the stack and reconstruncting the current UI Layer, Must be able to determine the size and all positions that must be redraw
			; takes r0 and r1, as start and end position of the ui element. assumes a retengular element
			; if it rebuilds and encounters a ui element that is a zero, it must go deeeper in the stack
			; if the index is not zero, do not overide
	rts



;--------- Behavior
; 
; 
; GameObject <sprite, SpriteLayer, Behavior FunctionID> ; FunctionID will simply be the sprite value, no need for a separate value
;                                                         Will leave this here so in the future i can implment a calli instruction
; 
LoadGameObjects: ; Must be inserted in LoadStage

	CallBehaviorIndex:    ; calls from the prop layer once


		rts

	CallBehaviorBackground:   ;  Ticks all behaviors of Background in level


		rts

	; Background Functions

		; Goal

		; Conveyour Belt

	; Prop Functions 

		; zero and Space

			DoNothing:
				rts

		; Wall

			BlockMovement: 
				push r0
				loadn r0, #1
				store moveBlocked, r0
				pop r0
				rts

		; Box

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

				loadn r6, #0
				store moveBlocked, r6
				
				
				load r6, currentPropLayer
				add r2, r6, r0 ; memory addres of r0 position in propLayer

				loadi r4, r2
				loadn r3, #'@'
				cmp r4, r3

				jne endboxmv

					sub r2, r0, r1 ; playerMoveDirection ; can be infered from r0 and r1
					; r2 will become a movent direction
				
					;if r2 = 3 (Left: -1 = 65535)
						loadn r3, #65535
						cmp r3, r2
						jeq boxMvLeft
				
					;if r2 = 1 (Right: +1)
						loadn r3, #1 
						cmp r3, r2
						jeq boxMvRight

					;if r2 = 2 (Up: -40 = 65496)
						loadn r3, #65496	
						cmp r3, r2
						jeq boxMvUp

					;if r2 = 4 (Down: +40)
						loadn r3, #40
						cmp r3, r2
						jeq boxMvDown
					
					; code will reach here if the boxes cross the topology bounderies

					; torus specific fix; will need to be moved to a function with a pointer in 
					; current topology manager or solver
						
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

					; if new position has Wall
				
					load r6, currentPropLayer
					add r2, r6, r0 ; memory address of r0 position in propLayer

					loadi r4, r2  ; char in address of r0  in propLayer

					loadn r3, #BehaviorJumpDict
					add r3, r3, r4

					push r0
					push r7
					loadi r7, r3
					call IndirectCall  ; Execute the Function of the next position
					pop r7
					pop r0

					
					;if valid
					load r3, moveBlocked
					loadn r4, #1
					cmp r3, r4
					jeq checkPushMovement_skipMove

						;MoveInMemory
						call MoveInMemory
					
						call SetIndexChanged

						checkPushMovement_skipMove:

				endboxmv:
				

				
				pop r6
				pop r5
				pop r4
				pop r3
				pop r2
				pop r1
				pop r0
				rts

ChechkBehavior:

; DATA TYPES
;____________________________________

; List: Var #lenght   <Element>

; InteractibleElement: var #4 <ID, Start, End, Function>

; UI Object : Var #6  <FunctionID, StartPos, EndPos, Color, RLE, InteractibleElementsNum ,InteractibleElementsList>

; Layer : var #1200 

; RLE : var#Lenght <Count, Object>

; Level : Var #5  ;<HUD, Props, Background, Behavior, Topology>



; Static Definitions
;____________________________________
; UI Data  ; UI object : Var #7  <Function, StartPos, EndPos, Color, RLE, InteractibleElementsNum ,InteractibleElementsList>

	UIConfirmationPrompt: var #7

		static UIConfirmationPrompt + #0,  #UIConfirmationPromptFunction
		static UIConfirmationPrompt + #1, #573
		static UIConfirmationPrompt + #2, #666
		static UIConfirmationPrompt + #3, #0 ; white
		static UIConfirmationPrompt + #4, #ConfirmationPromptRLE
        static UIConfirmationPrompt + #5, #2
        static UIConfirmationPrompt + #6, #UIConfirmationPromptInteractibleElementsList

		UIConfirmationPromptFunction:

			push r0
			push r1
			push r2
			push r3

			; Input

				load r0, InputedChar

				;DEBUG: display InputedChar value at position 1

					push r1
					push r2

					mov r1, r0
					loadn r2, #1
					outchar r1, r2

					pop r2
					pop r1

				;if a
					loadn r1, #'a'  
					cmp r0, r1
					jeq UIConfirmationPromptFunction_Ifa

				;if d
					loadn r1, #'d'  
					cmp r0, r1
					jeq UIConfirmationPromptFunction_Ifd

				;if esc:
					loadn r1, #27 ; ESC
					cmp r0, r1
					jeq UIConfirmationPromptFunction_IfESC

				;if enter
					loadn r1, #13 ; Enter
					cmp r0, r1
					jeq UIConfirmationPromptFunction_Ifenter

				;else:
					jmp UIConfirmationPrompt_Continue

				UIConfirmationPromptFunction_Ifa:		

					loadn r1, #1
					store UICurentlySelectedElementChanged, r1

					loadn r0, #65535 ; -1 shift
					jmp UIConfirmationPromptFunction_ResolveActive
								
				UIConfirmationPromptFunction_Ifd:

					loadn r1, #1
					store UICurentlySelectedElementChanged, r1
							
					loadn r0, #1 ; shift
					jmp UIConfirmationPromptFunction_ResolveActive

				UIConfirmationPromptFunction_IfESC:

					call UIClose
					jmp UIConfirmationPrompt_Exit

				UIConfirmationPromptFunction_Ifenter:

					loadn r0, #UIConfirmationPrompt
					call UISelectedInteractibleElementInteract
					jmp UIConfirmationPrompt_Continue

			UIConfirmationPromptFunction_ResolveActive:

				call UIInteractibleElementComputeShift

				loadn r0, #UIConfirmationPrompt
				call UIInteractibleElementHighLightRender


			UIConfirmationPrompt_Continue:

				;DEBUG: Force display UICurentlySelectedElement value at position 2

					push r1
					push r2

					load r1, UICurentlySelectedElement
					loadn r2, #48  ; ASCII '0'
					add r1, r1, r2
					loadn r2, #2
					outchar r1, r2

					pop r2
					pop r1


			UIConfirmationPrompt_Exit:

			pop r3
			pop r2
			pop r1
			pop r0
			rts

		ConfirmationPromptRLE : var #39  ; 19 runs, 39 words total

			static ConfirmationPromptRLE + #0, #1      ; count
			static ConfirmationPromptRLE + #1, #42    ; '*' (ASCII 42)
			static ConfirmationPromptRLE + #2, #12      ; count
			static ConfirmationPromptRLE + #3, #45    ; '-' (ASCII 45)
			static ConfirmationPromptRLE + #4, #1      ; count
			static ConfirmationPromptRLE + #5, #42    ; '*' (ASCII 42)
			static ConfirmationPromptRLE + #6, #26      ; count
			static ConfirmationPromptRLE + #7, #0    ; 0 (ASCII 32)
			static ConfirmationPromptRLE + #8, #1      ; count
			static ConfirmationPromptRLE + #9, #124    ; '|' (ASCII 124)
			static ConfirmationPromptRLE + #10, #2      ; count
			static ConfirmationPromptRLE + #11, #32    ; ' ' (ASCII 32)
			static ConfirmationPromptRLE + #12, #1      ; count
			static ConfirmationPromptRLE + #13, #78    ; 'N' (ASCII 78)
			static ConfirmationPromptRLE + #14, #1      ; count
			static ConfirmationPromptRLE + #15, #79    ; 'O' (ASCII 79)
			static ConfirmationPromptRLE + #16, #3      ; count
			static ConfirmationPromptRLE + #17, #32    ; ' ' (ASCII 32)
			static ConfirmationPromptRLE + #18, #1      ; count
			static ConfirmationPromptRLE + #19, #89    ; 'Y' (ASCII 89)
			static ConfirmationPromptRLE + #20, #1      ; count
			static ConfirmationPromptRLE + #21, #101    ; 'e' (ASCII 101)
			static ConfirmationPromptRLE + #22, #1      ; count
			static ConfirmationPromptRLE + #23, #115    ; 's' (ASCII 115)
			static ConfirmationPromptRLE + #24, #2      ; count
			static ConfirmationPromptRLE + #25, #32    ; ' ' (ASCII 32)
			static ConfirmationPromptRLE + #26, #1      ; count
			static ConfirmationPromptRLE + #27, #124    ; '|' (ASCII 124)
			static ConfirmationPromptRLE + #28, #26      ; count
			static ConfirmationPromptRLE + #29, #0    ; 0
			static ConfirmationPromptRLE + #30, #1      ; count
			static ConfirmationPromptRLE + #31, #42    ; '*' (ASCII 42)
			static ConfirmationPromptRLE + #32, #12      ; count
			static ConfirmationPromptRLE + #33, #45    ; '-' (ASCII 45)
			static ConfirmationPromptRLE + #34, #1      ; count
			static ConfirmationPromptRLE + #35, #42    ; '*' (ASCII 42)
			static ConfirmationPromptRLE + #36, #0      ; terminator

        UIConfirmationPromptInteractibleElementsList: var #2
		
			; InteractibleElement <Start, End, Function>
			static UIConfirmationPromptInteractibleElementsList + #0, #UIConfirmationPromptInteractibleElementONE
			static UIConfirmationPromptInteractibleElementsList + #1, #UIConfirmationPromptInteractibleElementTWO

				UIConfirmationPromptInteractibleElementONE: var #3
					static UIConfirmationPromptInteractibleElementONE + #0, #616
					static UIConfirmationPromptInteractibleElementONE + #1, #617
					static UIConfirmationPromptInteractibleElementONE + #2, #UIConfirmationPromptInteractibleElementONE_Function ; FUNCTION

					UIConfirmationPromptInteractibleElementONE_Function:
						call UIClose
						rts

				UIConfirmationPromptInteractibleElementTWO: var #3
					static UIConfirmationPromptInteractibleElementTWO + #0, #620
					static UIConfirmationPromptInteractibleElementTWO + #1, #623
					static UIConfirmationPromptInteractibleElementTWO + #2, #UIConfirmationPromptInteractibleElementTWO_Function ; FUNCTION

					UIConfirmationPromptInteractibleElementTWO_Function:

						push r0
						loadn r0, #1
						store UISignal, r0
						pop r0

						call UIClose

						rts

    ;MainMenu

		MainMenu: var #7

			static MainMenu + #0, #MainMenuFunction
			static MainMenu + #1, #0 ;#81
			static MainMenu + #2, #1199 ;#707
			static MainMenu + #3, #0 ; white
			static MainMenu + #4, #MainMenuRLE
			static MainMenu + #5, #2
			static MainMenu + #6, #MainMenuInteractibleElementsList

			MainMenuFunction:

				push r0
				push r1
				push r2
				push r3

				; Input

					load r0, InputedChar

					;DEBUG: display InputedChar value at position 1

						push r1
						push r2

						mov r1, r0
						loadn r2, #1
						outchar r1, r2

						pop r2
						pop r1

					;if w
						loadn r1, #'w'  
						cmp r0, r1
						jeq MainMenuFunction_Ifw

					;if d
						loadn r1, #'s'  
						cmp r0, r1
						jeq MainMenuFunction_Ifs

					;if enter
						loadn r1, #13 ; Enter
						cmp r0, r1
						jeq MainMenuFunction_Ifenter

					;else:
						jmp MainMenu_Continue

					MainMenuFunction_Ifw:		

						loadn r1, #1
						store UICurentlySelectedElementChanged, r1

						loadn r0, #65535 ; -1 shift
						jmp MainMenuFunction_ResolveActive
									
					MainMenuFunction_Ifs:

						loadn r1, #1
						store UICurentlySelectedElementChanged, r1
								
						loadn r0, #1 ; shift
						jmp MainMenuFunction_ResolveActive


					MainMenuFunction_Ifenter:

						loadn r0, #MainMenu
						call UISelectedInteractibleElementInteract
						jmp MainMenu_Continue

				MainMenuFunction_ResolveActive:

					call UIInteractibleElementComputeShift

					loadn r0, #MainMenu
					call UIInteractibleElementHighLightRender


				MainMenu_Continue:

					;DEBUG: Force display UICurentlySelectedElement value at position 2

						push r1
						push r2

						load r1, UICurentlySelectedElement
						loadn r2, #48  ; ASCII '0'
						add r1, r1, r2
						loadn r2, #2
						outchar r1, r2

						pop r2
						pop r1

				MainMenu_Exit:

				pop r3
				pop r2
				pop r1
				pop r0
				rts

			MainMenuRLE : var #285  ; 142 runs, 285 words total

				; Original: 1200 words, RLE: 285 words, saved 76.2%
				; RLE encoded level data

				static MainMenuRLE + #0, #84      ; count
				static MainMenuRLE + #1, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #2, #6      ; count
				static MainMenuRLE + #3, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #4, #7      ; count
				static MainMenuRLE + #5, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #6, #3      ; count
				static MainMenuRLE + #7, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #8, #23      ; count
				static MainMenuRLE + #9, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #10, #1      ; count
				static MainMenuRLE + #11, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #12, #1      ; count
				static MainMenuRLE + #13, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #14, #2      ; count
				static MainMenuRLE + #15, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #16, #2      ; count
				static MainMenuRLE + #17, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #18, #1      ; count
				static MainMenuRLE + #19, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #20, #1      ; count
				static MainMenuRLE + #21, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #22, #3      ; count
				static MainMenuRLE + #23, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #24, #1      ; count
				static MainMenuRLE + #25, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #26, #2      ; count
				static MainMenuRLE + #27, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #28, #1      ; count
				static MainMenuRLE + #29, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #30, #1      ; count
				static MainMenuRLE + #31, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #32, #1      ; count
				static MainMenuRLE + #33, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #34, #1      ; count
				static MainMenuRLE + #35, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #36, #3      ; count
				static MainMenuRLE + #37, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #38, #1      ; count
				static MainMenuRLE + #39, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #40, #3      ; count
				static MainMenuRLE + #41, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #42, #2      ; count
				static MainMenuRLE + #43, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #44, #3      ; count
				static MainMenuRLE + #45, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #46, #1      ; count
				static MainMenuRLE + #47, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #48, #3      ; count
				static MainMenuRLE + #49, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #50, #7      ; count
				static MainMenuRLE + #51, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #52, #1      ; count
				static MainMenuRLE + #53, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #54, #1      ; count
				static MainMenuRLE + #55, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #56, #1      ; count
				static MainMenuRLE + #57, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #58, #1      ; count
				static MainMenuRLE + #59, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #60, #1      ; count
				static MainMenuRLE + #61, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #62, #1      ; count
				static MainMenuRLE + #63, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #64, #1      ; count
				static MainMenuRLE + #65, #92    ; '\' (ASCII 92)
				static MainMenuRLE + #66, #1      ; count
				static MainMenuRLE + #67, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #68, #1      ; count
				static MainMenuRLE + #69, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #70, #1      ; count
				static MainMenuRLE + #71, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #72, #1      ; count
				static MainMenuRLE + #73, #92    ; '\' (ASCII 92)
				static MainMenuRLE + #74, #1      ; count
				static MainMenuRLE + #75, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #76, #1      ; count
				static MainMenuRLE + #77, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #78, #1      ; count
				static MainMenuRLE + #79, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #80, #1      ; count
				static MainMenuRLE + #81, #92    ; '\' (ASCII 92)
				static MainMenuRLE + #82, #1      ; count
				static MainMenuRLE + #83, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #84, #1      ; count
				static MainMenuRLE + #85, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #86, #1      ; count
				static MainMenuRLE + #87, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #88, #1      ; count
				static MainMenuRLE + #89, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #90, #1      ; count
				static MainMenuRLE + #91, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #92, #1      ; count
				static MainMenuRLE + #93, #92    ; '\' (ASCII 92)
				static MainMenuRLE + #94, #1      ; count
				static MainMenuRLE + #95, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #96, #1      ; count
				static MainMenuRLE + #97, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #98, #1      ; count
				static MainMenuRLE + #99, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #100, #1      ; count
				static MainMenuRLE + #101, #96    ; '`' (ASCII 96)
				static MainMenuRLE + #102, #1      ; count
				static MainMenuRLE + #103, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #104, #1      ; count
				static MainMenuRLE + #105, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #106, #1      ; count
				static MainMenuRLE + #107, #45    ; '-' (ASCII 45)
				static MainMenuRLE + #108, #1      ; count
				static MainMenuRLE + #109, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #110, #1      ; count
				static MainMenuRLE + #111, #41    ; ')' (ASCII 41)
				static MainMenuRLE + #112, #1      ; count
				static MainMenuRLE + #113, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #114, #1      ; count
				static MainMenuRLE + #115, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #116, #1      ; count
				static MainMenuRLE + #117, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #118, #6      ; count
				static MainMenuRLE + #119, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #120, #1      ; count
				static MainMenuRLE + #121, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #122, #1      ; count
				static MainMenuRLE + #123, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #124, #1      ; count
				static MainMenuRLE + #125, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #126, #1      ; count
				static MainMenuRLE + #127, #92    ; '\' (ASCII 92)
				static MainMenuRLE + #128, #3      ; count
				static MainMenuRLE + #129, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #130, #1      ; count
				static MainMenuRLE + #131, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #132, #1      ; count
				static MainMenuRLE + #133, #46    ; '.' (ASCII 46)
				static MainMenuRLE + #134, #2      ; count
				static MainMenuRLE + #135, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #136, #1      ; count
				static MainMenuRLE + #137, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #138, #3      ; count
				static MainMenuRLE + #139, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #140, #1      ; count
				static MainMenuRLE + #141, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #142, #2      ; count
				static MainMenuRLE + #143, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #144, #1      ; count
				static MainMenuRLE + #145, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #146, #2      ; count
				static MainMenuRLE + #147, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #148, #1      ; count
				static MainMenuRLE + #149, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #150, #1      ; count
				static MainMenuRLE + #151, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #152, #1      ; count
				static MainMenuRLE + #153, #44    ; ',' (ASCII 44)
				static MainMenuRLE + #154, #1      ; count
				static MainMenuRLE + #155, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #156, #1      ; count
				static MainMenuRLE + #157, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #158, #1      ; count
				static MainMenuRLE + #159, #92    ; '\' (ASCII 92)
				static MainMenuRLE + #160, #2      ; count
				static MainMenuRLE + #161, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #162, #1      ; count
				static MainMenuRLE + #163, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #164, #1      ; count
				static MainMenuRLE + #165, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #166, #1      ; count
				static MainMenuRLE + #167, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #168, #13      ; count
				static MainMenuRLE + #169, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #170, #1      ; count
				static MainMenuRLE + #171, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #172, #1      ; count
				static MainMenuRLE + #173, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #174, #1      ; count
				static MainMenuRLE + #175, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #176, #12      ; count
				static MainMenuRLE + #177, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #178, #1      ; count
				static MainMenuRLE + #179, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #180, #3      ; count
				static MainMenuRLE + #181, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #182, #1      ; count
				static MainMenuRLE + #183, #47    ; '/' (ASCII 47)
				static MainMenuRLE + #184, #184      ; count
				static MainMenuRLE + #185, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #186, #1      ; count
				static MainMenuRLE + #187, #42    ; '*' (ASCII 42)
				static MainMenuRLE + #188, #14      ; count
				static MainMenuRLE + #189, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #190, #1      ; count
				static MainMenuRLE + #191, #42    ; '*' (ASCII 42)
				static MainMenuRLE + #192, #24      ; count
				static MainMenuRLE + #193, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #194, #1      ; count
				static MainMenuRLE + #195, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #196, #14      ; count
				static MainMenuRLE + #197, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #198, #1      ; count
				static MainMenuRLE + #199, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #200, #24      ; count
				static MainMenuRLE + #201, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #202, #1      ; count
				static MainMenuRLE + #203, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #204, #2      ; count
				static MainMenuRLE + #205, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #206, #1      ; count
				static MainMenuRLE + #207, #78    ; 'N' (ASCII 78)
				static MainMenuRLE + #208, #1      ; count
				static MainMenuRLE + #209, #69    ; 'E' (ASCII 69)
				static MainMenuRLE + #210, #1      ; count
				static MainMenuRLE + #211, #87    ; 'W' (ASCII 87)
				static MainMenuRLE + #212, #3      ; count
				static MainMenuRLE + #213, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #214, #1      ; count
				static MainMenuRLE + #215, #71    ; 'G' (ASCII 71)
				static MainMenuRLE + #216, #1      ; count
				static MainMenuRLE + #217, #65    ; 'A' (ASCII 65)
				static MainMenuRLE + #218, #1      ; count
				static MainMenuRLE + #219, #77    ; 'M' (ASCII 77)
				static MainMenuRLE + #220, #1      ; count
				static MainMenuRLE + #221, #69    ; 'E' (ASCII 69)
				static MainMenuRLE + #222, #2      ; count
				static MainMenuRLE + #223, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #224, #1      ; count
				static MainMenuRLE + #225, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #226, #24      ; count
				static MainMenuRLE + #227, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #228, #1      ; count
				static MainMenuRLE + #229, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #230, #14      ; count
				static MainMenuRLE + #231, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #232, #1      ; count
				static MainMenuRLE + #233, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #234, #24      ; count
				static MainMenuRLE + #235, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #236, #1      ; count
				static MainMenuRLE + #237, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #238, #1      ; count
				static MainMenuRLE + #239, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #240, #1      ; count
				static MainMenuRLE + #241, #67    ; 'C' (ASCII 67)
				static MainMenuRLE + #242, #1      ; count
				static MainMenuRLE + #243, #72    ; 'H' (ASCII 72)
				static MainMenuRLE + #244, #1      ; count
				static MainMenuRLE + #245, #79    ; 'O' (ASCII 79)
				static MainMenuRLE + #246, #1      ; count
				static MainMenuRLE + #247, #83    ; 'S' (ASCII 83)
				static MainMenuRLE + #248, #1      ; count
				static MainMenuRLE + #249, #69    ; 'E' (ASCII 69)
				static MainMenuRLE + #250, #2      ; count
				static MainMenuRLE + #251, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #252, #1      ; count
				static MainMenuRLE + #253, #76    ; 'L' (ASCII 76)
				static MainMenuRLE + #254, #1      ; count
				static MainMenuRLE + #255, #69    ; 'E' (ASCII 69)
				static MainMenuRLE + #256, #1      ; count
				static MainMenuRLE + #257, #86    ; 'V' (ASCII 86)
				static MainMenuRLE + #258, #1      ; count
				static MainMenuRLE + #259, #69    ; 'E' (ASCII 69)
				static MainMenuRLE + #260, #1      ; count
				static MainMenuRLE + #261, #76    ; 'L' (ASCII 76)
				static MainMenuRLE + #262, #1      ; count
				static MainMenuRLE + #263, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #264, #1      ; count
				static MainMenuRLE + #265, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #266, #24      ; count
				static MainMenuRLE + #267, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #268, #1      ; count
				static MainMenuRLE + #269, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #270, #14      ; count
				static MainMenuRLE + #271, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #272, #1      ; count
				static MainMenuRLE + #273, #124    ; '|' (ASCII 124)
				static MainMenuRLE + #274, #24      ; count
				static MainMenuRLE + #275, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #276, #1      ; count
				static MainMenuRLE + #277, #42    ; '*' (ASCII 42)
				static MainMenuRLE + #278, #14      ; count
				static MainMenuRLE + #279, #95    ; '_' (ASCII 95)
				static MainMenuRLE + #280, #1      ; count
				static MainMenuRLE + #281, #42    ; '*' (ASCII 42)
				static MainMenuRLE + #282, #492      ; count
				static MainMenuRLE + #283, #32    ; ' ' (ASCII 32)
				static MainMenuRLE + #284, #0      ; terminator

			MainMenuInteractibleElementsList: var #2
		
				; InteractibleElement <Start, End, Function>
				static MainMenuInteractibleElementsList + #0, #MainMenuInteractibleElementONE
				static MainMenuInteractibleElementsList + #1, #MainMenuInteractibleElementTWO

				MainMenuInteractibleElementONE: var #3
					static MainMenuInteractibleElementONE + #0, #535
					static MainMenuInteractibleElementONE + #1, #545
					static MainMenuInteractibleElementONE + #2, #MainMenuInteractibleElementONE_Function ; FUNCTION

					MainMenuInteractibleElementONE_Function:

						call UIClose

						; Load Level 1
							loadn r2, #TestLevel
							call LoadStage ; (r1)

						; positions player in level

							loadn r1, #currentPropLayer
							loadi r1, r1

							loadn r0, #80
							store playerPos, r0
					
							add r2, r1, r0
							loadn r0, #'A'

							storei r2, r0


						; first Print

							call FullScreenPrint

						rts

				MainMenuInteractibleElementTWO: var #3
					static MainMenuInteractibleElementTWO + #0, #614
					static MainMenuInteractibleElementTWO + #1, #626
					static MainMenuInteractibleElementTWO + #2, #MainMenuInteractibleElementTWO_Function ; FUNCTION

					MainMenuInteractibleElementTWO_Function:

						push r0
						loadn r0, #1
						store UISignal, r0
						pop r0

						call UIClose

						rts

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

; Level Data: Var #5  ;<HUD, Props, Background, Behavior, Topology>

	EmptyRLE: var #3
		static EmptyRLE + #0, #1200; count
		static EmptyRLE + #1, #0    ; 0
		static EmptyRLE + #2, #0     ; terminator

	ZeroRLE: var #3
		static ZeroRLE + #0, #1200; count
		static ZeroRLE + #1, #32    ; ' ' (ASCII 32)
		static ZeroRLE + #2, #0     ; terminator

	TestLevel: var #5

		static TestLevel + #0, #EmptyRLE    ; UI
		static TestLevel + #1, #TestLevelPropsRLE
		static TestLevel + #2, #TitleRLE ;Background
		static TestLevel + #3, #EmptyRLE ;Behaviour ; Will be infered from the Prop Layer and Background Layer in my game;
		static TestLevel + #4, #TestLevelTopology      ;Topology

		; Original: 1200 words, RLE: 187 words, saved 84.4%
		; RLE encoded level data
		TestLevelPropsRLE : var #187  ; 93 runs, 187 words total

			static TestLevelPropsRLE + #0, #28      ; count
			static TestLevelPropsRLE + #1, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #2, #1      ; count
			static TestLevelPropsRLE + #3, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #4, #39      ; count
			static TestLevelPropsRLE + #5, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #6, #1      ; count
			static TestLevelPropsRLE + #7, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #8, #39      ; count
			static TestLevelPropsRLE + #9, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #10, #1      ; count
			static TestLevelPropsRLE + #11, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #12, #39      ; count
			static TestLevelPropsRLE + #13, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #14, #1      ; count
			static TestLevelPropsRLE + #15, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #16, #39      ; count
			static TestLevelPropsRLE + #17, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #18, #1      ; count
			static TestLevelPropsRLE + #19, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #20, #39      ; count
			static TestLevelPropsRLE + #21, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #22, #1      ; count
			static TestLevelPropsRLE + #23, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #24, #39      ; count
			static TestLevelPropsRLE + #25, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #26, #1      ; count
			static TestLevelPropsRLE + #27, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #28, #39      ; count
			static TestLevelPropsRLE + #29, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #30, #1      ; count
			static TestLevelPropsRLE + #31, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #32, #39      ; count
			static TestLevelPropsRLE + #33, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #34, #1      ; count
			static TestLevelPropsRLE + #35, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #36, #25      ; count
			static TestLevelPropsRLE + #37, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #38, #9      ; count
			static TestLevelPropsRLE + #39, #35    ; '#' (ASCII 64)
			static TestLevelPropsRLE + #40, #5      ; count
			static TestLevelPropsRLE + #41, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #42, #1      ; count
			static TestLevelPropsRLE + #43, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #44, #25      ; count
			static TestLevelPropsRLE + #45, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #46, #1      ; count
			static TestLevelPropsRLE + #47, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #48, #7      ; count
			static TestLevelPropsRLE + #49, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #50, #1      ; count
			static TestLevelPropsRLE + #51, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #52, #5      ; count
			static TestLevelPropsRLE + #53, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #54, #1      ; count
			static TestLevelPropsRLE + #55, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #56, #25      ; count
			static TestLevelPropsRLE + #57, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #58, #1      ; count
			static TestLevelPropsRLE + #59, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #60, #7      ; count
			static TestLevelPropsRLE + #61, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #62, #1      ; count
			static TestLevelPropsRLE + #63, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #64, #5      ; count
			static TestLevelPropsRLE + #65, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #66, #1      ; count
			static TestLevelPropsRLE + #67, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #68, #25      ; count
			static TestLevelPropsRLE + #69, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #70, #1      ; count
			static TestLevelPropsRLE + #71, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #72, #7      ; count
			static TestLevelPropsRLE + #73, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #74, #1      ; count
			static TestLevelPropsRLE + #75, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #76, #5      ; count
			static TestLevelPropsRLE + #77, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #78, #1      ; count
			static TestLevelPropsRLE + #79, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #80, #25      ; count
			static TestLevelPropsRLE + #81, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #82, #1      ; count
			static TestLevelPropsRLE + #83, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #84, #7      ; count
			static TestLevelPropsRLE + #85, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #86, #1      ; count
			static TestLevelPropsRLE + #87, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #88, #5      ; count
			static TestLevelPropsRLE + #89, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #90, #1      ; count
			static TestLevelPropsRLE + #91, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #92, #25      ; count
			static TestLevelPropsRLE + #93, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #94, #1      ; count
			static TestLevelPropsRLE + #95, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #96, #7      ; count
			static TestLevelPropsRLE + #97, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #98, #1      ; count
			static TestLevelPropsRLE + #99, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #100, #5      ; count
			static TestLevelPropsRLE + #101, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #102, #1      ; count
			static TestLevelPropsRLE + #103, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #104, #25      ; count
			static TestLevelPropsRLE + #105, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #106, #1      ; count
			static TestLevelPropsRLE + #107, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #108, #7      ; count
			static TestLevelPropsRLE + #109, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #110, #1      ; count
			static TestLevelPropsRLE + #111, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #112, #5      ; count
			static TestLevelPropsRLE + #113, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #114, #1      ; count
			static TestLevelPropsRLE + #115, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #116, #25      ; count
			static TestLevelPropsRLE + #117, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #118, #1      ; count
			static TestLevelPropsRLE + #119, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #120, #7      ; count
			static TestLevelPropsRLE + #121, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #122, #1      ; count
			static TestLevelPropsRLE + #123, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #124, #5      ; count
			static TestLevelPropsRLE + #125, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #126, #1      ; count
			static TestLevelPropsRLE + #127, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #128, #25      ; count
			static TestLevelPropsRLE + #129, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #130, #9      ; count
			static TestLevelPropsRLE + #131, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #132, #5      ; count
			static TestLevelPropsRLE + #133, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #134, #1      ; count
			static TestLevelPropsRLE + #135, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #136, #39      ; count
			static TestLevelPropsRLE + #137, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #138, #1      ; count
			static TestLevelPropsRLE + #139, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #140, #39      ; count
			static TestLevelPropsRLE + #141, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #142, #1      ; count
			static TestLevelPropsRLE + #143, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #144, #39      ; count
			static TestLevelPropsRLE + #145, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #146, #1      ; count
			static TestLevelPropsRLE + #147, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #148, #39      ; count
			static TestLevelPropsRLE + #149, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #150, #1      ; count
			static TestLevelPropsRLE + #151, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #152, #39      ; count
			static TestLevelPropsRLE + #153, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #154, #1      ; count
			static TestLevelPropsRLE + #155, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #156, #25      ; count
			static TestLevelPropsRLE + #157, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #158, #15      ; count
			static TestLevelPropsRLE + #159, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #160, #39      ; count
			static TestLevelPropsRLE + #161, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #162, #1      ; count
			static TestLevelPropsRLE + #163, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #164, #39      ; count
			static TestLevelPropsRLE + #165, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #166, #1      ; count
			static TestLevelPropsRLE + #167, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #168, #39      ; count
			static TestLevelPropsRLE + #169, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #170, #1      ; count
			static TestLevelPropsRLE + #171, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #172, #39      ; count
			static TestLevelPropsRLE + #173, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #174, #1      ; count
			static TestLevelPropsRLE + #175, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #176, #39      ; count
			static TestLevelPropsRLE + #177, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #178, #1      ; count
			static TestLevelPropsRLE + #179, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #180, #39      ; count
			static TestLevelPropsRLE + #181, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #182, #1      ; count
			static TestLevelPropsRLE + #183, #64    ; '@' (ASCII 64)
			static TestLevelPropsRLE + #184, #11      ; count
			static TestLevelPropsRLE + #185, #32    ; ' ' (ASCII 32)
			static TestLevelPropsRLE + #186, #0      ; terminator

		TestLevelTopology: var #1

	Level1: var #5

	Level2: var #5

;
