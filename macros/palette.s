; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s
; ================================================================================================================
; Palettes macros
_Setpalette             macro
                        ; 1 - Pointer to palette adresse
                        pea                     \1
                        ___xbios                6,6
                        endm

_Setcolor               macro
                        ; 1 - Colour index (0~15)
                        ; 2 - Colour value $0rgb with ste color coding, #-1 to left unchanged
                        move.w                  \2,-(sp)
                        move.w                  \1,-(sp)
                        ___xbios                7,6
                        endm

SaveSysPalette          macro
                        ; 1 - buffer to save the whole palette
                        ; side effects :
                        ; d4 - loop counter
                        ; d5 - color index
                        ; a4 - buffer cursor
                        moveq                   #0,d5
                        move.w                  #15,d4                  ; loop through all the 16 colors
                        lea                     \1,a4
.nextEntry\@            _Setcolor               d5,#-1
                        move.w                  d0,(a4)+
                        addq.w                  #1,d5
                        dbf.s                   d4,.nextEntry\@
                        endm

RestoreSavedPalette     macro
                        ; 1 - buffer containing the previously saved palette
                        _Setpalette             \1
                        endm
