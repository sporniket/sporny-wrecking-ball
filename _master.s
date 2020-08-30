; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Stub project for gaming app on Atari ST/STe
; ================================================================================================================
                        include                 'macros/sizeof.s'
                        include                 'macros/systraps.s'
                        include                 'macros/input.s'
                        include                 'macros/screen.s'
                        include                 'macros/palette.s'
                        include                 'macros/memory.s'
                        include                 'macros/tricks.s'
                        include                 'macros/dmasnd.s'
                        include                 'macros/special.s'

; ================================================================================================================
; Input macros
MouseOff                macro
                        _ikbdws                 1, ikbdMsOffJoyOn
                        endm

MouseOn                 macro
                        _ikbdws                 1, ikbdJoyOnMsOnRel
                        endm

; ================================================================================================================
; Basic macros

Print                   macro
                        pea                     \1
                        ___gemdos               9,6
                        endm

Terminate               macro
                        MouseOn
                        ___gemdos               0,0
                        endm
; ================================================================================================================

; ================================================================================================================
; Main
; ================================================================================================================
                        ; ========
                        ; TPA management
                        move.l                  4(sp),MmBasepage
                        ShrinkTpa               4096,12288              ;1/4 stack, 3/4 heap
                        tst.l                   d0
                        beq.s                   CanStart
                        cmp.l                   #-39,d0
                        bne.s                   InvalidMemory
                        Print                   messNotEnoughMemory
                        WaitInp
                        Terminate
InvalidMemory           Print                   messInvalidMemory
                        WaitInp
                        Terminate
CanStart:               ; --------
                        ; Save memory map boundaries
                        move.l                  a0,MmStackBase
                        move.l                  a2,MmHeapBase
                        move.l                  a3,MmHeapTop
                        ; Setup the new stack
                        move.l                  a2,sp
                        ; from now on :
                        ; -- before predecrement : MmStackBase < sp <= MmHeapBase
                        ; -- after predecrement : MmStackBase <= sp < MmHeapBase
                        ; -- OTHERWISE NOT GOOD
                        ;
                        ; TPA management DONE
                        ; ========
                        MouseOff
                        Print                   vt52ClearScreen

CheckColorMode:         ; ========
                        _Getrez
                        cmp.w                   #$2,d0
                        bge.s                   ColorModeRequired
                        bra.s                   SaveSysState
                        ; ========

ColorModeRequired:      ; ========
                        Print                   messColorModeRequired
                        WaitInp
                        Terminate

SaveSysState:           ; ========
                        lea                     BufferSysState,a0
                        move.w                  d0,(a0)+
                        ChangeToRez             #0
                        ; ========
                        ; -- setup joystick handling
                        SaveSysIkbdHandler      BufferSysIkbdvbase,BufferSysJoystckHandlr,a0
.waitIkbd               tst.b                   36(a0)                  ; wait for KBDVECS.ikbdstate to be 0
                        bne.s                   .waitIkbd
                        move.l                  #OnJoystickSysEvent,24(a0)
                        ; ========
                        ; -- setup palette
                        SaveSysPalette          BufferSysPalette
                        ; ========
                        ; I don't want to mess my brain with the STe rgb color coding, let the computer do it.
                        lea                     appPalette,a6
                        move.b                  #15,d7                  ; loop over all the colors
.nextAppColor           move.w                  (a6),d6
                        move.w                  d6,d5
                        and.w                   #$0eee,d5               ; ST compatible bits...
                        lsr.w                   #1,d5                   ; ... are put on the right
                        and.w                   #$0111,d6               ; STe extension bit...
                        lsl.w                   #3,d6                   ; ... is put on the left
                        or.w                    d5,d6                   ; recombine...
                        move.w                  d6,(a6)+                ; ... and save
                        dbf.s                   d7,.nextAppColor
                        ; ========
                        _Setpalette             appPalette
                        ; proceed to the app
                        bsr.w                   BodyOfApp

