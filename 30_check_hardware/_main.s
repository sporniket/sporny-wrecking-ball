; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Extract sprite sheets from the included pi1
; ================================================================================================================
                        include                 'macros/sizeof.s'
                        include                 'macros/systraps.s'
                        include                 'macros/input.s'
                        include                 'macros/screen.s'
                        include                 'macros/palette.s'
                        include                 'macros/memory.s'
                        include                 'macros/tricks.s'
                        include                 'macros/special.s'
                        include                 'macros/fileio.s'


; ================================================================================================================
Print                   macro
                        pea                     \1
                        ___gemdos               9,6
                        endm
;
PrintChar               macro
                        move.w                  \1,-(sp)
                        ___gemdos               2,4
                        endm
;
Terminate               macro
                        ___gemdos               0,0
                        endm
;
_xos_BlitMode               macro
                        move.w                  \1,-(sp)
                        ___xbios                64,4
                        endm

; ================================================================================================================
; Main
; ================================================================================================================
                        Print                   messCls
                        bsr                     CheckStColor
                        bsr                     CheckTosVersion
                        tst.b                   d0
                        beq.s                   ThatsAll
                        bsr                     CheckBlitter
                        tst.b                   d0
                        beq.s                   ThatsAll
                        bsr                     CheckDmaSound
ThatsAll:
                        Print                   messNewLine
                        Print                   messThatsAll
                        WaitInp
                        Terminate
; ================================================================================================================
; Check resolution
; ================================================================================================================
CheckStColor:
                        ;Getrez is 0 or 1
                        _xos_Getrez
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
                        rts
.ok
                        Print                   messOk
                        Print                   messNewLine
                        rts
; ================================================================================================================
CheckTosVersion:
                        ; -- want at least 1.02
                        ; d0 := TOS version
                        _xos_Supexec                #DoRetrieveTosVersion
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
                        _xos_BlitMode               #-1
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
                        btst                    #1,d7
                        beq.w                   .ko
                        Print                   messOk
                        btst                    #0,d7
                        beq.s                   .switchOn
                        Print                   messNewLine
                        moveq                   #1,d0
                        rts
.switchOn
                        PrintChar               #','
                        _xos_BlitMode               #1
                        Print                   messBlitterActivated
                        _xos_BlitMode               #-1
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
                        _xos_Supexec                #FnIsReadableAddress
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
                        move.l                  d7,d0
                        rts
.ko
                        Print                   messKo
                        Print                   messNewLine
                        ; d0 := result
                        move.l                  d7,d0
                        rts

; ================================================================================================================
; ================================================================================================================
; Test for accessible address, to check hardware registers
; ================================================================================================================
FnIsReadableAddress:    ; excerpt from https://github.com/emutos/emutos/blob/master/bios/vectors.S
                        ; _check_read_byte
                        ; to test hardware register.
                        ; 8(sp) : address to test. (It's a trap : called through supexec, pushed supexec params before)
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

; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; messages
; ================================================================================================================
messCls                 dc.b                    27,"E",0
messNewLine             dc.b                    10,13,0
messOk                  dc.b                    "...ok",0
messKo                  dc.b                    "...KO",0
messStColor             dc.b                    "Getrez is 0 or 1 ? ",0
messTosVersion          dc.b                    "TOS version > 1.00 ? ",0
messBlitter             dc.b                    "Has blitter ? ",0
messBlitterActivated    dc.b                    "was off -> switch on",0
messDmaSound            dc.b                    "Can access DMA sound register ? ",0
messThatsAll            dc.b                    "Done, press any key to quit.",0
