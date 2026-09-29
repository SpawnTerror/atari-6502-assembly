; -----------------------------------------------------------------------------
; Program:     scrolling-letters.asm
; Description: 10 parallel falling letters using Game Loop
; Author:      Spawn
; Date:        2026-09-29
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

; This is choppy and slow, using OS.

CH          = $02FC
WARMSV      = $E477
MAX_ENT     = 10

; OS Constants required for print_text
ROWCRS      = $54
COLCRS      = $55
ICCOM       = $0342
ICBAL       = $0344
ICBAH       = $0345
ICBLL       = $0348
ICBLH       = $0349
CIQV        = $E456
PUT         = 9

; Fast zero page variable
    ORG $0080
LOOP_ID .ds 1

; Arrays, state of 10 letters
    ORG $2000
IS_ACTIVE:  :MAX_ENT dta $00     
CHAR:       :MAX_ENT dta $00     
X_POS:      :MAX_ENT dta $00     
Y_POS:      :MAX_ENT dta $00     

    ORG $3000

main:
    lda #$FF
    sta CH

game_loop:
    jsr read_keyboard
    jsr update_physics
    jsr draw_screen
    jmp game_loop

; --- Read keyboard ---
read_keyboard:
    lda CH
    cmp #$FF
    beq read_done

    cmp #$21
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
    
    ; --- TRANSLATION FIX ---
    ; Load raw scancode (0-63) into Y. 
    ; We use Y so we don't destroy our slot counter in X.
    ldy CH              
    lda KEY_LUT, y      ; Fetch ATASCII letter from our look-up table
    sta CHAR, x         ; Store the real English letter in our entity array
    ; -----------------------
    
    lda #0
    sta Y_POS, x
    
    txa
    clc
    adc #10
    sta X_POS, x

clear_key:
    lda #$FF
    sta CH

read_done:
    rts

exit_prog:
    jmp WARMSV

; --- Update physics ---
update_physics:
    ldx #0

phys_loop:
    lda IS_ACTIVE, x
    cmp #0
    beq next_slot

    inc Y_POS, x
    lda Y_POS, x

    cmp #24
    bne next_slot

    lda #0
    sta IS_ACTIVE, x

next_slot:
    inx
    cpx #MAX_ENT
    bne phys_loop
    rts

; --- Draw screen ---
draw_screen:
    lda #<cls
    ldy #>cls
    jsr print_text

    ldx #0

draw_loop:
    lda IS_ACTIVE, x
    cmp #0
    beq next_draw

    lda Y_POS, x
    sta ROWCRS
    lda X_POS, x
    sta COLCRS

    lda CHAR, x
    sta draw_char_val

    txa
    pha

    lda #<draw_msg
    ldy #>draw_msg
    jsr print_text

    pla
    tax

next_draw:
    inx
    cpx #MAX_ENT
    bne draw_loop

    ; Delay Loop
    ldy #$FF
delay_outer:
    ldx #$FF
delay_inner:
    dex
    bne delay_inner
    dey
    bne delay_outer

    rts    

; --- Subroutines ---
print_text:
    ldx #0          
    sta ICBAL, x    
    tya             
    sta ICBAH, x    
    lda #PUT        
    sta ICCOM, x
    lda #$FF        
    sta ICBLL, x
    lda #$00        
    sta ICBLH, x
    jsr CIQV        
    rts

; --- DATA STRINGS ---
cls:
    dta $7D, $9B

draw_msg:
draw_char_val:
    dta $00, $9B        

; 64-byte Keyboard Matrix to ATASCII Look-Up Table
KEY_LUT:
    dta c'l', c'j', c';', $00, $00, c'k', c'+', c'*' ; 00-07
    dta c'o', $00, c'p', c'u', $9B, c'i', c'-', c'=' ; 08-0F
    dta c'v', $00, c'c', $00, $00, c'b', c'x', c'z' ; 10-17
    dta c'4', $00, c'3', c'6', $1B, c'5', c'2', c'1' ; 18-1F
    dta c',', c' ', c'.', c'n', $00, c'm', c'/', $00 ; 20-27
    dta c'r', $00, c'e', c'y', $7F, c't', c'w', c'q' ; 28-2F
    dta c'9', $00, c'0', c'7', $7E, c'8', c'<', c'>' ; 30-37
    dta c'f', c'h', c'd', $00, $00, c'g', c's', c'a' ; 38-3F

    run main