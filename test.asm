
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

main
  jsr SR_screen_setup
  jsr SR_main_loop
  rts


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

  ; turn on all 8 sprites
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
SR_main_loop
  lda #0
  sta screen_writes
-
  jsr SR_await_raster_line

  lda (PTR1), y
  eor #%10000000
  sta (PTR1), y

  jsr SR_wrap_lines

  ; Color
  lda #0
  sta (PTR2), y

  inc screen_writes
  lda screen_writes
  cmp #2
  bne skip_screen_writes_reset
  lda #0
  sta screen_writes
  jsr SR_wrap_colors

skip_screen_writes_reset
  jmp -
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


!zone
SR_await_raster_line
-
  ; Check raster line
  ldx #$f7
  cpx RASTER_LINE
  bne -
-
  ; Check raster line
  ldx #$f8
  cpx RASTER_LINE
  bne -
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

rlines
  !for i, 0, 4 {
    !byte 21 * i
  }
sprite_y_values
  !for i, 0, 4 {
    !byte (50 + (40 * i)) % 255
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
