; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s
; ================================================================================================================
; Screen macros
_Physbase               macro
                        ___xbios                2,2
                        endm

_Logbase                macro
                        ___xbios                3,2
                        endm

_Getrez                 macro
                        ___xbios                4,2
                        endm

_Vsync                  macro
                        ___xbios                37,2
                        endm

_Setscreen              macro
                        ; 1 - logical screen effective address, -1 to left unchanged
                        ; 2 - physical screen effective address, -1 to left unchanged
                        ; 3 - screen resolution, 0 => low res, 1 => med res, 2 => high res, -1 => unchanged
                        move.w                  \3,-(sp)
                        pea                     \2
                        pea                     \1
                        ___xbios                5,12
                        endm

ChangeToRez             macro
                        ; Meaningful for color ST screen only
                        ; 1 - screen resolution, 0 => low res, 1 => med res, -1 => unchanged
                        _Setscreen              -1,-1,\1
                        endm
