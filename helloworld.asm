ICCOM  = $0342   ; CIO Command
ICBAL  = $0344   ; Buffer Address Low byte
ICBAH  = $0345   ; Buffer Address High byte
ICBLL  = $0348   ; Buffer Length Low byte
ICBLH  = $0349   ; Buffer Length High byte
CIQV   = $E456   ; CIO Call Vector
WARMSV = $E477   ; OS Warm Start (Exit routine)
CH     = $02FC   ; Internal hardware keyboard code

    ORG $2000

start: 
    ldx #0
    lda #9
    sta ICCOM,x

    lda #<msg
    sta ICBAL,x
    lda #>msg
    sta ICBAH,x
    
    lda #$FF         
    sta ICBLL,x
    lda #$00
    sta ICBLH,x

    jsr CIQV

wait:
    lda CH       
    cmp #255     
    beq wait     

    jmp WARMSV

msg:
    dta c'Hello World!', $9B
