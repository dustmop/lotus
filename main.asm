.importzp buttons_curr, main_loop_ready, reply_length
.import EnableDisplay
.import DisableDisplay
.import SpriteDma
.import ClearScreen
.import WaitDuringStartup
.import WaitNewFrame
.import InputControllerInit
.import InputControllerReadButtons

.import LotusTextLoadGraphics
.import LotusTextLoadPalette
.import LotusTextInit
.import LotusTextUpdate
.import LotusTextDuringVblank

.include "system_defs.h.asm"

.segment "CODE"

.export RESET, NMI

response_buffer = $700

RESET:
  sei
  cld
  ldy #$40
  sty $4017
  dey
StackAndGraphics:
  ldx #$ff
  txs
  inx
  stx PPU_CTRL
  stx PPU_MASK
  stx $4010
  stx $4015

  jsr WaitDuringStartup

.scope EraseAllRam
  ldx #$00
Loop:
  lda #$00
  sta $000,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  lda #$ff
  sta $200,x
  inx
  bne Loop
.endscope

  jsr WaitDuringStartup
  jsr LotusTextLoadPalette
  jsr SpriteDma
  jsr LotusTextLoadGraphics
  jsr WaitDuringStartup
  jsr EnableDisplay

  lda #0
  sta main_loop_ready

  jsr LotusTextInit

MainLoop:
  jsr WaitNewFrame
  jsr InputControllerReadButtons
  lda buttons_curr
  jsr LotusTextUpdate
  bcs MessageEntered
  jmp MainLoop

MessageEntered:
  sta reply_length
  jsr WaitNewFrame
  jsr DisableDisplay
  jsr ClearScreen
.scope RenderMessages
  bit PPU_STATUS
  lda #$20
  sta PPU_ADDR
  lda #$40
  sta PPU_ADDR
  ldx #0
MessageLoop:
  lda message,x
  sta PPU_DATA
  inx
  cpx #message_length
  bne MessageLoop
RenderReply:
  lda #$20
  sta PPU_ADDR
  lda #$60
  sta PPU_ADDR
  ldx #0
ReplyLoop:
  lda response_buffer,x
  sta PPU_DATA
  inx
  cpx reply_length
  bne ReplyLoop
.endscope
  jsr WaitNewFrame
  jsr EnableDisplay

ForeverLoop:
  jmp ForeverLoop

message:
;     Y   O   U   _   W   R   O   T   E
.byte $19,$0f,$15,$00,$17,$12,$0f,$14,$05
message_length = * - message


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NMI:
  pha
  txa
  pha
  tya
  pha

  lda #1
  sta main_loop_ready

  jsr SpriteDma

  jsr LotusTextDuringVblank

  lda #0
  sta PPU_SCROLL
  sta PPU_SCROLL

  pla
  tay
  pla
  tax
  pla
  rti
