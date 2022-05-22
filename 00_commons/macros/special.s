; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s
; ================================================================================================================
; Special execute calls
_Supexec                macro
                        ; 1 - address of the subroutine to execute in supervisor mode
                        move.l                  \1,-(sp)
                        ___xbios                38,6
                        endm
;
