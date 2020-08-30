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
; struct Menu
                        rsreset
Menu_Phase              rs.w                    1                       ; 3 : transition effect, 2 : select + wait fire press, 1 : wait fire release, 0 : done
Menu_PhaseNext          rs.w                    1                       ; the next phase value.
Menu_Count              rs.w                    1                       ; transition counter
Menu_Count_Next         rs.w                    1                       ; next value of transition counter
Menu_PtrStartToRedraw   rs.l                    1                       ; pointer to start of memory to clear
Menu_PtrEndToRedraw     rs.l                    1                       ; End of memory screen
Menu_BlitCountY         rs.w                    1                       ; y count value for blitter
Menu_ZeroBuffer         rs.l                    1                       ; buffer of zero to clear registers to movem
Menu_PtrImageBase       rs.l                    1                       ; Pointer to start of the title image
Menu_PtrImageCurrent    rs.l                    1                       ; Pointer to the start of the image part to display
Menu_PtrImageTop        rs.l                    1                       ; Pointer to the end of the title image
Menu_FireState          rs.w                    1                       ; 1 : fire is pressed
SIZEOF_Menu             rs.w                    0
;
; consts
Menu_INC_Y_UPDT         =                       1280                    ; Advance by eight screen line per normal update
Menu_INC_Y_UPDT_END     =                       -160                    ; Go back by one screen line per end transition update
Menu_INC_Y_BLITTER      =                       -1600                   ; After copying 1 full line (start + 160), go back to 9 lines before the start = 10 lines back
Menu_PHASE_TRANSIT      =                       3
Menu_PHASE_WT_FIRE_PRS  =                       2
Menu_PHASE_WT_FIRE_RLS  =                       1
Menu_PHASE_DONE         =                       0


;
DoBlitPartialScreen     macro
                        ; - 1 address to the start of image data to display
                        ; - 2 address to the start of memory screen to update
                        ; - 3 number of lines
                        ; - 4 spare address register
                        ; - 5 spare address register
                        ; - 6 spare data register
                        ; --
                        ; y increment : after copying 1 full line (start + 160), go back to 9 lines before the start = 10 lines back = 1600 backwards
                        ; --
                        ; \4 := blitter base
                        move.l                  #BlitterBase,\4
                        ; -- Setup Source
                        ; \5 := base + $20
                        lea                     $20(\4),\5
                        move.w                  #2,(\5)+                ; source x increment (contiguous)
                        move.w                  #-1600,(\5)+            ; source y increment
                        move.l                  \1,(\5)+                ; source address
                        ; -- setup masks
                        move.w                  #$ffff,(\5)+
                        move.w                  #$ffff,(\5)+
                        move.w                  #0,(\5)+
                        ; -- setup Dest
                        move.w                  #2,(\5)+
                        move.w                  #-1600,(\5)+
                        move.l                  \2,(\5)+
                        ; -- setup x/y counts
                        move.w                  #80,(\5)+
                        move.w                  \3,(\5)+
                        ; -- Hop/op values
                        move.w                  #$0203,(\5)+ ; HOP = 2 (source), OP = 3 (source)
                        ; -- set skew/shift registers
                        addq.l                  #1,\5
                        move.b                  #0,(\5)
                        ; -- do the blit
                        DoBlitAndWait
                        endm
;
ExecBlitPartialScreen   DoBlitPartialScreen     a4,a3,d6,a2,a1,d5
                        rts
; ----------------------------------------------------------------------------------------------------------------
; before all
; ----------------------------------------------------------------------------------------------------------------
PhsMenuBeforeAll:
                        ; -- init Menu constants
                        ; a6 := the menu
                        move.l                  #TheMenu,a6
                        ;
                        ; -- init Menu_PtrImage...
                        ; a5 := start of image data
                        move.l                  #TitleDat,a5
                        lea                     34(a5),a5
                        move.l                  a5,Menu_PtrImageBase(a6)
                        lea                     32000(a5),a5
                        move.l                  a5,Menu_PtrImageTop(a6)
                        rts
