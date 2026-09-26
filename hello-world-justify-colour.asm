; -----------------------------------------------------------------------------
; Program:     hello-world-justify-colour.asm
; Description: Hello World using white text and black background
; Author:      Spawn
; Date:        2026-09-25
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

    ORG $2000 

; --- OS shadow registers ---
COLOUR1     = $02C5     ; Text colour luminace
COLOUR2     = $02C6     ; Background colour
COLOUR4     = $02C8     ; Border colour

; --- OS CIO registers ---
ICCOM       = $0342     ; CIO Command
ICBAL       = $0344     ; Buffer Address Low byte
ICBAH       = $0345     ; Buffer Address High byte
ICBLL       = $0348     ; Buffer Length Low byte
ICBLH       = $0349     ; Buffer Length High byte
CIQV        = $E456     ; CIO Call Vector

; --- CIO commands ---
PRINT       = 9
PUTCHARS    = 11

; --- OS cursor registers ---
ROWCRS      = $54       ; OS Row Cursor
COLCRS      = $55       ; OS Column Cursor

; --- System vectors and hardware ---
WARMSV      = $E477     ; OS warm restart (exit)
CH          = $02FC     ; Internal hardware keyboard code (pressed key)

main:
    ; STEP 1: Configure screen colours 
    lda #$00            ; $00 is Black
    sta COLOUR2         ; Set Background
    sta COLOUR4         ; Set Border

    lda #$0F            ; $0F is Pure White (hue 0, luminance 15)
    sta COLOUR1         ; Set Text

    ;  STEP 2: Clear the screen via CIO 
    ldx #0              ; Target channel 0 (screen editor) - It is already open

    lda #PUTCHARS       ; Use command 11 (put characters) instead of 9 (print)
    sta ICCOM, x        ; Store 9 at ICCOM + x

    lda #<cls           ; Point to clear screen low byte
    sta ICBAL, x
    lda #>cls           ; Point to clear screen high byte
    sta ICBAH, x

    jsr CIQV            ; Execute CIO vector

    ; STEP 3: Position the cursor
    lda #12             ; Load row 12
    sta ROWCRS

    lda #10             ; Load column 10
    sta COLCRS

    ; STEP 4: Print the message
    ldx #0              ; Back from subroutine CIQV destroyed the register X (maybe)

    lda #PRINT          ; Print
    sta ICCOM, x

    lda #<msg           ; Message low byte
    sta ICBAL, x
    lda #>msg           ; Message high byte
    sta ICBAH, x

    lda #$FF            ; Max length low byte 
    sta ICBLL, x
    lda #$00            ; Max length high byte
    sta ICBLH, x

    jsr CIQV            ; Execute CIO vector

wait:
    lda CH              ; Read hardware keyboard register
    cmp #255          ; 255 = no key pressed
    beq wait            ; If 255, loop back to 'wait'

    jmp WARMSV          ; Else if key pressed, exit to OS

; --- Data definitions ---
cls:
    dta $7D, $9B        ; Clear screen ATASCII code and EOF code

msg:
    dta c'Hello World!', $9B

    run main            ; Define $02E0 run vector for a clean boot
