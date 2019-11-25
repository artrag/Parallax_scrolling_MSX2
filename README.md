# Parallax_scrolling_MSX2
Parallax scrolling for MSX2

Demo test from the Total Parody project of a full screen fine scrolling in 8 directions with two layers of parallax in screen 5 (bitmap mode)
ASM code is included (GEN80 assembler)

The whole screen is composed by 16x16 blocks and reconstructed in 16 steps column by column
Two video pages are used for double buffering the scree composition
Other two pages are used to store the 16x16 blocks of the two layers
While building the screen, HW scrolling is used to move the visible page pixel by pixel