; ----------------------------------------------------------------------------------------------------------------
; before each
; ----------------------------------------------------------------------------------------------------------------
PhsMenuBeforeEach:
                        ; a6 := the menu
                        move.l                  #TheMenu,a6
                        ; -- init Menu counters
                        moveq                   #0,d7
                        move.w                  d7,Menu_Count(a6)
                        ; -- init menu phase
                        ; d6 := start menu phase.
                        moveq                   #Menu_PHASE_TRANSIT,d6
                        move.w                  d6,Menu_Phase(a6)
                        move.w                  d6,Menu_PhaseNext(a6)
                        ; -- init Menu_PtrStartToRedraw
                        ; d0 := pointer to the start of memory screen
                        _Logbase
                        ; d1 := pointer to the start of the redraw = d0 - 1 lines offset = d0 - 160
                        move.l                  d0,d1
                        sub.l                   #160,d1
                        move.l                  d1,Menu_PtrStartToRedraw(a6)
                        ; -- init Menu_PtrEndToRedraw
                        ; d0 := pointer to end of memory screen
                        add.l                   #32000,d0
                        move.l                  d0,Menu_PtrEndToRedraw(a6)
                        ; -- init Menu_PtrImageCurrent
                        ; a5 := Start of image data - 1 lines = a6 - 160
                        move.l                  Menu_PtrImageBase(a6),a5
                        lea                     -160(a5),a5
                        move.l                  a5,Menu_PtrImageCurrent(a6)
                        rts
; ----------------------------------------------------------------------------------------------------------------
; update
; ----------------------------------------------------------------------------------------------------------------
PhsMenuUpdate:
                        ; a6 := the menu
                        move.l                  #TheMenu,a6
                        ; -- Check phase
                        ; d7 := phase
                        moveq                   #0,d7
                        move.w                  Menu_Phase(a6),d7
                        ; select phase -- case not 0
                        dbf.s                   d7,.waitFireRelease
                        ; -- else next phase
                        ; a2 := address to jump to
                        move.l                  #PhsMenuAfterEach,a2
                        jsr                     (a2)
                        move.l                  #PhsFadeToGameBeforeEach,a2
                        jsr                     (a2)
                        move.l                  #PhsFadeToGameUpdate,PtrNextUpdate
                        move.l                  #PhsFadeToGameRedraw,PtrNextRedraw
                        bra.w                   .thatsAll
                        ; select phase -- case not 1
.waitFireRelease        dbf.s                   d7,.waitFirePress
                        ; -- poll joystick status
                        ; a0 := Ptr to joystick states
                        lea                     BufferJoystate,a0
                        ; d5 := [j0,j1] combined in a word
                        move.w                  (a0),d6
                        btst.w                  #7,d6
                        ; -- if fire is pressed
                        bne.s                   .thatsAll
                        ; -- else next state is 0
                        ; d7 :next state
                        moveq                   #Menu_PHASE_DONE,d7
                        move.w                  d7,Menu_PhaseNext(a6)
                        bra.s                   .thatsAll
                        ; select phase -- case not 2
.waitFirePress          dbf.s                   d7,.runTransition
                        ;
                        ; -- poll joystick status
                        ; a0 := Ptr to joystick states
                        lea                     BufferJoystate,a0
                        ; d5 := [j0,j1] combined in a word
                        move.w                  (a0),d6
                        btst.w                  #7,d6
                        ; -- if fire is not pressed
                        beq.s                   .thatsAll
                        ; -- else next state is 1
                        ; d7 :next state
                        moveq                   #Menu_PHASE_WT_FIRE_RLS,d7
                        move.w                  d7,Menu_PhaseNext(a6)
                        bra.s                   .thatsAll
                        ; select phase -- default
