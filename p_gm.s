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
; Phase : Game
; ---
; This phase is one run of the game : destroy all the bricks and dodge the bombs
; ---
; A bitmap will be used to materialize all the position of the ball on the screen that are occupied (1) or free
; to go (1).
;
; The bitmap is updated at redraw time, like an offscreen
; ================================================================================================================
; ----------------------------------------------------------------------------------------------------------------
; Macros for this phase
; ----------------------------------------------------------------------------------------------------------------
PosModelToStatusMatrix  macro
                        ; finds the address, value, bit in the bricks status bitmap from the given coordinates.
                        ; 1 - data register containing the x value (byte)
                        ; 2 - data register containing the y value (byte)
                        ; 3 - address register of the status matrix
                        ; 4 - spare address register to do the work (side effect)
                        ; 5 - spare data register to do the work ( => byte of the status matrix)
                        ; 6 _ spare data register to do the work ( => bit of \5 to test)
                        cmp.b                   #5,\2
                        bpl.s                   .outOfRange\@            ; is \2 >= 5 ?
                        ; -- else in range
                        ; \5 := line byte offset = y * 5 = (y * 4) + (y) = (\2 * 4) + (\2)
                        moveq                   #0,\5
                        move.b                  \2,\5
                        WdMul4                  \5
                        add.b                   \2,\5
                        ; \4 := address of the start of line = \3 + \5
                        move.l                  \3,\4
                        add.l                   \5,\4
                        ; \5 := x
                        moveq                   #0,\5
                        move.b                  \1,\5
                        ; \6 := bit to test = $7 - (\5 mod 8) = not (\5 & %111) & %111 (keep 3 ls bits)
                        moveq                   #0,\6
                        move.b                  \5,\6
                        and.b                   #7,\6
                        not.b                   \6
                        and.b                   #7,\6
                        ; \5 := cell to byte offset = \5 / 8 = \5 >> 3
                        lsr.b                   #3,\5
                        ; \4 := address of the status matrix value
                        add.l                   \5,\4
                        ; \5 := byte of the status matrix
                        move.b                  (\4),\5
                        bra.s                   .done\@
.outOfRange\@           moveq                   #0,\5
                        moveq                   #0,\6
.done\@                  ; ========
                        endm
;
TstModelToStatusMatrix  macro
                        ; finds whether the given coordinates in the game model has a brick or not (Z bit of ccr)
                        ; 1 - data register containing the x value (byte)
                        ; 2 - data register containing the y value (byte)
                        ; 3 - address register of the status matrix
                        ; 4 - spare address register to do the work (side effect)
                        ; 5 - spare data register to do the work ( => byte of the status matrix)
                        ; 6 _ spare data register to do the work ( => bit of \5 to test)
                        PosModelToStatusMatrix  \1,\2,\3,\4,\5,\6
                        btst.b                  \6,\5
                        endm
;
PosToFreedomMatrix      macro
                        ; finds the address, value, bit in the freedom matrix from a position (x,y)
                        ; 1 - data register containing the x value (byte)
                        ; 2 - data register containing the y value (byte)
                        ; 3 - address register of the status matrix
                        ; 4 - spare address register to compute the address of the target byte
                        ; 5 - spare data register => byte of the status matrix
                        ; 6 _ spare data register => bit of \5 to test
                        cmp.b                   #50,\2
                        ; -- if \2 >= 50
                        bpl.s                   .outOfRange\@
                        ; -- else in range
                        ; \5 := line byte offset = y * 10 = (y * 8) + y + y = y << 3 + y + y
                        moveq                   #0,\5
                        move.b                  \2,\5
                        lsl.w                   #3,\5
                        add.w                   \2,\5
                        add.w                   \2,\5
                        ; \4 := address of the start of line = \3 + \5
                        move.l                  \3,\4
                        add.l                   \5,\4
                        ; \5 := x to byte offset in line = \1 / 8 = \1 >> 3
                        move.w                  \1,\5
                        lsr.w                   #3,\5
                        ; \4 := address of the freedom matrix byte to test
                        add.l                   \5,\4
                        ; \5 := byte of the status matrix
                        move.b                  (\4),\5
                        ; \6 := bit to test = $7 - (\1 mod 8) = not (\1 & %111) & %111 (keep 3 low bits)
                        move.b                  \1,\6
                        and.b                   #7,\6
                        not.b                   \6
                        and.b                   #7,\6
                        bra.s                   .done\@
.outOfRange\@           moveq                   #0,\5
                        moveq                   #0,\6
.done\@
                        endm

;
TstPosToFreedomMatrix   macro
                        ; finds whether the given coordinates in the game model has a brick or not (free if Z bit of ccr is set, i.e. beq)
                        ; 1 - data register containing the x value (byte)
                        ; 2 - data register containing the y value (byte)
                        ; 3 - address register of the status matrix
                        ; 4 - spare address register to do the work (side effect)
                        ; 5 - spare data register to do the work ( => byte of the status matrix)
                        ; 6 _ spare data register to do the work ( => bit of \5 to test)
                        PosToFreedomMatrix       \1,\2,\3,\4,\5,\6
                        btst.l                   \6,\5
                        endm
;

WhenHalfSpeedSkipOrGo   macro
                        ; Check whether the ball is at half speed and disable the ball updating when at the off phase
                        ; 1 - pointer to the ball
                        ; 2 - spare data register to work
                        ; 3 - branch destination when the update should be disabled
                        ; -- check halfspeed status
                        ; \2 := halfspeed phase
                        move.b                  7(\1),\2
                        tst.b                   \2
                        ; -- if \2 == 0
                        beq.s                   .continue\@
                        ; -- else check whether halfspeed is enabled
                        ; \2 := halfspeed enable
                        move.b                  6(\1),\2
                        tst.b                   \2
                        ; -- if halfspeed is disabled
                        beq.w                   \3
.continue\@             ; ========
                        endm

;
ExecSoundBallRebound:
                        ; -- shut up all channels
                        move.b                  #7,$ff8800
                        move.b                  #%111111,$ff8802
                        ; -- setup A 440 Hz to channel A (Tone $11C -> {0,1}={$1c,$01})
                        move.b                  #0,$ff8800
                        move.b                  #$1c,$ff8802
                        move.b                  #0,$ff8800
                        move.b                  #$1c,$ff8802
                        ; -- set envelop 0
                        move.b                  #13,$ff8800
                        move.b                  #$0,$ff8802
                        move.b                  #8,$ff8800
                        move.b                  #$10,$ff8802
                        ; -- set envelop refresh to 200 Hz (period = 1250 ? = $04e2)
                        move.b                  #11,$ff8800
                        move.b                  #$e2,$ff8802
                        move.b                  #12,$ff8800
                        move.b                  #$04,$ff8802
                        ; -- start channel A
                        move.b                  #7,$ff8800
                        move.b                  #%111110,$ff8802
                        rts
