; -----------------------------------------------------------------------------
; Program:     smooth-letters.asm
; Description: 10 concurrent falling letters using Direct VRAM & Throttled VBLANK
; Author:      Spawn
; Date:        2026-09-29
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

CH          = $02FC         ; Hardware keyboard register
WARMSV      = $E477
RTCLOK      = $14           ; OS 50Hz frame counter
SAVMSC      = $58           ; OS 16-bit pointer to start of Screen Memory

MAX_ENT     = 10

; --- ZERO PAGE VARIABLES ---
    ORG $0080
PTR         .ds 2           ; Reserves $80 (Low Byte) and $81 (High Byte)
TICK_TIMER  .ds 1           ; Counter to throttle the physics speed
SPAWN_COL   .ds 1           ; Dedicated tracker for the next X spawn position

; --- ENTITY ARRAYS ---
    ORG $2000
IS_ACTIVE:  :MAX_ENT dta 0
CHAR:       :MAX_ENT dta 0
Y_POS:      :MAX_ENT dta 0
SCR_LO:     :MAX_ENT dta 0  
SCR_HI:     :MAX_ENT dta 0  

    ORG $3000

main:
    lda #$FF
    sta CH                  ; Clear keyboard buffer
    
    lda #0
    sta TICK_TIMER          ; Initialize throttle
    sta SPAWN_COL           ; Start spawning at column 0

game_loop:
    ; --- 1. VBLANK SYNC (50 Hz) ---
    lda RTCLOK
wait_vblank:
    cmp RTCLOK
    beq wait_vblank

    ; --- 2. INPUT POLLING (Runs 50x per second) ---
    jsr read_keyboard

    ; --- 3. PHYSICS THROTTLE ---
    inc TICK_TIMER
    lda TICK_TIMER
    cmp #4                  ; Adjust falling speed here
    bne skip_physics        
    
    lda #0
    sta TICK_TIMER          
    
    ; --- 4. PHYSICS & RENDER (Runs 12.5x per second) ---
    jsr update_and_draw

skip_physics:
    jmp game_loop

; -----------------------------------------------------------------------------
; SUBROUTINE: Read Keyboard & Spawn
; -----------------------------------------------------------------------------
read_keyboard:
    lda CH
    cmp #$FF
    beq read_done
    cmp #$21                ; Spacebar scancode
    beq exit_prog

    ldx #0
find_slot:
    lda IS_ACTIVE, x
    cmp #0
    beq spawn_letter
    inx
    cpx #MAX_ENT
    bne find_slot
    jmp clear_key

spawn_letter:
    lda #1
    sta IS_ACTIVE, x
    
    ldy CH              
    lda KEY_LUT, y      
    sta CHAR, x         
    
    lda #0
    sta Y_POS, x
    
    ; --- DECOUPLED HORIZONTAL SPACING ---
    ; Calculate exact starting memory address: SAVMSC + SPAWN_COL
    lda SPAWN_COL
    clc
    adc SAVMSC
    sta SCR_LO, x
    
    lda SAVMSC+1
    adc #0
    sta SCR_HI, x

    ; --- INCREMENT SPAWN_COL FOR THE NEXT LETTER ---
    lda SPAWN_COL
    clc
    adc #4                  ; Move 4 columns to the right for next time
    cmp #40                 ; Did we hit the right edge of the screen?
    bcc save_col            ; If A < 40 (Branch on Carry Clear), skip the reset
    lda #0                  ; Reset back to the left edge
save_col:
    sta SPAWN_COL

clear_key:
    lda #$FF
    sta CH
read_done:
    rts

exit_prog:
    jmp WARMSV

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

    ; --- ERASE OLD CHARACTER ---
    ldy #0                  
    lda #0                  ; Screen code for blank space
    sta (PTR), y            

    ; --- GRAVITY (16-BIT MATH) ---
    clc
    lda SCR_LO, x
    adc #40
    sta SCR_LO, x
    sta PTR                 

    lda SCR_HI, x
    adc #0                  
    sta SCR_HI, x
    sta PTR+1               

    ; --- COLLISION DETECTION ---
    inc Y_POS, x
    lda Y_POS, x
    cmp #24
    bne draw_new

    ; Hit bottom of screen - kill entity
    lda #0
    sta IS_ACTIVE, x
    jmp next_entity

draw_new:
    ; --- DRAW NEW CHARACTER ---
    lda CHAR, x
    sta (PTR), y

next_entity:
    inx
    cpx #MAX_ENT
    bne entity_loop
    rts

; -----------------------------------------------------------------------------
; LOOK-UP TABLE (Scancode to Screen Code)
; -----------------------------------------------------------------------------
KEY_LUT:
    dta d'l', d'j', d';', $00, $00, d'k', d'+', d'*' ; 00-07
    dta d'o', $00, d'p', d'u', $00, d'i', d'-', d'=' ; 08-0F
    dta d'v', $00, d'c', $00, $00, d'b', d'x', d'z' ; 10-17
    dta d'4', $00, d'3', d'6', $00, d'5', d'2', d'1' ; 18-1F
    dta d',', d' ', d'.', d'n', $00, d'm', d'/', $00 ; 20-27
    dta d'r', $00, d'e', d'y', $00, d't', d'w', d'q' ; 28-2F
    dta d'9', $00, d'0', d'7', $00, d'8', d'<', d'>' ; 30-37
    dta d'f', d'h', d'd', $00, $00, d'g', d's', d'a' ; 38-3F

    run main