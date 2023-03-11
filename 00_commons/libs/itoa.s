; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES ...
; ================================================================================================================
; 'Integers TO Ascii'
; ---
; Some utilities to convert integer values (signed or unsigned) into decimal, hexadecimal(lower case) or 
; binary strings.
; ---

itoa_pushCharFromDigit      macro
                            ; 1 - data register containing a single digit, to change into ascii value
                            ; 2 - address register of the end of the string buffer to append the ascii value into
                            cmp.b   #10,\1
                            blo     .isDigitChar_\@
                            ; is in [a-f]
                            add.b   #87,\1 ; convert to ascii (10 gives 'a' = 97 = 87 + 10)
                            move.b  \1,(\2)+
                            bra     .done_\@
                            ; is in [0-9]
.isDigitChar_\@             add.b   #48,\1 ; convert to ascii (0 gives '0' = 48)
                            move.b  \1,(\2)+
.done_\@                    nop                            
                            endm

; ================================================================================================================
; @declare A = itoa_appHexUint8(strbuf, value)
; @brief Appends hex string of unsigned byte to given string buffer.
; 
; @param strbuf : pointer to the first available byte of the string buffer, MUST HAVE at least 4 bytes remaining.
; @param value  : byte value, unsigned
;
; @returns a0 a pointer to the end of the string buffer.
; 
; ----------------------------------------------------------------------------------------------------------------
; actual subroutine
srA_itoa_appHexUint8        move.l  4(sp),a0 ; a0 := strbuf
                            ; append '$' to string
                            move.b  #'$',(a0)+
                            ; d0 := value
                            moveq   #0,d0
                            move.b  8(sp),d0
                            ; d1 := temp, next digit
                            move.l  d0,d1
                            lsr.b   #4,d1 ; first digit
                            itoa_pushCharFromDigit  d1,a0
                            ; d1 := temp, next digit
                            move.l  d0,d1
                            and.b   #$f,d1 ; last digit
                            itoa_pushCharFromDigit  d1,a0
                            ; force end of c-string
                            move.b  #0,0(a0)
                            rts
; ----------------------------------------------------------------------------------------------------------------
; call using branch
bsrA_itoa_appHexUint8       macro
                            ; 1 - strbuf
                            ; 2 - value
                            ; saves context
                            movem.l     d0-d7/a1-a6,-(sp)
                            ; stacks args
                            move.b      \2,-(sp)
                            move.l      \1,-(sp)
                            ; ready to branch
                            bsr         srA_itoa_appHexUint8
                            ; fixes stack
                            add.l       #6,sp
                            ; restore context
                            movem.l     (sp)+,d0-d7/a1-a6
                            ; that's all
                            endm
; ----------------------------------------------------------------------------------------------------------------
; call using jump
jsrA_itoa_appHexUint8       macro
                            ; 1 - strbuf
                            ; 2 - value
                            ; saves context
                            movem.l     d0-d7/a1-a6,-(sp)
                            ; stacks args
                            move.b      \2,-(sp)
                            move.l      \1,-(sp)
                            ; ready to branch
                            jsr         srA_itoa_appHexUint8
                            ; fixes stack
                            add.l       #6,sp
                            ; restore context
                            movem.l     (sp)+,d0-d7/a1-a6
                            ; that's all
                            endm
