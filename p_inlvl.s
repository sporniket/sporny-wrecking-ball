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
; Phase : Init level
; [ ] before all
; [ ] before each
; [ ] update
; [ ] redraw
; [ ] after each
; [ ] after all
; ---
; Three steps :
; * fade to black
; * show text (TODO)
; * show the level
; ---
; ================================================================================================================
;
InitLevel_STEP_FADE     = 4
InitLevel_STEP_TEXT     = 3
InitLevel_STEP_WAIT     = 2
InitLevel_STEP_LEVEL    = 1
InitLevel_STEP_END      = 0

InitLevel_LEVEL_LINE_END = 10


;
InitLevel_BlitFadeClr   macro
                        ; 1 - address register, to FadeClr instance
                        ; 2 - address register, to the blit list
                        ; --
                        ; This is a blit item opcode 2
                        move.w                  #2,(\2)+
                        ; -- Setup Source
                        move.w                  FadeClr_SrcIncX(\1),(\2)+                ; source x increment (contiguous)
                        move.w                  FadeClr_SrcIncY(\1),(\2)+            ; source y increment
                        move.l                  FadeClr_PtrSrc(\1),(\2)+                ; source address
                        ; -- setup masks
                        move.w                  #$ffff,(\2)+
                        move.w                  #$ffff,(\2)+
                        move.w                  #$ffff,(\2)+
                        ; -- setup Dest
                        move.w                  FadeClr_DestIncX(\1),(\2)+
                        move.w                  FadeClr_DestIncY(\1),(\2)+
                        move.l                  FadeClr_PtrDest(\1),(\2)+
                        ; -- setup x/y counts
                        move.w                  #80,(\2)+
                        move.w                  FadeClr_CountY(\1),(\2)+
                        ; -- Hop/op values
                        move.w                  #$0203,(\2)+ ; HOP = 2 (source), OP = 3 (source)
                        ; -- set skew/shift registers
                        move.w                  #0,(\2)+
                        endm
;

;
InitLevel_BlitFadeClr2   macro
                        ; 1 - address register, to FadeClr instance
                        ; 2 - address register, to the blit list
                        ; --
                        ; This is a blit item opcode 3
                        move.w                  #3,(\2)+
                        ; -- Setup Source
                        move.l                  FadeClr_PtrSrc2(\1),(\2)+                ; source address
                        ; -- setup Dest
                        move.l                  FadeClr_PtrDest2(\1),(\2)+
                        ; -- setup y counts
                        move.w                  FadeClr_CountY2(\1),(\2)+
                        endm
;
;
InitLevel_PushFirstBb   macro
                        ; put first brick blit ('bb') item into the blit list.
                        ; - 1 address to the sprite data
                        ; - 2 address to the start of memory screen to update
                        ; - 3 shift to the right
                        ; - 4 address of next blit item in the blitter list buffer
                        ; - 5 spare data register
                        ; --
                        ; This is a blit item opcode 2
                        move.w                  #2,(\4)+
                        ; -- Setup Source
                        move.w                  #8,(\4)+ ; source x increment
                        move.w                  #0,(\4)+ ; source y increment
                        move.l                  \1,(\4)+ ; source address
                        ; -- setup masks
                        ; \5 := $ffff0000 >> \3 = [endmask 1|endmask3]
                        move.l                  #$ff000000,\5
                        lsr.l                   \3,\5
                        ; swap to put endmask1, swap again to put endmask3
                        swap                    \5
                        move.w                  \5,(\4)+
                        move.w                  #$ffff,(\4)+
                        swap                    \5
                        move.w                  \5,(\4)+
                        ; -- setup Dest
                        move.w                  #8,(\4)+
                        move.w                  #152,(\4)+ ; 160 bytes - 1 * 8
                        move.l                  \2,(\4)+
                        ; -- setup x/y counts
                        move.w                  #2,(\4)+
                        move.w                  #8,(\4)+
                        ; -- Hop/op values
                        move.w                  #$0203,(\4)+ ; HOP = 2 (source), OP = 3 (source)
                        ; -- set skew/shift registers
                        move.b                  #0,(\4)+
                        move.b                  \3,(\4)+
                        endm
;
;
InitLevel_PushNextBb    macro
                        ; put next brick blit ('bb') item into the blit list.
                        ; - 1 address to the sprite data
                        ; - 2 address to the start of memory screen to update
                        ; - 3 address of next blit item in the blitter list buffer
                        ; --
                        ; This is a blit item opcode 3
                        move.w                  #3,(\3)+
                        ; -- Setup Source
                        move.l                  \1,(\3)+ ; source address
                        ; -- setup Dest
                        move.l                  \2,(\3)+
                        ; -- setup x/y counts
                        move.w                  #8,(\3)+
                        endm
