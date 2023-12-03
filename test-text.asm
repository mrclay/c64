; C64

*=$0801   ; Starting Address BASIC + 1 => SYS 2049
 
  !byte $0C,$08,$40,$00,$9E,$20,$32,$30,$36,$32,$00,$00,$00 ; BASIC CODE: 1024 SYS 2062

  BORDER_COLOR      = $D020
  BACKGROUND_COLOR  = $D021
  RASTER_LINE       = $D012
  TEXT_START_L      = $00
  TEXT_START_H      = $04
  COLOR_START_L     = $00
  COLOR_START_H     = $D8
  ABOUT_POS         = $07D3
  PTR1 = $FB
  PTR2 = $FD

main:
  ; Clear screen kernel function
  jsr $E544
 
  ; Green border, black background
  lda #$0E
  sta BORDER_COLOR
  lda #$00
  sta BACKGROUND_COLOR

  lda #TEXT_START_L
  sta PTR1
  lda #TEXT_START_H
  sta PTR1 + 1

  lda #COLOR_START_L
  sta PTR2
  lda #COLOR_START_H
  sta PTR2 + 1

  ldx #7
  ldy #69
  lda #25
  clc
  jsr debug
  sec
  lda #0
  cmp #0
  jsr debug

  rts

!source "debug.asm"

; Input: line -> A
; Result: PTR1 has address of beginning of line A
set_PTR1_to_line:
  clc
  rol
  tax
  lda text_pos_data, x
  sta PTR1
  inx
  lda text_pos_data, x
  sta PTR1 + 1
  
  rts

text_pos_data:
  !byte $04, $00
  !byte $04, $28
  !byte $04, $50
  !byte $04, $78
  !byte $04, $A0
  !byte $04, $C8
  !byte $04, $F0
  !byte $05, $18
  !byte $05, $40
  !byte $05, $68
  !byte $05, $90
  !byte $05, $B8
  !byte $05, $E0
  !byte $06, $08
  !byte $06, $30
  !byte $06, $58
  !byte $06, $80
  !byte $06, $A8
  !byte $06, $D0
  !byte $06, $F8
  !byte $07, $20
  !byte $07, $48
  !byte $07, $70
  !byte $07, $98
  !byte $07, $C0
 