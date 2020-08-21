; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; App body
; ================================================================================================================
BodyOfApp:              ; Entry point of the application
                        ; Your code start here...
                        ; ----------------------------------------------------------------
                        lea                     screenBase,a6
                        _Logbase
                        move.l                  d0,(a6)
doDrawMask
                        move.l                  (a6),a0
                        move.w                  #0,d5
                        move.w                  #4,d6                   ; mask 5 lines
.nextLine               move.l                  a0,a1
                        move.w                  #7,d4                   ; eight pair of swatches
.nextPair               move.w                  d5,(a1)+
                        move.w                  d5,(a1)+
                        move.w                  d5,(a1)+
                        move.w                  d5,(a1)+                ; 4 bitplans erased
                        ;done group
                        dbf.s                   d4,.nextPair
                        ;done line
                        lea                     160(a0),a0
                        dbf.s                   d6,.nextLine
                        ;done doDrawMask

doDrawSwatches
                        move.l                  (a6),a0
                        lea                     160(a0),a0              ; draw from line 1
                        move.w                  #2,d6                   ; draw 3 lines
.nextLine               move.l                  a0,a1
                        move.w                  #7,d4                   ; eight pair of swatches
                        moveq                   #0,d2
.nextPair               move.w                  #2,d3                   ; 3 bitplans using d2
                        move.w                  #0,d1
                        ;manually put first bitplan
                        move.w                  #$007f,(a1)+
.nextBitplan            btst.b                  d1,d2
                        beq.s                   .isBlankBitplan
                        move.w                  #$7f7f,(a1)+
                        bra.s                   .proceed
.isBlankBitplan         addq.l                  #2,a1
.proceed                addq.l                  #1,d1
                        dbf.s                   d3,.nextBitplan
                        addq.w                  #1,d2
                        dbf.s                   d4,.nextPair
                        lea                     160(a0),a0
                        dbf.s                   d6,.nextLine

                        ;
                        ; Wait vbl
                        ;
                        _Vsync

doPollJoysticks
.loop                   lea                     BufferJoystate,a0
                        move.w                  (a0),d0
                        move.l                  (a6),a1
                        lea                     2560(a1),a1
                        ; first line : fire + up
                        ;move.w                  d0,160(a1)              ;debug
                        move.l                  #$7700,4(a1)
                        move.l                  #$7700,12(a1)
                        move.l                  #$7070,324(a1)
                        move.l                  #$7070,332(a1)
                        move.l                  #$0700,644(a1)
                        move.l                  #$0700,652(a1)
                        btst.w                  #15,d0
                        beq.s                   .testUp0
                        or.w                    #$7000,0(a1)
                        and.l                   #$0fff,4(a1)
.testUp0                btst.w                  #8,d0
                        beq.s                   .testFire1
                        or.w                    #$0700,0(a1)
                        and.l                   #$f0ff,4(a1)
.testFire1              btst.w                  #7,d0
                        beq.s                   .testUp1
                        or.w                    #$7000,8(a1)
                        and.l                   #$0fff,12(a1)
.testUp1                btst.w                  #0,d0
                        beq.s                   .testLeft0
                        or.w                    #$0700,8(a1)
                        and.l                   #$f0ff,12(a1)
.testLeft0              btst.w                  #10,d0
                        beq.s                   .testRight0
                        or.w                    #$7000,320(a1)
                        and.l                   #$0fff,324(a1)
.testRight0             btst.w                  #11,d0
                        beq.s                   .testLeft1
                        or.w                    #$0070,320(a1)
                        and.l                   #$ff0f,324(a1)
.testLeft1              btst.w                  #2,d0
                        beq.s                   .testRight1
                        or.w                    #$7000,328(a1)
                        and.l                   #$0fff,332(a1)
.testRight1             btst.w                  #3,d0
                        beq.s                   .testDown0
                        or.w                    #$0070,328(a1)
                        and.l                   #$ff0f,332(a1)
.testDown0              btst.w                  #9,d0
                        beq.s                   .testDown1
                        or.w                    #$0700,640(a1)
                        and.l                   #$f0ff,644(a1)
.testDown1              btst.w                  #1,d0
                        beq.s                   FinishOrLoop
                        or.w                    #$0700,648(a1)
                        and.l                   #$f0ff,652(a1)


FinishOrLoop            IsWaitingKey
                        beq.w                   doPollJoysticks
                        WaitInp

                        ; ----------------------------------------------------------------
                        ; Your code end there
                        rts
; ================================================================================================================
