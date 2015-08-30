.export WaitDuringStartup
.export WaitNewFrame
.export EnableDisplay
.export DisableDisplay
.export SpriteDma
.export ClearScreen

.importzp main_loop_ready

.include "system_defs.h.asm"

.segment "CODE"

.proc WaitDuringStartup
Wait:
  bit PPU_STATUS
  bpl Wait
  rts
.endproc

.proc WaitNewFrame
Loop:
  lda main_loop_ready
  beq Loop
  lda #0
  sta main_loop_ready
  rts
.endproc

.proc EnableDisplay
  pha
  lda #$88
  sta PPU_CTRL
  lda #$1e
  sta PPU_MASK
  lda #0
  sta PPU_SCROLL
  sta PPU_SCROLL
  pla
  rts
.endproc

.proc DisableDisplay
  pha
  lda #$06
  sta PPU_MASK
  pla
  rts
.endproc

.proc SpriteDma
  lda #$00
  sta OAM_ADDR
  lda #$02
  sta OAM_DMA
  rts
.endproc

.proc ClearScreen
  lda #$20
  sta PPU_ADDR
  lda #0
  sta PPU_ADDR
  ; Clear loop.
  ldy #4
  ldx #0
OuterLoop:
InnerLoop:
  sta PPU_DATA
  dex
  bne InnerLoop
  dey
  bne OuterLoop
  rts
.endproc
