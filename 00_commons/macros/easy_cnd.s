; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Macros to write conditional snippet more readable
; ================================================================================================================
; ================================================================================================================
AssignVaElseVbTo        macro
                        ; dest.size := cond ? va : vb
                        ; 1 - cond (cc, eq, ne,...)
                        ; 2 - value a, to assign if condition is true
                        ; 3 - value b, to assign if condition is false
                        ; 4 - size of value (b,w,l)
                        ; 5 - destination of value
                        ; --
                        b\1.s                   .isTrue\@
                        move.\4                 \3,\5
                        bra.s                   .end\@
.isTrue\@
                        move.\4                 \2,\5
.end\@
                        endm
; ================================================================================================================
BranchSraElseSrb        macro
                        ; if (cond) then bsr Sra else bsr Srb
                        ; 1 - cond (cc,eq,ne,...)
                        ; 2 - subroutine a if condition is true
                        ; 3 - subroutine b if condition is false
                        ; --
                        b\1.s                   .isTrue\@
                        bsr                     \3
                        bsr.s                   .end\@
.isTrue\@
                        bsr                     \2
.end\@
                        endm
; ================================================================================================================
; ================================================================================================================
