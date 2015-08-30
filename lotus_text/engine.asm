.export LotusTextInit
.export LotusTextUpdate
.export LotusTextDuringVblank


.import ConvertInputIntoLeafCommand
.import ConvertInputIntoSymbolSelect
.import block_data


.include "sprites.h.asm"
.include "system_defs.h.asm"


.segment "ZEROPAGE"


; Buttons being held on the input device.
user_input: .byte 0
; The currently inputted command, ignoring rendering and double presses.
current_command: .byte 0
; How long the current input has been pressed for, capped to $40.
step_same: .byte 0
; The leaf being rendered. Usually same as current_command, except for far
; leaves, which require a double press, or a few frames after a near command
; begins, to add a short delay (so that double presses render more nicely).
showing_leaf: .byte 0
; State for near / far leaf. $ff = begin, $fe = done, other = current near leaf.
double_state: .byte 0
; Currently selected icon within a leaf. $ff = none, $00 = left, $02 = right,
; $04 = both.
current_select: .byte 0
; Count down after a combo selection is released, to add soem input buffering
; for combo selections.
step_combo: .byte 0
; Index into the response buffer. That is, how many chars have been input.
response_index: .byte 0
; Used for the formula [S = T * 3 / 4].
tmp: .byte 0
; If non $ff, index of which leaf to highlight.
nmi_highlight_leaf: .byte 0
; If non $ff, index of which leaf to de-highlight.
nmi_clear_leaf: .byte 0
; If non $ff, high byte of the PPU address where to write response data.
nmi_response_ppu_high: .byte 0
; Low byte of the PPU address where to write response data.
nmi_response_ppu_low:  .byte 0
; Single byte to write as response data.
nmi_response_ppu_data: .byte 0

.exportzp user_input


.segment "CODE"


ALPHANUMERIC_TILE_START = $01
CONTROL_TILE_START = $25
INIT_LEAF_INDEX = $08
MIN_LEAF_OFFSET = $100 - ((INIT_LEAF_INDEX * 3/4) / 2)

BLANK_TILE  = $28
SPACE_TILE  = $00
PERIOD_TILE = $27
BACKSPACE_CTRL = $25
SPACE_CTRL     = $26
PERIOD_CTRL    = $27

LEAF_HIGHLIGHT_THRESHOLD = 5
CENTER_FORGET_THRESHOLD = 12
SYMBOL_COMBO_THRESHOLD = 4

DOUBLE_STATE_READY = $ff
DOUBLE_STATE_DENIED = $fe

SYMBOL_DENIED = $fe

COMBO_A_B = 4

RESPONSE_DISPLAY_V = 15

symbol_position_data = block_data + (13 * 8)

response_buffer = $700


.macro IncrementCapped place
  .local Done
  inc place
  bit place
  bvc Done
  lda place
  eor #$60
  sta place
Done:
.endmacro


;LotusTextInit
; Initializes state for engine. No parameters.
.proc LotusTextInit
  pha
  lda #0
  sta sprite_attr+$f8
  sta sprite_attr+$fc
  lda #$ff
  sta current_command
  sta step_same
  sta showing_leaf
  sta double_state
  sta nmi_highlight_leaf
  sta nmi_clear_leaf
  sta nmi_response_ppu_high
  sta nmi_response_ppu_low
  sta nmi_response_ppu_data
  sta current_select
  pla
  rts
.endproc


;LotusTextUpdate
; Apply user input, decide what leaf to highlight, or if symbols is selected,
; or if any input needs to be appended.
; reg:A = Buttons currently being pressed. Message length upon enter.
; flag:C = True if enter is pressed.
.proc LotusTextUpdate
  sta user_input
  ; Check for enter command (start button).
  and #INPUT_BUTTON_START
  beq NotEnterCommand
EnterCommand:
  ; Set the carry flag when enter is pressed.
  lda response_index
  sec
  rts
NotEnterCommand:
  ; Initialize rendering changes.
  lda #$ff
  sta nmi_highlight_leaf
  sta nmi_clear_leaf
  sta nmi_response_ppu_high
  ; Input convert to command.
  jsr ConvertInputIntoLeafCommand
