; -----------------------------------------------------------------------------
; Program:     hello-world-optimized.asm
; Description: Hello World using white text and black background
;              Optimized subroutine 'print_text' for reuse
; Author:      Spawn
; Date:        2026-09-25
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

; Saved approximately 12 bytes of RAM. The original code duplicated a 23-byte CIO configuration 
; block twice (46 bytes). The new structure uses a single 20-byte subroutine called by two 7-byte 
; instruction blocks (34 bytes total). Every additional text print in the future will now only 
; cost 7 bytes of memory instead of 23.
;
; This version is actually slower by 14 clock cycles per execution. Jumping to a subroutine (jsr) 
; costs 6 cycles, returning from it (rts) costs 6 cycles, and transferring the Y register to the 
; accumulator (tya) costs 2 cycles.


    org $2000

PRINT           = 9

COLOUR1         = $02C5         ; Text, zero-page address shadow register copied to GTIA
COLOUR2         = $02C6         ; Background, zero-page address
COLOUR3         = $02C8         ; Border, zero-page address

ICCOM           = $0342         ; 1/8 Input/Output Control Blocks 16-bytes on page 3 (e.g., read, write, draw)
ICBAL           = $0344         ; Data address low byte (pointer to text)
ICBAH           = $0345         ; Data address high byte (pointer to text)
ICBLL           = $0348         ; Data length low byte (how many characters)
ICBLH           = $0349         ; Data length high byte (how many characters)
CIQV            = $E456         ; The OS subroutine address we jump to when mail is ready

ROWCRS          = $54           ; Text row location, zero-page address
COLCRS          = $55           ; Text column location, zero-page address

WARMSV          = $E477         ; Warm reset address for clean quit
CH              = $02FC         ; Keyboard key pressed value address

main:

    lda #$00                    ; Load black $00 into the bacground and border addresses
    sta COLOUR2
    sta COLOUR3

    lda #$0F                    ; Load white $0F into the font address
    sta COLOUR1

    lda #<clear_screen           ; Load 'clearscreen' low and high bytes into registers a and y
    ldy #>clear_screen
    jsr print_text              ; Jump to subroutine to clear the screen then come back using rts

    lda #12                     ; Load number 12 into row and 10 into column addresses
    sta ROWCRS
    lda #10
    sta COLCRS

    lda #<message               ; Load 'message' low and high bytes into registers a and y 
    ldy #>message
    jsr print_text              ; Jump to subroutine again, but this time with a text message

wait:

    lda CH                      ; Grab keyboard raw keycode value from $02FC
    cmp #$FF                     ; Compare to 255 (no key pressed)
    beq wait                    ; Branch on equal means jump to wait (loop when nothing pressed)
    jmp WARMSV                  ; Loop finished, so we need to exit - jump to warm reset subroutine address

print_text:                     ; Custom subroutine used two times

    ldx #0
    sta ICBAL, x                ; Store message low byte address currently in 'a'
    tya                         ; Do the same with y high byte address, but first copy 'y' to 'a'
    sta ICBAH, x
    lda #PRINT                  ; Store 9 in 'a'
    sta ICCOM, x                ; Move it into the address
    lda #$FF                    ; Length of text 255 and 0 into the addresses
    sta ICBLL, x
    lda #$00
    sta ICBLH, x
    jsr CIQV                    ; Let CIO execute the print command now
    rts                         ; Return to the next command after the subroutine jump

clear_screen:
    dta $7D, $9B                ; Two bytes, one is clear screen, $9B is end of line

message:
    dta c'Hello World!', $9B    ; Main message bytes plus $9B as end of line

    run main                    ; Write memory address of 'main' into $02E0 so Atari can boot into it