;
;
InitLevel_CellToSprdat  macro
                        ; convert a cell value (from level representation) into the pointer of the sprite data
                        ; 1 - data register, cell value to convert
                        ; 2 - spare data register, result
                        ; 3 - address register, pointer to the sprite sheet.
                        ; 4 - address register, address of the sprite index table
                        ; --
                        ; \2 := sprite index (low byte of \1)
                        moveq                   #0,\2
                        move.b                  \1,\2
                        ; \2 := 2*\2, offset in the index table
                        WdMul2                  \2
                        move.w                  (\4,\2),\2
                        add.l                   \3,\2
                        endm
;
;
InitLevel_execFadeClr
                        ; ---
                        ; a6 - Ptr to the fadeclr transition
                        ; ---
                        ; a5 := start of blit list
                        SetupHeapAddress        HposBlitListBase,a5
                        ; -- setup PtrBlitterList
                        ; a0 := PtrBlitterList
                        move.l                  #PtrBlitterList,a0
                        move.l                  a5,(a0)
                        ; -- setup blit list
                        ; a4,d6 : spare register
                        InitLevel_BlitFadeClr   a6,a5
                        ; d6 := count y 2 (workaround blitter glitch)
                        moveq                   #0,d6
                        move.w                  FadeClr_CountY2(a6),d6
                        tst.w                   d6
                        beq.s                   .doneList
                        InitLevel_BlitFadeClr2  a6,a5
                        ; -- end of blit list
.doneList
                        move.w                  #0,(a5)+
                        _Supexec                #BlitRunList
                        rts

; ----------------------------------------------------------------------------------------------------------------
; before all
; ----------------------------------------------------------------------------------------------------------------
PhsInitLevelBeforeAll:
                        ; -- store current level pointer
                        ; a6 := actual address
                        SetupHeapAddress        HposCurrentLvlBase,a6
                        ; a5 := pointer to set
                        lea                     InitLevel_PtrCrntLvl,a5
                        move.l                  a6,(a5)
                        ; -- store fade effect pointer
                        ; a6 := actual address
                        SetupHeapAddress        HposFadeEffectBase,a6
                        ; a5 := pointer to set
                        lea                     InitLevel_PtrFadeClr,a5
                        move.l                  a6,(a5)
                        rts
; ----------------------------------------------------------------------------------------------------------------
; before each
; ----------------------------------------------------------------------------------------------------------------
PhsInitLevelBeforeEach:
                        ; -- init step
                        move.w                  #InitLevel_STEP_FADE,InitLevel_Step
                        move.w                  #InitLevel_STEP_FADE,InitLevel_StepNext
                        ; -- init transition
                        ; a6 := transition to setup
                        DerefPtrToPtr           InitLevel_PtrFadeClr,a6
                        ; (init all but the screen address)
                        FadeClr_init            a6,SpritesLinesDat,2,-160,0,0,0,2,-1600,1280,-160,0,-5760,d7
                        ; retrieve the start address of the screen
                        _Logbase
                        move.l                  d0,FadeClr_Dest(a6)
                        move.l                  d0,FadeClr_PtrDest(a6)
                        add.l                   #-5760,d0
                        move.l                  d0,FadeClr_PtrDest2(a6)
                        ; -- load level data into current level
                        ; a6 := current level memory area
                        SetupHeapAddress        HposCurrentLvlBase,a6
                        ; a5 := actual level to load
                        ; TODO : Ptr to current level data, for now fixed
                        lea                     DatLevel0,a5
                        ; a4,d7,d6,d5,d4,d3 : spare registers
                        Level_init_v0           a5,a6,a4,d7,d6,d5,d4,d3
                        ; -- init line counter
                        move.w                  #0,InitLevel_LvlLine
                        ; -- init ptr to cell
                        ; a3 : ptr to first cell
                        lea                     Level_Bricks(a6),a3
                        move.l                  a3,InitLevel_PtrCell
                        move.l                  #$00314159,a3 ; magic number to debug in hatari
                        ;
                        ;
                        ; -- clear screen (workaround blitter glitch that cannot override some pixels during fade effect ???)
                        ; // STUDY ME !!! THERE MUST BE SOMETHING FISHY IN MY CODE... IT HAS TO !
                        Print                   vt52ClearScreen
                        rts