.scope UseLeafResult
  cmp current_command
  bne DiffCommand
ContinueCommand:
  ; Continuing the same command. Increase the time counter.
  IncrementCapped step_same
  cpx #0
  beq ContinueCenter
  bmi Next
ContinueNear:
  ; Check if we just crossed the threshold for rendering.
  lda step_same
  cmp #LEAF_HIGHLIGHT_THRESHOLD
  bne Next
  ; Threshold crossed. Render the current leaf.
  lda current_command
  sta showing_leaf
  sta nmi_highlight_leaf
  bne Next;always
ContinueCenter:
  lda step_same
  cmp #CENTER_FORGET_THRESHOLD
  bne Next
  ;
  lda #DOUBLE_STATE_READY
  sta double_state
  bne Next;always
DiffCommand:
  sta current_command
  ; If the incoming command is "NEAR", don't render just yet.
  cpx #1
  bne RenderNow
  ; Unless it is a double press according to the state machine.
  cmp double_state
  bne AfterRenderLeaf
  ; This is a double press. Set step to full.
  ldx #$3f
  stx step_same
  ldx #$ff
  ; Convert the command to the "FAR" value.
  ; TODO: Hacky conversion routine.
  ;          U   R   D   L
  ; regular $10 $28 $38 $50
  ; double  $08 $20 $40 $58
  clc
  adc #$08
  cmp #$38
  bcs RenderNow
  sec
  sbc #$10
RenderNow:
  ; Render the incoming command.
  sta nmi_highlight_leaf
AfterRenderLeaf:
  ; If leaf goes to neutral while a symbol is selected, append and deny.
  lda current_select
  bmi Nope
  jsr AppendInput
  lda #SYMBOL_DENIED
  sta current_select
Nope:
  ; Render the removal of the old command.
  lda showing_leaf
  sta nmi_clear_leaf
  ; Set currently showing leaf as the incoming command.
  lda nmi_highlight_leaf
  sta showing_leaf
  ; State machine for double press.
  cpx #0
  beq ToCenter
  bpl ToNear
ToDiagonal:
  ; "DIAGONAL" sets the double_state to "DENIED".
  lda #DOUBLE_STATE_DENIED
  sta double_state
  bne Next
ToNear:
  ; If double_state is currently "DENIED", keep it that way.
  lda double_state
  cmp #DOUBLE_STATE_DENIED
  beq ResetStep
  ; Have come to "NEAR" from "CENTER", set the double_state.
  lda current_command
  sta double_state
  bpl ResetStep
ToCenter:
  ; Skip if the double_state is a "NEAR" value, or "READY".
  lda double_state
  cmp #DOUBLE_STATE_DENIED
  bne ResetStep
  ; Set the state back to "READY".
  lda #DOUBLE_STATE_READY
  sta double_state
ResetStep:
  ; Clear the step counter.
  lda #0
  sta step_same
Next:
.endscope ;UseLeafResult

  jsr ConvertInputIntoSymbolSelect
.scope UseSymbolResult
  ; Decrement the step.
  ldx step_combo
  beq Analyze
  dec step_combo
Analyze:
  ; No change, finished.
  cmp current_select
  beq Done
  ; Some change. If incoming change is released buttons, skip ahead.
  cmp #$ff
  beq Released
  ; Not released. Check if the symbol select is denied.
  ldx current_select
  cpx #SYMBOL_DENIED
  beq Done
  ; Check if the previous press was combo.
  cpx #COMBO_A_B
  bne Update
  ; It was combo, start the count-down timer.
  ldx #SYMBOL_COMBO_THRESHOLD
  stx step_combo
  bne Update;always
Released:
  ; Something was being pressed, but now isn't.
  ; If the step_combo is running, treat it as a combo press.
  ldx step_combo
  beq Append
  ; Non-zero step_combo. Reset counter and treat the press as a combo.
  lda #0
  sta step_combo
  lda #COMBO_A_B
  sta current_select
  lda #$ff
Append:
  jsr AppendInput
Update:
  ; Store the selected sybmol.
  sta current_select
Handled:
  ; Reset the double_state, depending upon whether the leaf is center or not.
  lda showing_leaf
  cmp #$ff
  beq Center
