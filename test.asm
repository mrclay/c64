
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
  SPRITE_PTR2 = $07F9
  SPRITE_PTR3 = $07FA
  SPRITE_PTR4 = $07FB
  SPRITE_PTR5 = $07FC
  SPRITE_PTR6 = $07FD
  SPRITE_PTR7 = $07FE
  SPRITE_PTR8 = $07FF

  SPRITE_X1 = $D000

  NUM_INTERRUPTS = 6

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

  ; Pointers to top left
  ; PTR1 will point to screen character address
  lda #<CHAR_START
  sta PTR1
  lda #>CHAR_START
  sta PTR1_HIGH

  ; scale all 8 sprites x2
  lda #%11111111
	sta $D01D	; x-axis
	sta $D017	; y-axis

  ; sprite FG colors
	lda #$00
  !for i, 0, 7 {
    sta $D027 + i
  }

  ; point to our sprite data
  lda #SPRITE_DATA_SQUARE
  sta SPRITE_PTR1
  sta SPRITE_PTR2
  sta SPRITE_PTR3
  sta SPRITE_PTR6
  sta SPRITE_PTR7
  sta SPRITE_PTR8
  lda #SPRITE_DATA_L
  sta SPRITE_PTR4
  lda #SPRITE_DATA_R
  sta SPRITE_PTR5

  ; turn on sprite 1
  lda #%11111111
	sta $d015

  ; x positions
  !for i, 0, 7 {
    lda #(20 + (40 * i)) % 255
    sta SPRITE_X1 + (2 * i)
  }
  lda #%11000000
  sta $D010

  ; y positions
  lda #50
  !for i, 0, 7 {
    sta SPRITE_X1 + (i * 2) + 1
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
  jsr SR_after_screen
  jmp .done

.irq_not_5
  ldy active_interrupt
  lda sprite_y_values, y
  !for i, 0, 7 {
    sta SPRITE_X1 + 1 + (2 * i)
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
  ;jsr SR_wrap_lines
  ;jsr SR_wrap_colors
  rts


!zone
; Sets A to 1 if end of screen, otherwise 0
bump_pointers
  inc PTR1
  inc PTR2

  jmp screen_end_check
after_screen_end_check
  cmp #1
  beq .return_1

  ; check for low byte wrapping
  lda PTR1
  ; If not 0, we did not wrap
  cmp #0
  bne .return_0

  ; rollover high byte
  lda #0
  sta PTR1
  sta PTR2
  inc PTR1_HIGH
  inc PTR2_HIGH
.return_0
  lda #0
  jmp after_bump_pointers
.return_1
  lda #1
  jmp after_bump_pointers


!zone
screen_end_check
  lda PTR1 + 1
  cmp #7
  bne .return_0
  lda PTR1
  cmp #232
  bne .return_0
  ; yes
  lda #1
  jmp after_screen_end_check
.return_0
  lda #0
  jmp after_screen_end_check


;;;;;;;;;;;;;;;;;;; Data

; Smoother color gradient
colors !byte 11, 11, 12, 15, 1, 7, 13, 3, 4, 14, 6, 2, 10, 9, 8, 5

init_color_indices
  !byte  0, 0, 0, 1, 1, 1, 2, 2, 2, 3
  !byte  3, 3, 4, 4, 4, 5, 5, 5, 6, 6
  !byte  6, 7, 7, 7, 8, 8, 8, 9, 9, 9
  !byte 10,10,11,11,12,12,13,13,14,14
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

active_interrupt !byte 0

rasterlines
  !for i, 0, 4 {
    !byte 50 + (42 * i) - 15
  }
  !byte 210
  !byte 50 + (42 * 0) - 15

sprite_y_values
  !for i, 0, 4 {
    !byte 50 + (42 * i)
  }


; sprite 1
*=$2000
  !byte %11111111,%11111111,%11111110
  !byte %11111111,%11111111,%11111100
  !byte %11111111,%11111111,%11111100
  !byte %11111111,%11111111,%11111000
  !byte %11111111,%11111111,%11111000
  !byte %11111111,%11111111,%11110000
  !byte %11111111,%11111111,%11110000
  !byte %11111111,%11111111,%11100000
  !byte %11111111,%11111111,%11100000
  !byte %11111111,%11111111,%11000000
  !byte %11111111,%11111111,%10000000
  !byte %11111111,%11111111,%10000000
  !byte %11111111,%11111111,%00000000
  !byte %11111111,%11111111,%00000000
  !byte %11111111,%11111110,%00000000
  !byte %11111111,%11111110,%00000000
  !byte %11111111,%11111100,%00000000
  !byte %11111111,%11111100,%00000000
  !byte %11111111,%11111000,%00000000
  !byte %11111111,%11111000,%00000000
  !byte %11111111,%11110000,%00000000
  !byte 0
; sprite 2
  !byte %01111111,%11111111,%11111111
  !byte %00111111,%11111111,%11111111
  !byte %00111111,%11111111,%11111111
  !byte %00011111,%11111111,%11111111
  !byte %00011111,%11111111,%11111111
  !byte %00001111,%11111111,%11111111
  !byte %00001111,%11111111,%11111111
  !byte %00000111,%11111111,%11111111
  !byte %00000111,%11111111,%11111111
  !byte %00000011,%11111111,%11111111
  !byte %00000001,%11111111,%11111111
  !byte %00000001,%11111111,%11111111
  !byte %00000000,%11111111,%11111111
  !byte %00000000,%11111111,%11111111
  !byte %00000000,%01111111,%11111111
  !byte %00000000,%01111111,%11111111
  !byte %00000000,%00111111,%11111111
  !byte %00000000,%00111111,%11111111
  !byte %00000000,%00011111,%11111111
  !byte %00000000,%00011111,%11111111
  !byte %00000000,%00001111,%11111111
  !byte 0
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
SR_wrap_colors
  !for j, 0, 24 {
    lda COLOR_START + (j * 40)
    sta temp_line + j
  }
  !for i, 0, 38 {
    !for j, 0, 24 {
      lda COLOR_START + (j * 40) + i + 1
      sta COLOR_START + (j * 40) + i
    }
  }
  !for j, 0, 24 {
    lda temp_line + j
    sta COLOR_START + (j * 40) + 39
  }
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
  lda #<CHAR_START
  sta PTR1
  lda #>CHAR_START
  sta PTR1_HIGH

  lda #<COLOR_START
  sta PTR2
  lda #>COLOR_START
  sta PTR2_HIGH

  lda #0
  sta current_x
-
  lda PTR1
  ; Write only lower chars
  and #%01111111

  ; Draw character
  ldy ptr_idx
  sta (PTR1), y

  ; Color
  ldy current_x
  lda init_color_indices, y
  tay
  lda colors, y
  ldy #0
  sta (PTR2), y

  inc current_x
  lda current_x
  cmp #40
  bne skip_reset_current_x
  lda #0
  sta current_x

skip_reset_current_x
  jmp bump_pointers
after_bump_pointers
  cmp #0
  beq -
  ; end of screen reached
  rts
