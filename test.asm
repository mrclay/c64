/**
 * C64, Kick assembler
 */

*=$0801   // Starting Address BASIC + 1 => SYS 2049
 
  .byte $0C,$08,$40,$00,$9E,$20,$32,$30,$36,$32,$00,$00,$00 // BASIC CODE: 1024 SYS 2062

  .const BORDER_COLOR      = $D020
  .const BACKGROUND_COLOR  = $D021
  .const RASTER_LINE       = $D012
  .const TEXT_START_H      = $04
  .const TEXT_START_L      = $00
  .const COLOR_START_H     = $D8
  .const COLOR_START_L     = $00
  .const ABOUT_POS         = $07D3
  .const PTR1              = $FB
  .const PTR2              = $FD
  .const CHAR_ROM          = $D000

  // Clear screen kernel function
  jsr $E544
 
  // Green border, black background
  lda #$0E
  sta BORDER_COLOR
  lda #$00
  sta BACKGROUND_COLOR

  // Bottom 2 rows blue space
  ldx #0
blue_lines:
  lda #32
  ora #%10000000
  sta $0798, x
  lda #$0e
  sta $DB98, x
  inx
  cpx #80
  bne blue_lines

tag_setup:
  ldx #0
tag:
  lda about, x
  cmp #0
  beq main_init
  ora #%10000000
  sta ABOUT_POS, x
  inx
  jmp tag
  
main_init:
  ldy #0
  ldx #1

main:
  jsr wait
  // Remove some from X
  txa
  sec
  sbc #40
  tax
  
  // PTR1 will serve as start of 2-byte address pointer [low, high]
  lda #TEXT_START_L
  sta PTR1
  lda #TEXT_START_H
  sta PTR1 + 1

  // PTR2 will serve as start of 2-byte address pointer [low, high]
  lda #COLOR_START_L
  sta PTR2
  lda #COLOR_START_H
  sta PTR2 + 1

loop_low_byte:
  // Maybe we'll write a space, depending on PTR1 and X
  lda #$ff
  sec
  sbc PTR1
  and #%00000111
  cmp #%00000111
  bne write_char
  jmp write_blank
  
write_blank:
  lda #32
  // Write only upper (negative) chars
  ora #%10000000
  // Address written to is really PTR1 + 1, PTR1 + Y
  sta (PTR1), y
  // Fixed color for these
  lda #$0E
  sta (PTR2), y
  jmp increments

write_char:
  // Put X + PTR1 into A
  txa
  clc
  adc PTR1
  // Write only upper (negative) chars
  ora #%10000000
  // Address written to is really PTR1 + 1, PTR1 + Y
  sta (PTR1), y

  // Store X on stack
  stx tmp_x
  txa

  // Make A change less often
  clc
  ror
  ror
  ror
  ror
  and #$0F
  // Use A as index into colors
  tax
  lda colors, x
  sta (PTR2), y

  // Restore X
  ldx tmp_x
  jmp increments

increments:
  inc PTR1
  inc PTR2
  // Check if PTR1 wrapped to 0
  lda PTR1
  cmp #0
  beq fb_wrapped_to_0

  // Two checks to see if we've written the last char.
  lda PTR1 + 1
  cmp #7
  bne loop_low_byte
  // Passed Check 1
  lda PTR1
  cmp #152
  bne loop_low_byte
  // Passed Check 2
  jmp main

fb_wrapped_to_0:
  // Bump the high address bytes
  inc PTR1 + 1
  inc PTR2 + 1
  jmp loop_low_byte

// Awaits the 255 raster line.
wait:
  sta tmp_a
!loop:
  // Check raster line
  lda #$FF
  cmp RASTER_LINE
  bne !loop-
  // Restore A
  lda tmp_a
  rts

// Smoother color gradient
colors:
  .byte 11, 11, 12, 15, 1, 7, 13, 3, 14, 6, 2, 10, 9, 8, 5, 4

about:
  .text "mrclay.org nov 2023"
  .byte 0

letter:
  .byte 0, 0, 0, 0, 0, 0, 0, 0

tmp_a: .byte 0
tmp_x: .byte 0

