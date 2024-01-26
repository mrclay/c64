
*=$0801   ; Starting Address BASIC + 1 => SYS 2049

  !byte $0C,$08,$40,$00,$9E,$20,$32,$30,$36,$32,$00,$00,$00 ; BASIC CODE 1024 SYS 2062

  BORDER_COLOR      = $D020
  BACKGROUND_COLOR  = $D021
  RASTER_LINE       = $D012
  CHAR_START        = $0400
  COLOR_START       = $D800
  ABOUT_POS         = $07D3
  PTR1              = $FB
  PTR1_HIGH         = $FC
  PTR2              = $FD
  PTR2_HIGH         = $FE
  CHAR_ROM          = $D000
  MOVE_CHAR_BY      = 40

  SPRITE_DATA_L = $80
  SPRITE_DATA_R = $81
  SPRITE_DATA_SQUARE = $82

  SPRITE_PTR1 = $07F8
  SPRITE_X1 = $D000
  SPRITE_X_HIGH = $D010

  NUM_INTERRUPTS = 6

  ; How many lines before the target raster line before we start
  ; moving sprites
  PREP_LINES = 16

main
  jsr SR_screen_setup
  jsr SR_init_irqs
  jmp *


!zone
SR_screen_setup
  ; Clear screen kernel function
  jsr $E544

  lda #$00
  sta BORDER_COLOR
  lda #$00
  sta BACKGROUND_COLOR

  ; scale all 8 sprites x2
  lda #%11111111
  sta $D01D ; x-axis
  sta $D017 ; y-axis

  ; sprite FG colors
  !for i, 0, 7 {
    lda #0
    sta $D027 + i
  }

  ; point to our sprite data
  lda #SPRITE_DATA_L
  sta SPRITE_PTR1
  sta SPRITE_PTR1 + 1
  sta SPRITE_PTR1 + 2
  sta SPRITE_PTR1 + 3
  sta SPRITE_PTR1 + 4
  sta SPRITE_PTR1 + 5
  sta SPRITE_PTR1 + 6
  sta SPRITE_PTR1 + 7

  ; turn on sprites
  lda #%11111111
  sta $d015

  ; sprite X values
  ldy #0
  !for i, 0, 7 {
    lda sprite_x1_low_values + i, y
    sta SPRITE_X1 + (i * 2)
  }
  lda sprite_x_high_values
  sta SPRITE_X_HIGH

  ; sprite Y values
  ldy #0
  lda sprite_y_values, y
  !for i, 0, 7 {
    sta SPRITE_X1 + 1 + (2 * i)
  }

  jsr SR_fill_screen
  rts


!zone
irq_handler
  lda $D012
  lda active_interrupt
  cmp #5
  beq .irq_5
  jmp .irq_not_5

.irq_5
  inc frame
  ; jsr SR_move_colors
  jmp .done

.irq_not_5
  ; sprite Y values
  ldy active_interrupt
  !for i, 0, 7 {
    lda sprite_y_values, y
    sta SPRITE_X1 + 1 + (i * 2)
  }

.done
  ; set up for next rasterline
  ldy active_interrupt
  lda rasterlines + 1, y
  sta $D012
  iny
  cpy #NUM_INTERRUPTS
  bne .skip_reset_interrupt
  ldy #0
.skip_reset_interrupt
  sty active_interrupt
  asl $d019   ; clear interupt flag
  jmp $ea81


!zone
SR_after_screen
  ; TODO make these a lot faster or spread them across interrupts
  ; jsr SR_wrap_lines
  ; jsr SR_wrap_colors
  rts


;;;;;;;;;;;;;;;;;;; Data

; Smoother color gradient
colors
  !byte 11, 12, 15, 1, 7, 13, 3, 4, 14, 6, 2, 10, 9, 8, 5
  !byte 11, 12, 15, 1, 7, 13, 3, 4, 14, 6, 2, 10, 9, 8, 5
  !byte 11, 12, 15, 1, 7, 13, 3, 4, 14, 6, 2, 10, 9, 8, 5

color_idx !byte 0
about !scr "mrclay.org nov 2023"
  !byte 0
