LOTUS_TEXT_LIB=lotus_text/.b/engine.o lotus_text/.b/highlighting.o lotus_text/.b/gfx_data.o

lotus_text_lib: gen/block_data.asm chr.dat nametable.dat \
            .b/engine.o .b/highlighting.o .b/gfx_data.o

lotus_text_clean:
	rm -rf .b/

gen/block_data.asm: build_blocks.py blocks_metadata.png
	mkdir -p gen/
	python build_blocks.py blocks_metadata.png > gen/block_data.asm

chr.dat nametable.dat: image.png
	mkdir -p .b/
	makechr font.png -o .b/font.%s.dat -p P/10-30-2c-0f/
	makechr image.png -o .b/image.%s.dat -p P/0f-30-2c-00/
	makechr font.png -o .b/sprite.%s.dat -p P/0f-30/ -s
	python merge_chr_dat.py \
            -c .b/font.chr.dat -c .b/image.chr.dat -m .b/merged.chr.dat \
            -i .b/image.nametable.dat -o .b/resource.nametable.dat
	head -c 4096 .b/merged.chr.dat > .b/resource.chr.dat
	tail -c 4096 .b/sprite.chr.dat >> .b/resource.chr.dat
	cp .b/resource.chr.dat chr.dat
	cp .b/resource.nametable.dat nametable.dat

.b/engine.o .b/highlighting.o .b/gfx_data.o: engine.asm highlighting.asm gfx_data.asm nametable.dat
	mkdir -p .b/
	ca65 engine.asm -o .b/engine.o
	ca65 highlighting.asm -o .b/highlighting.o
	ca65 gfx_data.asm -o .b/gfx_data.o
