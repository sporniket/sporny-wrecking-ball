; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Stub project for gaming app on Atari ST/STe
; ================================================================================================================
                        include                 'macros/sizeof.s'
                        include                 'macros/easy_cnd.s'
                        include                 'macros/systraps.s'
                        include                 'macros/input.s'
                        include                 'macros/screen.s'
                        include                 'macros/palette.s'
                        include                 'macros/memory.s'
                        include                 'macros/tricks.s'
                        include                 'macros/dmasnd.s'
                        include                 'macros/special.s'
                        include                 'macros/blitter.s'

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
;
;
PrintChar               macro
                        move.w                  \1,-(sp)
                        ___gemdos               2,4
                        endm
;
;
Terminate               macro
                        MouseOn
                        ___gemdos               0,0
                        endm
;
;
SetupAbnormalTerm       macro
                        move.l                  #HastilyTerminateHandler,-(sp)
                        move.w                  #258,-(sp)
                        ___bios                 5,8
                        endm

; ================================================================================================================

; ================================================================================================================
; Main
; ================================================================================================================
                        ; ========
                        ; TPA management
                        move.l                  4(sp),MmBasepage
                        ShrinkTpa               4096,SIZEOF_HEAP_ACTUAL              ;4kB stack + strictly necessary heap
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
                        bsr                     CheckHardwareOrDie

                        ; ========
                        _Getrez
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
                        ; -- prepare to quit abruptly
                        SetupAbnormalTerm
                        ; -- Display greeting message
                        FlushInp
                        Print                   messGreetings
                        WaitInp
                        FlushInp
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
;
; ================================================================================================================
; Hardware checks -- main
; ================================================================================================================
CheckHardwareOrDie:
                        bsr                     CheckTosVersion
                        tst.b                   d0
                        beq.s                   .die
                        bsr                     CheckBlitter
                        tst.b                   d0
                        beq.s                   .die
                        bsr                     CheckDmaSound
                        tst.b                   d0
                        beq                     .die
                        bsr                     CheckStColor
                        tst.b                   d0
                        beq                     .die
                        rts

.die
                        Print                   messNewLine
                        Print                   messTheEnd
                        WaitInp
                        Terminate
; ================================================================================================================
; Check resolution
; ================================================================================================================
CheckStColor:
                        ;Getrez is 0 or 1
                        _Getrez
                        ; d7 := output char from d0 = 0 + $30 (ascii code of '0')
                        moveq                   #0,d7
                        move.w                  d0,d7
                        add.w                   #$30,d7
                        Print                   messStColor
                        PrintChar               d7
                        cmp.b                   #$32,d7
                        blo.s                   .ok
                        Print                   messKo
                        Print                   messNewLine
                        moveq                   #0,d0
                        rts
.ok
                        Print                   messOk
                        Print                   messNewLine
                        moveq                   #1,d0
                        rts
; ================================================================================================================
CheckTosVersion:
                        ; -- want at least 1.02
                        ; d0 := TOS version
                        _Supexec                #DoRetrieveTosVersion
                        ; d7 := backup result
                        moveq                   #0,d7
                        move.w                  d0,d7
                        ; {d6,d5} := {high byte,low byte} of tos version
                        moveq                   #0,d6
                        move.w                  d0,d6
                        lsr.w                   #8,d6
                        moveq                   #0,d5
                        move.b                  d0,d5
                        Print                   messTosVersion
                        ; d4 := next char
                        moveq                   #0,d4
                        move.b                  d6,d4
                        add.b                   #$30,d4
                        PrintChar               d4
                        PrintChar               #'.'
                        move.b                  d5,d4
                        lsr.b                   #4,d4
                        add.b                   #$30,d4
                        PrintChar               d4
                        move.b                  d5,d4
                        and.b                   #$f,d4
                        add.b                   #$30,d4
                        PrintChar               d4
                        cmp.w                   #$0100,d7
                        beq.s                   .ko
                        Print                   messOk
                        Print                   messNewLine
                        moveq                   #1,d0
                        rts
.ko
                        Print                   messKo
                        Print                   messNewLine
                        moveq                   #0,d0
                        rts

DoRetrieveTosVersion:
                        move.l                  #$4f2,a0
                        move.l                  (a0),a0
                        moveq                   #0,d0
                        move.w                  2(a0),d0
                        rts
; ================================================================================================================
; Check Blitter
; ================================================================================================================
CheckBlitter:
                        _BlitMode               #-1
                        ; d7 := backup result
                        moveq                   #0,d7
                        move.w                  d0,d7
                        ; d6 := digit char of blitter mode
                        moveq                   #0,d6
                        move.b                  d7,d6
                        add.b                   #$30,d6
                        ;
                        Print                   messBlitter
                        PrintChar               d6
                        btst.b                  #1,d7
                        beq.w                   .ko
                        Print                   messOk
                        btst.b                  #0,d7
                        beq.s                   .switchOn
                        Print                   messNewLine
                        moveq                   #1,d0
                        rts
.switchOn
                        PrintChar               #','
                        _BlitMode               #1
                        Print                   messBlitterActivated
                        _BlitMode               #-1
                        move.w                  d0,d7
                        move.b                  d7,d6
                        add.b                   #$30,d6
                        PrintChar               #'.'
                        PrintChar               #'.'
                        PrintChar               #'.'
                        PrintChar               d6
                        Print                   messNewLine
                        moveq                   #1,d0
                        rts