;
DoSoundBallRebound      macro
                        ; -- supexec the routine
                        _Supexec                #ExecSoundBallRebound
                        endm

; ----------------------------------------------------------------------------------------------------------------
; before all
; ----------------------------------------------------------------------------------------------------------------
PhsGameBeforeAll:       ; ========
                        ; -- setup pointer to BrickStatus
                        ; a6 := Storage of the pointer
                        move.l                  #PtrBrickStatusMatrix,a6
                        ; d7 := Ptr address
                        move.l                  MmHeapBase,d7
                        add.l                   #HposBrickBase,d7
                        move.l                  d7,(a6)
                        ; -- setup pointer to BallFreedom
                        ; a6 := Storage of the pointer
                        move.l                  #PtrBallFreedomMatrix,a6
                        ; d7 := Ptr address
                        move.l                  MmHeapBase,d7
                        add.l                   #HposFreedomBase,d7
                        move.l                  d7,(a6)
                        ; -- setup brick sprite vectors : even
                        ; a6 := Ptr to vector
                        move.l                  #SprVcBrickEven,a6
                        move.l                  #SprDtBrickRow0Even,(a6)+
                        move.l                  #SprDtBrickRow1Even,(a6)+
                        move.l                  #SprDtBrickRow2Even,(a6)+
                        move.l                  #SprDtBrickRow3Even,(a6)+
                        move.l                  #SprDtBrickRow4Even,(a6)+
                        move.l                  #SprDtNoBrickEven,(a6)+
                        ; -- setup brick sprite vectors : odd
                        move.l                  #SprVcBrickOdd,a6
                        move.l                  #SprDtBrickRow0Odd,(a6)+
                        move.l                  #SprDtBrickRow1Odd,(a6)+
                        move.l                  #SprDtBrickRow2Odd,(a6)+
                        move.l                  #SprDtBrickRow3Odd,(a6)+
                        move.l                  #SprDtBrickRow4Odd,(a6)+
                        move.l                  #SprDtNoBrickOdd,(a6)+
                        rts
; ----------------------------------------------------------------------------------------------------------------
; before each
; ----------------------------------------------------------------------------------------------------------------
PhsGameBeforeEach:      ; ========
                        ; -- init the brick status bit field
                        ; a6 := ptr to grid status matrix
                        DerefPtrToPtr           PtrBrickStatusMatrix,a6
                        ; -- set all bits to 1 over 25 bytes = 6 long + 1 byte
                        rept                    6
                        move.l                  #$ffffffff,(a6)+
                        endr
                        move.b                  #$ff,(a6)
                        ; ========
                        ; -- init the freedom matrix with brick occupation
                        ; a6 := ptr to the freedom matrix
                        DerefPtrToPtr           PtrBallFreedomMatrix,a6
                        ; -- 10 lines occupied by bricks = 100 bytes = (4 * 25) = 25 long
                        rept                    25
                        move.l                  #$ffffffff,(a6)+
                        endr
                        ; -- 40 lines occupied by nothing = 400 bytes = 4 * 100 bytes
                        ; d7 := loop counter
                        move.w                  #3,d7
.doFillFreedom          rept                    25
                        move.l                  #0,(a6)+
                        endr
                        dbf.s                   d7,.doFillFreedom
                        ; ========
                        ; -- Init the ball
                        ; a6 := ptr to the ball
                        lea                     TheBall,a6
                        move.l                  #$2427ffff,(a6)+        ; {x,y,dx,dy} := {36,39,-1,-1}
                        move.l                  #$24270100,(a6)+        ; {next x,next y,enable halfspeed, halfspeed phase} := {36,39,1,0}
                        move.b                  #30,(a6)+               ; wait around 0.6 seconds (at 50 Hz) before starting the ball
                        move.b                  #2,(a6)+                ; 2 remaining balls
                        ; ========
                        ; -- Game is not over
                        ; a6 := ptr to the game
                        lea                     TheGame,a6
                        move.b                  #1,5(a6)
                        rts
; ----------------------------------------------------------------------------------------------------------------
; update
; ----------------------------------------------------------------------------------------------------------------
PhsGameUpdate:
                        ; ======== ======== ======== ========
                        ; -- is game not over ?
                        ; a6 := the game
                        lea                     TheGame,a6
                        tst.b                   5(a6)
                        bne.s                   .startUpdateBall
                        ; -- else end of game, go to the next phase
                        ; a2 := subroutines
                        move.l                  #PhsGameAfterEach,a2
                        jsr                     (a2)
                        move.l                  #PhsFadeToEndBeforeEach,a2
                        jsr                     (a2)
                        move.l                  #PhsFadeToEndUpdate,PtrNextUpdate
                        move.l                  #PhsFadeToEndRedraw,PtrNextRedraw

                        ; -- return
                        rts
.startUpdateBall        ; ======== ======== ======== ========
                        ; == Ball update
                        ; ========
                        ; a5 := the ball
                        lea                     TheBall,a5
                        ; -- check freezing of the ball
                        ; d7 := freezing counter
                        moveq                   #0,d7
                        move.b                  8(a5),d7
                        tst.b                   d7
                        ; -- if (d7 == 0)
                        beq.s                   .checkHalfSpeedState
                        ; -- else update counter and pass
                        subq.b                  #1,d7
                        move.b                  d7,8(a5)
                        bra.w                   .startUpdatePlayer
                        ; -- check halfspeed status
                        ; d7 := spare register for the macro
.checkHalfSpeedState    WhenHalfSpeedSkipOrGo   a5,d7,.startUpdatePlayer
.doStartUpdateBall      ; ========
                        ; d7 := dy
                        moveq                   #0,d7
                        move.b                  3(a5),d7
                        ; d6 := current y
                        moveq                   #0,d6
                        move.b                  1(a5),d6
                        ; d5 := rebound tracker, bit field : ......yx ; bit set = free to rebound on x or y
                        moveq                   #3,d5
                        ; ========
                        cmp.b                   #50,d6
                        ; -- if d6 < 50
                        bmi.s                   .startMoveBallAlongY
                        ; -- else the ball is lost
                        ; d4 := remaining balls
                        move.b                  9(a5),d4
                        tst.b                   d4
                        ; -- if there are remaining balls
                        bne.s                   .useRemainingBall
                        ; -- else game over
                        move.b                  #0,5(a6)
                        ; -- game over, return
                        rts
                        ; -- decrease remaining ball, init ball position and freeze
