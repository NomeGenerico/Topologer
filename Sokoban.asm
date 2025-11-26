jmp main

playerPos: var#1
playerPrevPos: var#1
playerOriginalPos: var#1
playerMoveDirection: var#1
playerOrientation: var#1

moveBlocked : var#1 ; flag for box pushing functions

StageData:  var#4    ; will store data for the stage /  0-3 layers to be loaded, HUD, Prop, Background, Behaviour. 4-Topology
; will be used in the loading of a new stage or level. Its used to set all of the relevant Variables

; Important Pointers
currentUILayer: var#1
currentPropLayer: var#1
currentBackgroundLayer: var#1
currentBehaviourLayer: var#1
curentTopology: var#1

; Render Data
currentScreenIndexesChanged : var#1210
currentScreenIndexesChangedIndex: var#1


; UI Data 
UIStack : var#20 ; max of 20 ui elements
UIStackPointer: var#1
UICurentlySelectedElement: var#3 ;<ID, StartPos, EndPos>
UIPreviousSelectedElement: var#3 ;<ID, StartPos, EndPos>

; ColorData
uiLayerColor: var#1 
propLayerColor: var#1
backgroundLayerColor: var#1
currentPrintingColor: var#1 ; 0 is the value for white, USE 1 FOR NO COLOR

LayerProps : string "                                                                                                                                                                                                                                                                                                                                                                                       @@@@@@@                                 @     @                                 @     @                                 @     @                                 @     @                                 @     @                                 @@@@@@@                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  "
LayerBackground : string "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                "
LayerUI : var#1200
LayerBehavior: var#1200

InputedChar: var#1

ISUIActive: var#1 
static ISUIActive + #0, #0

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

		; Load Level 1
			loadn r2, #Level1
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


	mainLoop:

		; Input
		call InputHandler
	
		;GameUpdate

			call movePlayer  ;TODO: put checkPushMovement in a BehaviourLayer; and check if UI is active or not. 
			; Behavior ; TODO

			; Ticks all entities that must be ticked in every "frame"

			call UIHandeler
			
		; call UIHandler ; Checks if ui is active

						     
		;RenderLoop:
			call render   ; makes it skip zeros in the UI Buffer, instead of the spaces

	jmp mainLoop

InputHandler:

	push r0
	push r1


	inchar r0
	store InputedChar, r0

	; Global UI Must be called from here

	; if esc
		loadn r1, #27 ; ESC
		cmp r0, r1
		jne SkipInputESCUIcall

		loadn r0, #UIConfirmationPrompt
		call UICall

		SkipInputESCUIcall:

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
		jeq MovePlayerUiSlip


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
		call checkPushMovement	


	endMovePlayer:
	store playerPos, r0 
	
	;takes r0 = new pos
	load r1, playerPrevPos; takes r1 = prev sos

	call MoveInMemory ; 
	
	call SetIndexChanged
	mov r0, r1
	call SetIndexChanged

	MovePlayerUiSlip:
	pop r3
	pop r2
	pop r1
	pop r0

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
	loadn r3, #'@'
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

	; if ui active
		load r0, ISUIActive
		loadn r1, #1
		cmp r0, r1
		jeq ScreenRenderIndexUI
    
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



	ScreenRenderIndexUI:

	loadn r0, #currentScreenIndexesChanged  	; Start address
    load r2, currentScreenIndexesChangedIndex   ; End adddres

	ScreenRenderIndexUI_loop:     ; BIG BUG, MUST CHECK IF CHAR IS ZERO BEFORE ADDING COLOR

		cmp r0, r2
		jeq ScreenRenderHighlightedUI

		loadi r1, r2 ; gets index to render

		call ScreenRenderUIIndex

		dec r2
		jmp ScreenRenderIndexUI_loop

	ScreenRenderHighlightedUI:

	; set screen index changed

		loadn r0, #UICurentlySelectedElement  ; <ID, StartPos, EndPos>
		inc r0 ; start pos
		mov r2, r0
		
		inc r0
		loadi r1, r0 ; set end pos

		loadi r0, r2 ; set start pos

		loadn r3, #0 ; set function to SetIndexChanged

		call SquareFinder 	;<Start, End,    , FunctionID>

	; set HighlightColor

	loadn r0, #64512 ; should be the color blue


	store currentPrintingColor, r0

	; sets loop

	loadn r0, #currentScreenIndexesChanged  	; Start address
    load r2, currentScreenIndexesChangedIndex   ; End adddres

	ScreenRenderHighlightedUI_loop:
		
		; print again with highlight color

		cmp r0, r2
		jeq ScreenRenderIndexExit

			loadi r1, r2 ; gets index to render

			call ScreenRenderUIIndex

			dec r2
			jmp ScreenRenderIndexUI_loop


	jmp ScreenRenderIndexExit



	ScreenRenderIndexExit:

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

