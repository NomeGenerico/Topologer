# Sokoban Assembly Game - Technical Documentation

## Overview

This is a Sokoban-style puzzle game developed in assembly language for the ICMC-USP processor, a simple Von Neumann architecture computer implementing a RISC instruction set. The unique feature of this game is its exploration of different 2D manifold topologies, where puzzles exist on surfaces like a torus (Pac-Man style wrapping).

**Platform**: ICMC-USP Processor ([More Info](https://github.com/simoesusp/Processador-ICMC/tree/master))

**Screen Resolution**: 40 columns × 30 rows = 1200 character positions

**Current Status**: Core gameplay systems implemented including player movement, box pushing, layered rendering, and a complete UI framework.

([Video Explicando](https://youtu.be/GGOwl66_xmA))

---

## Architecture Overview

The game follows a modular architecture with several independent systems that communicate through shared memory variables:

```
┌─────────────────────────────────────────────────────┐
│                   Main Game Loop                    │
│  (Input → Update → Render)                          │
└──────────────┬──────────────────────────────────────┘
               │
     ┌─────────┴─────────────────────────────┐
     │                                       │
┌────▼─────┐  ┌──────────┐  ┌───────────┐   ┌▼────────┐
│  Input   │  │ Movement │  │ Behavior  │   │   UI    │
│ Handler  │→ │  System  │→ │  System   │   │ System  │
└──────────┘  └────┬─────┘  └─────┬─────┘   └─────────┘
                   │              │
              ┌────▼──────────────▼────┐
              │  Topology System       │
              └────────┬───────────────┘
                       │
              ┌────────▼───────────┐
              │  Rendering System  │
              │  (3 Layers)        │
              └────────────────────┘
```

### Memory Organization

The game uses several key memory regions:

- **Layer Buffers** (1200 chars each): UI, Props, Background, Behavior
- **Render Queue**: Dirty rendering optimization (1210 indices)
- **UI Stack**: Up to 20 stacked UI elements
- **Behavior Jump Table**: 128 function pointers for game objects

---

## Core Systems

### 1. Rendering System

The rendering system implements a **layered, dirty rendering** approach for optimal performance.

#### Layer Architecture

The game uses four distinct layers rendered in priority order:

1. **UI Layer** (highest priority) - Menus, dialogs, prompts
2. **Props Layer** - Player, boxes, walls, interactive objects
3. **Background Layer** - Static decorative elements, titles
4. **Behavior Layer** - Invisible collision/interaction data

**Key Functions**:
- `render()` - Main render loop, dispatches to either normal or UI rendering
- `ScreenRenderIndex(r1)` - Renders a single screen position from Props/Background layers
- `ScreenRenderUIIndex(r1)` - Renders a single screen position from UI layer
- `FullScreenPrint()` - Forces complete screen refresh

#### Dirty Rendering Optimization

Instead of redrawing the entire 1200-character screen each frame, the system tracks which positions have changed:

```
currentScreenIndexesChanged[1210]  ← Buffer of changed indices
currentScreenIndexesChangedIndex   ← Write pointer into buffer
```

**How it works**:
1. Game logic calls `SetIndexChanged(r0)` whenever a position changes
2. The index is added to the `currentScreenIndexesChanged` buffer
3. During render, only indices in the buffer are redrawn
4. Buffer is cleared after rendering

**Key Functions**:
- `SetIndexChanged(r0)` - Marks position r0 as needing redraw
- `SquareFinderSetIndexChanged(r1)` - Marks rectangular regions for redraw

#### Color System

Each layer has an associated default color:
- `uiLayerColor` - White (0)
- `propLayerColor` - White (0) 
- `backgroundLayerColor` - White (0)
- `currentPrintingColor` - Temporary color override (0 = use layer default)

Colors are added to ASCII values before output: `outchar (character + color), position`

---

### 2. Input System

Simple but effective buffered input handling.

**Key Variables**:
- `InputedChar` - Current frame's processed input
- `InputedCharBuffered` - Next frame's input (prevents input loss)

**Function**: `InputHandler()`

The input handler reads one character per frame using the `inchar` instruction. Input is stored directly without debouncing or delay (delay logic was moved out of this system for modularity).

---

### 3. Movement and Topology System

The movement system handles player and box movement with support for different 2D manifold topologies.

#### Basic Movement Functions

- `MvRight(r0)` - Add 1 to position
- `MvLeft(r0)` - Subtract 1 from position  
- `MvUp(r0)` - Subtract 40 from position (one row)
- `MvDown(r0)` - Add 40 to position

These functions perform raw position changes without bounds checking.

#### Topology System

**Function**: `mvTopology(r0, r1)` 

Takes a position and previous position, applies topological wrapping rules, and returns the corrected position.

**Current Implementation: Torus (Pac-Man Style)**

The torus topology creates seamless wrapping on both axes:

```
Horizontal Wrapping:
  Left edge (column 0) → Right edge (column 39)
  Right edge (column 39) → Left edge (column 0)

Vertical Wrapping:
  Top edge (row 0) → Bottom edge (row 29)
  Bottom edge (row 29) → Top edge (row 0)
```

**Algorithm Overview**:
1. Calculate column of previous and new position using `mod 40`
2. If columns sum to 39, horizontal wrap occurred
3. Calculate row of new position using `div 40`  
4. If row is 30 or -1, vertical wrap occurred
5. Apply appropriate correction (+/- 1200 for vertical, +/- 40 for horizontal)

**Design Note**: The topology system is currently hardcoded for torus. Future improvements will make this configurable via function pointers.

#### Player Movement

**Function**: `movePlayer()`

Complete player movement pipeline:

1. Check if UI is active (if so, skip all movement)
2. Reset `moveBlocked` flag to 0
3. Save current position as `playerPrevPos`
4. Check input (w/a/s/d) and call appropriate movement function
5. Apply topology corrections via `mvTopology()`
6. **Behavior Check**: Look up the character at new position in Props layer
7. Use `BehaviorJumpDict` to call the appropriate behavior function
8. If `moveBlocked` flag is still 0, execute the move:
   - Call `MoveInMemory()` to update layer
   - Mark old and new positions as changed

---

### 4. Behavior System

The behavior system implements game object logic using a **jump table pattern**.

#### Behavior Jump Dictionary

```assembly
BehaviorJumpDict: var #128  ; Array of 128 function pointers
```

This array maps ASCII character values to function addresses. When the player moves to a position, the character at that position is used as an index into this table to call the appropriate behavior.

**Currently Defined Behaviors**:
- ASCII 0 (null) → `DoNothing`
- ASCII 32 (space) → `DoNothing`
- ASCII 35 ('#', wall) → `BlockMovement`
- ASCII 64 ('@', box) → `checkPushMovement`

#### Indirect Function Calls

Since the processor doesn't support indirect jumps natively, the code uses a clever pattern:

```assembly
; Load function address into r7
mov r7, functionAddress
; Call through stack manipulation
call IndirectCall

; IndirectCall implementation:
IndirectCall:
    push r7    ; Push address onto stack
    rts        ; Return pops address and jumps to it
```

#### Behavior Functions

**`DoNothing()`** - No-op for empty space

**`BlockMovement()`** - Sets `moveBlocked = 1` to prevent movement

**`checkPushMovement()`** - Complex box pushing logic:

1. Check if the object is actually a box ('@')
2. Calculate movement direction from position difference
3. Apply same movement to box position
4. Apply topology corrections to box's new position
5. **Recursively check** the behavior at box's destination
6. If destination allows movement, call `MoveInMemory()` for the box
7. If destination blocks, set `moveBlocked = 1`

This recursive approach allows **pushing multiple boxes** in a chain. When box A is pushed into box B, box B's behavior function is called, which can then push box B into box C, etc.

---

### 5. UI System

A sophisticated system for managing stacked, interactive user interface elements.

#### UI Architecture

The UI system implements a **stack-based modal dialog** pattern. Multiple UI elements can be stacked, but only the topmost one receives input and is fully rendered.

**Key Variables**:
- `UIStack[20]` - Stack of up to 20 UI element addresses
- `UIStackPointer` - Points to current top of stack
- `ISUIActive` - Boolean flag (0 = game active, 1 = UI active)
- `UICurentlySelectedElement` - Index of highlighted interactible element
- `UIPreviousSelectedElement` - Previous selection (for unhighlighting)
- `uIHighlightColor` - Color for highlighted UI elements (yellow, 64512)

#### UI Object Data Structure

Each UI element is defined as a 7-word structure:

```
UIElement: var #7
  [0] Function address        - Input handler for this element
  [1] Start position         - Top-left corner screen position  
  [2] End position           - Bottom-right corner screen position
  [3] Default color          - Color for rendering
  [4] RLE data address       - Compressed visual representation
  [5] Interactible count     - Number of selectable elements
  [6] Interactible list addr - Array of interactible elements
```

**Interactible Element Structure** (3 words each):
```
InteractibleElement: var #3
  [0] Start position    - Bounding box start
  [1] End position      - Bounding box end
  [2] Function address  - Called when activated (Enter key)
```

#### Core UI Functions

**`UICall(r0)`** - Opens a UI element

1. Extracts start position, end position, and RLE data from UI structure
2. Calls `UIDrawToBuffer()` to decompress RLE into UI layer
3. Calls `SquareFinder()` to mark rectangular region as changed
4. Renders entire UI buffer with `FullScreenUIPrint()`
5. Pushes element address onto UI stack
6. Sets `ISUIActive = 1`
7. Initializes selection indices to 0

**`UIClose()`** - Closes the topmost UI element

1. Resets selection tracking variables
2. Pops UI stack pointer
3. If stack is now empty:
   - Sets `ISUIActive = 0`  
   - Marks UI region for redraw
   - Calls `ScreenRenderChanged()` to show game underneath
4. If stack still has elements:
   - Redraws previous UI element

**`UIHandeler()`** - Dispatches input to active UI or game

Called every frame from main loop:
- If `ISUIActive = 1`: Calls the active UI element's function
- If `ISUIActive = 0`: Checks if ESC was pressed to open pause menu

**`UIInteractibleElementComputeShift(r0)`** - Updates selection

Takes a shift value (±1):
1. Saves current selection as previous
2. Adds shift to current selection
3. Handles wrap-around using modulo arithmetic
4. Handles underflow (65535 wraps to max)

**`UIInteractibleElementHighLightRender(r0)`** - Visual feedback

1. Finds currently selected interactible element
2. Sets printing color to highlight color (Blue)
3. Uses `SquareFinder()` to mark bounding box as changed
4. Calls `ScreenRenderUIChanged()` to redraw with highlight
5. Repeats process for previously selected element with default color

**`UISelectedInteractibleElementInteract(r0)`** - Activates selection

1. Finds currently selected interactible element
2. Extracts its function address
3. Calls function through `IndirectCall` pattern

#### UI Drawing System

**`UIDrawToBuffer(r0, r1)`** - Decompresses RLE into UI layer

- r0: Starting screen position
- r1: Address of RLE data

Uses RLE decoder with special behavior: **zeros in the RLE do not overwrite existing UI buffer contents**. This allows transparent overlays when stacking UI elements.

**`SquareFinder(r0, r1)`** - Marks rectangular regions

Given start and end positions, calculates all screen indices in the rectangle and adds them to the changed indices buffer. Uses nested loops over X and Y coordinates.

#### Example: Main Menu

The main menu demonstrates the full UI system:

```assembly
MainMenu: var #7
  [0] #MainMenuFunction          - Handles w/s for navigation, Enter for selection
  [1] 0                         - Start at top-left
  [2] 1199                      - End at bottom-right (full screen)
  [3] 0                         - White color
  [4] #MainMenuRLE              - ASCII art title + menu
  [5] 2                         - Two options
  [6] #MainMenuInteractibleList

MainMenuInteractibleList:
  [0] #NewGameButton            - "NEW GAME" option
  [1] #LevelSelectButton        - "CHOOSE LEVEL" option
```

When "NEW GAME" is activated, its function calls `UIClose()`, loads a level via `LoadStage()`, and calls `FullScreenPrint()` to show the game.

---

### 6. RLE Compression System

**Run-Length Encoding** is used to compress level data and UI graphics, saving significant memory.

#### RLE Format

RLE data is stored as pairs of values terminated by 0:

```
[count₁, character₁, count₂, character₂, ..., 0]
```

Example: 
```
"AAABBC" → [3, 'A', 2, 'B', 1, 'C', 0]
```

**Compression Ratios**:
- TestLevel: 1200 words → 187 words (84.4% saved)
- MainMenu: 1200 words → 285 words (76.2% saved)

#### RLE Functions

**`RLEDecoder(r0, r1)`** - Decompresses RLE to memory

- r0: Destination address (where to write)
- r1: Source RLE data address

Algorithm:
1. Read count and character from RLE
2. Write character `count` times to destination
3. Advance destination pointer
4. Repeat until terminator (0) is reached

Used by `LoadStage()` to decompress all four layers.

**`RLEEncoder()`** - TODO: Not yet implemented

**`RLETraverser(r0, r1)`** - Random access into RLE (experimental)

This function provides efficient random access to compressed data without full decompression. It maintains a buffer (`RLETraverserBuffer`) of recent positions to optimize sequential access patterns.

*Note: This function is defined but not currently used in the codebase.*

---

### 7. Level Loading System

**Function**: `LoadStage(r2)` 

Takes a pointer to a Level structure and loads all layer data.

#### Level Data Structure

```
Level: var #5
  [0] UI layer RLE address
  [1] Props layer RLE address  
  [2] Background layer RLE address
  [3] Behavior layer RLE address
  [4] Topology identifier
```

**Loading Process**:

For each layer:
1. Load destination pointer (e.g., `currentUILayer`)
2. Load RLE source address from level structure
3. Call `RLEDecoder(destination, source)`
4. Increment to next layer

Finally, load topology identifier (currently unused, always torus).

**Current Levels**:
- `TestLevel` - Demo level with box pushing
- `Level1`, `Level2` - TODO: Not yet defined

---

### 8. Memory Management System

#### MoveInMemory Function

**Function**: `MoveInMemory(r0, r1)`

Moves a character from one position to another in the Props layer:

1. r1 = source position
2. r0 = destination position
3. Read character at source
4. Write space (' ') to source
5. Write character to destination

**Critical Note**: Always call from last-moved object to first, otherwise objects can "Thanos snap" (disappear) if their destination overwrites their source before reading.

#### Layer Pointer System

Instead of hardcoding layer addresses, the game uses pointer variables:

- `currentUILayer`
- `currentPropLayer`
- `currentBackgroundLayer`
- `currentBehaviourLayer`

This design allows easy level switching via `LoadStage()` without complex memory management.

---

## Data Types Reference

### String
```assembly
string "text data"
```
Null-terminated character array.

### RLE (Run-Length Encoded)
```
var #N
[count, char, count, char, ..., 0]
```

### Layer
```
var #1200
```
1200-character screen buffer (40×30).

### List
```
var #length
[element₀, element₁, ...]
```

### UI Object
```
var #7
[function, startPos, endPos, color, rleAddr, interactCount, interactListAddr]
```

### Interactible Element
```
var #3  
[startPos, endPos, functionAddr]
```

### Level
```
var #5
[uiRLE, propsRLE, bgRLE, behaviorRLE, topology]
```

---

## Game Flow

### Initialization (main:)

1. Initialize `currentScreenIndexesChangedIndex` pointer
2. Set up layer pointers to default memory regions
3. Clear UI layer using RLE decoder
4. Initialize UI stack pointer
5. Position player at index 80
6. Place player character 'A' in Props layer
7. Call `UICall(#MainMenu)` to show main menu

### Main Game Loop

```
mainLoop:
    InputHandler()         - Read one character
    movePlayer()          - Process movement if game active
    UIHandeler()          - Dispatch to UI or check for ESC
    render()              - Draw changed screen positions
    jmp mainLoop
```

### Typical Gameplay Sequence

1. **Menu Phase**: Player navigates menu with W/S, presses Enter
2. **Menu Action**: Selected function calls `UIClose()` and `LoadStage()`
3. **Game Phase**: Player moves with W/A/S/D
   - Movement updates Props layer
   - Behavior system handles collisions and box pushing
   - Dirty rendering updates only changed positions
4. **Pause**: Player presses ESC
   - Confirmation prompt is pushed onto UI stack
   - Game continues underneath but receives no input
5. **Resume**: Player selects "NO" on prompt
   - UI closes, game continues from exact state

---

## Performance Optimizations

### Dirty Rendering
Only redraws changed portions of screen (typically 2-10 positions per frame vs. 1200).

### RLE Compression  
Reduces memory usage by 75-85% for large levels and UI elements.

### Layer Priority System
Renders layers from top to bottom, stopping at first non-space character. Avoids redundant drawing.

### Indirect Call Pattern
Enables polymorphic behavior without complex branching logic.

### Stateless Rendering
Render functions are pure - they read from layers but don't modify game state, preventing render/update coupling bugs.

---

## Known Limitations and Future Work

### Current Limitations

1. **Hardcoded Topology**: Torus logic is embedded in `mvTopology()`. Other manifolds require code changes.

2. **No Undo System**: Cannot reverse moves (would require state history stack).

3. **Limited Object Types**: Only player, walls, and boxes. No buttons, doors, teleporters, etc.

4. **Static Backgrounds**: Background layer is static; no animated elements.

5. **Single-Character Objects**: All objects are single ASCII characters (no multi-tile sprites).

### Planned Improvements

**Short Term**:
- Goal tiles ('P') to detect level completion
- Win condition checking and level progression
- More levels with increasing difficulty

**Medium Term**:
- Configurable topology system with function pointers
- Additional object types (buttons, doors, pressure plates)
- Undo function with state stack
- Level selection menu

**Long Term**:
- Non-orientable surfaces (Möbius strip, Klein bottle)
- Non-traditional 2D manifolds
- Animated backgrounds
- More sophisticated sprite system

---

## Assembly Language Notes

### Register Usage Conventions

The codebase follows these informal conventions:

- **r0-r2**: General purpose, frequently clobbered
- **r3-r6**: Local variables within functions
- **r7**: Special role for indirect calls (function pointer)

All functions preserve registers by pushing/popping around their logic.

### Common Patterns

**Position Calculation**:
```assembly
; Convert (x, y) to linear index
; index = y * 40 + x
mul r1, r3, r2    ; r1 = y * 40  
add r1, r1, r0    ; r1 = y * 40 + x
```

**Character Lookup**:
```assembly
; Get character at position r1 in layer
load r0, currentPropLayer
add r0, r0, r1       ; r0 = layer address + position
loadi r2, r0         ; r2 = character
```

**Colored Output**:
```assembly
; Output character r4 with color r3 at position r1  
add r4, r2, r3       ; r4 = character + color
outchar r4, r1       ; Display at position
```

---

## Testing and Debugging

### Debug Output

The code includes several debug outputs (search for "DEBUG"):

- Position 0: Shows `ISUIActive` value
- Position 1: Shows last input character (ASCII value)
- Position 2: Shows `UICurentlySelectedElement` index

These can be enabled/disabled by commenting the respective code blocks.

---

## Glossary

**Dirty Rendering**: Only redrawing portions of the screen that have changed since last frame.

**RLE (Run-Length Encoding)**: Compression technique that stores repeated values as (count, value) pairs.

**Topology**: In this context, the "shape" of the game world and how edges connect (e.g., torus wraps both edges).

**2D Manifold**: A mathematical surface that locally looks like a flat plane but may have global properties like wrapping or twisting.

**Jump Table**: An array of function pointers used to implement polymorphic dispatch.

**Indirect Call**: Calling a function through a pointer rather than a direct address.

**Modal Dialog**: A UI element that blocks interaction with elements beneath it until closed.

**Stack-Based UI**: UI system where elements are stacked like plates, and only the top element is active.
