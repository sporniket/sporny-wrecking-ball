# sporny-wrecking-ball

A little breakout style game for the Atari STE written in assembly 68k

# How to build

For now the build process from scratch is a mess, I will work on that later.

My daily working environment is a Linux PC.

To sum up, there are generators for generating the assets (and for the font, one program to generate the template font to edit on a graphic program). These are built using `make-xxx.bash`. These generator must be run on Atari (I use emulator for that)

Then, use the `make.bash` script to generate the game program (it's a single file then).

* Clone this repository somewhere under linux. In your local copy, create a 'build' directory.
* Require vasm 1.8i in the path (vasmm68k_mot). See http://sun.hasenbraten.de/vasm/
* Require an emulator like Hatari (tested on 2.2.1). See https://hatari.tuxfamily.org/ . Setup a configuration that use the 'build' folder as a root of an emulated harddrive, then start the emulator.


## Build on real Atari

It should be possible. I will work on that later.

The bash scripts are the only files that do not follows the "8.3" file naming.

The source is written using a devpac-ish syntax and keywords (macro etc...). Otherwise get a binary of vasm, a command line, and study the scripts to devise the build command.

Good luck.
