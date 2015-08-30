.export InputControllerInit
.export InputControllerReadButtons

.include "system_defs.h.asm"

.importzp buttons_curr

.segment "CODE"

.proc InputControllerInit
  lda #0
  sta buttons_curr
  rts
.endproc

.proc InputControllerReadButtons
  ldy #1
  sty INPUT_PORT_1
  sty buttons_curr
  dey
  sty INPUT_PORT_1
Loop:
  lda INPUT_PORT_1
  lsr a
  rol buttons_curr
  bcc Loop
Done:
  lda buttons_curr
  rts
.endproc