.useRemainingBall       subq.b                  #1,d4
                        ; -- update remaining ball
                        move.b                  d4,9(a5)
                        ; -- init ball position and freeze (copy from before each)
                        ; a4 := ptr to the ball
                        move.l                  a5,a4
                        move.l                  #$2427ffff,(a4)+        ; {x,y,dx,dy} := {36,39,-1,-1}
                        move.l                  #$24270100,(a4)+        ; {next x,next y,enable halfspeed, halfspeed phase} := {36,39,1,0}
                        move.b                  #30,(a4)                ; wait around 0.6 seconds (at 50 Hz) before starting the ball
                        rts
.startMoveBallAlongY    ; ========
                        tst.b                   d7
                        ; -- if d7 < 0
                        bmi.s                   .tryMoveBallUp
                        ; -- else if d7 > 0
                        bne.s                   .tryMoveBallDown
                        ; -- else d7 = 0, force move up
                        subq.b                  #1,d7
.tryMoveBallUp          ; ========
                        tst.b                   d6
                        ; -- if d6 > 0
                        bhi.s                   .doMoveBallAlongY
                        ; -- else rebound to go down
                        moveq                   #1,d7
                        and.b                   #$fd,d5                   ; mark rebound on y as done
                        DoSoundBallRebound
                        bra.s                   .doMoveBallAlongY
.tryMoveBallDown        ; ========
                        nop                     ; for now do nothing special
.doMoveBallAlongY       ; ========
                        ; d6 := next y = y + dy
                        add.b                   d7,d6
                        ; -- Keep them for the next step
                        ; d4 := dy
                        move.l                  d7,d4
                        ; d3 := next y
                        move.l                  d6,d3
.startMoveBallAlongX    ; ========
                        ; d7 := dx
                        move.b                  2(a5),d7
                        ; d6 := current x
                        move.b                  0(a5),d6
                        ; ========
                        tst.b                   d7
                        ; -- if d7 < 0
                        bmi.s                   .tryMoveBallLeft
                        ; -- else if d7 > 0
                        bne.s                   .tryMoveBallRight
                        ; -- else d = 0, force move left
                        subq.b                  #1,d7
.tryMoveBallLeft        ; ========
                        tst.b                   d6
                        ; -- if d6 > 0
                        bhi.w                   .doMoveBallAlongX
                        ; -- else rebound to go right
                        moveq                   #1,d7
                        and.b                   #$fe,d5                   ; mark rebound along x as done
                        DoSoundBallRebound
                        bra.s                   .doMoveBallAlongX
.tryMoveBallRight       ; ========
                        cmp.b                   #79,d6
                        ; -- if d6 < 79
                        bmi.s                   .doMoveBallAlongX
                        ; -- else rebound to go left
                        moveq                   #-1,d7
                        and.b                   #$fe,d5                   ; mark rebound along x as done
                        DoSoundBallRebound
.doMoveBallAlongX       ; ========
                        ; d6 := next x = x + dx
                        add.b                   d7,d6
                        ; ========
                        ; -- End of first step of the update of the ball
                        ; Summary
                        ; {d7, d6, d4, d3} := {dx, next x, dy, next y}
                        ; d5 := bitfield ......yx ; Bit clear on x or y mark rebound along x, y as done respectively.
                        ; ========
                        ; -- Second step of the update of the ball
                        ; ========
                        tst.b                   d5
                        ; if d5 == 0 <=> rebound done on both axis
                        beq.w                   .commitBall
                        ; -- else there are rebounds to consider
                        ; a4 := Freedom matrix
                        DerefPtrToPtr           PtrBallFreedomMatrix,a4
                        ; -- Testing 3 positions in the matrix
                        ; -- 1. (next x, next y)
                        ; -- 2. (x, next y)
                        ; -- 3. (next x, y)
                        ; -- Then store each test in d5 : ...312yx
                        ; a3,d2,d1 := spare registers for the macro TstPosToFreedomMatrix
                        ; -- test 1
                        TstPosToFreedomMatrix   d6,d3,a4,a3,d2,d1
                        ; if position is free
                        beq.s                   .tstFreedom2
                        ; -- else mark bit 3 of d5
                        bset.l                  #3,d5
.tstFreedom2            ; ========
                        ; -- test 2
                        ; d0 := x
                        move.b                  0(a5),d0
                        ; a3,d2,d1 := spare registers for the macro TstPosToFreedomMatrix
                        TstPosToFreedomMatrix   d0,d3,a4,a3,d2,d1
                        ; -- if position is free
                        beq.s                   .tstFreedom3
                        ; -- else mark bit 2 of d5
                        bset.l                  #2,d5
.tstFreedom3            ; ========
                        ; -- test 3
                        ; d0 := y
                        move.b                  1(a5),d0
                        ; a3,d2,d1 := spare registers for the macro TstPosToFreedomMatrix
                        TstPosToFreedomMatrix   d6,d0,a4,a3,d2,d1
                        ; -- if position is free
                        beq.s                   .processBallRebounds
                        ; -- else mark bit 4 of d5
                        bset.l                  #4,d5
.processBallRebounds    ; ========
                        ; -- save next x, next y and d5 value for the bricks management
                        ; a3 := level management structure
                        lea                     TheLevel,a3
                        move.b                  d6,2(a3)
                        move.b                  d3,3(a3)
                        move.b                  d5,4(a3)
                        ; -- extract values for switch/case logic
                        ; d2 := (d5 >> 2) & 7 = extract the 3 bits value stored from d5, as switch-case
                        moveq                   #0,d2
                        move.b                  d5,d2
                        lsr.b                   #2,d2
                        and.b                   #7,d2
                        ; d1 := d5 & 3 - 1 = the status of rebounds to do, 0 already been processed, as switch-case
                        ; 0 - x only
                        ; 1 - y only
                        ; 2 - x and y
                        moveq                   #0,d1
                        move.b                  d5,d1
                        and.b                   #3,d1
                        subq.b                  #1,d1
                        ; -- switch (d1)
                        dbf.s                   d1,.processBallReboundY
                        ; -- d1 : case 0
                        ; -- do rebound x if bit 2 of d2 set or d2 == 2
                        btst.l                  #2,d2
                        beq.s                   .doBallReboundX
                        cmp.b                   #2,d2
                        bne.w                   .commitBall
