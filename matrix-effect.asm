; -----------------------------------------------------------------------------
; Program:     matrix-rain.asm
; Description: 60 concurrent automatic drops with Staggered Temporal Spawning
; Author:      Spawn
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

CH          = $02FC         
WARMSV      = $E477
RTCLOK      = $14           
SAVMSC      = $58           
RANDOM      = $D20A         ; Hardware Random Number Generator (0-255)

; Colors
COLOR1      = $02C5         ; Text luminance
COLOR2      = $02C6         ; Background (dictates Hue for text)
COLOR4      = $02C8         ; Border

MAX_ENT     = 60

; --- ZERO PAGE VARIABLES ---
    ORG $0080
PTR         .ds 2           
TICK_TIMER  .ds 1           

; --- ENTITY ARRAYS ---
    ORG $2000
IS_ACTIVE:  :MAX_ENT dta 0
IS_ERASER:  :MAX_ENT dta 0  ; 0 = Draws Random Chars, 1 = Draws Black Spaces
Y_POS:      :MAX_ENT dta 0
SCR_LO:     :MAX_ENT dta 0  
SCR_HI:     :MAX_ENT dta 0  

    ORG $3000

main:
    ; --- MATRIX COLORS ---
    lda #$C0                ; Hue $C (Green), Luminance $0 (Black)
    sta COLOR2              
    lda #$0A                ; Luminance $A (Bright)
    sta COLOR1              
    lda #$00                ; Pure black border
    sta COLOR4              

    lda #$FF
    sta CH                  
    
    lda #0
    sta TICK_TIMER          

game_loop:
    ; --- 1. VBLANK SYNC (50 Hz) ---
    lda RTCLOK
wait_vblank:
    cmp RTCLOK
    beq wait_vblank

    ; --- 2. INPUT POLLING ---
    lda CH
    cmp #$21                ; Spacebar
    beq exit_prog

    ; --- 3. AUTO-SPAWNER (TEMPORAL RANDOMNESS) ---
    ; 50% chance to spawn a drop this frame
    lda RANDOM
    and #$01                ; Masks all bits except the lowest one (0 or 1)
    bne skip_spawn_1        ; If it's 1 (50% of the time), skip spawning
    jsr spawn_drop
skip_spawn_1:

    ; 12.5% chance to spawn a SECOND drop this frame to keep density unpredictable
    lda RANDOM
    and #$07                ; Masks to 0-7
    bne skip_spawn_2        ; If it's not 0 (87.5% of the time), skip
    jsr spawn_drop
skip_spawn_2:

    ; --- 4. PHYSICS THROTTLE ---
    inc TICK_TIMER
    lda TICK_TIMER
    cmp #3                  ; Physics speed (Lower = Faster rain)
    bne skip_physics        
    
    lda #0
    sta TICK_TIMER          
    
    ; --- 5. RENDER ---
    jsr update_and_draw

skip_physics:
    jmp game_loop

exit_prog:
    jmp WARMSV

; -----------------------------------------------------------------------------
; SUBROUTINE: Find an empty array slot and spawn a drop
; -----------------------------------------------------------------------------
spawn_drop:
    ldx #0
find_slot:
    lda IS_ACTIVE, x
    cmp #0
    beq init_spawn
    inx
    cpx #MAX_ENT
    bne find_slot
    rts                     ; If all 60 slots are full, abort spawn this frame

init_spawn:
    lda #1
    sta IS_ACTIVE, x
    
    lda #0
    sta Y_POS, x
    
    ; 50/50 Chance to be a Drawer (0) or Eraser (1)
    lda RANDOM
    and #1
    sta IS_ERASER, x
    
    ; Pick a random column (0-39)
get_x:
    lda RANDOM
    and #$3F                ; Mask to 0-63
    cmp #40                 ; Is it 40 or higher?
    bcs get_x               ; If yes, reroll
    
    ; Calculate exact starting memory address: SAVMSC + Random Column
    clc
    adc SAVMSC              
    sta SCR_LO, x
    
    lda SAVMSC+1            
    adc #0                  
    sta SCR_HI, x

    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: Update Physics & Direct VRAM Draw
; -----------------------------------------------------------------------------
update_and_draw:
    ldx #0

entity_loop:
    lda IS_ACTIVE, x
    cmp #0
    beq next_entity

    ; --- SETUP ZERO PAGE POINTER ---
    lda SCR_LO, x
    sta PTR
    lda SCR_HI, x
    sta PTR+1

    ; --- DETERMINE RENDER TYPE ---
    lda IS_ERASER, x
    bne draw_space          ; If 1, branch to draw space

    ; Draw Random Character
    lda RANDOM
    and #$3F                ; Mask to 0-63
    jmp render_byte

draw_space:
    lda #0                  ; Screen code for blank space

render_byte:
    ldy #0                  
    sta (PTR), y            ; Inject byte into Video RAM

    ; --- GRAVITY (16-BIT MATH) ---
    clc
    lda SCR_LO, x
    adc #40
    sta SCR_LO, x
    
    lda SCR_HI, x
    adc #0                  
    sta SCR_HI, x

    ; --- COLLISION DETECTION ---
    inc Y_POS, x
    lda Y_POS, x
    cmp #24
    bne next_entity

    ; Hit bottom of screen - kill entity
    lda #0
    sta IS_ACTIVE, x

next_entity:
    inx
    cpx #MAX_ENT
    bne entity_loop
    rts

    run main