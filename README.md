# sporny-wrecking-ball

A little breakout style game for the Atari STE written in assembly 68k

# How to build

## Required

* A Linux installation, Ubuntu is recommanded (as "the author uses Ubuntu").
  * make, gcc,... to be able to build vasm
* Hatari, an Atari ST/STE/TT/Falcon emulator.
  * Setup hatari to have a blitter and DMA sound. Recommanded is a STE, tos 1.62.

## Procedure

* Clone the repository, including the submodules

```shell
git clone --recurse-submodules https://github.com/sporniket/sporny-wrecking-ball
cd sporny-wrecking-ball
```

* Source the `environment` file : `. environment`
* Invoke the CLI to install vasm (at the date of writing : _vasm 1.9_): `ap install vasm`
* Invoke the CLI to setup some local files : `ap setup`
* Source again the `environment` file : `. environment`
* Invoke the CLI to create some makefiles snippets : `ap scandeps`
* Invoke the CLI to build the program : `ap build swb`
* Launch the CLI to launch the program : `ap run swb`

## Build on real Atari

Hopefully, it may be possible.

* The source is written using a devpac-ish syntax and keywords (macro etc...).
* For a given program source, e.g. `10_wrecking_ball`, all the files inside follows the '8.3' naming scheme.
* The source expects the assembly program to automatically use the right length for branches (short or long).

Good luck.
