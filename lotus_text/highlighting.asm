.export ConvertInputIntoLeafCommand
.export ConvertInputIntoSymbolSelect
.export block_data

.importzp user_input

.include "system_defs.h.asm"

INPUT_BUTTON_D_PAD = INPUT_BUTTON_UP | INPUT_BUTTON_RIGHT | INPUT_BUTTON_DOWN | INPUT_BUTTON_LEFT

INPUT_BUTTON_A_AND_B = INPUT_BUTTON_A | INPUT_BUTTON_B

COMBO_A_B = 4

.segment "CODE"

_gen_block_data:
.include "gen/block_data.asm"
block_data = _gen_block_data - $08

CONTROL_INDEX      = $00
DOUBLE_UP_INDEX    = $08
UP_INDEX           = $10
UP_RIGHT_INDEX     = $18
DOUBLE_RIGHT_INDEX = $20
RIGHT_INDEX        = $28
DOWN_RIGHT_INDEX   = $30
DOWN_INDEX         = $38
DOUBLE_DOWN_INDEX  = $40
DOWN_LEFT_INDEX    = $48
LEFT_INDEX         = $50
DOUBLE_LEFT_INDEX  = $58
UP_LEFT_INDEX      = $60


.proc ConvertInputIntoLeafCommand
  ldx #0
  lda user_input
  and #INPUT_BUTTON_D_PAD
  beq Failure
.scope TryUp
  cmp #INPUT_BUTTON_UP
  bne Next
  inx
  lda #UP_INDEX
  bpl Done
Next:
.endscope
.scope TryRight
  cmp #INPUT_BUTTON_RIGHT
  bne Next
  inx
  lda #RIGHT_INDEX
  bpl Done
Next:
.endscope
.scope TryDown
  cmp #INPUT_BUTTON_DOWN
  bne Next
  inx
  lda #DOWN_INDEX
  bpl Done
Next:
.endscope
.scope TryLeft
  cmp #INPUT_BUTTON_LEFT
  bne Next
  inx
  lda #LEFT_INDEX
  bpl Done
Next:
.endscope
.scope TryUpRight
  cmp #(INPUT_BUTTON_UP | INPUT_BUTTON_RIGHT)
  bne Next
  dex
  lda #UP_RIGHT_INDEX
  bpl Done
Next:
.endscope
.scope TryDownRight
  cmp #(INPUT_BUTTON_DOWN | INPUT_BUTTON_RIGHT)
  bne Next
  dex
  lda #DOWN_RIGHT_INDEX
  bpl Done
Next:
.endscope
.scope TryDownLeft
  cmp #(INPUT_BUTTON_DOWN | INPUT_BUTTON_LEFT)
  bne Next
  dex
  lda #DOWN_LEFT_INDEX
  bpl Done
Next:
.endscope
.scope TryUpLeft
  cmp #(INPUT_BUTTON_UP | INPUT_BUTTON_LEFT)
  bne Next
  dex
  lda #UP_LEFT_INDEX
  bpl Done
Next:
.endscope
Failure:
  lda #$ff
Done:
  rts
.endproc


.proc ConvertInputIntoSymbolSelect
  lda user_input
  and #INPUT_BUTTON_A_AND_B
  beq Failure
.scope TryB
  cmp #INPUT_BUTTON_B
  bne Next
  lda #0
  bpl Done
Next:
.endscope
.scope TryA
  cmp #INPUT_BUTTON_A
  bne Next
  lda #2
  bpl Done
Next:
.endscope
.scope TryAAndB
  cmp #(INPUT_BUTTON_A | INPUT_BUTTON_B)
  bne Next
  lda #COMBO_A_B
  bpl Done
Next:
.endscope
Failure:
  lda #$ff
Done:
  rts
.endproc