.doBallReboundX         ; ========
                        ; d7 := -d7
                        neg.b                   d7
                        ; d6 := d6 + d7 + d7
                        add.b                   d7,d6
                        add.b                   d7,d6
                        DoSoundBallRebound
                        bra.w                   .commitBall
                        ; ========
.processBallReboundY    ; -- switch (d1)
                        dbf.s                   d1,.processBallReboundXY
                        ; -- d1 : case 1
                        ; -- do NOT rebound y if d2 in [0,4,7]
                        tst.l                   d2
                        beq.w                   .commitBall
                        cmp.b                   #4,d2
                        beq.w                   .commitBall
                        cmp.b                   #7,d2
                        beq.w                   .commitBall
.doBallReboundY         ; ========
                        ; d4 := -d4
                        neg.b                   d4
                        ; d3 := d3 + d4 + d4
                        add.b                   d4,d3
                        add.b                   d4,d3
                        DoSoundBallRebound
                        bra.s                   .commitBall
                        ; ========
.processBallReboundXY   ; -- d1 : case 2
                        ; -- do rebound according to the value of d2
                        ; -- 0:nothing ; 1:y ; 2:x+y; 3:y ; 4:x ; 5:x+y ; 6:x ; 7:x+y
                        ; -- we will reuse doBallReboundX and doBallReboundY
                        ; -- when we need to do both rebounds, we do the rebound x here then
                        ; -- go to doBallReboundY (closer to this point)
                        ; // TODO : use a vectors of jumps, should be better for highest values of d2 (do the math before)
                        ; switch d2 : case 0
                        tst.b                   d2,
                        beq.s                   .commitBall
                        ; switch d2 : case 1
                        cmp.b                  #1,d2
                        beq.s                   .doBallReboundY
                        ; switch d2 : case 2
                        cmp.b                  #2,d2
                        beq.s                   .doBallReboundXY
                        ; switch d2 : case 3
                        cmp.b                  #3,d2
                        beq.s                   .doBallReboundY
                        ; switch d2 : case 4
                        cmp.b                  #4,d2
                        beq.w                   .doBallReboundX
                        ; switch d2 : case 5
                        cmp.b                  #5,d2
                        beq.s                   .doBallReboundXY
                        ; switch d2 : case 6
                        cmp.b                  #6,d2
                        beq.w                   .doBallReboundX
                        ; switch d2 : case 7
                        ; -> .doBallReboundXY
.doBallReboundXY        ; --
                        ; d7 := -d7
                        neg.b                   d7
                        ; d6 := d6 + d7 + d7
                        add.b                   d7,d6
                        add.b                   d7,d6
                        ; --
                        bra.w                   .doBallReboundY
                        ; ========
.commitBall             ; a4 := start of the memory structur to update = TheBall + 2
                        lea                     2(a5),a4
                        ; -- save new dx
                        move.b                  d7,(a4)+
                        ; -- save new dy
                        move.b                  d4,(a4)+
                        ; -- save next x
                        move.b                  d6,(a4)+
                        ; -- save next y
                        move.b                  d3,(a4)+
                        ; ======== ======== ======== ========
                        ; == Player update
                        ; ========
                        ; -- load player status
                        ; a6 := PlayerBumper
.startUpdatePlayer      lea                     PlayerBumper,a6
                        ; d7 := PlayerBumper.x
                        move.b                  0(a6),d7
                        ; d6 := dx
                        moveq                   #0,d6
                        ; d5 := PlayerBumper.y
                        move.b                  1(a6),d5
                        ; d4 := dy
                        moveq                   #0,d4
                        ; ========
                        ; -- poll joystick status
                        ; a2 := Ptr to joystick states
                        lea                     BufferJoystate,a2
                        ; d3 := [j0,j1] combined in a word
                        move.w                  (a2),d3
                        ; ========
                        ; -- Compution of dy
                        ; ========
                        ; -- j1.up == 0 ?
                        btst.b                  #0,d3
                        beq.s                   .tstMoveDown
                        ; -- else moving up
                        subq.b                  #1,d4
                        ; ========
                        ; -- j1.down == 0 ?
.tstMoveDown            btst.b                  #1,d3
                        beq.s                   .applyMoveY
                        ; -- else moving down
                        addq.b                  #1,d4
                        ; ========
                        ; -- Apply dy to y, must stay inside [0...]10
.applyMoveY             add.b                   d4,d5
                        ; -- y >= 0 ?
                        bpl.s                   .capY
                        ; -- else force y to 0
                        moveq                   #0,d5
                        bra.s                   .moveX
                        ; -- y < 9 ?
.capY                   cmp.b                   #9,d5
                        bmi.s                   .moveX
                        ; -- else force y to 8
                        move.b                  #8,d5
                        ; ========
                        ; -- Computation of dx, the player moves by 2 units
                        ; ========
                        ; -- j1.left == 0 ?
.moveX                  btst.b                  #2,d3
                        beq.s                   .moveRight
                        ; -- else moving left
                        subq.b                  #2,d6
                        ; ========
.moveRight              ; -- j1.right == 0 ?
                        btst.b                  #3,d3
                        beq.s                   .applyMoveX
                        ; -- else moving right
                        addq.b                  #2,d6
                        ; ========
                        ; -- Apply dx to y, must stay inside [0...64]
.applyMoveX             add.b                   d6,d7
                        ; -- x >= 0 ?
                        bpl.s                   .capX
                        ; -- else force x to 0
                        moveq                   #0,d7
                        bra.s                   .doUpdatePlayer
                        ; -- x <= 64 ?
.capX                   cmp.b                   #64,d7
                        bmi.s                   .doUpdatePlayer
                        ; -- else force x to 64
                        move.b                  #64,d7
                        ; ========
                        ; -- Save updated model
                        ; -- PlayerBumper.nextX
.doUpdatePlayer         move.b                  d7,4(a6)
                        ; -- PlayerBumper.nextY
                        move.b                  d5,5(a6)
                        ; -- PlayerBumper.dx
                        move.b                  d6,6(a6)
                        ; -- PlayerBumper.dy
                        move.b                  d4,7(a6)