.runTransition
                        ; d6 := Transition start counter
                        moveq                   #0,d6
                        move.w                  Menu_Count(a6),d6
                        ; -- compute address offset
                        ; d5 := address offset
                        move.l                  #Menu_INC_Y_UPDT,d5
                        ; d4 := blitter y count = 8 most of the time
                        moveq                   #8,d4
                        ; __unless mi(cmp.w #8,d6)
                        cmp.w                   #8,d6
                        bmi.s                   .END_unless_000001__p_menu
.BEGIN_unless_000001__p_menu
                        ; -- blitter y count is step + 1
                        moveq                   #1,d4
                        add.w                   d6,d4
                        bra.s                   .updatePtrs
.END_unless_000001__p_menu
                        ; -- if before step 25, use normal offset
                        ; __unless mi(cmp.w #25,d6)
                        cmp.w                   #25,d6
                        bmi.s                   .END_unless_000002__p_menu
.BEGIN_unless_000002__p_menu
                        ; -- Use end offset
                        move.l                  #Menu_INC_Y_UPDT_END,d5
                        ; -- Blitter y count is 32 - step
                        moveq                   #32,d4
                        sub.w                   d6,d4
.END_unless_000002__p_menu
                        ; -- do the update
                        ; a5 := Ptr to source
.updatePtrs             move.l                  Menu_PtrImageCurrent(a6),a5
                        add.l                   d5,a5
                        move.l                  a5,Menu_PtrImageCurrent(a6)
                        ; a5 :=  Ptr to dest
                        move.l                  Menu_PtrStartToRedraw(a6),a5
                        add.l                   d5,a5
                        move.l                  a5,Menu_PtrStartToRedraw(a6)
                        ; -- update blitter count
                        move.w                  d4,Menu_BlitCountY(a6)
                        ; -- update counter and test for the end of the transition end
                        addq.w                  #1,d6
                        move.w                  d6,Menu_Count_Next(a6)
                        cmp.b                   #32,d6
                        ; -- if there are still steps to perform the end of the transition
                        bmi.s                   .thatsAll
                        ; -- else next state is 2
                        ; d7 := next state
                        moveq                   #Menu_PHASE_WT_FIRE_PRS,d7
                        move.w                  d7,Menu_PhaseNext(a6)
                        ; ========
.thatsAll               rts
; ----------------------------------------------------------------------------------------------------------------
; redraw
; ----------------------------------------------------------------------------------------------------------------
PhsMenuRedraw:
                        ;rts
                        ; a6 := the menu
                        move.l                  #TheMenu,a6
                        ; __select over TheMenu.Menu_Phase
.BEGIN_select_000003__p_menu
                        ; d7 := menu phase
                        moveq                   #0,d7
                        move.w                  Menu_Phase(a6),d7
                        ; __unless case 0
.BEGIN_select_000003__p_menu__case_0
                        dbf.s                   d7,.BEGIN_select_000003__p_menu__case_1
                        rts
                        ; __unless case 1
.BEGIN_select_000003__p_menu__case_1
                        dbf.s                   d7,.BEGIN_select_000003__p_menu__case_2
                        ; __break
                        bra.s                   .END_select_000003__p_menu
                        ; __unless case 2
.BEGIN_select_000003__p_menu__case_2
                        dbf.s                   d7,.BEGIN_select_000003__p_menu__default
                        ; __break
                        bra.s                   .END_select_000003__p_menu
                        ; __default
.BEGIN_select_000003__p_menu__default
                        ; -- call redraw by blitting
                        ; a4 := source
                        move.l                  Menu_PtrImageCurrent(a6),a4
                        ; a3 := dest
                        move.l                  Menu_PtrStartToRedraw(a6),a3
                        ; d6 := count lines to redraw
                        move.w                  Menu_BlitCountY(a6),d6
                        _Supexec                #ExecBlitPartialScreen
                        ; -- commit next step
                        ; d5 := temp reg
                        move.w                  Menu_Count_Next(a6),d5
                        move.w                  d5,Menu_Count(a6)
.END_select_000003__p_menu
                        ; -- commit next phase
                        ; d7 := temp reg
.commitNext             move.w                  Menu_PhaseNext(a6),d7
                        move.w                  d7,Menu_Phase(a6)
.thatsAll               rts
; ----------------------------------------------------------------------------------------------------------------
; after each
; ----------------------------------------------------------------------------------------------------------------
PhsMenuAfterEach:
                        rts
; ----------------------------------------------------------------------------------------------------------------
; after all
; ----------------------------------------------------------------------------------------------------------------
PhsMenuAfterAll:
                        rts
; ================================================================================================================
; Model
; ================================================================================================================
TheMenu                 ds.b                    SIZEOF_Menu
                        even
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
