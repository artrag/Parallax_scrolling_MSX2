# Parallax_scrolling_MSX2
Parallax scrolling for MSX2

Demo test from the Total Parody project of a full screen fine scrolling in 8 directions with two layers of parallax in screen 5 (bitmap mode)
ASM code is included (GEN80 assembler)
The main file is FOR2.GEN. The executable is FOR2.COM

The whole screen is composed by 16x16 blocks and reconstructed in 16 steps column by column. Transparent blocks are supported (up to 4 per column)

Two video pages are used for double buffering the screen composition.

Other two pages are used to store the 16x16 blocks of the two layers.

While building the screen, HW scrolling is used to move the visible page pixel by pixel