; -- bricks, TODO
                        ; ======== ======== ======== ========
                        ; == update level
                        ; ========
                        ; a6 := the level
                        lea                     TheLevel,a6
                        ; a5 := the ball
                        lea                     TheBall,a5
                        ; -- reset the brick counter
                        move.b                  #0,5(a6)
                        ; -- load data
                        ; -- to save space, and because the testing macro only need one value at a time,
                        ; -- we will use the same register for :
                        ; -- * the ball x position and saved next x (reminder : before rebounds on something)
                        ; -- * the ball y position and saved next y (idem)
                        ; d7 := [ [ball.x >> 1].w | [level.originalnextx >> 1].w ]
                        moveq                   #0,d7
                        move.b                  0(a5),d7
                        lsr.b                   #1,d7
                        swap                    d7
                        move.b                  2(a6),d7
                        lsr.b                   #1,d7
                        ; d6 := [ [ball.y >> 1].w | [level.originalnexty >> 1].w ]
                        moveq                   #0,d6
                        move.b                  1(a5),d6
                        lsr.b                   #1,d6
                        swap                    d6
                        move.b                  3(a6),d6
                        lsr.b                   #1,d6
                        ; d5 := saved rebound context (reminder : ...312yx)
                        moveq                   #0,d5
                        move.b                  4(a6),d5
                        tst.b                   d5
                        ; -- if 0 == d5
                        beq.w                   .cleanupBrickSavedField
                        ; -- else there may be someting to do
                        ; d4 := extract the ...312.. bits of d5
                        move.l                  d5,d4
                        and.b                   #$1c,d4
                        tst.b                   d4
                        ; -- if 0 == d4
                        beq.w                   .cleanupBrickSavedField
                        ; -- else there is something to do
                        ; -- prepare to save the bricks to erase
                        ; d3 := count of bricks to erase
                        moveq                   #0,d3
                        ; a4 := start of the list of the BrickStatus
                        lea                     6(a6),a4
                        ; a3 := status matrix
                        DerefPtrToPtr           PtrBrickStatusMatrix,a3
                        ; ========
                        cmp.b                   #$08,d4
                        ; if d4 != ...010..
                        bne.s                   .tryBrickEraseAlongX
                        ; -- else the unique brick to erase will be at nextx, nexty
                        ; a2,d2,d1 := spare register for the macro
                        TstModelToStatusMatrix  d7,d6,a3,a2,d2,d1
                        ; -- if no brick
                        beq.w                   .cleanupBrickSavedField
                        ; -- else erase brick and store in list
                        bclr.b                  d1,(a2)
                        move.b                  d7,(a4)+
                        move.b                  d6,(a4)+
                        addq.b                  #1,d3
                        move.b                  d3,5(a6)
                        bra.w                   .cleanupBrickSavedField
                        ; ========
.tryBrickEraseAlongX    ; -- process rebound along X (interested in ...31..x of d5)
                        btst.l                  #0,d5
                        ; -- if there is no rebound to process
                        beq.s                   .tryBrickEraseAlongY
                        ; -- else try erasing along x
                        btst.l                  #4,d5
                        ; -- if there was no collision next to the ball
                        beq.s                   .tryBrickEraseAlongY
                        ; use y
                        swap                    d6
                        ; a2,d2,d1 := spare register for the macro
                        TstModelToStatusMatrix  d7,d6,a3,a2,d2,d1
                        ; -- if no brick
                        beq.s                   .tryBrickEraseAlongY
                        ; -- else erase brick and store in list
                        bclr.b                  d1,(a2)
                        move.b                  d7,(a4)+
                        move.b                  d6,(a4)+
                        ; -- update and save item count
                        addq.b                  #1,d3
                        move.b                  d3,5(a6)
                        ; -- restore d6
                        swap                    d6
                        ; ========
.tryBrickEraseAlongY    ; -- process rebound along Y (interested in ....12y. of d5)
                        btst.l                  #1,d5
                        ; -- if there is no rebound to process
                        beq.s                   .cleanupBrickSavedField
                        ; -- else try erasing along y
                        btst.l                  #2,d5
                        ; -- if there was no collision next to the ball
                        beq.s                   .cleanupBrickSavedField
                        ; use x
                        swap                    d7
                        ; a2,d2,d1 := spare register for the macro
                        TstModelToStatusMatrix  d7,d6,a3,a2,d2,d1
                        ; -- if no brick
                        beq.s                   .cleanupBrickSavedField
                        ; -- else erase brick and store in list
                        bclr.b                  d1,(a2)
                        move.b                  d7,(a4)+
                        move.b                  d6,(a4)+
                        ; -- update and save item count
                        addq.b                  #1,d3
                        move.b                  d3,5(a6)
                        ; ========
.cleanupBrickSavedField ; -- reset saved next x, next y, rebound status
                        move.b                  #0,2(a6)
                        move.b                  #0,3(a6)
                        move.b                  #0,4(a6)



