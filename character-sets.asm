; -----------------------------------------------------------------------------
; Program:     character-sets.asm
; Description: Understanding mwa, mva and character sets (2 bits per colour)
; Author:      Spawn
; Date:        2026-10-05
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

    org $2000

WARMSV = $E477      ; warm reset OS subroutine
CH     = $02FC      ; keyboard value (255 if nothing pressed)

SDLSTL = $0230      ; display list address
CHBAS  = $02f4      ; character base register, write word into it with charset

charset                 = $3c00 ; character set 4 pages of 256 bytes, 1 kB
screen_buffer           = $4000
eight_blank_lines       = $70   ; %01110000 for 8 blank lines for overscan
load_memory_scan        = $40   ; %01000000 bit 6 request a memory pointer update
jump_to_vertical_blank  = $41   ; jump loop

antic_mode_5            = 5     ; %00000101 lower bits for the graphics mode 5, 40 x 12 rows
antic_mode_2            = 2     ; %00000010 lower bits for the graphics mode 2, 40 x 12 rows

main
    ; Load the display list
    mwa #display_list SDLSTL
    mva #>charset CHBAS

    ldx #0
loop
    mva characters,x charset,x
    inx
    cpx #8
    bne loop


wait_for_key
    ; Press 'space' to warm reset subroutine
    lda CH
    cmp #255
    beq wait_for_key
    jmp WARMSV

display_list
    .byte eight_blank_lines, eight_blank_lines, eight_blank_lines
    .byte antic_mode_2 + load_memory_scan, <screen_buffer, >screen_buffer
    .byte antic_mode_5, antic_mode_5, antic_mode_5, antic_mode_5, antic_mode_5, antic_mode_5
    .byte antic_mode_5, antic_mode_5, antic_mode_5, antic_mode_5, antic_mode_5
    .byte jump_to_vertical_blank, <display_list, >display_list

characters
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000