; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s
; ================================================================================================================
; File io macros
;
_fcreate                macro
                        ; 1 - filename
                        ; 2 - file attribute (e.g. #0 : regular)
                        move.w                  \2,-(sp)
                        move.l                  \1,-(sp)
                        ___gemdos               60,8
                        endm
;
_fopen                  macro
                        ; 1 - filename
                        ; 2 - mode (e.g. #4 : read-write)
                        move.w                  \2,-(sp)
                        move.l                  \1,-(sp)
                        ___gemdos               61,8
                        endm
;
_fwrite                 macro
                        ; 1 - handle
                        ; 2 - buffer size
                        ; 3 - buffer address
                        move.l                  \3,-(sp)
                        move.l                  \2,-(sp)
                        move.w                  \1,-(sp)
                        ___gemdos               64,12
                        endm
;
_fclose                 macro
                        ; 1 - handle
                        move.w                  \1,-(sp)
                        ___gemdos               62,4
                        endm
;
