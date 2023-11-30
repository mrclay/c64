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
  
  // $FB will serve as start of 2-byte address pointer [low, high]
  lda #TEXT_START_L
  sta $FB
  lda #TEXT_START_H
  sta $FC

  // $FD will serve as start of 2-byte address pointer [low, high]
  lda #COLOR_START_L
  sta $FD
  lda #COLOR_START_H
  sta $FE

loop_low_byte:
  // Maybe we'll write a space, depending on $FB and X
  lda #$ff
  sec
  sbc $FB
  and #%00000111
  cmp #%00000111
  bne write_char
  jmp write_blank
  
write_blank:
  lda #32
  // Write only upper (negative) chars
  ora #%10000000
  // Address written to is really $FC, $FB + Y
  sta ($FB), y
  // Fixed color for these
  lda #$0E
  sta ($FD), y
  jmp increments

write_char:
  // Put X + $FB into A
  txa
  clc
  adc $FB
  // Write only upper (negative) chars
  ora #%10000000
  // Address written to is really $FC, $FB + Y
  sta ($FB), y

  // Store X on stack
  txa
  pha

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
  sta ($FD), y

  // Restore X
  pla
  tax
  jmp increments

increments:
  inc $FB
  inc $FD
  // Check if $FB wrapped to 0
  lda $FB
  cmp #0
  beq fb_wrapped_to_0

  // Two checks to see if we've written the last char.
  lda $FC
  cmp #7
  bne loop_low_byte
  // Passed Check 1
  lda $FB
  cmp #152
  bne loop_low_byte
  // Passed Check 2
  jmp main

fb_wrapped_to_0:
  // Bump the high address bytes
  inc $FC
  inc $FE
  jmp loop_low_byte

// Awaits the 255 raster line.
wait:
  // Store A to be nice
  pha
wait_1:
  // Check raster line
  lda #$FF
  cmp RASTER_LINE
  bne wait_1
  // Restore A
  pla
  rts

// Smoother color gradient
colors:
  .byte 11, 11, 12, 15, 1, 7, 13, 3, 14, 6, 2, 10, 9, 8, 5, 4

about:
  .text "mrclay.org nov 2023"
  .byte 0