ScreenRenderUIIndex:   ; <ScreenIndex>

	push r0
	push r1
	push r2


	;load r0, currentUILayer
	;r1 index to render
	; current printing color can be set 

	; checks printing color

		load r2, currentPrintingColor
		loadn r0, #1
		cmp r0, r2
		jne ScreenRenderUIIndex_UsePassedColor

			jmp ScreenRenderUIIndex_UsePassedColor

		ScreenRenderUIIndex_UseDefaultColor:

			load r2, uiLayerColor

		ScreenRenderUIIndex_UsePassedColor:

	load r0, currentUILayer

	add r0, r0, r1 ; 
	loadi r0, r0   ; gets value in the ui layer at index r1

	add r0, r0, r2 ; gets colored character

	outchar r0, r1 ; outputs character r0 in position r1

	pop r2
	pop r1
	pop r0

	rts

SetIndexChanged: ; <index>
    ; r0 = index

	mov r7, r0
    
    push r2
    push r3
    
    load r2, currentScreenIndexesChangedIndex  ; Get current write pointer
    
    storei r2, r0  ; Write new position
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

;TODO:
RLEEncoder:

	rts

RLETraverser:   ; TODO
				; needs to traverse the rle string looking for a single char eficiently if called multiple times in sequence


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
SquareFinder: ;<Start, End,    , FunctionID> ; function must be an ID because there is no indirect call. Same for Behaviour *sad emoji*
	; given two positions, can apply a function in every square marked by these positions in a specific buffer

	push r0 ; Start ; y
	push r1 ; end	; y
	push r2 ; 
	push r3 ; function

	push r4 ; start x
	push r5 ; end x
	push r6
	push r7


	; find x and y of start and end ; y will overide the start and end positions in r0 and r1 

		loadn r7, #40
		mod r4, r0, r7 ; x start pos
		div r0, r0, r7 ; y start pos

		mod r5, r1, r7 ; x end pos
		div r1, r1 ,r7 ; y end pos


	SquareFinder_xloop:

	cmp r4, r5 ; while r5 >= r4
	jgr SquareFinder_xloop_end


		SquareFinder_yloop:
		cmp r0, r1
		jgr SquareFinder_yloop_end

			; convert back into screen index

			mul r6, r0 , r7 ; y * 40
			add r6, r4, r6 ; add x pos

			; r6 contains the screen index 

			jmp SquareFinderJumpTable
			SquareFinderJumpTable_exit:

			inc r0
			SquareFinder_yloop_end:
			

		inc r4
		jmp SquareFinder_xloop

	SquareFinder_xloop_end:


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
			; operates on r0, r1, r2
			; calls a UI element, and pushes the stack 
			; takes r0 as the poiter to the UI element functi											; no calli   :|on ; the element is resposable for reducing the uielement pointer 
			; r1 as the start position of where it will Draw
			; r2 is the elements color. 

			push r0
			push r1
			push r2
			push r3


			; first drawing of the element
				store currentPrintingColor, r2

				; protect Ui position on screen 

				inc r0
				loadi r3, r0
				inc r0
				inc r0
				inc r0 ; Pointer to the Addres of the RLE 
				loadi r0, r0  ; r0, contains the addres of the RLE
				mov r1, r0 ; RLE Address
				mov r0, r3 ; ScreenIndex startPos

				call UIDrawToBuffer; 

				mov r1, r2

				loadn r3, #0
				call SquareFinder  ; Updates currentScreenIndexesChanged

			; Pushing the element into the stack

				load r1, UIStackPointer
				storei r1, r0
				inc r1
				store UIStackPointer, r1



			; r0 will be the start of the draw position	
			; r1 will be the end of the draw position
			; r2 will be the outupt   ; exemple, confirmation prompt returns either a 1 or a 0

			loadn r0, #1
			store ISUIActive, r0

			pop r3
			pop r2
			pop r1
			pop r0
	rts

