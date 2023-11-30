// ***************************
// * Example: Move a sprite  *
// ***************************
 
*=$0801   // Starting Address BASIC + 1 => SYS 2049
 
  .byte $0C,$08,$40,$00,$9E,$20,$32,$30,$36,$32,$00,$00,$00 // BASIC CODE: 1024 SYS 2062
  
  // Define some Constants for convenience
  .const CLEAR   = $E544
  .const CHROUT  = $FFD2
  .const GETIN   = $FFE4
  .const SCNKEY  = $FF9F 
  .const ENTER   = $C202
  .const INVERSE = $C204
  .const NORMAL  = $C206
  .const MARK    = $C208

  .const COLOR_BLACK       = $00
  .const COLOR_GREEN       = $05
  .const COLOR_LIGHTGREEN  = $0D

  .const SCREEN_CENTER     = $0590
  
  .const SPRITE_0_X_POSITION = $D000
  .const SPRITE_0_UPPER_X    = $D010
  
  .const SPRITE_0_Y_POSITION = $D001
 
  .const BORDER_COLOR        = $D020
  .const BACKGROUND_COLOR    = $D021
 
  .const SPRITE_0_COLOR      = $D027
  
  .const SPRITE_0_POINTER    = $0400 + $03F8 // Last 8 Bytes of Screen RAM
  .const SPRITE_0_DATA       = $0340         // Block 13, 13*64=>832 => $0340

 
  // Start Program
  jsr $E544             // call the Function that clears the screen
 
  lda #$0D              // using block 13 for sprite0
  sta SPRITE_0_POINTER  // set block 13 as target address for Data of Sprite0
 
  // Initialization
  lda #COLOR_GREEN      // load green color code into A
  sta BORDER_COLOR      // make border green
    
  lda #COLOR_LIGHTGREEN // load lightgreen color code into A
  sta BACKGROUND_COLOR  // make background lightgreen
  
  lda #$01              // enable...
  sta $D015             // ...Sprite 0 => %0000 0001 (all sprites off except Sprite 0)
  
  lda #COLOR_BLACK      // load black color code into A
  sta SPRITE_0_COLOR    // make Sprite0 completely black
  
  // Reset Sprite Data
  ldx #$00    // init x
  lda #$00    // init a
  
clean:
  sta SPRITE_0_DATA,x   // write 0 into sprite data at x
  inx                   // increment x
  cpx #$3F              // is x <= 63?
  bne clean             // if yes, goto clean
  
  // Build the Sprite
  ldx #$00              // init x
build:
  lda data, x           // load data at x
  sta SPRITE_0_DATA,x   // write into sprite data at x
  inx                   // increment x
  cpx #$3F              // is x <= 63?
  bne build             // if yes, goto build
  
  // Set Start Location of Sprite 0
  ldx #24                   // initial x position
  ldy #50                   // initial y position
  stx SPRITE_0_X_POSITION   // move sprite 0 to x position
  sty SPRITE_0_Y_POSITION   // move sprite 0 to y position

game_loop:
  jsr wait
  jsr SCNKEY    // get key
  jsr GETIN     // put key in acc
  
  cmp #68
  beq right_try_move

  cmp #65
  beq left_try_move
  
  cmp #83
  beq down_try_move
  
  cmp #87
  beq up_try_move

  lda SPRITE_0_X_POSITION
  jsr hex_from_int
  sty SCREEN_CENTER
  stx SCREEN_CENTER + 1
  lda SPRITE_0_UPPER_X
  jsr hex_from_int
  sty SCREEN_CENTER + 2
  stx SCREEN_CENTER + 3

  jmp game_loop

down_try_move:
  lda SPRITE_0_Y_POSITION
  cmp #240
  bcs game_loop             // Y too high to move
  adc #10
  sta SPRITE_0_Y_POSITION
  jmp game_loop

up_try_move:
  lda SPRITE_0_Y_POSITION
  cmp #60
  bcc game_loop             // Y too low to move
  sbc #10
  sta SPRITE_0_Y_POSITION
  jmp game_loop

right_try_move:
  lda SPRITE_0_UPPER_X
  and #1                    // mask bit 1
  cmp #1
  beq right_handle_upper    // branch if sprite > 255
  jmp right_nudge_x

right_handle_upper:
  lda SPRITE_0_X_POSITION
  cmp #70
  bcs game_loop             // too high to move
  jmp right_nudge_x

right_nudge_x:
  lda SPRITE_0_X_POSITION
  clc
  adc #10
  sta SPRITE_0_X_POSITION
  bcs toggle_x_upper        // if overflowed, toggle upper
  jmp game_loop

left_try_move:
  lda SPRITE_0_UPPER_X
  and #1                    // mask bit 1
  cmp #1
  beq left_nudge_x          // sprite > 255, we can definitely move
  lda SPRITE_0_X_POSITION   // can we move?
  cmp #25
  bcs left_nudge_x          // > 25, yes
  jmp game_loop

left_nudge_x:
  lda SPRITE_0_X_POSITION
  sec
  sbc #10
  sta SPRITE_0_X_POSITION
  bcc toggle_x_upper        // carry was removed, toggle upper
  jmp game_loop

toggle_x_upper:
    lda SPRITE_0_UPPER_X
    eor #1
    sta SPRITE_0_UPPER_X
    jmp game_loop


  // Wait Subroutine
  //// This will make the c64 wait for roughly one frame
wait:
  lda #$FF    // load 255 into A
  cmp $D012   // look if current rasterline equals 255
  bne wait    // if no, goto wait
  rts         // if yes, return from subroutine


  // The Data for our Sprite
data:
  .byte %11111111, %11000000, 0
  .byte %10000000, %01000000, 0
  .byte %10000000, %01000000, 0
  .byte %10000000, %01000000, 0
  .byte %10000000, %01000000, 0
  .byte %10000000, %01000000, 0
  .byte %10000000, %01000000, 0
  .byte %10000000, %01000000, 0
  .byte %10000000, %01000000, 0
  .byte %11111111, %11000000, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0
  .byte 0, 0, 0

// Usage: LDA ...
//        JSR hex_from_int
//        X = high byte, Y = low byte
hex_from_int:
  pha
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexits, x
  sta tmp

  pla
  and #%00001111
  tax
  lda hexits, x
  tax
  ldy tmp
  rts

tmp:
  .byte 0
hexits:
  .text "0123456789abcdefg"
