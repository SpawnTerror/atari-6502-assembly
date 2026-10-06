; -----------------------------------------------------------------------------
; Program:     display-list.asm
; Description: Use display lists and graphics modes
; Author:      Spawn
; Date:        2026-10-05
; Platform:    Atari 8-bit / 6502
; -----------------------------------------------------------------------------

    org $2000

SAVMSC = $0058      ; screen memory address
WARMSV = $E477      ; warm reset OS subroutine
CH     = $02FC      ; keyboard value (255 if nothing pressed)
SDLSTL = $0230      ; display list address

screen_buffer           = $4000
eight_blank_lines       = $70   ; %01110000 for 8 blank lines for overscan
antic_mode              = 5     ; %00000010 lower bit for the graphics mode 5, 40 x 12 rows
load_memory_scan        = $40   ; %01000000 bit 6 request a memory pointer update
jump_to_vertical_blank  = $41   ; jump loop

main
    ; Load the display list
    lda #<display_list
    sta SDLSTL
    lda #>display_list
    sta SDLSTL+1

    ; Main program
    ldy #$00

loop
    ; Put the text data in the screen buffer
    lda text_data, y
    sta screen_buffer,y
    iny
    cpy #12
    bne loop

wait_for_key
    ; Press 'space' to warm reset subroutine
    lda CH
    cmp #255
    beq wait_for_key
    jmp WARMSV

display_list
    .byte eight_blank_lines, eight_blank_lines, eight_blank_lines
    .byte antic_mode + load_memory_scan, <screen_buffer, >screen_buffer
    .byte antic_mode, antic_mode, antic_mode, antic_mode, antic_mode, antic_mode
    .byte antic_mode, antic_mode, antic_mode, antic_mode, antic_mode
    .byte jump_to_vertical_blank, <display_list, >display_list

text_data
    dta d'Hello World!'