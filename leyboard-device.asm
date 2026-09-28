; -----------------------------------------------------------------------------
; Program:     keyboard-device.asm
; Description: Open a new channel to handle the keyboard input
; Author:      Spawn
; Date:        2026-09-27
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

; CIO Commands
OPEN        = 3     ; page 88 CIO commands
GET         = 7
PUT         = 9
CLOSE       = 12

; Colours
COLOUR_1    = $02C5 ; page 64 shadow registers 
COLOUR_2    = $02C6
COLOUR_4    = $02C8
BLACK       = $00
WHITE       = $0F

; CIO Mailboxes
ICCOM   = $0342     ; page 85 - 86
ICBAL   = $0344      
ICBAH   = $0345      
ICBLL   = $0348      
ICBLH   = $0349      
ICAX1   = $034A     ; Auxiliary 1 (Required for OPEN command)
                    ; 4 for READ, 8 for WRITE, 12 for both    
ICAX2   = $034B     ; Auxiliary 2 (Required for OPEN command)
                    ; 0 for keyboard (not needed)
CIQV    = $E456

; Text position
ROWCRS  = $54        
COLCRS  = $55        

; Quit subroutine
WARMSV  = $E477

; --- PROGRAM START ---
    ORG $3000

main:
    ; Configure colours
    lda #BLACK
    sta COLOUR_2
    sta COLOUR_4

    lda #WHITE
    sta COLOUR_1

    ; Open channel 1 (for keyboard) spaced 16 bytes apart from channel 0 (screen)
    ldx #$10
    lda #OPEN
    sta ICCOM, x

    ; Load 4 into A and set Auxiliary 1 to read only access
    lda #4
    sta ICAX1, x

    ; Load 0 into A and set Auxiliary 2 to nothing
    lda #0
    sta ICAX2, x

    ; Load low byte of dev name string (K:) to point CIO buffer address to string
    lda #>keyboard_device
    sta ICBAH, x
    lda #<keyboard_device
    sta ICBAL, x

    ; Call CIO vector to setup the above
    jsr CIQV

    ; Clear screen
    lda #<cls
    ldy #>cls
    jsr print_text

    ; Position
    lda #10
    sta ROWCRS
    lda #10
    sta COLCRS

    ; Print 'Hello World!'
    lda #<msg1
    ldy #>msg1
    jsr print_text

    ; Position
    lda #12
    sta ROWCRS
    lda #10
    sta COLCRS

    ; Print 'Key pressed: '
    lda #<msg2      
    ldy #>msg2      
    jsr print_text

    ; Position
    lda #14         
    sta ROWCRS
    lda #10         
    sta COLCRS

    ; Print 'Press SPACE to quit'
    lda #<msg3      
    ldy #>msg3      
    jsr print_text

wait_key:
    ; Loads hex $10 into X to target Channel 1 & loads the GET command (7) into A.
    ldx #$10
    lda #GET
    sta ICCOM, x

    ; Trick, load 0 into A = CIO buffer length is 0. OS pauses until key pressed
    ; Then returns a single character directly inside the A register
    lda #0          
    sta ICBLL, x
    sta ICBLH, x

    ; Execute the above with GET command (7) Program halts until key pressed
    jsr CIQV

    ; Compare key in A with hex $20 (ATASCII for space)
    cmp #$20
    beq exit_prog

    ; Pressed key in A goes into blank space inside data string
    sta msg2_char

    ; Move cursor back into position of character pressed
    lda #12         
    sta ROWCRS
    lda #10         
    sta COLCRS

    ; Print mutated string
    lda #<msg2      
    ldy #>msg2      
    jsr print_text

    ; Loop back
    jmp wait_key

exit_prog:
    ; Clean up our open channel before quit!
    ldx #$10
    lda #CLOSE      
    sta ICCOM, x
    jsr CIQV
    jmp WARMSV

; --- SUBROUTINES ---

print_text:
    ldx #0          ; Target channel 0 (Screen Editor)
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

; --- DATA DEFINITIONS ---
keyboard_device:
    dta c'K:', $9B  ; Device name "K:" followed by End of Line
cls:
    dta $7D, $9B    
msg1:
    dta c'Hello World!', $9B 
msg2:
    dta c'Key pressed: '
msg2_char:
    dta c' ', $9B    ; We split this off so we have a label pointing exactly to the blank space
msg3:
    dta c'Press SPACE to quit', $9B

    run main