; -- bombs, TODO
.doUpdateFreedomMatrix  ; ======== ======== ======== ========
                        ; == update freedom matrix
                        ; ========
                        ; a6 := player
                        lea                     PlayerBumper,a6
                        ; a5 := freedom matrix
                        DerefPtrToPtr           PtrBallFreedomMatrix,a5
                        ; ========
                        ; -- erase player occupation
                        ; d7 := player.x,
                        moveq                   #0,d7
                        move.b                  0(a6),d7
                        ; d6 := player.y+40
                        moveq                   #40,d6
                        add.b                   1(a6),d6
                        ; {a4,d5,d4} := {target address, byte value, bit index}
                        PosToFreedomMatrix d7,d6,a5,a4,d5,d4
                        ; d4 := d7 & %111 (keep least significant bits in the "right" order)
                        move.b                  d7,d4
                        and.b                   #7,d4
                        ; d3 := $ff00 ror d4 = [end brush|start brush] to erase
                        moveq                   #0,d3
                        move.w                  #$ff00,d3
                        ror.w                   d4,d3
                        ; a3 := a4 + 1 line of offset = a4 + 10
                        lea                     10(a4),a3
                        ; -- erase first target byte
                        and.b                   d3,(a4)+
                        and.b                   d3,(a3)+
                        ; -- erase middle byte
                        move.b                  #0,(a4)+
                        move.b                  #0,(a3)+
                        ; -- erase last byte
                        ; d3 := end brush
                        lsr.w                   #8,d3
                        and.b                   d3,(a4)
                        and.b                   d3,(a3)
                        ; ========
                        ; -- draw player occupation
                        ; d7 := player.next x
                        move.b                  4(a6),d7
                        ; d6 := player.y+40
                        moveq                   #40,d6
                        add.b                   5(a6),d6
                        ; {a4,d5,d4} := {target address, byte value, bit index}
                        PosToFreedomMatrix d7,d6,a5,a4,d5,d4
                        ; d4 := d7 & %111 (keep least significant bits in the "right" order)
                        move.b                  d7,d4
                        and.b                   #7,d4
                        ; d3 := $00ff ror d4 = [end brush|start brush] to draw
                        moveq                   #0,d3
                        move.w                  #$ff,d3
                        ror.w                   d4,d3
                        ; a3 := a4 + 1 line of offset = a4 + 10
                        lea                     10(a4),a3
                        ; -- draw first target byte
                        or.b                    d3,(a4)+
                        or.b                    d3,(a3)+
                        ; -- draw middle byte
                        move.b                  #$ff,(a4)+
                        move.b                  #$ff,(a3)+
                        ; -- draw last byte
                        ; d3 := end brush
                        lsr.w                   #8,d3
                        or.b                    d3,(a4)
                        or.b                    d3,(a3)
                        ; ========
                        ; -- erase bricks if appliable
                        ; a6 := the level
                        lea                     TheLevel,a6
                        ; d7 := the count of bricks to erase
                        moveq                   #0,d7
                        move.b                  5(a6),d7
                        tst.b                   d7
                        ; -- if count == 0
                        beq.s                   .thatsAll
                        ; -- else there are bricks to erase
                        ; a4 := cursor to the list
                        lea                     6(a6),a4
                        ; d7 := loop counter = count - 1
                        subq.b                  #1,d7
.doEraseNextBrick       ; -- load brick position (must be << 1)
                        ; d6 := x << 1
                        moveq                   #0,d6
                        move.b                  (a4)+,d6
                        add.b                   d6,d6
                        ; d5 := y << 1
                        moveq                   #0,d5
                        move.b                  (a4)+,d5
                        add.b                   d5,d5
                        ; a3,d4,d3 := spare register for the macro
                        PosToFreedomMatrix d6,d5,a5,a3,d4,d3
                        ; d3 := d6 & %111 (keep 3 least significant bits for rotating)
                        move.b                  d6,d3
                        and.b                   #7,d3
                        ; d2 := mask to erase = %00111111 ror d3 = $3f ror d3
                        moveq                   #$3f,d2
                        ror.b                   d3,d2
                        ; -- erase the brick
                        and.b                   d2,(a3)
                        lea                     10(a3),a3
                        and.b                   d2,(a3)
                        ; -- next
                        dbf.s                   d7,.doEraseNextBrick
                        ; ======== ======== ======== ========
.thatsAll               rts
; ----------------------------------------------------------------------------------------------------------------
; redraw
; ----------------------------------------------------------------------------------------------------------------
PhsGameRedraw:          ; ========
                        ; -- is game not over ?
                        ; a6 := the game
                        lea                     TheGame,a6
                        tst.b                   5(a6)
                        bne.s                   .startRedrawBricks
                        ; -- else do nothing
                        rts
.startRedrawBricks      ; ======== ======== ======== ========
                        ; == Redraw (erase only) bricks
                        ; ========
                        ; a6 := the level
                        lea                     TheLevel,a6
                        ; d7 := brick count
                        moveq                   #0,d7
                        move.b                  5(a6),d7
                        tst.b                   d7
                        ; if brick count == 0
                        beq.w                   .startRedrawPlayer
                        ; -- else there are bricks to erase
                        ; a4 := cursor to the list
                        lea                     6(a6),a4
                        ; d7 := loop counter = count - 1
                        subq.b                  #1,d7
.doRedrawNextBrick      ; d6 = offset x screen = x brick * 8 / 2 = x brick * 4
                        moveq                   #0,d6
                        move.b                  (a4)+,d6
                        WdMul4                  d6
                        ; d5 := memory screen line offset := y brick * 8 * 160 = y brick * 8 * 16 * 2 * 5
                        ;    := (y brick << 8)*(4 + 1)
                        ; compute y brick << 8 first
                        moveq                   #0,d5
                        move.b                  (a4)+,d5
                        lsl.w                   #8,d5
                        ; d4 := temp register for storing 4*d5, small enough to use word length
                        move.l                  d5,d4
                        WdMul4                  d4
                        add.w                   d4,d5
                        ; -- erase an even or odd cell
                        ; a3 := memory screen + line offset
                        move.l                  a5,a3
                        add.l                   d5,a3
                        btst.w                  #2,d6
                        ; -- if odd cell
                        bne.w                   .doEraseOddBrick
                        ; -- else erase even brick
                        ; a3 := add offset d6 (16px aligned)
                        add.l                   d6,a3
                        rept                    8
                        and.l                   #$00ff00ff,(a3)
                        or.l                    #$ff000000,(a3)+
                        and.l                   #$00ff00ff,(a3)+
                        lea                     152(a3),a3
                        endr
                        ; -- next
                        dbf.s                   d7,.doRedrawNextBrick
                        bra.w                   .startRedrawPlayer
