#importonce

#import "ptrs.asm"

// Draw registers to bottom of screen and await a key press
//
debug:
  jmp !main+
  
  .const DEBUG_GETIN   = $FFE4
  .const DEBUG_SCNKEY  = $FF9F
  .const DEBUG_OUTPUT_START = $C007

  _debug_output:
    // This is a template we'll write into at these positions:
    // Pos:    1    2              5    6              9    A
    .byte $81, $20, $20, $20, $98, $20, $20, $20, $99, $20, $20
    .byte 0

  // Vars for registers
  _debug_axy: .byte 0, 0, 0

!main:
  sta _debug_axy
  stx _debug_axy + 1
  sty _debug_axy + 2

  // Fill template with AA XX YY

  // A high nibble, then low
  ror; ror; ror; ror
  jsr hexit_from_nibble
  sta _debug_output + $1
  lda _debug_axy
  jsr hexit_from_nibble
  sta _debug_output + $2

  // X high nibble, then low
  lda _debug_axy + 1
  ror; ror; ror; ror
  jsr hexit_from_nibble
  sta _debug_output + $5
  lda _debug_axy + 1
  jsr hexit_from_nibble
  sta _debug_output + $6

  // Y high nibble, then low
  lda _debug_axy + 2
  ror; ror; ror; ror
  jsr hexit_from_nibble
  sta _debug_output + $9
  lda _debug_axy + 2
  jsr hexit_from_nibble
  sta _debug_output + $A

  // Output
  lda #>DEBUG_OUTPUT_START
  sta PTR1
  lda #<DEBUG_OUTPUT_START
  sta PTR1 + 1

  ldy #0
!display:
  lda _debug_output, y
  beq !loop+
  sta (PTR1), y
  iny
  jmp !display-

  // Await key press
!loop:
  jsr DEBUG_SCNKEY
  jsr DEBUG_GETIN
  beq !loop-

  rts


// Input: A
// Result: A is a hexit
hexit_from_nibble:
  jmp !main+

  !hexits: .text "0123456789abcdef"
  !tmp_t: .byte 0

!main:
  // Save Y
  sty !tmp_t-
  and #%00001111
  // Write hexit
  tay
  lda !hexits-, y
  // Restore Y
  ldy !tmp_t-

  rts

dot_halt:
  lda #102
  sta $07E7
  jmp dot_halt