UIClose:

	push r0
	push r1

	loadn r0, #0
	loadn r1, #UICurentlySelectedElement
	storei r1, r0 ; reset id
	inc r1 
	storei r1, r0 ; reset start
	inc r1 
	storei r1, r0 ; reset end

	load r0, UIStackPointer
	dec r0
	store UIStackPointer, r0	

	pop r1
	pop r0

	rts

TODO:
UIRedraw:   ; <> Rebuilds UI Buffer from the stack  
			; Travels the stack and reconstruncting the current UI Layer, Must be able to determine the size and all positions that must be redraw
			; takes r0 and r1, as start and end position of the ui element. assumes a retengular element
			; if it rebuilds and encounters a ui element that is a zero, it must go deeeper in the stack
			; if the index is not zero, do not overide
	rts

UIDrawToBuffer:   ; <Start, <UIElemenent_RLE>> 
					
	; prints to the buffer. But values of zero do not overide what was there	
	;takes r1 as the pointer to the RLE of the UI element 

	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	; r1 is the string it will decode

	load r3, currentUILayer ; addres the first position of the ui leayer
	add r0, r0, r3
	
	loadn r3, #0

	UIDrawToBuffer_Loop:

		loadi r4, r1    ;  r1 is the pointer to the fisrt string character ;count
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

	load r0, UIStackPointer
	loadi r0, r0 ; Ui element Address
	loadi r0, r0 ; UIElement Function ID

	jmp UICallJumpTable
	UICallJumpTable_exit:



	rts


;--------- Behavior
; The original idea with indirect calls will not work, there will be a need for a jump table
; 
; GameObject <sprite, SpriteLayer, Behavior FunctionID> ; FunctionID will simply be the sprite value, no need for a separate value
;                                                         Will leave this here so in the future i can implment a calli instruction
; 
LoadGameObjects: ; Must be inserted in LoadStage

;______________
; jump tables: 

	SquareFinderJumpTable:  ; r6 is screen index ; r3 is function id ; uses r2, which is reserved in Square finder, no current conflic but beware

		push r0
		push r2


		loadn r2, #0 ; set screen index changed
			cmp r2, r3
			jne idzeroskip
			call SetIndexChanged
			idzeroskip:




		pop r2
		pop r0

		jmp SquareFinderJumpTable_exit

	UICallJumpTable: 

		push r2

		loadn r2, #'0' ;  must clean the stack
		cmp r2, r0
			jeq idUIskip

		loadn r2, #'1'
		cmp r2, r0
			jne idUIoneskip
			call SetIndexChanged
			idUIoneskip:

		


		idUIskip:
		pop r2

		jmp UICallJumpTable_exit

	BehaviorHandelerJumpTable: ; <ID - Sprite>

		push r2

		loadn r2, #'@'
		cmp r2, r0
			jne idboxskip
			call SetIndexChanged
			idboxskip:


		pop r2
		;jmp BehaviorHandelerJumpTable_exit