bit_masks !byte 128, 64, 32, 16, 8, 4, 2, 1
letter !fill 8
current_line !byte 0
current_x !byte 0
tmp_a !byte 0
tmp_x !byte 0
char_choice_offset  !byte 1
ptr_idx !byte 0
active_letter_block !byte 0
idx_in_active_set !byte 0
screen_writes !byte 0
temp_line !fill 40
frame !byte 0

active_interrupt !byte 0

rasterlines
  !for i, 0, 4 {
    !byte 50 + (42 * i) - PREP_LINES
  }
  !byte 210
  !byte 50 - PREP_LINES

sprite_y_values
  !for i, 0, 4 {
    !byte 50 + (42 * i)
  }

sprite_x1_low_values
  !byte  24 %$ff
  !byte  64 %$ff
  !byte 104 %$ff
  !byte 144 %$ff
  !byte 184 %$ff
  !byte 224 %$ff
  !byte 264 %$ff
  !byte 304 %$ff

sprite_x_high_values
  !byte %11000000


; sprite 1
*=$2000
!byte %11110000,%10010000,%00000000
!byte %11110000,%10010000,%01100000
!byte %11110000,%10010000,%01100000
!byte %11110000,%11110000,%00000000
!byte %00001111,%00001111,%00000000
!byte %00001111,%00001001,%00000000
!byte %00001111,%00001001,%00000000
!byte %00001111,%00001111,%00000000
!byte %11110000,%11110000,%11110000
!byte %00010000,%11110000,%10000000
!byte %00010000,%11110000,%10000000
!byte %11110000,%11110000,%11110000
!byte %00001111,%00001111,%00000000
!byte %00001001,%00001111,%00000000
!byte %00001001,%00001111,%00000000
!byte %00001111,%00001111,%00000000
!byte %00000000,%11110000,%11110000
!byte %01100000,%10010000,%11110000
!byte %01100000,%10010000,%11110000
!byte %00000000,%10010000,%11110000
!byte %00000000,%00000000,%00000000
  !byte 0
  !fill 64, $ff
  !fill 64, $ff
  !fill 64, $ff
  !fill 64, $ff
  !fill 64, $ff
  !fill 64, $ff
  !fill 64, $ff

!zone
SR_wrap_lines
  !for i, 0, 39 {
    lda CHAR_START + (24 * 40) + i
    sta temp_line + i
  }
  !for outer, 23, 0 {
    !for inner, 0, 39 {
      lda CHAR_START + (outer * 40) + inner
      sta CHAR_START + ((outer + 1) * 40) + inner
    }
  }
  !for i, 0, 39 {
    lda temp_line + i
    sta CHAR_START + i
  }
  rts


!zone
SR_move_colors
  ldy #0
  lda frame
  ror
  ror
  tax
.loop
  txa
  and #%00001111
  tax
  !for i, 0, 24 {
    lda colors, x
    sta COLOR_START + (i * 40), y
  }
  inx
  iny
  cpy #39
  beq .done
  jmp .loop
.done
  rts


!zone
SR_init_irqs
  sei                  ; set interrupt bit, make the CPU ignore interrupt requests
  lda #%01111111       ; switch off interrupt signals from CIA-1
  sta $DC0D

  AND $D011            ; clear most significant bit of VIC's raster register
  sta $D011

  lda $DC0D            ; acknowledge pending interrupts from CIA-1
  lda $DD0D            ; acknowledge pending interrupts from CIA-2

  ldy #0
  sty active_interrupt

  lda rasterlines, y
  sta $D012

  lda #<irq_handler    ; set interrupt vectors, pointing to interrupt service routine below
  sta $0314
  lda #>irq_handler
  sta $0315

  lda #%00000001       ; enable raster interrupt signals from VIC
  sta $D01A

  cli                  ; clear interrupt flag, allowing the CPU to respond to interrupt requests
  rts


!zone
SR_fill_screen
  lda #32 | %10000000
  ldy #0
.loop1
  !for i, 0, 24 {
    sta CHAR_START + (i * 40), y
  }
  iny
  cpy #39
  bne .loop1

  ldy #0
.loop2
  !for i, 0, 24 {
    lda colors, y
    sta COLOR_START + (i * 40), y
  }
  iny
  cpy #39
  beq .done
  jmp .loop2
.done
  rts
