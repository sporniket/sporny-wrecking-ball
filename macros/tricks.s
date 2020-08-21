; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Tricks of the 68k
; ================================================================================================================
; Multiply by a power of 2 -- byte -- BEWARE OF OVERFLOWS
;
BtMul2                  macro
                        ; 1 - register to double
                        add.b                   \1,\1
                        endm

BtMul4                  macro
                        ; 1 - register to double
                        BtMul2                  \1
                        BtMul2                  \1
                        endm

; ================================================================================================================
; Multiply by a power of 2 -- word -- BEWARE OF OVERFLOWS
;
WdMul2                  macro
                        ; 1 - register to double
                        add.w                   \1,\1
                        endm

WdMul4                  macro
                        ; 1 - register to double
                        WdMul2                  \1
                        WdMul2                  \1
                        endm
