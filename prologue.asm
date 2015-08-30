.segment "INESHDR"

.byte "NES", $1a
.byte $01 ; prg * $4000
.byte $01 ; chr-ram
.byte $01
.byte $00
.byte $00 ; 8) mapper variant
.byte $00 ; 9) upper bits of ROM size
.byte $00 ; 10) prg ram
.byte $00 ; 11) chr ram ($2000)
.byte $00 ; 12) tv system - ntsc
.byte $00 ; 13) vs hardware
.byte $00 ; reserved
.byte $00 ; reserved

.segment "ZEROPAGE"
main_loop_ready: .byte 0
buttons_curr: .byte 0
reply_length: .byte 0

.exportzp main_loop_ready
.exportzp buttons_curr
.exportzp reply_length

.segment "VECTORS"
.import NMI
.import RESET

.word NMI
.word RESET
.word 0

.segment "CHR"

.incbin "lotus_text/chr.dat"