NotCenter:
  lda #DOUBLE_STATE_DENIED
  bne GotDoubleState;always
Center:
  lda #DOUBLE_STATE_READY
GotDoubleState:
  sta double_state
Done:
.endscope ;UseSymbolResult

.scope RenderCurrentSelect
  lda current_select
  bmi EraseSprites
ShowSprites:
  lda showing_leaf
  bpl HaveLeaf
CenterLeaf:
  ; When no leaf is selected, $ff needs to be converted to 0.
  clc
  adc #1
HaveLeaf:
  clc
  adc current_select
  tax
  ; Sprite0, Position
  lda symbol_position_data+0,x
  sta sprite_v+$f8
  lda symbol_position_data+1,x
  sta sprite_h+$f8
  ; Sprite1, Position
  lda response_index
  lsr a
  lsr a
  and #$78
  clc
  adc #RESPONSE_DISPLAY_V
  sta sprite_v+$fc
  lda response_index
  .repeat 3
  asl a
  .endrepeat
  sta sprite_h+$fc
  ; Sprite0, Tile
  jsr GetChar
  sta sprite_tile+$f8
  ; Sprite1, Tile
  sta sprite_tile+$fc
  jmp Done
EraseSprites:
  lda #$ff
  sta sprite_v+$f8
  sta sprite_v+$fc
Done:
.endscope
  clc
  rts
.endproc


;LotusTextDuringVblank
; Call during vblank to apply render changes to PPU.
; Clobbers reg:A, reg:X
.proc LotusTextDuringVblank
  bit PPU_STATUS
  jsr ClearLeaves
  jsr HighlightLeaves
  ; Tail-call
  jmp RenderResponseData
.endproc


.proc ClearLeaves
  ldx nmi_clear_leaf
  bmi Next
  ldy #4
Loop:
  lda #$23
  sta PPU_ADDR
  lda block_data,x
  beq Next
  sta PPU_ADDR
  inx
  lda #0
  sta PPU_DATA
  inx
  dey
  bne Loop
Next:
  rts
.endproc


.proc HighlightLeaves
  ldx nmi_highlight_leaf
  bmi Next
  ldy #4
Loop:
  lda #$23
  sta PPU_ADDR
  lda block_data,x
  beq Next
  sta PPU_ADDR
  inx
  lda block_data,x
  sta PPU_DATA
  inx
  dey
  bne Loop
Next:
  rts
.endproc


.proc RenderResponseData
  lda nmi_response_ppu_high
  bmi Done
  sta PPU_ADDR
  lda nmi_response_ppu_low
  sta PPU_ADDR
  lda nmi_response_ppu_data
  sta PPU_DATA
Done:
  rts
.endproc


.proc GetChar
  lda current_select
  bmi Done
  ; (leaf - (leaf / 4) + select) / 2
  lda showing_leaf
  bmi Control
Normal:
  pha
  lsr a
  lsr a
  sta tmp
  pla
  sec
  sbc tmp
  clc
  adc current_select
  lsr a
  clc
  adc #(ALPHANUMERIC_TILE_START + MIN_LEAF_OFFSET)
Done:
  rts
Control:
  lda current_select
  lsr a
  clc
  adc #CONTROL_TILE_START
  rts
.endproc


.proc AppendInput
  pha
  jsr GetChar
  cmp #BACKSPACE_CTRL
  beq Backspace
  cmp #SPACE_CTRL
  beq Space
  bne Normal
Space:
  lda #SPACE_TILE
Normal:
  sta nmi_response_ppu_data
  ldx response_index
  sta response_buffer,x
WritePosition:
  lda #$20
  sta nmi_response_ppu_high
  lda response_index
  clc
  adc #$40
  sta nmi_response_ppu_low
  inc response_index
  bne Done;always
Backspace:
  lda response_index
  beq Done
  lda #BLANK_TILE
  sta nmi_response_ppu_data
  dec response_index
  ldx response_index
  lda #0
  sta response_buffer,x
  lda #$20
  sta nmi_response_ppu_high
  lda response_index
  clc
  adc #$40
  sta nmi_response_ppu_low
Done:
  pla
  rts
.endproc
