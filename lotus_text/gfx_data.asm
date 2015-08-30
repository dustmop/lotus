.export LotusTextLoadGraphics
.export LotusTextLoadPalette

.include "system_defs.h.asm"

.importzp pointer

.segment "CODE"

.proc LotusTextLoadGraphics
  lda PPU_STATUS
  lda #$20
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldy #$00
Loop0:
  lda nametable+$000,y
  sta PPU_DATA
  iny
  bne Loop0
Loop1:
  lda nametable+$100,y
  sta PPU_DATA
  iny
  bne Loop1
Loop2:
  lda nametable+$200,y
  sta PPU_DATA
  iny
  bne Loop2
Loop3:
  lda nametable+$300,y
  sta PPU_DATA
  iny
  bne Loop3
  rts
.endproc

nametable:
  .incbin "nametable.dat"
.repeat 64
  .byte 0
.endrepeat

.proc LotusTextLoadPalette
  lda PPU_STATUS
  lda #$3f
  sta PPU_ADDR
  ldx #$00
  stx PPU_ADDR
Loop:
  lda palette,x
  sta PPU_DATA
  inx
  cpx #$20
  bne Loop
  rts
.endproc

palette:
;bg
.byte $0f,$30,$00,$00
.byte $0f,$30,$01,$00
.byte $0f,$30,$00,$01
.byte $0f,$0f,$0f,$0f
;sprite
.byte $0f,$27,$0f,$0f
.byte $0f,$0f,$0f,$0f
.byte $0f,$0f,$0f,$0f
.byte $0f,$0f,$0f,$0f
