; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s, sizeof.s
; ================================================================================================================
; memory management, including the MShrink of the TPA (MUST be the first macro called then.)
; ================================================================================================================
_Malloc                 macro
                        ; 1 - the number of byte to allocate or -1 to get the size of free memory
                        move.l                  \1,-(sp)
                        ___gemdos               72,6
                        endm

_Mfree                  macro
                        ; 1 - adress of the block to free, previously allocated
                        move.l                  \1,-(sp)
                        ___gemdos               73,6
                        endm

_Mshrink                macro
                        ; 1 - address of the block to shrink
                        ; 2 - new size
                        move.l                  \2,-(sp)
                        pea                     \1
                        move.w                  #0,-(sp)
                        ___gemdos               74,12
                        endm

ShrinkTpa               macro
                        ; Shrink the TPA to be nice to the OS, MUST be called at the very beginning of the program.
                        ; see https://freemint.github.io/tos.hyp/en/gemdos_tpa.html
                        ; 1 - wanted length in words for the stack
                        ; 2 - wanted length in words of the heap
                        ;
                        ; Side effects
                        ; d0 - either ENSMEM(-39), or return of mshrink : E_OK (0) or EIMBA(-40)
                        ; a0 - meaningful if E_OK ; base of the stack
                        ; d1 - meaningful if E_OK ; size of the stack in bytes
                        ; a1 - meaningful if E_OK ; top of the stack/base of the heap
                        ; d2 - meaningful if E_OK ; size of the heap in bytes
                        ; a2 - meaningful if E_OK ; top of the heap
                        ; --------
                        move.l                  4(sp),a0                ; Pointer to process descriptor
                        movem                   d3-d6/a3-a6,-(sp)
                        ; d0 := -39 (ENSMEM, 'Error Not Sufficient MEMory')
                        move.l                  #-39,d0
                        ; d6 := current size of tpa
                        move.l                  4(a0),d6
                        sub.l                   0(a0),d6
                        ; d5 := program size without stack and heap
                        move.l                  #SizeOf_Basepage,d5
                        add.l                   12(a0),d5               ; + text length
                        add.l                   20(a0),d5               ; + data length
                        add.l                   28(a0),d5               ; + bss length
                        ; a6 := base of the stack
                        move.l                  a0,a6
                        add.l                   d5,a6
                        ; d4 := wanted stack size
                        move.l                  #\1,d4
                        add.l                   d4,d4
                        ; a5 := top of the wanted stack
                        move.l                  a6,a5
                        add.l                   d4,a5
                        cmp.l                   4(a0),a5
                        blo.s                   stackIsGood\@
                        ; -- else not enough memory
                        bra.s                   thatsNotOk\@
stackIsGood\@           ; -- d5 += stack size
                        add.l                   d4,d5
                        ; d3 := wanted heap size
                        move.l                  #\2,d3
                        add.l                   d3,d3
                        ; a4 := top of the wanted heap
                        move.l                  a5,a4
                        add.l                   d3,a4
                        cmp.l                   4(a0),a4
                        blo.s                   heapIsGood\@
                        ; -- else not enough memory
                        bra.s                   thatsNotOk\@
heapIsGood\@            ; -- d5 += heap size
                        add.l                   d3,d5

                        _Mshrink                (a0),d5
                        tst.l                   d0
                        bne.s                   thatsNotOk\@
                        ; -- OK, setup side effects
                        move.l                  a5,a1
                        move.l                  d4,d1
                        move.l                  a4,a2
                        move.l                  d3,d2
                        bra.s                   thatsAll\@
thatsNotOk\@            ; -- KO, setup side effects (d0 has been already set)
                        move.l                  #0,a0
                        moveq                   #0,d1
                        move.l                  #0,a1
                        moveq                   #0,d2
                        move.l                  #0,a2
thatsAll\@              ; -- restore
                        movem                   (sp)+,d3-d6/a3-a6
                        endm

DerefPtrToPtr           macro
                        ; dereference a pointer, and store in address register
                        ; 1 - The label to dereference
                        ; 2 - The target address register
                        lea                     \1,\2
                        move.l                  (\2),\2
                        endm

DerefOffPtrToPtr        macro
                        ; dereference a pointer stored at (address + offset)
                        ; 1 - The label to the start of the array
                        ; 2 - The target address register
                        ; 3 - The offset in byte, MUST be correct
                        lea                     \1,\2
                        add.l                   \3,\2
                        move.l                  (\2),\2
                        endm
; TODO : dereference using immediate value (addq #\x or lea \x(\2))
;
OffsTbl_getLongAtWdIndx   macro
                        ; Get the long value at the given index from the first element.
                        ; 1 - address register, ptr to the table
                        ; 2 - const, index (word)
                        ; 3 - spare data => result
                        ; --
                        ; \3 := displacement = 4 * \2
                        moveq                   #0,\3
                        move.w                  \2,\3
                        LgMul4                  \3
                        move.l                  (\1,\3),\3
                        endm