; ----------------------------------------------------------------------------------------------------------------
; update
; ----------------------------------------------------------------------------------------------------------------
PhsInitLevelUpdate:
                        ;--
                        ; d7 := current step
                        moveq                   #0,d7
                        move.w                  InitLevel_Step,d7
                        ; -- select d7
                        dbf                     d7,.caseStepLevel
                        ; -- case InitLevel_STEP_END
                        ; -- next game phase
                        move.l                  #PhsInitLevelAfterEach,a2
                        jsr                     (a2)
                        move.l                  #PhsGameBeforeEach,a2
                        jsr                     (a2)
                        move.l                  #PhsGameUpdate,PtrNextUpdate
                        move.l                  #PhsGameRedraw,PtrNextRedraw
                        rts
.caseStepLevel
                        dbf                     d7,.caseStepWait
                        ; -- case InitLevel_STEP_LEVEL
                        ; d6 := line counter
                        moveq                   #0,d6
                        move.w                  InitLevel_LvlLine,d6
                        cmp.w                   #InitLevel_LEVEL_LINE_END,d6
                        bmi.s                   .prepareLevelLine
                        rts
.prepareLevelLine
                        ; TODO prepare blit list
                        ; -- init registers (ptr to blit list)
                        ; a6 := start of blit list
                        SetupHeapAddress        HposBlitListBase,a6
                        ; -- setup PtrBlitterList
                        ; a5 := PtrBlitterList
                        move.l                  #PtrBlitterList,a5
                        move.l                  a6,(a5)
                        ; -- reference pointers
                        ; a3 := start of index tables
                        lea                     IndexBricksTbl,a3
                        ; a2 := start of sprite datas
                        lea                     SpritesBricksDat,a2
                        ; ===== First run, even cells (0,2,...) =====
                        ; a5 := Ptr to cell
                        DerefPtrToPtr           InitLevel_PtrCell,a5
                        ; d5 := displacement to current line
                        move.l                  d6,d5
                        WdMul2                  d5
                        mulu.w                  #40,d5
                        add.l                   d5,a5
                        ; a4 := Start of screen
                        _Logbase
                        move.l                  d0,a4
                        ; d5 := displacement to current screen line (previously 80*level line) = d5 * 16
                        lsl.l                   #4,d5
                        add.l                   d5,a4
                        ; d4 := sprite destination
                        move.l                  a4,d4
                        ; d3 := shift value (0)
                        moveq                   #0,d3
                        ; -- push blit list for first cell
                        ; d6 := cell value
                        moveq                   #0,d6
                        move.w                  (a5)+,d6
                        addq.w                  #2,a5
                        ; d5 := pointer to sprite
                        InitLevel_CellToSprdat  d6,d5,a2,a3
                        ; d2 := spare data register
                        InitLevel_PushFirstBb   d5,d4,d3,a6,d2
                        rept 3
                        addq.l                  #2,d5
                        addq.l                  #2,d4
                        InitLevel_PushNextBb    d5,d4,a6
                        endr
                        ; -- loop 19 times over d2
                        moveq                   #18,d2
.prepareNextCellEven
                        ; d6 := cell value
                        moveq                   #0,d6
                        move.w                  (a5)+,d6
                        addq.w                  #2,a5
                        ; d5 := pointer to sprite
                        InitLevel_CellToSprdat  d6,d5,a2,a3
                        ; -- prepare blits
                        rept 4
                        addq.l                  #2,d4
                        InitLevel_PushNextBb    d5,d4,a6
                        addq.l                  #2,d5
                        endr
                        dbf                     d2,.prepareNextCellEven
                        ; ===== Second run, odd cells (1,3,...) =====
                        ; d6 := line counter (reload)
                        moveq                   #0,d6
                        move.w                  InitLevel_LvlLine,d6
                        ; a5 := Ptr to cell
                        DerefPtrToPtr           InitLevel_PtrCell,a5
                        ; d5 := displacement to current line
                        move.l                  d6,d5
                        WdMul2                  d5
                        mulu.w                  #40,d5
                        add.l                   d5,a5
                        addq.l                  #2,a5
                        ; a4 := Start of screen
                        _Logbase
                        move.l                  d0,a4
                        ; d5 := displacement to current screen line (previously 80*level line) = d5 * 16
                        lsl.l                   #4,d5
                        add.l                   d5,a4
                        ; d4 := sprite destination
                        move.l                  a4,d4
                        ; d3 := shift value (8)
                        moveq                   #8,d3
                        ; -- push blit list for first cell
                        ; d6 := cell value
                        moveq                   #0,d6
                        move.w                  (a5)+,d6
                        addq.w                  #2,a5
                        ; d5 := pointer to sprite
                        InitLevel_CellToSprdat  d6,d5,a2,a3
                        ; d2 := spare data register
                        InitLevel_PushFirstBb   d5,d4,d3,a6,d2
                        rept 3
                        addq.l                  #2,d5
                        addq.l                  #2,d4
                        InitLevel_PushNextBb    d5,d4,a6
                        endr
                        ; -- loop 19 times over d2
                        moveq                   #18,d2
