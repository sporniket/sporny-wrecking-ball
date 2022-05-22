; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s,
; ================================================================================================================
; See Atari compendium, DMA Sound registers (pdf page 312)
; Dma Sound setup structure
                        rsreset
DmaSound_base           rs.l 1                  ; pointer to start of the sound (included)
DmaSound_top            rs.l 1                  ; pointer to end of the sound (excluded)
DmaSound_mode           rs.w 1                  ; sound mode : ........m.....rr (m : mono flag ; rr : replay rate)
SIZEOF_DmaSound         rs.w 0

; constants : modes
DmaSound_MONO_6         = $80
DmaSound_MONO_12        = $81
DmaSound_MONO_25        = $82
DmaSound_MONO_50        = $83

; constants : control
DmaSound_CTL_STOP       = 0
DmaSound_CTL_ONCE       = 1
DmaSound_CTL_REPEAT     = 3
; ================================================================================================================
;
DmaSound_doPlayOnce     macro
                        ; Play a dma sound sample, MUST be run in supervisor mode
                        ; 1 - Label to the base addrress to setup
                        ; 2 - Label to the top address to setup
                        ; 3 - spare adresse register for use
                        ; 4 - spare data register for use
                        ; 5 - spare data register for use
                        ; --
                        ; -- we use movep to fill the low bytes of 4 dma sound registries at a time
                        ; -- setup playback control + frame base
                        move.w                  #$8901,\3
                        move.l                  \1,\4
                        and.l                   #$ffffff,\4 ; highest byte at 0 = stop playback
                        movep.l                 \4,0(\3)
                        ; -- setup frame top + playback mode
                        move.w                  #$890f,\3
                        move.l                  \2,\4
                        lsl.l                   #8,\4
                        move.b                  #DmaSound_MONO_12,\4
                        movep.l                 \4,0(\3)
                        ; -- play once
                        move.w                  #DmaSound_CTL_ONCE,$ffff8900.w
                        endm
;
;
DmaSound_setupSound     macro
                        ; fill the target descriptor
                        ; 1 - Sound memory start (included)
                        ; 2 - Sound memory end (excluded)
                        ; 3 - Sound mode
                        ; 4 - address register, pointer to the descriptor to fill
                        move.l                  \1,DmaSound_base(\4)
                        move.l                  \2,DmaSound_top(\4)
                        move.w                  \3,DmaSound_mode(\4)
                        endm
;
; ================================================================================================================
; Microwire macros, MUST be run in supervisor mode

DmaSound_waitMicrowire  macro
.wait\@                 cmp.w                   #$07ff,$ffff8924
                        bne.s                   .wait\@
                        endm

DmaSound_setupMicrowire macro
                        move.w                  #$07ff,$ffff8924
                        move.w                  #$0554,$ffff8922 ; left volume, high
                        DmaSound_waitMicrowire
                        move.w                  #$0514,$ffff8922 ; left volume, high
                        DmaSound_waitMicrowire
                        move.w                  #$04e8,$ffff8922 ; master volume, high
                        ;move.w                  #$0401,$ffff8922 ; -12db mix sound ?
                        DmaSound_waitMicrowire
                        endm
;
