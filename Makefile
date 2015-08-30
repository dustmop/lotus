default: demo_lotus.nes

include lotus_text/Makefile

demo_lotus.nes: input.asm main.asm prologue.asm graphics.asm
	cd lotus_text/ && make lotus_text_lib && cd ../
	mkdir -p .b/
	ca65 input.asm -o .b/input.o
	ca65 main.asm -o .b/main.o
	ca65 prologue.asm -o .b/prologue.o
	ca65 graphics.asm -o .b/graphics.o
	ld65 .b/input.o .b/main.o .b/prologue.o .b/graphics.o $(LOTUS_TEXT_LIB) -o demo_lotus.nes -C link.cfg

clean:
	rm -rf .b/
	rm demo_lotus.nes
	cd lotus_text/ && make lotus_text_clean && cd ../