.prepareNextCellOdd
                        ; d6 := cell value
                        moveq                   #0,d6
                        move.w                  (a5)+,d6
                        addq.w                  #2,a5
                        ; d5 := pointer to sprite
                        InitLevel_CellToSprdat  d6,d5,a2,a3
                        ; -- prepare blits
                        rept 4
                        addq.l                  #2,d4
                        InitLevel_PushNextBb    d5,d4,a6
                        addq.l                  #2,d5
                        endr
                        dbf                     d2,.prepareNextCellOdd
                        ; ===== terminate list =====
                        move.w                  #0,(a6)+
                        ; -- advance line counter
                        ; d6 := line counter
                        moveq                   #0,d6
                        move.w                  InitLevel_LvlLine,d6
                        addq.w                  #1,d6
                        move.w                  d6,InitLevel_LvlLine
                        rts
.caseStepWait
                        dbf                     d7,.caseStepText
                        ; -- case InitLevel_STEP_WAIT
                        rts
.caseStepText
                        dbf                     d7,.caseStepFade
                        ; -- case InitLevel_STEP_TEXT
                        rts
.caseStepFade
                        ; -- case InitLevel_STEP_FADE
                        ; a6 := transition to update
                        DerefPtrToPtr           InitLevel_PtrFadeClr,a6
                        ; d6, d5 : spare registers
                        FadeClr_runStep         a6,d6,d5
                        rts
; ----------------------------------------------------------------------------------------------------------------
; redraw
; ----------------------------------------------------------------------------------------------------------------
PhsInitLevelRedraw:
                        ;--
                        ; d7 := current step
                        moveq                   #0,d7
                        move.w                  InitLevel_Step,d7
                        ; -- select d7
                        dbf                     d7,.caseStepLevel
                        ; -- case InitLevel_STEP_END
                        ; -- next game phase
                        ; TODO
                        rts
.caseStepLevel
                        dbf                     d7,.caseStepWait
                        ; -- case InitLevel_STEP_LEVEL
                        _Supexec                #BlitRunList
                        ; d6 := line counter
                        moveq                   #0,d6
                        move.w                  InitLevel_LvlLine,d6
                        cmp.w                   #InitLevel_LEVEL_LINE_END,d6
                        bpl                     .nextStep
                        rts

.caseStepWait
                        dbf                     d7,.caseStepText
                        ; -- case InitLevel_STEP_WAIT
                        bra                     .nextStep
                        rts
.caseStepText
                        dbf                     d7,.caseStepFade
                        ; -- case InitLevel_STEP_TEXT
                        bra                     .nextStep
                        rts
.caseStepFade
                        ; -- case InitLevel_STEP_FADE
                        ; a6 := transition to update
                        DerefPtrToPtr           InitLevel_PtrFadeClr,a6
                        bsr                     InitLevel_execFadeClr
                        ; d6 : spare register
                        FadeClr_onFinished      a6,d6,.nextStep
                        FadeClr_commit          a6
                        bra.s                   .thatsAll
.nextStep
                        ; -- advance step
                        ; d6 := step to update
                        move.w                  InitLevel_Step,d6
                        subq.w                  #1,d6
                        move.w                  d6,InitLevel_Step
.thatsAll               rts
; ----------------------------------------------------------------------------------------------------------------
; after each
; ----------------------------------------------------------------------------------------------------------------
PhsInitLevelAfterEach:
                        rts
; ----------------------------------------------------------------------------------------------------------------
; after all
; ----------------------------------------------------------------------------------------------------------------
PhsInitLevelAfterAll:
                        rts
; ================================================================================================================
; Model
InitLevel_PtrCrntLvl    dc.l                    0                       ; pointer to the current level
InitLevel_PtrFadeClr    dc.l                    0                       ; pointer to the fade transition
InitLevel_Step          dc.w                    0                       ;
InitLevel_StepNext      dc.w                    0                       ;
InitLevel_PtrCell       dc.l                    0                       ; pointer to the next cell to draw
InitLevel_LvlLine       dc.w                    0                       ; counter of current line of level redrawing
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
