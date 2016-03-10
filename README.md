# lotus.nes

Experimental, alternative text input for the NES, using the LotusText library.


# Download

http://dustmop.io/dat/lotus.nes


# About

http://www.dustmop.io/blog/2016/03/10/lotus-text/


# Building

    make

To modify the graphics in LotusText, you'll need makechr. To modify the metadata for attributes, you'll need python. See lotus_text/Makefile


# Using

This ROM displays 12 leafs on screen, with three symbols on each leaf. Pressing a direction on the d-pad highlights that leaf, with diagonals for diagonal leaves, and double-taps for far leaves. Once selected, B will pick the left symbol, A will pick the right symbol, and both at once will pick the center symbol. Pressing start will confirm the selected input.

The center area contains common operations, backspace, blank space, and period. These can be selected with B and A the same way, without pressing anything on the d-pad.

See lotus_text/ABOUT.txt for the LotusText API description.
