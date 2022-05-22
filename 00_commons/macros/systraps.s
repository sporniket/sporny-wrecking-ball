; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Trap macros (bios, xbios, gemdos, gem)
; ----------------------------------------------------------------------------------------------------------------
___trap                 macro
                        ;1 - trap to call, e.g. 14 (gemdos)
                        ;2 - opcode > 0
                        ;3 - stack correction offset >= 0
                        move.w                  #\2,-(sp)
                        trap                    #\1
                        ifne                    \3
                        iflt                    \3-8
                        addq.l                  #\3,sp
                        else
                        lea                     \3(sp),sp
                        endif
                        endif
                        endm

; ----------------------------------------------------------------------------------------------------------------
; TOS level traps (bios, xbios, gemdos)
; ----------------------------------------------------------------------------------------------------------------
___bios                 macro
                        ;1 - opcode > 0
                        ;2 - stack correction offset >0
                        ___trap                 13,\1,\2
                        endm

___xbios                macro
                        ;1 - opcode > 0
                        ;2 - stack correction offset >0
                        ___trap                 14,\1,\2
                        endm

___gemdos               macro
                        ;1 - opcode > 0
                        ;2 - stack correction offset >0
                        ___trap                 1,\1,\2
                        endm

; ----------------------------------------------------------------------------------------------------------------
; GEM level traps (vdi, aes)
; ----------------------------------------------------------------------------------------------------------------
___vdi                  macro
                        ; 1 - effective address of VDI call structure (see the Atari compendium - VDIPB)
                        move.l                  \1,d1
                        move.w                  #$73,d0
                        trap                    #2
                        endm

___aes                  macro
                        ; 1 - effective address of AES call structure (see the Atari compendium - AESPB)
                        move.l                  \1,d1
                        move.w                  #$c8,d0
                        trap                    #2
                        endm
