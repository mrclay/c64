; Draw registers to bottom of screen and await a key press
;
!zone
debug
  jmp ._main
  
  DEBUG_GETIN = $FFE4
  DEBUG_SCNKEY = $FF9F
  DEBUG_OUTPUT_START = $C007

  ; In case other code is using this, we'll back its content
  ; up on the stack
  DEBUG_PTR1 = $FB

_debug_output
    ; This is a template we'll write into at these positions
    ; What   A    A              X    X
    ; idx    $1   $2             $5   $6
    !byte $81, $20, $20, $20, $98, $20, $20, $20
    ; What   Y    Y         SR (8 bits)
    ; idx    $9   $A        $C
    !byte $99, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
    !byte 0

  ; Vars for registers and status
_debug_axys !byte 0, 0, 0, 0

._main
  ; Capture registers and SR
  sta _debug_axys
  stx _debug_axys + 1
  sty _debug_axys + 2
  ; We can get raw SR byte by passing it through the stack
  php
  pla
  sta _debug_axys + 3
  
  ; Back up contents.
  lda DEBUG_PTR1
  pha
  lda DEBUG_PTR1 + 1
  pha

  ; Fill template with AA XX YY

  ; A high nibble, then low
  lda _debug_axys
  ror; ror; ror; ror
  jsr hexit_from_nibble
  sta _debug_output + $1
  lda _debug_axys
  jsr hexit_from_nibble
  sta _debug_output + $2

  ; X high nibble, then low
  lda _debug_axys + 1
  ror; ror; ror; ror
  jsr hexit_from_nibble
  sta _debug_output + $5
  lda _debug_axys + 1
  jsr hexit_from_nibble
  sta _debug_output + $6

  ; Y high nibble, then low
  lda _debug_axys + 2
  ror; ror; ror; ror
  jsr hexit_from_nibble
  sta _debug_output + $9
  lda _debug_axys + 2
  jsr hexit_from_nibble
  sta _debug_output + $A

  ; SR from bit 7 working down
  ldy #8
--
  dey
  ; Prepare to analyze bit Y of SR byte (in A)
  ; Get Y into X
  tya
  tax
  lda _debug_axys + 3
-
  ; Loop X to move our bit into position
  ror
  dex
  cpx #0
  bne -
  ; Output it
  and #%0001
  jsr hexit_from_nibble
  sta _debug_output + $C, y
  cpy #0
  bne --

  ; Output
  lda #>DEBUG_OUTPUT_START
  sta DEBUG_PTR1
  lda #<DEBUG_OUTPUT_START
  sta DEBUG_PTR1 + 1

  ldy #0
_display
  lda _debug_output, y
  beq key_wait
  sta (DEBUG_PTR1), y
  iny
  jmp _display

  ; Await key press
key_wait
  jsr DEBUG_SCNKEY
  jsr DEBUG_GETIN
  beq key_wait

  ; Restore ptr contents, registers
  pla
  sta DEBUG_PTR1 + 1
  pla
  sta DEBUG_PTR1
  lda _debug_axys
  ldx _debug_axys + 1
  ldy _debug_axys + 2

  rts


; Input A
; Result A is a hexit
!zone
hexit_from_nibble
  jmp ._main

._hexits !scr "0123456789abcdef"
._tmp_t !byte 0

._main
  ; Save Y
  sty ._tmp_t
  and #%00001111
  ; Write hexit
  tay
  lda ._hexits, y
  ; Restore Y
  ldy ._tmp_t

  rts

dot_halt
  lda #102
  sta $07E7
  jmp dot_halt
