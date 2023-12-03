
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

  ; Clear screen kernel function
  jsr $E544
 
  ; Green border, black background
  lda #$0E
  sta BORDER_COLOR
  lda #$00
  sta BACKGROUND_COLOR

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




  ; Bottom 2 rows blue space
  ldx #0
blue_lines
  lda #32
  ora #%10000000
  sta $0798, x
  lda #$0e
  sta $DB98, x
  inx
  cpx #80
  bne blue_lines

tag_setup
  ldx #0
tag
  lda about, x
  cmp #0
  beq main
  ora #%10000000
  sta ABOUT_POS, x
  inx
  jmp tag

main
  ; jsr sr_wait
  ; Start at top left of screen memory and write each byte.
  lda #0
  sta active_letter_block
  sta letter_idx
  jsr sr_adjust_char_choice_offset
  jsr sr_move_pointers_to_topleft

  ; draw
  ;   jsr sr_should_draw_blank
  ;   cmp #0
  ;   beq skip_draw_char
  ;   jsr draw_char
  ;   jmp after_draw
  ; skip_draw_char
  ;   jsr draw_blank
  ; after_draw
  ; next_screen_position
  ; 

  jmp draw_something

sr_adjust_char_choice_offset
  lda char_choice_offset
  sec
  sbc #MOVE_CHAR_BY
  sta char_choice_offset
  rts

sr_move_pointers_to_topleft
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
  rts

draw_something
  ; Figure out what we're drawing.
  lda active_letter_block
  cmp #2
  ; idx < 2, we don't have a set for
  bcc draw_colored_char
  cmp #4
  ; idx >= 4, we don't have a set for
  bcs draw_colored_char

  ; active_letter_block either 2 or 3
  ldy letter_idx
  lda active_letter_block
  cmp #2
  beq pre_check_set_2
  jmp pre_check_set_3
pre_check_set_2
  lda big_set_2, y
  and #1
  jmp check_set
pre_check_set_3
  lda big_set_3, y
  and #1
check_set
  beq set_has_1
  jmp draw_colored_char
set_has_1
  jmp draw_blank

after_set_check
  cmp #1
  beq draw_blank
  jmp draw_colored_char

draw_blank
  lda #32 + 128
  ldy ptr_idx
  ; Address written to is really PTR1 + 1, PTR1 + Y
  sta (PTR1), y
  ; Fixed color for these
  lda #$0E
  sta (PTR2), y
  jmp next_screen_position

draw_colored_char
  ; Char is char_choice_offset + PTR1
  lda char_choice_offset
  clc
  adc PTR1
  ; Write only upper (negative) chars
  ora #%10000000
  ; Draw character
  ldy ptr_idx
  sta (PTR1), y

  ; Make color change less often
  lda char_choice_offset
  clc
  ror
  ror
  ror
  and #$0F
  ; Use A as index into colors
  tax
  lda colors, x
  ; Change color
  ldy ptr_idx
  sta (PTR2), y
  jmp next_screen_position

next_screen_position
  inc PTR1
  inc PTR2
  inc letter_idx

  ; Check if PTR1 wrapped to 0
  lda PTR1
  cmp #0
  beq ptr1_wrapped_to_0

  ; Two checks to see if we've written the last char.
  lda PTR1 + 1
  cmp #7
  bne handle_big_wrapping
  ; Passed Check 1
  lda PTR1
  cmp #152
  bne handle_big_wrapping
  ; Passed Check 2
  jmp main

ptr1_wrapped_to_0
  ; Bump the high address bytes
  inc PTR1 + 1
  inc PTR2 + 1

handle_big_wrapping
  lda letter_idx
  ; < 160 we're done with this position
  cmp #160
  bne jmp2draw_something
  jmp skip_draw_next

jmp2draw_something
  jmp draw_something

skip_draw_next
  ; We need to reset offset and bump active set
  lda #0
  sta letter_idx
  ; The screen has 6 4-line blocks
  inc active_letter_block
  ; if < 6, we're OK to move on
  lda active_letter_block
  cmp #6
  bne jmp2draw_something
  ; reset the active block
  lda #0
  sta active_letter_block
  inc screen_writes
  lda screen_writes
  cmp #0
  beq slide_letters
  jmp draw_something

slide_letters
  jmp draw_something

jmp2_draw_blank
  jmp draw_blank

; Awaits the 255 raster line.
sr_wait
  sta tmp_a
-
  ; Check raster line
  lda #$FF
  cmp RASTER_LINE
  bne -
  ; Restore A
  lda tmp_a
  rts

; Smoother color gradient
colors
  !byte 11, 11, 12, 15, 1, 7, 13, 3, 14, 6, 2, 10, 9, 8, 5, 4

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
letter_idx !byte 0
screen_writes !byte 0

big_set_2
  !byte 0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,1,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,1,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
big_set_3
  !byte 0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,0,1,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  !byte 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

track_line !byte 0
track_x !byte 0

!source "debug.asm"