.doEraseOddBrick        ; ========
                        ; a3 := add offset d6 & $fff0 (16px aligned)
                        bclr.l                  #2,d6
                        add.l                   d6,a3
                        rept                    8
                        and.l                   #$ff00ff00,(a3)
                        or.l                    #$00ff0000,(a3)+
                        and.l                   #$ff00ff00,(a3)+
                        lea                     152(a3),a3
                        endr
                        ; -- next
                        dbf.s                   d7,.doRedrawNextBrick
                        ; ======== ======== ======== ========
                        ; -- do nothing if dx, dy are 0 (//NOT YET, what about the first redraw ?)
                        ; -- if dy != 0, erase all player parts at old pos then draw all player parts at new pos
                        ; -- if dx != 0, draw the sequence {erase,1,skip,2,3} (minus) or {1,2,skip,3,erase} (plus) at new pos.
                        ; -- commit new position
                        ; a6 := Player
.startRedrawPlayer      lea                     PlayerBumper,a6
                        ; a4 := start of the Player screen area
                        lea                     25600(a5),a4
                        ; a3 := current place to redraw in the screen memory
                        move.l                  a4,a3
                        ; -- erase conditionally
                        move.b                  6(a6),d7
                        tst.b                   d7
                        bne.s                   .erasePlayer
                        move.b                  7(a6),d7
                        beq.w                   .drawPlayer
.erasePlayer            ; ========
                        ; -- offset to first line
                        ; d5 := offset to the start of the line
                        ; d2 := temp
                        ModelToScreenY          1(a6),d5,d2
                        ; update offset a3
                        add.l                   d5,a3
                        ; ========
                        ; -- offset and shift to the first column
                        ; d5,d4 := offset and shift value to the screen x (shift value will be 0 or 2)
                        ModelToScreenX          0(a6),d5,d4
                        ; -- update offset a3
                        add.l                   d5,a3
                        ; ========
                        tst.w                   d4
                        bne.s                   .eraseOdd
                        ; -- else the player is aligned to 16px positions
                        ; d3 := loop counter
                        moveq                   #7,d3
.loopEraseEven          move.l                  #$ffff0000,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffff0000,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffff0000,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffff0000,(a3)+
                        move.l                  #0,(a3)+
                        lea                     128(a3),a3
                        dbf.s                   d3,.loopEraseEven
                        bra.s                   .drawPlayer
.eraseOdd               ; ========
                        ; d3 := loop counter
                        moveq                   #7,d3
.loopEraseOdd           and.l                   #$ff00ff00,(a3)
                        or.l                    #$00ff0000,(a3)+
                        and.l                   #$ff00ff00,(a3)+
                        move.l                  #$ffff0000,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffff0000,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffff0000,(a3)+
                        move.l                  #0,(a3)+
                        and.l                   #$00ff00ff,(a3)
                        or.l                    #$ff000000,(a3)+
                        and.l                   #$00ff00ff,(a3)+
                        lea                     120(a3),a3
                        dbf.s                   d3,.loopEraseOdd
.drawPlayer             ; ========
                        ; -- reset a3 := start of the drawable area
                        move.l                  a4,a3
                        ; -- offset to first line
                        ; d5 := offset to the start of the line
                        ; d2 := temp
                        ModelToScreenY           5(a6),d5,d2
                        ; -- update offset a3
                        add.l                   d5,a3
                        ; ========
                        ; -- offset and shift to the first column
                        ; d5,d4 := offset and shift value to the screen x (shift value will be 0 or 2)
                        ModelToScreenX           4(a6),d5,d4
                        ; -- update offset a3
                        add.l                   d5,a3
                        ; ========
                        tst.w                   d4
                        bne.s                   .drawPlayerOdd
                        ; -- else the player is aligned to 16px positions
                        ; d3 := loop counter
                        moveq                   #7,d3
.loopDrawEven           move.l                  #$ffffffff,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffffffff,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffffffff,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffffffff,(a3)+
                        move.l                  #0,(a3)+
                        lea                     128(a3),a3
                        dbf.s                   d3,.loopDrawEven
                        bra.s                   .doneDrawPlayer
.drawPlayerOdd          ; ========
                        ; d3 := loop counter
                        moveq                   #7,d3
.loopDrawOdd            and.l                   #$ff00ff00,(a3)
                        or.l                    #$00ff00ff,(a3)+
                        and.l                   #$ff00ff00,(a3)+
                        move.l                  #$ffffffff,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffffffff,(a3)+
                        move.l                  #0,(a3)+
                        move.l                  #$ffffffff,(a3)+
                        move.l                  #0,(a3)+
                        and.l                   #$00ff00ff,(a3)
                        or.l                    #$ff00ff00,(a3)+
                        and.l                   #$00ff00ff,(a3)+
                        lea                     120(a3),a3
                        dbf.s                   d3,.loopDrawOdd
.doneDrawPlayer         ; ========
                        ; -- done, commit model update
                        move.b                  4(a6),0(a6)
                        move.b                  5(a6),1(a6)


                        ; ========
RedrawBall:
                        ; a6 := ptr to the ball
                        lea                     TheBall,a6
                        ; a4 := start address of the redrawing area (the full screen)
                        lea                     0(a5),a4
                        ; a3 := start address of the ball redrawing to compute
                        move.l                  a4,a3
                        ; ========
                        ; == erase ball
                        ; ======
                        ; -- offset to first line
                        ; d7 := from y to offset
                        ; d2 := temp
                        ModelToScreenY          1(a6),d7,d2
                        ; -- update offset a3
                        add.l                   d7,a3
                        ; ======
                        ; -- Offset to actual drawing start address and shifting of the pattern
                        ;
                        ModelToScreenX          0(a6),d7,d6
                        ; ========
                        ; -- update offset a3
                        add.w                   d7,a3
                        ; ========
                        ; draw using the right shift
                        dbf.s                   d6,.caseEraseShift4
                        and.l                   #$0fff0fff,(a3)
                        or.l                    #$f0000000,(a3)+
                        and.l                   #$0fff0fff,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$0fff0fff,(a3)
                        or.l                    #$f0000000,(a3)+
                        and.l                   #$0fff0fff,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$0fff0fff,(a3)
                        or.l                    #$f0000000,(a3)+
                        and.l                   #$0fff0fff,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$0fff0fff,(a3)
                        or.l                    #$f0000000,(a3)+
                        and.l                   #$0fff0fff,(a3)+
                        bra.w                   .draw
.caseEraseShift4        dbf.s                   d6,.caseEraseShift8
                        and.l                   #$f0fff0ff,(a3)
                        or.l                    #$0f000000,(a3)+
                        and.l                   #$f0fff0ff,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$f0fff0ff,(a3)
                        or.l                    #$0f000000,(a3)+
                        and.l                   #$f0fff0ff,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$f0fff0ff,(a3)
                        or.l                    #$0f000000,(a3)+
                        and.l                   #$f0fff0ff,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$f0fff0ff,(a3)
                        or.l                    #$0f000000,(a3)+
                        and.l                   #$f0fff0ff,(a3)+
                        bra.w                   .draw
.caseEraseShift8        dbf.s                   d6,.caseEraseShift12
                        and.l                   #$ff0fff0f,(a3)
                        or.l                    #$00f00000,(a3)+
                        and.l                   #$ff0fff0f,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$ff0fff0f,(a3)
                        or.l                    #$00f00000,(a3)+
                        and.l                   #$ff0fff0f,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$ff0fff0f,(a3)
                        or.l                    #$00f00000,(a3)+
                        and.l                   #$ff0fff0f,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$ff0fff0f,(a3)
                        or.l                    #$00f00000,(a3)+
                        and.l                   #$ff0fff0f,(a3)+
                        bra.s                   .draw
.caseEraseShift12       and.l                   #$fff0fff0,(a3)
                        or.l                    #$000f0000,(a3)+
                        and.l                   #$fff0fff0,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$fff0fff0,(a3)
                        or.l                    #$000f0000,(a3)+
                        and.l                   #$fff0fff0,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$fff0fff0,(a3)
                        or.l                    #$000f0000,(a3)+
                        and.l                   #$fff0fff0,(a3)+
                        lea                     152(a3),a3
                        and.l                   #$fff0fff0,(a3)
                        or.l                    #$000f0000,(a3)+
                        and.l                   #$fff0fff0,(a3)+

.draw                   move.l                  a4,a3                   ; go back to top of the screen
                        ; ======
                        ; -- offset to first line
                        ; d7 := from newY to offset
                        ; d2 := temp
                        ModelToScreenY           5(a6),d7,d2
                        ; -- update offset
                        add.l                   d7,a3
                        ; ======
                        ; d7,d6 := new x -> offset to actual drawing start address and shifting of the pattern, resp.
                        ModelToScreenX          4(a6),d7,d6
                        ; ========
                        ; -- update offset a3
                        add.w                   d7,a3
                        ; ========
                        ; draw using the right shift
                        dbf.s                   d6,.caseDrawShift4
                        or.l                    #$60006000,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$f000f000,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$f000f000,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$60006000,(a3)+
                        or.l                    #0,(a3)+
                        bra.w                   .done
.caseDrawShift4         dbf.s                   d6,.caseDrawShift8
                        or.l                    #$06000600,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$0f000f00,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$0f000f00,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$06000600,(a3)+
                        or.l                    #0,(a3)+
                        bra.s                   .done
.caseDrawShift8         dbf.s                   d6,.caseDrawShift12
                        or.l                    #$00600060,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$00f000f0,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$00f000f0,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$00600060,(a3)+
                        or.l                    #0,(a3)+
                        bra.s                   .done
.caseDrawShift12        or.l                    #$00060006,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$000f000f,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$000f000f,(a3)+
                        or.l                    #0,(a3)+
                        lea                     152(a3),a3
                        or.l                    #$00060006,(a3)+
                        or.l                    #0,(a3)+
.done                   nop
                        ; -- done, commit new coordinates
                        move.b                  4(a6),0(a6)
                        move.b                  5(a6),1(a6)

.DrawRemainingBalls:     ; ========
                        ; -- draw the remainng balls
                        ; d7 := remaining balls
                        moveq                   #0,d7
                        move.b                  9(a6),d7
                        tst.b                   d7
                        ; a4 := start of the display at bitplan 3 = a5 + 196 * 160 + 6 = a5 + 31366
                        lea                     31366(a5),a4
                        ; -- if (d7 == 0)
                        beq.s                   .drawNoRemaining
                        ; -- else display some balls (up to 2)
                        cmp.b                   #2,d7
                        ; -- if (d7 < 2)
                        bpl.s                   .drawTwoRemaining
                        move.w                  #$6000,(a4)
                        lea                     160(a4),a4
                        move.w                  #$f000,(a4)
                        lea                     160(a4),a4
                        move.w                  #$f000,(a4)
                        lea                     160(a4),a4
                        move.w                  #$6000,(a4)
                        ; -- thatsAll
                        rts
.drawTwoRemaining       ; ========
                        move.w                  #$6060,(a4)
                        lea                     160(a4),a4
                        move.w                  #$f0f0,(a4)
                        lea                     160(a4),a4
                        move.w                  #$f0f0,(a4)
                        lea                     160(a4),a4
                        move.w                  #$6060,(a4)
                        rts
.drawNoRemaining        ; ========
                        move.w                  #$0,(a4)
                        lea                     160(a4),a4
                        move.w                  #$0,(a4)
                        lea                     160(a4),a4
                        move.w                  #$0,(a4)
                        lea                     160(a4),a4
                        move.w                  #$0,(a4)
.thatsAll               rts
;
; ----------------------------------------------------------------------------------------------------------------
; after each
; ----------------------------------------------------------------------------------------------------------------
PhsGameAfterEach:
                        rts
; ----------------------------------------------------------------------------------------------------------------
; after all
; ----------------------------------------------------------------------------------------------------------------
PhsGameAfterAll:
                        rts

; ================================================================================================================
; Model
; ================================================================================================================
; Brick status model : a bitmap, 40 bits = 5 bytes per line, 5 lines => 25 bytes
; ================================================================================================================
PtrBrickStatusMatrix    dc.l                    0
; ================================================================================================================
; Ball freedom matrix model : a bitmap, 50 lines of 80 bits = 10 bytes per line => 500 bytes
; ================================================================================================================
PtrBallFreedomMatrix    dc.l                    0
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
TheGame:
                        dc.l                    0                       ; score
                        dc.b                    0                       ; is game over ?
                        even
; ================================================================================================================
TheBall:
                        dc.b                    36,20                   ; x,y
                        dc.b                    0,0                     ; dx,dy
                        dc.b                    37,19                   ; nx 'new x', ny 'new y'
                        dc.b                    1,0                     ; flag 'half speed' (not 0), half speed phase
                        dc.b                    0                       ; counter to freeze the ball until 0
                        dc.b                    0                       ; remaining balls
                        even
; ================================================================================================================
PlayerBumper:
                        dc.b                    32,5,8,1                ; x,y,w,h
                        ; 0 <= x < 72
                        ; 0 <= y < 10
                        ; w may change with bonus
                        ; h stay constant.
                        dc.b                    32,5,0,0
                        ; next x, y, dx, dy respectively
                        dc.b                    0,0
                        ; next w, dw respectively
                        even
; ================================================================================================================
TheLevel:
                        dc.w                    0                       ; Number of remaining bricks to break (0 = win)
                        ; saved values from the ball update (step 2 of processing rebounds, see .processBallRebounds)
                        dc.b                    0                       ; initial next x from the ball update
                        dc.b                    0                       ; initial next y from the ball update
                        dc.b                    0                       ; rebound status flag (...tttyx)
                        ; bricks to erase on screen
                        dc.b                    0                       ; number of bricks (0, 1 or 2)
                        ds.b                    0,4                     ; buffer, bricks position in the bricks status model (col, row) , 2 bytes each
                        even
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