.ko
                        Print                   messKo
                        Print                   messNewLine
                        moveq                   #0,d0
                        rts

; ================================================================================================================
; Check DMA sound
; ================================================================================================================
CheckDmaSound:
                        ; push low byte address of dma sound control register
                        move.l                  #$ffff8900,-(sp)
                        _Supexec                #FnIsReadableAddress
                        ; fix stack
                        addq.l                  #4,sp
                        ; d7 := backup value
                        moveq                   #0,d7
                        move.b                  d0,d7
                        ; d6 := d7 as digit char
                        move.l                  d7,d6
                        add.b                   #$30,d6
                        ;
                        Print                   messDmaSound
                        PrintChar               d6
                        tst.b                   d7
                        beq.s                   .ko
                        Print                   messOk
                        Print                   messNewLine
                        ; d0 := result
                        moveq                   #1,d0
                        rts
.ko
                        Print                   messKo
                        Print                   messNewLine
                        ; d0 := result
                        moveq                   #0,d0
                        rts


; ================================================================================================================
; Test for accessible address, to check hardware registers
; ================================================================================================================
FnIsReadableAddress:    ; excerpt from https://github.com/emutos/emutos/blob/master/bios/vectors.S
                        ; _check_read_byte
                        ; to test hardware register.
                        ; 8(sp) : address to test. (It's a trap : called through supexec, pushed supexec params before)
                        ; @return d0 != 0 if ok
                        ;
                        ; d1 := backup stack
                        move.l                  sp,d1
                        ; a2 := exception vector adress
                        move.l                  #8,a2
                        ; a1 := backup original exception handler
                        move.l                  (a2),a1
                        ; a0 := our exception handler
                        move.l                  #HandlerBusError,a0
                        move.l                  a0,(a2)
                        ; d0 := init response to failure
                        moveq                   #0,d0
                        nop
                        ; a0 := the address to test
                        move.l                  8(sp),a0
                        tst.b                   (a0)
                        nop
                        ; d0 := success
                        moveq                   #1,d0


HandlerBusError:
                        ; restore exception handler
                        move.l                  a1,(a2)
                        ; restore stack
                        move.l                  d1,sp
                        nop
                        ; that's all
BuggyReturn:
                        rts

HastilyTerminateHandler:
                        RestoreSysIkbdHandler   BufferSysIkbdvbase,BufferSysJoystckHandlr,a0
                        RestoreSavedPalette     BufferSysPalette
                        ; ========
                        lea                     BufferSysState,a6
                        move.w                  (a6)+,d7
                        ChangeToRez             d7
                        ; ========
                        MouseOn
                        ;
                        rts

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
; Libs
; ================================================================================================================
                        include                 'libs/blitter.s'
                        include                 'libs/dmasnd.s'
; ================================================================================================================
; App body
; ================================================================================================================
                        include                 'includes/fade_clr.s'
                        include                 'includes/mdl_levl.s'
                        include                 'includes/game_stt.s'
                        include                 'app.s'
; ================================================================================================================
; Global data
; ================================================================================================================
; Memory management data
;
; Program memory map : [MmBasepage...[MmStackBase...]MmHeapBase...]MmHeapTop
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
;
; ================================================================================================================
; Strings for the hardware checks
messCls                 dc.b                    27,"E",0
messNewLine             dc.b                    10,13,0
messOk                  dc.b                    "...ok",0
messKo                  dc.b                    "...KO",0
messStColor             dc.b                    "Getrez is 0 or 1 ? ",0
messTosVersion          dc.b                    "TOS version > 1.00 ? ",0
messBlitter             dc.b                    "Has blitter ? ",0
messBlitterActivated    dc.b                    "was off -> switch on",0
messDmaSound            dc.b                    "Can access DMA sound register ? ",0
; ================================================================================================================
; Greeting message
messGreetings           dc.b 10,13,"SPORNY'S WRECKING BALL 'PRELUDE'"
                        dc.b 10,13,"Alpha 'Merry End of the Year !' version"
                        dc.b 10,13
                        dc.b 10,13,"# Some tips to play..."
                        dc.b 10,13
                        dc.b 10,13,"When the ball is captive, HOLD FIRE to"
                        dc.b 10,13,"steer the ball left or right THEN"
                        dc.b 10,13,"RELEASE FIRE"
                        dc.b 10,13
                        dc.b 10,13,"* Orange-ish gem : 'Juggernaut' mode"
                        dc.b 10,13,"* Blue-ish gem : 'Shallow' mode"
                        dc.b 10,13,"* Green-ish blob : 'Sluggish' mode"
                        dc.b 10,13
                        dc.b 10,13,"* WIN LEVEL CONDITIONS : "
                        dc.b 10,13
                        dc.b 10,13,"  * Reach an unlocked 'Exit'"
                        dc.b 10,13,"    Unlock 'Exit' by collecting all keys"
                        dc.b 10,13
                        dc.b 10,13,"  * Collect all the stars"
                        dc.b 10,13
                        dc.b 10,13,"  * Break all the bricks"
                        dc.b 10,13
                        dc.b 10,13,"Press any key and have fun !"
                        dc.b 0
                        even