;____________________________________
; UI Data

	; UI object : Var#5  <FunctionID, StartPos, EndPos, Color, RLE>

	UIConfirmationPrompt: var#5 

		static UIConfirmationPrompt + #0,  #1  ; id one    ;#UIConfirmationPromptFunction if i had calli
		static UIConfirmationPrompt + #1, #574
		static UIConfirmationPrompt + #2, #708
		static UIConfirmationPrompt + #3, #0 ; white
		static UIConfirmationPrompt + #4, #ConfirmationPromptRLE

		UIConfirmationPromptFunction:   ; id 0

			push r0
			push r1 ; where to "print", actualy we are puting it into the uiLayer
			push r2 ; color
			push r3

			;

				; handle the input given and executes logic

				; Mark active options, in a first moment, only one single element should be active. 
				; this element, will be drawn again in the render pass with a diferent color.
				; might have to make this part of the render system, with a list of tuples of the elements, first element start, end, secondend element start, end...
		

				load r0, InputedChar

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
					jeq UIConfirmationPrompt_Exit

				UIConfirmationPromptFunction_Ifa:

					loadn r0, #65534 ; -1
					jmp UIConfirmationPromptFunction_ResolveActive

				UIConfirmationPromptFunction_Ifd:
				
					loadn r0, #1
					jmp UIConfirmationPromptFunction_ResolveActive

				UIConfirmationPromptFunction_ResolveActive:
				;loadn r0, shift
				load r1, UICurentlySelectedElement ; Always set this to zero when closing the UI
				loadn r2, #2 ; number of elements

				push r0
				push r1
				push r2
				store UIPreviousSelectedElement, r1
				; add data to currentScreenIndexesChanged

					loadn r2, #UICurentlySelectedElement
					loadn r1, #UIPreviousSelectedElement

					loadi r0, r2 
					storei r1, r0 ;id
					inc r1 
					inc r2
					loadi r0, r2 
					storei r1, r0 ;start
					inc r1
					inc r2 
					loadi r0, r2 
					storei r1, r0 ;end
				pop r2
				pop r1
				pop r0



				add r1, r1, r0
				mod r1, r1, r2

				store UICurentlySelectedElement, r1
				

				; MarkingElement
				;if UICurentlySelectedElement = 0
					; "No"
					loadn r2, #0
					cmp r1, r2
					jne UIConfirmationPromptFunction_UICurentlySelectedElementEQ1

					loadn r1, #43 ; position of the N of the No
					loadn r2, #44 ; position of the o of the No	

					jmp UIConfirmationPromptFunction_MarkActive
				

				UIConfirmationPromptFunction_UICurentlySelectedElementEQ1:
					;Yes

					loadn r1, #47 ; position of the Y of the Yes
					loadn r2, #49 ; position of the s of the Yes


				UIConfirmationPromptFunction_MarkActive:
				;load r0, Ui element position
				
				loadn r0, #UIConfirmationPrompt
				inc r0
				loadi r0, r0

				;Redraw Elements with new color:

				add r1, r1, r0
				add r2, r2, r0

				loadn r0, #UICurentlySelectedElement
				inc r0 
				storei r0, r1 ; Update start
				inc r0 
				storei r0, r2 ; Update end

			jmp UIConfirmationPrompt_Continue

			UIConfirmationPrompt_Exit:


				call UIClose

			UIConfirmationPrompt_Continue:

			pop r3
			pop r2
			pop r1
			pop r0
			rts

		ConfirmationPromptRLE : var#39  ; 19 runs, 39 words total

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
			static ConfirmationPromptRLE + #36, #1106      ; count
			static ConfirmationPromptRLE + #37, #0    ; 0 (ASCII 32)
			static ConfirmationPromptRLE + #38, #0      ; terminator
		
;MainMenu

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

; Level Data: Var#5  ;<HUD, Props, Background, Behavior, Topology>

	EmptyRLE: var#3
		static EmptyRLE + #0, #1200; count
		static EmptyRLE + #1, #0    ; 0
		static EmptyRLE + #2, #0     ; terminator

	ZeroRLE: var#3
		static ZeroRLE + #0, #1200; count
		static ZeroRLE + #1, #32    ; ' ' (ASCII 32)
		static ZeroRLE + #2, #0     ; terminator

	Level1: var#5

		static Level1 + #0, #EmptyRLE    ; UI
		static Level1 + #1, #Level1PropsRLE
		static Level1 + #2, #TitleRLE ;Background
		static Level1 + #3, #EmptyRLE ;Behaviour ; Will be infered from the Prop Layer and Background Layer in my game;
		static Level1 + #4, #Level1Topology      ;Topology

		; Original: 1200 words, RLE: 187 words, saved 84.4%
		; RLE encoded level data
		Level1PropsRLE : var#187  ; 93 runs, 187 words total

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

	Level2: var#5


;
