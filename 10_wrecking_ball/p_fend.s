; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Adress registry management in update subroutine
; * a6 : main object (structure pointer) that is processed. (TO BE SET)
; ================================================================================================================
; Adress registry management in redraw subroutine
; * a6 : main object (structure pointer) that is processed. (TO BE SET)
; * a5 : memory address of the logical screen. (ALREADY SET)
; ================================================================================================================
; Phase : Fade to end
; [ ] before all
; [ ] before each
; [ ] update
; [ ] redraw
; [ ] after each
; [ ] after all
; ---
; This phase do something
;
; ---
; ================================================================================================================
; ----------------------------------------------------------------------------------------------------------------
; before all
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToEndBeforeAll:
                        rts
; ----------------------------------------------------------------------------------------------------------------
; before each
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToEndBeforeEach:
                        ; -- init Fend_Count
                        moveq                   #0,d7
                        move.w                  d7,Fend_Count
                        ; -- init Fend_PtrStartToRedraw
                        ; d0 := pointer to the start of memory screen
                        _xos_Logbase
                        move.l                  d0,Fend_PtrStartToRedraw
                        ; -- init Fend_PtrEndToRedraw
                        ; d0 := pointer to end of memory screen
                        add.l                   #32000,d0
                        move.l                  d0,Fend_PtrEndToRedraw
                        rts
; ----------------------------------------------------------------------------------------------------------------
; update
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToEndUpdate:
                        ; -- Check Fend_Count
                        ; a6 := Fend_count
                        lea                     Fend_Count,a6
                        ; d7 := Fend_count value
                        move.w                  (a6),d7
                        cmp.w                   #200,d7
                        ; -- if (d7 < 200)
                        blo.s                   .doUpdate
                        ; -- else next phase
                        move.l                  #PhsFadeToEndAfterEach,a2
                        jsr                     (a2)
                        move.l                  #PhsMenuBeforeEach,a2
                        jsr                     (a2)
                        move.l                  #PhsMenuUpdate,PtrNextUpdate
                        move.l                  #PhsMenuRedraw,PtrNextRedraw
                        bra.s                   .thatsAll
                        ; ========
                        ; -- update Fend_Count
.doUpdate               addq.w                  #8,d7
                        move.w                  d7,(a6)
                        ; ========
.thatsAll               rts
; ----------------------------------------------------------------------------------------------------------------
; redraw
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToEndRedraw:
                        ;rts
                        ; -- Check that we are still inside the memory of the screen
                        ; a6 := Fend_PtrStartToRedraw
                        DerefPtrToPtr           Fend_PtrStartToRedraw,a6
                        ; a4 := Fend_PtrEndToRedraw
                        DerefPtrToPtr           Fend_PtrEndToRedraw,a4
                        cmp.l                   a4,a6
                        ; -- if (a4 <= a6)
                        bhs.s                   .thatsAll
                        ; -- else redraw
                        ; d7 : loop over 8 lines
                        move.w                  #7,d7
                        ; -- clear d0-d6,a0
                        ; a4 := Fend_ZeroBuffer
                        lea                     Fend_ZeroBuffer,a4
                        movem.l                 (a4)+,d0-d6/a0
                        ; a4 := End of memory to clear = a6 + 8*160
                        lea                     1280(a6),a4
                        ; -- update Fend_PtrStartToRedraw
                        ; a3 := Fend_PtrStartToRedraw location
                        lea                     Fend_PtrStartToRedraw,a3
                        move.l                  a4,(a3)
                        ; -- do the clearing line by line = 5 * (8 * 4 = 32bytes per movem)
.nextLine               movem.l                 d0-d6/a0,-(a4)
                        movem.l                 d0-d6/a0,-(a4)
                        movem.l                 d0-d6/a0,-(a4)
                        movem.l                 d0-d6/a0,-(a4)
                        movem.l                 d0-d6/a0,-(a4)
                        dbf                     d7,.nextLine
.thatsAll               rts
; ----------------------------------------------------------------------------------------------------------------
; after each
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToEndAfterEach:
                        rts
; ----------------------------------------------------------------------------------------------------------------
; after all
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToEndAfterAll:
                        rts
; ================================================================================================================
; Model
; ================================================================================================================
Fend_Count              dc.w                    0                       ; line counter for erased lines
Fend_PtrStartToRedraw   dc.l                    0                       ; pointer to start of memory to clear
Fend_PtrEndToRedraw     dc.l                    0                       ; End of memory screen
Fend_ZeroBuffer         ds.l                    8                       ; buffer of zero to clear registers to movem
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
