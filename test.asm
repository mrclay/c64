
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


main

; !zone
; letter_testing
;   sei        ; disable interrupts
;
;   lda #$50
;   sta PTR1
;   lda #$D1
;   sta PTR1 + 1
;
;   ; Capture letter bytes
;
;   lda #$33  ; make the CPU see the Character Generator ROM...
;   sta $01   ; ...at $D000 by storing %00110011 into location $01
;
;
;   lda #1
;   sta $C000
;   lda #2
;   sta $C001
;   lda $C000
;   lda $C001
;
;   ldy #0
; .loop
;   lda (PTR1), y
;   sta letter, y
;   iny
;   cpy #8
;   bne .loop
;   lda #$37    ; switch in I/O mapped registers again...
;   sta $01     ; ... with %00110111 so CPU can see them
;
;
;   ; Setup PTR2 for writing
;   lda #TEXT_START_L
;   sta PTR2
;   lda #TEXT_START_H
;   sta PTR2 + 1
;
;   ldx #0
;   ldy #0
; .loop_x
; .loop_y
;   lda letter, x
;   and bit_masks, y
;   cmp bit_masks, y
;   beq .draw_1
;
; .draw_0
;   lda #32
;   sta (PTR2), y
;   jmp .next
; .draw_1
;   ; Draw 1
;   lda #224
;   sta (PTR2), y
;
; .next
;   iny
;   cpy #8
;   bne .loop_y
;
;   ; Advance to next line
;   ; Add 40 to PTR2
;   lda PTR2
;   clc
;   adc #40
;   sta PTR2
;   bcc .skip
;   inc PTR2 + 1
; .skip
;   ldy #0
;   inx
;   cpx #8
;   bne .loop_x
;
; done 
;   cli         ; enable interrupts
;   ; jmp done
;   rts

  jsr SR_screen_setup
  jsr SR_blue_space
  jsr SR_write_tag
  jsr SR_main_loop
  rts


!zone
SR_screen_setup
  ; Clear screen kernel function
  jsr $E544
 
  ; Green border, black background
  lda #$0E
  sta BORDER_COLOR
  lda #$00
  sta BACKGROUND_COLOR
  rts


!zone
SR_write_tag
  ldx #0
-
  lda about, x
  cmp #0
  beq .done
  ora #%10000000
  sta ABOUT_POS, x
  inx
  jmp -
.done
  rts


!zone
SR_blue_space
  ; Bottom 2 rows blue space
  ldx #0
-
  lda #32
  ora #%10000000
  sta $0798, x
  lda #$0e
  sta $DB98, x
  inx
  cpx #80
  bne -
  rts


!zone
SR_main_loop
-
  ; adjust char_choice_offset
  lda char_choice_offset
  sec
  sbc #MOVE_CHAR_BY
  sta char_choice_offset

  ; Pointers to top left
  ; PTR1 will point to screen character address
  lda #<CHAR_START
  sta PTR1
  lda #>CHAR_START
  sta PTR1_HIGH

  ; PTR2 will point to screen color address
  lda #<COLOR_START
  sta PTR2
  lda #>COLOR_START
  sta PTR2_HIGH

  lda #0
  sta idx_in_active_set
  sta active_letter_block

  jsr SR_draw_screen
  jmp -
  rts


!zone
SR_draw_screen
  ;jsr SR_await_raster_line
-
  jsr SR_draw_one
  jsr SR_bump_letter_idx
  jsr SR_bump_pointers
  cmp #0
  beq -
  ; end of screen reached
  
  lda color_idx
  clc
  adc #1
  and #$0F
  sta color_idx

  inc screen_writes
  lda screen_writes
  cmp #2
  bne .done
  lda #0
  sta screen_writes
  jsr SR_slide_letters
.done
  rts


!zone
SR_await_raster_line
-
  ; Check raster line
  lda #$FF
  cmp RASTER_LINE
  bne -
  rts


!zone
SR_draw_one
  jmp .decide_which_to_draw
.draw_big_letter_piece
  lda #(32 + 128)
  ldy ptr_idx
  ; Address written to is really PTR1 + 1, PTR1 + Y
  sta (PTR1), y
  ; Fixed color for these
  lda #$0E
  sta (PTR2), y
  rts
.draw_text_char
  ; Char is char_choice_offset + PTR1
  lda char_choice_offset
  clc
  adc PTR1
  ; Write only upper (negative) chars
  ora #%10000000

  ; Draw character
  ldy ptr_idx
  sta (PTR1), y

  ; Change color
  ldx color_idx
  lda colors, x
  ldy ptr_idx
  sta (PTR2), y
  rts

; Sets A to 1 or 0
.decide_which_to_draw
  lda active_letter_block
  ; idx < 2, we don't have a set for this
  cmp #2
  bcc .draw_text_char
  ; idx >= 4, we don't have a set for this
  cmp #4
  bcs .draw_text_char

  ; active_letter_block either 2 or 3
  ; check the active block
  cmp #2
  beq .pre_check_set_2
  jmp .pre_check_set_3
.pre_check_set_2
  ldy idx_in_active_set
  lda big_set_2, y
  and #1
  jmp .do_check
.pre_check_set_3
  ldy idx_in_active_set
  lda big_set_3, y
  and #1
.do_check
  cmp #0
  beq .draw_text_char
  jmp .draw_big_letter_piece


!zone
; Sets A to 1 if end of screen, otherwise 0
SR_bump_pointers
  inc PTR1
  inc PTR2

  jsr SR_is_end_of_screen
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
  rts
.return_1
  lda #1
  rts


!zone
SR_is_end_of_screen
  lda PTR1 + 1
  cmp #7
  bne .return_0
  lda PTR1
  cmp #152
  bne .return_0
  ; yes
  lda #1
  rts
.return_0
  lda #0
  rts


!zone
SR_bump_letter_idx
  inc idx_in_active_set
  lda idx_in_active_set
  ; < 160 nothing to do
  cmp #160
  bne .done
  ; We need to reset offset and bump active set
  lda #0
  sta idx_in_active_set
  ; The screen has 6 4-line blocks
  inc active_letter_block
  ; if < 6, we're OK to move on
  lda active_letter_block
  cmp #6
  bne .done
  ; Wrap active block
  lda #0
  sta active_letter_block
.done
  rts


!zone
SR_slide_letters
  rts


;;;;;;;;;;;;;;;;;;; Data

; Smoother color gradient
colors
  !byte 11, 11, 12, 15, 1, 7, 13, 3, 4, 14, 6, 2, 10, 9, 8, 5

color_idx !byte 0

about
  !scr "mrclay.org nov 2023"
  !byte 0

bit_masks
  !byte 128, 64, 32, 16, 8, 4, 2, 1

letter
  !byte 0, 0, 0, 0, 0, 0, 0, 0

tmp_a !byte 0
tmp_x !byte 0
char_choice_offset  !byte 1
ptr_idx !byte 0

active_letter_block !byte 0
idx_in_active_set !byte 0
screen_writes !byte 0

big_set_2
  !byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
big_set_3
  !byte 0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
