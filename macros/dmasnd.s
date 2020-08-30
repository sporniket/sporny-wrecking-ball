; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s,
; ================================================================================================================
; Dma sound macros, MUST be run in supervisor mode

DmaSound_setupFrame     macro
                        ; split the 3 bytes of the sound addresse (beginning or end) into one of the frames registers
                        ; 1 - address register, contains the start of the frame to set
                        ; 2 - data register, contains the value to put in frame
                        ; 3 - spare data register
                        ; -- high byte first
                        swap                    \2
                        move.w                  \2,(\1)+
                        ; -- middle high byte then
                        swap                    \2
                        moveq                   #0,\3
                        ; \3 := low byte backup before shifting
                        move.b                  \2,\3
                        lsr.w                   #8,\2
                        move.w                  \2,(\1)+
                        ; -- low byte, finally
                        move.w                  \3,(\1)+
                        endm
;
DmaSound_playOnce       macro
                        ; 1 - Label to the base addrress to setup
                        ; 2 - Label to the top address to setup
                        ; 3 - spare adresse register for use
                        ; 4 - spare data register for use
                        ; 3 - spare dd register for use
                        ; -- setup frame base
                        move.l                  #$ffff8902,\3
                        move.l                  \1,\4
                        DmaSound_setupFrame     \3,\4,\5
                        ; -- setup frame end
                        move.l                  #$ffff890e,\3
                        move.l                  \2,\4
                        DmaSound_setupFrame     \3,\4,\5
                        ; -- setup mono 6xxx Hz
                        move.w                  #$0080,$ffff8920
                        ; -- play once
                        move.w                  #$0001,$ffff8900
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
