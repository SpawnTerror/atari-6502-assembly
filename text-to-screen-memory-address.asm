; -----------------------------------------------------------------------------
; Program:     text-to-screen-memory-address.asm
; Description: Use a pointer to a physical screen's memory location
;              and store the letters there
; Author:      Spawn
; Date:        2026-10-03
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

    org $2000

SAVMSC = $0058
WARMSV = $E477
CH     = $02FC

main:
    ldy #$00

loop
    lda hello, y
    sta (SAVMSC),y
    iny
    cpy #12
    bne loop

repeat:
    lda CH
    cmp #255
    beq repeat
    jmp WARMSV

hello:
    dta d'Hello World!'