EndOfApp:
                        Print                   messTheEnd
                        WaitInp
                        Print                   vt52ClearScreen
                        RestoreSysIkbdHandler   BufferSysIkbdvbase,BufferSysJoystckHandlr,a0
                        RestoreSavedPalette     BufferSysPalette
                        ; ========
                        lea                     BufferSysState,a6
                        move.w                  (a6)+,d7
                        ChangeToRez             d7
                        ; ========
                        MouseOn
                        Terminate

; ================================================================================================================
; Custom handlers
; ================================================================================================================
OnJoystickSysEvent      movem                   a1,-(sp)
                        lea                     BufferJoystate,a1
                        addq.l                  #1,a0                   ;skip event source
                        move.b                  (a0)+,(a1)+             ;j0 state
                        move.b                  (a0)+,(a1)+             ;j1 state
                        movem                   (sp)+,a1
                        rts
BufferJoystate          dc.w                    0
; ================================================================================================================
; App body
; ================================================================================================================
                        include                 'app.s'
; ================================================================================================================
; Global data
; ================================================================================================================
; Memory management data
;
; Program memory map : [MmBasepage...[MmStackBase...]MmHeapBase...]MmHeapTop
;
; --- Notation convention ---
; Given :
; * '[MmAaa' : MmAaa = start of memory area, address of the first byte inside
; * ']MmBbb' : MmBbb = end of memory area, address of the first byte after
;
; Then :
; * The size of the memory area '[MmAaa...]MmBbb' is 'MmBbb - MmAaa'
; --- --- --- --- --- --- ---
;
MmBasepage              dc.l                    0                       ; save the basepage here
MmStackBase             dc.l                    0                       ; save the base of the stack here
MmHeapBase              dc.l                    0                       ; save the base of the heap here
MmHeapTop               dc.l                    0                       ; save the top of the heap here
; ================================================================================================================
; Buffers to save system value to be restored at the end.
BufferSysState          dc.w                    0                       ;_Getrez, in case of going back to medium
BufferSysPalette        ds.w                    16                      ;Buffer for system palette
BufferSysIkbdvbase      dc.l                    0                       ;System IKBD vector base
BufferSysJoystckHandlr  dc.l                    0                       ;System IKBD joystick vector
; Screen adresses
screenBase              dc.l                    0
; Human readable palette for the app. It will be converted into STe color palette on startup.
; The palette of the stup is adapted from "DawnBringer's 16 Col Palette v1.0"
; see http://pixeljoint.com/forum/forum_posts.asp?TID=12795
; see https://lospec.com/palette-list/dawnbringer-16
; Colors 0, 1, 6 and 15 are put at index 1, 0, 2 and 3 resp. to optimize drawing of the sample game. (needs only
; bitplan 0 and 1 for drawing, thus 6 bitplans counting the masking.)
appPalette              dc.w                    $0423,$0112,$0c44,$0ded,$0336,$0555,$0843,$0362
                        dc.w                    $0776,$057c,$0c73,$0899,$06a3,$0ca9,$06bc,$0dc6
; Ikbd instructions for ikbdws, see the Atari compendium
ikbdMsOffJoyOff         dc.b                    $12, $1a                ; byte count = 2 - 1 = 1
ikbdMsOffJoyOn          dc.b                    $12, $14                ; byte count = 2 - 1 = 1
ikbdJoyOnMsOnRel        dc.b                    $14, $08                ; byte count = 2 - 1 = 1
                        even
; VT-52 sequences (C-Strings)
vt52ClearScreen         dc.b                    27,"E",0
                        even
; various messages (C-strings)
messNotEnoughMemory     dc.b                    "Not enough memory, press a key to quit",10,13,0
messInvalidMemory       dc.b                    "Invalid memory, press a key to quit",10,13,0
messColorModeRequired   dc.b                    "This app runs in ST color mode only, press a key to quit.",10,13,0
messTheEnd              dc.b                    10,13,"That's all folks, press a key to quit.",0
dbgDing                 dc.b                    7,0                     ; When you don't know where it goes...
                        even
