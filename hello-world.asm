; SpawnTerror 20-09-2026
; hello.asm
; My first asm program for Atari 65 XE

    ; column 0 - labels 
    ; column 1 - instructions eg. lda, sta and directives eg. ORG, dta

;
; STEP 1 - Assigning labels, memory definitions
;

ICCOM  = $0342   ; CIO Command - Central input output subsystem address, IOCBs - Input/Output Control Blocks
ICBAL  = $0344   ; Buffer Address Low byte
ICBAH  = $0345   ; Buffer Address High byte
ICBLL  = $0348   ; Buffer Length Low byte
ICBLH  = $0349   ; Buffer Length High byte
CIQV   = $E456   ; CIO Call Vector
WARMSV = $E477   ; OS Warm Start (Exit routine)
CH     = $02FC   ; Internal hardware keyboard code

;
; STEP 2 - Set the memory origin and create the entry label
;

    ; $0000 to $1FFF (~8KB): OS variables, CPU stack, and DOS.
    ; $2000 to $BFFF (~40KB): Free RAM for your software and video memory.
    ; $C000 to $FFFF (~16KB): Hardware registers and the OS ROM. 
    ; When you call the CIO vector at $E456, the CPU is reading code permanently 
    ; burned into a physical ROM chip at this location.

    ORG $2000 ; Origin, 64kb of ram from $0000 to $FFFF, we use 8192 in decimal

start: ; label, removed by assembler upon compile, points to $2000

;
; STEP 3 - Configure CPU registers to command the operating system
;

    ldx #0 ; load register x with 0 (as we want $0342 address - COMMAND 9 - print)
    lda #9 ; load accumulator with 9 (print)
    sta ICCOM,x ; store 9 in $0342 + 0

;
; STEP 4 - Provide memory address and length for my text string
;

    ; Provide memory address of text string
    lda #<msg   ; load accumulator with lower byte of the message address (for example $2030 is $30)
    sta ICBAL,x ; store accumulator in label + 0
    lda #>msg   ; load accumulator with higher byte of the message address (for example $2030 is $20)
    sta ICBAH,x ; store accumulator in label + 0

    ; Provide maximum length of the text, maximum 255 as this CPU only works with 255 max
    lda #$FF    ; move buffer length value 255 into accumulator
    sta ICBLL,x ; store this at lower byte address
    lda #$00    ; move buffer length value 0 into accumulator
    sta ICBLH,x ; store this at higher byte address

;
; STEP 5 - Call operating system and wait for key press to exit
;

    jsr CIQV    ; call CIO vector in OS ROM

wait:

    lda CH      ; read keyboard hardware register and store into accumulator
    cmp #255  ; 255 ($FF) means no key pressed
    beq wait    ; if equal to 255 loop back to wait:

    jmp WARMSV ; else, exit back to DOS / OS

;
; STEP 6 - The message
;

msg:

    dta c'Hello World!', $9B    ; define text atascii, assembler directive not CPU instruction
                                ; place raw 8 bit values into physical RAM at this location
                                ; c means transalte into atari atascii hex byte values
                                ; $9B is end of file