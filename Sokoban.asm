jmp main

posPlayer: var#1
prevposPlayer: var#1

main:

	;SetUp
	loadn r0, #34
	store posPlayer, r0
	
	mainLoop:
	
	
	;Movement
	call movePlayer
	
	
	;RenderLoop:
	call render


	jmp mainLoop



movePlayer:
	
	push r0
	push r1
	push r2
	

	load r0, posPlayer
	store prevposPlayer, r0
	inchar r1
	

	;if a
	loadn r2, 'a' 
	cmp r1, r2
	jeq mvleft
	
	;if d
	loadn r2, 'd' 
	cmp r1, r2
	jeq mvright

	;if w
	loadn r2, 'w' 
	cmp r1, r2
	jeq mvup

	;if s
	loadn r2, 's' 
	cmp r1, r2
	jeq mvdown

	;else
	jmp endMovePlayer

	mvleft:
	loadn r1, #1
	sub r0, r0, r1
	jmp endMovePlayer

	mvright:
	loadn r1, #1
	add r0, r0, r1
	jmp endMovePlayer

	mvup:
	loadn r1, #40
	sub r0, r0, r1
	jmp endMovePlayer

	mvdown:
	loadn r1, #40
	add r0, r0, r1
	jmp endMovePlayer




	endMovePlayer:
	store posPlayer, r0 

	pop r2
	pop r1
	pop r0
	RTS




render:
	;Prologue
	push r0
	push r1
	push r2
	
	;Render Player

	load r2, prevposPlayer
	load r0, posPlayer
	
	cmp r0, r2
	jeq renderSkipPrevPosClear	

	loadn r1, ' '
	outchar r1, r2
	renderSkipPrevPosClear:
		
	loadn r1, 'A'
	outchar r1, r0
	
	renderCleanPlayerSkip:
	
	;Epilogue
	
	pop r2
	pop r1
	pop r0
	RTS

