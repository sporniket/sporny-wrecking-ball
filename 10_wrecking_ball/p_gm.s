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
                        ; finds the address, value in the bricks list from the given coordinates.
                        ; 1 - data register containing the x value (byte) of the cell
                        ; 2 - data register containing the y value (byte) of the cell
                        ; 3 - address register of the status matrix
                        ; 4 - spare address register to do the work
                        ; 5 - spare data register to do the work ( => word value of the cell)
                        cmp.b                   #10,\2
                        bpl                     .outOfRange\@            ; is \2 >= 5 ?
                        ; -- else in range
                        ; \5 := y*8 = \2 << 3
                        ; \4 := line byte offset = 2*(y * 5 * 8) = 2*((8y * 4) + (8y)) = 2*((\4 * 4) + (\4))
                        moveq                   #0,\5
                        move.b                  \2,\5
                        lsl.w                   #3,\5
                        move.l                  #0,\4
                        move.w                  \5,\4
                        WdMul4                  \4
                        add.w                   \5,\4
                        WdMul2                  \4
                        ; \4 := address of the start of line = \3 + \5
                        add.l                   \3,\4
                        ; \5 := byte offset to x = 2*x
                        moveq                   #0,\5
                        move.b                  \1,\5
                        WdMul2                  \5
                        ; \4 := address of the status matrix value
                        add.l                   \5,\4
                        ; \5 := byte of the status matrix
                        move.w                  (\4),\5
                        bra                     .done\@
.outOfRange\@           moveq                   #0,\5
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
                        PosModelToStatusMatrix  \1,\2,\3,\4,\5
                        tst.w                   \5
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
                        bpl                     .outOfRange\@
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
                        and.w                   #$ff,\5
                        lsr.w                   #3,\5
                        ; \4 := address of the freedom matrix byte to test
                        add.l                   \5,\4
                        ; \5 := byte of the status matrix
                        move.b                  (\4),\5
                        ; \6 := bit to test = $7 - (\1 mod 8) = not (\1) & %111 (keep 3 low bits)
                        move.b                  \1,\6
                        not.b                   \6
                        and.l                   #7,\6
                        bra                     .done\@
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
;
;

WhenHalfSpeedSkipOrGo   macro
                        ; Check whether the ball is at half speed and disable the ball updating when at the off phase
                        ; 1 - pointer to the ball
                        ; 2 - spare data register to work
                        ; 3 - branch destination when the update should be disabled
                        ; -- check halfspeed status
                        ; \2 := halfspeed phase
                        move.b                  GameState_Ball_phase(\1),\2
                        tst.b                   \2
                        ; -- reset phase if \2 == 0
                        beq                     .resetPhase\@
                        ; -- else test bit #0 of phase
                        btst.l                  #0,\2
                        ; -- refresh normally if not set
                        beq                     .continue\@
                        ; -- else ...
                        ; -- ...update phase
                        subq.b                  #1,\2
                        move.b                  \2,GameState_Ball_phase(\1)
                        ; -- ... and check whether halfspeed is enabled
                        ; \2 := Ball behavior
                        move.w                  GameState_Ball_behavior(\1),\2
                        cmp.w                   #BALL_BEHAVIOR_GLUE,\2
                        ; -- if halfspeed is disabled
                        beq                     \3
                        bra                     .thatsAll\@
.resetPhase\@           ; ========
                        add.b                   #15,\2
                        move.b                  \2,GameState_Ball_phase(\1)
                        bra                     .thatsAll\@
.continue\@             ; ========
                        ; -- else update phase...
                        subq.b                  #1,\2
                        move.b                  \2,GameState_Ball_phase(\1)
.thatsAll\@
                        endm

;
ExecSoundBallRebound:
                        ; -- shut up all channels
                        move.b                  #7,$ff8800
                        move.b                  #%111111,$ff8802
                        ; -- setup A 440 Hz to channel A (Tone $11C -> {0,1}={$1c,$01})
                        move.b                  #0,$ff8800
                        move.b                  #$1c,$ff8802
                        move.b                  #1,$ff8800
                        move.b                  #$01,$ff8802
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
                        _xos_Supexec                #ExecSoundBallRebound
                        endm
;

;
DoBlitPlayerFirst       macro
                        ; - 1 address to the sprite data
                        ; - 2 address to the start of memory screen to update
                        ; - 3 shift to the right
                        ; - 4 spare address register
                        ; - 5 spare address register
                        ; - 6 spare data register
                        ; --
                        ; \4 := blitter base
                        move.w                  #2,(\4)+
                        ; -- Setup Source
                        move.w                  #8,(\4)+ ; source x increment
                        move.w                  #0,(\4)+ ; source y increment
                        move.l                  \1,(\4)+ ; source address
                        ; -- setup masks
                        ; \5 := $ffff0000 >> \3 = [endmask 1|endmask3]
                        move.l                  #$ffff0000,\5
                        lsr.l                   \3,\5
                        ; swap to put endmask1, swap again to put endmask3
                        swap                    \5
                        move.w                  \5,(\4)+
                        move.w                  #$ffff,(\4)+
                        swap                    \5
                        move.w                  \5,(\4)+
                        ; -- setup Dest
                        move.w                  #8,(\4)+
                        move.w                  #128,(\4)+ ; 160 bytes - 4 * 8
                        move.l                  \2,(\4)+
                        ; -- setup x/y counts
                        move.w                  #5,(\4)+
                        move.w                  #8,(\4)+
                        ; -- Hop/op values
                        move.w                  #$0203,(\4)+ ; HOP = 2 (source), OP = 3 (source)
                        ; -- set skew/shift registers
                        move.b                  #0,(\4)+
                        move.b                  \3,(\4)+
                        endm
;

;
DoBlitPlayerNext        macro
                        ; Append the blitting of the next bitplan.
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
                        ; -- use the blitter to display the player
                        ; -- a3 : start of the data of the player
                        ; -- a2 : start of the memory screen to update
                        ; -- d1 : shift to do
                        ; -- a1, a0, d0 : spare register.
ExecShowPlayer
                        ; a1 := start of blit list
                        SetupHeapAddress        HposBlitListBase,a1
                        ; -- setup PtrBlitterList
                        ; a0 := PtrBlitterList
                        move.l                  #PtrBlitterList,a0
                        move.l                  a1,(a0)
                        ; -- setup blit list
                        ; d0 : spare register
                        DoBlitPlayerFirst       a3,a2,d1,a1,d0
                        addq.l                  #2,a3
                        addq.l                  #2,a2
                        DoBlitPlayerNext        a3,a2,a1
                        addq.l                  #2,a3
                        addq.l                  #2,a2
                        DoBlitPlayerNext        a3,a2,a1
                        addq.l                  #2,a3
                        addq.l                  #2,a2
                        DoBlitPlayerNext        a3,a2,a1
                        ; -- end of blit list
                        move.w                  #0,(a1)+
                        _xos_Supexec                #BlitRunList
                        rts
;

;
DoBlitBallFirst         macro
                        ; Append the blitting of the first bitplan.
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
                        ; \6 := $ffff0000 >> \3 = [endmask 1|endmask3]
                        move.l                  #$f0000000,\5
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
                        move.w                  #4,(\4)+
                        ; -- Hop/op values
                        move.w                  #$0203,(\4)+ ; HOP = 2 (source), OP = 3 (source)
                        ; -- set skew/shift registers
                        move.b                  #0,(\4)+
                        move.b                  \3,(\4)+
                        endm
;

;
DoBlitBallNext          macro
                        ; Append the blitting of the next bitplan.
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
                        move.w                  #4,(\3)+
                        endm
;
                        ; -- use the blitter to display the ball
                        ; -- a3 : start of the data of the ball
                        ; -- a2 : start of the memory screen to update
                        ; -- d1 : shift to do
                        ; -- a1, a0, d0 : spare register.
ExecShowBall
                        ; a1 := start of blit list
                        SetupHeapAddress        HposBlitListBase,a1
                        ; -- setup PtrBlitterList
                        ; a0 := PtrBlitterList
                        move.l                  #PtrBlitterList,a0
                        move.l                  a1,(a0)
                        ; -- setup blit list
                        ; d0 : spare register
                        DoBlitBallFirst         a3,a2,d1,a1,d0
                        addq.l                  #2,a3
                        addq.l                  #2,a2
                        DoBlitBallNext          a3,a2,a1
                        addq.l                  #2,a3
                        addq.l                  #2,a2
                        DoBlitBallNext          a3,a2,a1
                        addq.l                  #2,a3
                        addq.l                  #2,a2
                        DoBlitBallNext          a3,a2,a1
                        ; -- end of blit list
                        move.w                  #0,(a1)+
                        _xos_Supexec                #BlitRunList
                        rts
;

;
DoBlitClrBrickFirst     macro
                        ; Append the first blitting that erase a whole brick (top half).
                        ; - 1 address to the sprite data
                        ; - 2 address to the start of memory screen to update
                        ; - 3 address of next blit item in the blitter list buffer
                        ; - 4 data register [mask 1|mask 3]
                        ; - 5 destination y increment
                        ; - 6 x count
                        ; --
                        ; This is a blit item opcode 2
                        move.w                  #2,(\3)+
                        ; -- Setup Source
                        move.w                  #8,(\3)+ ; source x increment
                        move.w                  #0,(\3)+ ; source y increment
                        move.l                  \1,(\3)+ ; source address
                        ; -- setup masks
                        ; swap to put endmask1, swap again to put endmask3
                        swap                    \4
                        move.w                  \4,(\3)+
                        move.w                  #$ffff,(\3)+
                        swap                    \4
                        move.w                  \4,(\3)+
                        ; -- setup Dest
                        move.w                  #8,(\3)+
                        move.w                  \5,(\3)+
                        move.l                  \2,(\3)+
                        ; -- setup x/y counts
                        move.w                  \6,(\3)+
                        move.w                  #4,(\3)+
                        ; -- Hop/op values
                        move.w                  #$0203,(\3)+ ; HOP = 2 (source), OP = 3 (source)
                        ; -- set skew/shift registers
                        move.b                  #0,(\3)+
                        move.b                  #0,(\3)+
                        endm
;

;
DoBlitClrBrickNext      macro
                        ; Append the next blitting that erase a whole brick (bottom half).
                        ; - 1 address to the sprite data
                        ; - 2 address to the start of memory screen to update
                        ; - 3 address of next blit item in the blitter list buffer
                        ; --
                        ; This is a blit item opcode 3
                        move.w                  #3,(\3)+
                        ; -- Setup Source
                        move.l                  \1,(\3)+
                        ; -- setup Dest
                        move.l                  \2,(\3)+
                        ; -- setup y counts
                        move.w                  #4,(\3)+
                        endm
;

ExecSound               macro
                        ; Execute the playing of the given dma sound description
                        ; 1 - the pointer to the descriptor of the dma sound.
                        ; 2 - spare address register
                        ; --
                        move.l                  #DmaSound_PtrDesc,\2
                        move.l                  \1,(\2)
                        _xos_Supexec                #DmaSound_playOnce
                        endm
;
; ----------------------------------------------------------------------------------------
; macro to manage bricks
;
Game_scanBrkToDelete  macro
                        ; find the extends of the deletion to do
                        ; \1 - pointer to the initial cell
                        ; \2 - value of the initial cell
                        ; \3 - col of the initial cell => col of the leftmost cell to delete
                        ; \4 - spare address register => pointer to last cell to clear (excluded)
                        ; \5 - spare data register => number of cells to delete
                        ; \6 - spare data register
                        ; \7 - spare address register => pointer to first cell to clear
                        ; --
                        ; \5 := extends of the bricks (number of tiles)
                        moveq                   #1,\5
                        ; -- scan to the left first
                        ; \7 := init cursor to next cell (take predecrement into account)
                        move.l                  \1,\7
                        btst                    #9,\2
                        bne                     .doneLeft\@
.nextLeft\@
                        ; update \5
                        addq.b                  #1,\5
                        ; update \3
                        subq.b                  #1,\3
                        ; \6 := cell value
                        move.w                  -(\7),\6
                        btst                    #9,\6
                        beq                     .nextLeft\@
.doneLeft\@
                        ; \4 := init cursor to next cell (take postincrement into account)
                        lea                     2(\1),\4
                        btst                    #8,\2
                        bne                     .doneScanToRight\@
.nextRight\@
                        ; update \5
                        addq.b                  #1,\5
                        ; \6 := cell value
                        move.w                  (\4)+,\6
                        btst                    #8,\6
                        beq                     .nextRight\@
.doneScanToRight\@
                        endm
;
;
RelaunchBall            macro
                        ; Re-initialize the ball (new ball).
                        ; 1 - Ptr to game state
                        ; 2 - spare data register
                        ; --
                        ; -- Ball is captive
                        move.b                  #BALL_CAPTV_WAIT_FIRE,GameState_Ball_cptvState(\1)
                        ; to the left (-1)
                        move.b                  #$ff,GameState_Ball_cptvSteer(\1)
                        move.b                  #1,GameState_Ball_cptvPos(\1)
                        move.b                  #BALL_POSCAPTV_LEFT,GameState_Ball_cptvPosT(\1)

                        move.b                  #$24,GameState_Ball_x(\1)
                        move.b                  #$27,GameState_Ball_y(\1)
                        ; dx := -1
                        move.b                  #$ff,GameState_Ball_dx(\1)
                        ; dy := -1
                        move.b                  #$ff,GameState_Ball_dy(\1)
                        move.b                  #$24,GameState_Ball_xNext(\1)
                        move.b                  #$27,GameState_Ball_yNext(\1)
                        move.b                  #$01,GameState_Ball_hlfSpd(\1)
                        move.b                  #$00,GameState_Ball_phase(\1)
                        ; -- reset ball behavior to glue, but for only 1 rebound
                        GameState_Ball_setBehavior \1,#BALL_BEHAVIOR_GLUE,\2
                        move.w                  #0,GameState_Ball_bhvrTtl(\1)
                        ; wait around 0.6 seconds (at 50 Hz) before starting the ball
                        move.b                  #0,GameState_Ball_freeze(\1)
                        endm
;
;
RelaunchPlayer           macro
                        ; Re-initialize the player position
                        ; 1 - Ptr to the game state
                        ; --
                        move.b                  #32,GameState_Player_x(\1)
                        move.b                  #5,GameState_Player_y(\1)
                        move.b                  #8,GameState_Player_w(\1)
                        move.b                  #2,GameState_Player_h(\1)
                        move.b                  #0,GameState_Player_dx(\1)
                        move.b                  #0,GameState_Player_dy(\1)
                        move.b                  #32,GameState_Player_xNext(\1)
                        move.b                  #5,GameState_Player_yNext(\1)
                        ; -- prepare mouse handler client
                        move.w                  #160,d0
                        move.w                  #20,d1
                        bsr                     sr_mshandlr_reset_pos
                        endm
;
;
GameIsCleared           macro
                        ; The level has been completed
                        ; 1 - Ptr to the game state
                        ; 2 - spare address register
                        ; --
                        ; a4 := spare register
                        ExecSound               #Game_sndGameClear,\2
                        ; -- the game is clear
                        move.b                  #0,GameState_isOver(\1)
                        move.b                  #0,GameState_isClear(\1)
                        endm
;
; ----------------------------------------------------------------------------------------------------------------
; before all
; ----------------------------------------------------------------------------------------------------------------
PhsGameBeforeAll:       ; ========
                        ; -- setup sound descriptors
                        ; a6 := ptr to each structur
                        move.l                  #Game_sndGetReady,a6
                        DmaSound_setupSound     #SndGetReadyBase,#SndGetReadyTop,#DmaSound_MONO_6,a6
                        move.l                  #Game_sndOhNo,a6
                        DmaSound_setupSound     #SndOhNoBase,#SndOhNoTop,#DmaSound_MONO_6,a6
                        move.l                  #Game_sndGameOver,a6
                        DmaSound_setupSound     #SndGameOverBase,#SndGameOverTop,#DmaSound_MONO_6,a6
                        move.l                  #Game_sndGameClear,a6
                        DmaSound_setupSound     #SndYouWonBase,#SndYouWonTop,#DmaSound_MONO_6,a6
                        ; -- setup pointer to BrickStatus
                        ; a6 := Storage of the pointer
                        move.l                  #PtrBrickStatusMatrix,a6
                        ; a5 := Ptr current level
                        SetupHeapAddress        HposCurrentLvlBase,a5
                        lea                     Level_Bricks(a5),a5
                        move.l                  a5,(a6)
                        ; -- setup pointer to BallFreedom
                        ; a6 := Storage of the pointer
                        move.l                  #PtrBallFreedomMatrix,a6
                        ; a5 := Ptr address
                        SetupHeapAddress        HposFreedomBase,a5
                        move.l                  a5,(a6)
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
                        ;
                        ; -- setup microwire sound
                        _xos_Supexec                #SetupMicrowire
                        rts
; ----------------------------------------------------------------------------------------------------------------
; before each
; ----------------------------------------------------------------------------------------------------------------
PhsGameBeforeEach:      ; ========
                        ; ========
                        ; -- init the freedom matrix with brick occupation
                        ; a6 := ptr to the freedom matrix
                        DerefPtrToPtr           PtrBallFreedomMatrix,a6
                        ; a5 := ptr to grid status matrix
                        DerefPtrToPtr           PtrBrickStatusMatrix,a5
                        ; -- 20 lines occupied by bricks = 20 * 80 cells = 20 * 10 bytes = 200 bytes, to be filled by scanning the bricks
                        ; a4 := ptr to dest even rows
                        move.l                  a6,a4
                        ; a3 := ptr to dest odd rows = even row + 10
                        move.l                  a6,a3
                        add.l                   #10,a3
                        ; clear d7
                        moveq                   #0,d7
                        ; d5..d2 := brushes for filling dest byte
                        moveq                   #0,d5
                        rept 10 ; 10 lines of bricks
                        rept 10 ; 10 groups of 4 bricks
                        ; d6 := next value for dest (even and odd)
                        moveq                   #0,d6
                        ; -- brick 1 of 4
                        ; d7 := brick value
                        ; d5 := brush to use
                        move.w                  (a5)+,d7
                        tst.w                   d7
                        AssignVaElseVbTo        eq,#0,#%11000000,b,d5
                        or.b                    d5,d6
                        ; -- brick 2 of 4
                        ; d7 := brick value
                        ; d5 := brush to use
                        move.w                  (a5)+,d7
                        tst.w                   d7
                        AssignVaElseVbTo        eq,#0,#%110000,b,d5
                        or.b                    d5,d6
                        ; -- brick 3 of 4
                        ; d7 := brick value
                        ; d5 := brush to use
                        move.w                  (a5)+,d7
                        tst.w                   d7
                        AssignVaElseVbTo        eq,#0,#%1100,b,d5
                        or.b                    d5,d6
                        ; -- brick 4 of 4
                        ; d7 := brick value
                        ; d5 := brush to use
                        move.w                  (a5)+,d7
                        tst.w                   d7
                        AssignVaElseVbTo        eq,#0,#%11,b,d5
                        or.b                    d5,d6
                        ; -- assign byte to dest
                        move.b                  d6,(a4)+
                        move.b                  d6,(a3)+
                        endr
                        ; -- next line -> skip one line for even and odd pointers
                        lea                     10(a4),a4
                        lea                     10(a3),a3
                        endr
                        ; -- 30 lines occupied by nothing = 30 * 80 cells = 30 * 10 bytes = 300 bytes = 75 long
                        ; d7 := loop counter, 3 times
                        move.w                  #2,d7
.doFillFreedom          rept                    25
                        move.l                  #0,(a4)+
                        endr
                        dbf                     d7,.doFillFreedom
                        ; ========
                        ; -- Init the ball
                        ; a6 := ptr to the game state
                        SetupHeapAddress        HposGameStateBase,a6
                        ; d6 : spare data register
                        RelaunchBall            a6,d6
                        ; 2 remaining balls
                        move.b                  #2,GameState_Ball_remning(a6)
                        ; -- Init the player
                        RelaunchPlayer          a6
                        ; -- clear the collision list
                        GameState_clearCldList  a6,a5
                        ; ========
                        ; -- Game is not over nor clear
                        move.b                  #1,GameState_isOver(a6)
                        move.b                  #1,GameState_isClear(a6)
                        ; ========
                        ; -- Introductory sound
                        ExecSound               #Game_sndGetReady,a5
                        rts
; ----------------------------------------------------------------------------------------------------------------
; update
; ----------------------------------------------------------------------------------------------------------------
PhsGameUpdate:
                        ; ======== ======== ======== ========
                        ; -- is game done ?
                        ; a6 := the game state
                        SetupHeapAddress        HposGameStateBase,a6
                        tst.b                   GameState_isClear(a6)
                        ; -- if not game clear
                        bne                     .checkGameOver
                        ; -- else next level
                        ; d7 := current level to update
                        moveq                   #0,d7
                        move.w                  GameState_Level_srcCur(a6),d7
                        addq.w                  #1,d7
                        cmp.w                   GameState_Level_srcSize(a6),d7
                        ; -- if srcCur >= srcSize
                        bpl                     .backToMenu
                        ; -- else update current level, go back to play
                        move.w                  d7,GameState_Level_srcCur(a6)
                        ; a2 := subroutines
                        move.l                  #PhsGameAfterEach,a2
                        jsr                     (a2)
                        move.l                  #PhsInitLevelBeforeEach,a2
                        jsr                     (a2)
                        move.l                  #PhsInitLevelUpdate,PtrNextUpdate
                        move.l                  #PhsInitLevelRedraw,PtrNextRedraw
                        rts

.checkGameOver
                        tst.b                   GameState_isOver(a6)
                        bne                     .startUpdateBall
                        ; -- else end of game, go to the next phase
                        ; a2 := subroutines
.backToMenu
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
                        ; -- check captive mode
                        ; d7 := captive state
                        moveq                   #0,d7
                        move.b                  GameState_Ball_cptvState(a6),d7
                        tst.b                   d7
                        ; -- skip free ball update if not 0, the captive ball update happens after the player update.
                        bne                     .startUpdatePlayer
                        ; ========
                        ; -- check freezing of the ball
                        ; d7 := freezing counter
                        moveq                   #0,d7
                        move.b                  GameState_Ball_freeze(a6),d7
                        tst.b                   d7
                        ; -- if (d7 == 0)
                        beq                     .checkHalfSpeedState
                        ; -- else update counter and pass
                        subq.b                  #1,d7
                        move.b                  d7,GameState_Ball_freeze(a6)
                        bra                     .startUpdatePlayer
                        ; -- check halfspeed status
                        ; d7 := spare register for the macro
.checkHalfSpeedState    WhenHalfSpeedSkipOrGo   a6,d7,.startUpdatePlayer
.doStartUpdateBall      ; ========
                        ; d7 := dy
                        moveq                   #0,d7
                        move.b                  GameState_Ball_dy(a6),d7
                        ; d6 := current y
                        moveq                   #0,d6
                        move.b                  GameState_Ball_y(a6),d6
                        ; d5 := rebound tracker, bit field : ......yx ; bit set = free to rebound on x or y
                        moveq                   #3,d5
                        ; ========
                        cmp.b                   #50,d6
                        ; -- if d6 < 50
                        bmi                     .startMoveBallAlongY
                        ; -- else the ball is lost
                        ; d4 := remaining balls
                        move.b                  GameState_Ball_remning(a6),d4
                        tst.b                   d4
                        ; -- if there are remaining balls
                        bne                     .useRemainingBall
                        ; -- else game over
                        move.b                  #0,GameState_isOver(a6)
                        ; -- play "game over" sound
                        ; a4 := spare register
                        ExecSound               #Game_sndGameOver,a4
                        ; -- game over, return
                        rts
                        ; -- decrease remaining ball, init ball position and freeze
.useRemainingBall       subq.b                  #1,d4
                        ; -- update remaining ball
                        move.b                  d4,GameState_Ball_remning(a6)
                        ; -- play "oh no"
                        ; a4 := spare register
                        ExecSound               #Game_sndOhNo,a4
                        ; -- init ball position and freeze (copy from before each)
                        ; d3 : spare data register
                        RelaunchBall            a6,d3
                        rts
.startMoveBallAlongY    ; ========
                        tst.b                   d7
                        ; -- if d7 < 0
                        bmi                     .tryMoveBallUp
                        ; -- else if d7 > 0
                        bne                     .tryMoveBallDown
                        ; -- else d7 = 0, force move up
                        subq.b                  #1,d7
.tryMoveBallUp          ; ========
                        tst.b                   d6
                        ; -- if d6 > 0
                        bhi                     .doMoveBallAlongY
                        ; -- else rebound to go down
                        moveq                   #1,d7
                        bclr                    #1,d5                   ; mark rebound on y as done
                        DoSoundBallRebound
                        bra                     .doMoveBallAlongY
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
                        move.b                  GameState_Ball_dx(a6),d7
                        ; d6 := current x
                        move.b                  GameState_Ball_x(a6),d6
                        ; ========
                        tst.b                   d7
                        ; -- if d7 < 0
                        bmi                     .tryMoveBallLeft
                        ; -- else if d7 > 0
                        bne                     .tryMoveBallRight
                        ; -- else d = 0, force move left
                        subq.b                  #1,d7
.tryMoveBallLeft        ; ========
                        tst.b                   d6
                        ; -- if d6 > 0
                        bhi                     .doMoveBallAlongX
                        ; -- else rebound to go right
                        moveq                   #1,d7
                        bclr                    #0,d5                    ; mark rebound along x as done
                        DoSoundBallRebound
                        bra                     .doMoveBallAlongX
.tryMoveBallRight       ; ========
                        cmp.b                   #79,d6
                        ; -- if d6 < 79
                        bmi                     .doMoveBallAlongX
                        ; -- else rebound to go left
                        moveq                   #-1,d7
                        bclr                    #0,d5                    ; mark rebound along x as done
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
                        beq                     .commitBall
                        ; -- else there are rebounds to consider
                        ; a4 := Freedom matrix
                        DerefPtrToPtr           PtrBallFreedomMatrix,a4
                        ; a3 := Ptr to ball collision list
                        GameState_clearCldList  a6,a3
                        ; -- Testing 3 positions in the matrix
                        ; -- 1. (next x, next y)
                        ; -- 2. (x, next y)
                        ; -- 3. (next x, y)
                        ; -- Then store each test in d5 : ...312yx
                        ; -- test 1
                        ; a2,d2,d1 := spare registers for the macro TstPosToFreedomMatrix
                        TstPosToFreedomMatrix   d6,d3,a4,a2,d2,d1
                        ; if position is free
                        beq                     .tstFreedom2
                        ; -- else mark bit 3 of d5
                        bset.l                  #3,d5
                        GameState_setCldPoint   a3,d6,d3
.tstFreedom2            ; ========
                        ; -- test 2
                        ; d0 := x
                        move.b                  GameState_Ball_x(a6),d0
                        ; a2,d2,d1 := spare registers for the macro TstPosToFreedomMatrix
                        TstPosToFreedomMatrix   d0,d3,a4,a2,d2,d1
                        ; -- if position is free
                        beq                     .tstFreedom3
                        ; -- else mark bit 2 of d5
                        bset.l                  #2,d5
                        GameState_pushCldPoint  a3,d0,d3
.tstFreedom3            ; ========
                        ; -- test 3
                        ; d0 := y
                        move.b                  GameState_Ball_y(a6),d0
                        ; a2,d2,d1 := spare registers for the macro TstPosToFreedomMatrix
                        TstPosToFreedomMatrix   d6,d0,a4,a2,d2,d1
                        ; -- if position is free
                        beq                     .processBallRebounds
                        ; -- else mark bit 4 of d5
                        bset.l                  #4,d5
                        GameState_pushCldPoint  a3,d6,d0
.processBallRebounds    ; ========
                        ; REORDERING : a3 free
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
                        dbf                     d1,.processBallReboundY
                        ; -- d1 : case 0
                        ; -- There is no rebound when the ball has Juggernaut behaviour.
                        ; d0 := ball behavior
                        move.w                  GameState_Ball_behavior(a6),d0
                        cmp.b                   #BALL_BEHAVIOR_JUGGERNAUT,d0
                        beq                     .commitBall
                        ; -- do rebound x if bit 2 of d2 set or d2 == 2
                        ; d0 := d2 & %110 (6), nothing to do if 0
                        moveq                   #0,d0
                        move.b                  d2,d0
                        and.b                   #6,d0
                        beq                     .commitBall
.doBallReboundX         ; ========
                        ; -- There is no rebound when the ball has Juggernaut behaviour.
                        ; d0 := ball behavior
                        move.w                  GameState_Ball_behavior(a6),d0
                        cmp.b                   #BALL_BEHAVIOR_JUGGERNAUT,d0
                        beq                     .commitBall
                        ; d7 := -d7
                        neg.b                   d7
                        ; d6 := d6 + d7 + d7
                        add.b                   d7,d6
                        add.b                   d7,d6
                        bra                     .commitBall
                        ; ========
.processBallReboundY    ; -- switch (d1)
                        dbf                     d1,.processBallReboundXY
                        ; -- d1 : case 1
                        ; d0 := d2 & %11 (3), nothing to do if 0
                        moveq                   #0,d0
                        move.b                  d2,d0
                        and.b                   #3,d0
                        beq                     .commitBall
.doBallReboundY         ; ========
                        ; -- special behaviour if collision against the paddle
                        tst.b                   d4
                        ; -- if ball going up
                        bmi                     .doBallReboundYReally
                        ; -- else
                        cmp.b                   #40,d3
                        ; -- if next y out of the paddle area
                        bmi                     .doBallReboundYReally
                        ; -- else collision against the player bumper, need x
                        ; FIXME : if sticky, implement another logic
                        ; FIXME : when it happens on the border of the screen (left or right), cannot force dx !!
                        ; d0 := -(bumper.x - (next x - dx)) = -bumper.x + next x - dx
                        move.b                  GameState_Player_x(a6),d0
                        add.b                   d7,d0
                        neg.b                   d0
                        add.b                   d6,d0
                        ; -- test the side of rebound or in the middle, force direction on the side, leave in the middle
                        cmp.b                   #12,d0
                        bmi                     .isBumpOnLeft
                        ; -- else force dx to the right
                        tst.b                   d7
                        ; -- if needed to force
                        bmi                     .forceXMove
                        bra                     .doBallReboundYPaddle
.isBumpOnLeft           cmp.b                   #3,d0
                        bpl                     .doBallReboundYPaddle
                        ; -- force dx to the left
                        tst.b                   d7
                        bmi                     .doBallReboundYPaddle
                        ; -- ... only if need to force
.forceXMove             ; d7 := -d7
                        neg.b                   d7
                        ; d6 := d6 + 2 * d7
                        add.b                   d7,d6
                        add.b                   d7,d6
;
.doBallReboundYPaddle:
                        ; -- do the rebound
                        ; d4 := -d4
                        neg.b                   d4
                        ; d3 := d3 + d4 + d4
                        add.b                   d4,d3
                        add.b                   d4,d3
                        ; -- update behaviour
                        ; d2 : spare data register
                        GameState_Ball_updateBehavior a6,d2
                        ; --
                        DoSoundBallRebound
                        bra                     .commitBall

.doBallReboundYReally:
                        ; -- There is no rebound when the ball has Juggernaut behaviour.
                        ; d0 := ball behavior
                        move.w                  GameState_Ball_behavior(a6),d0
                        cmp.b                   #BALL_BEHAVIOR_JUGGERNAUT,d0
                        beq                     .commitBall
                        ; -- do the rebound
                        ; d4 := -d4
                        neg.b                   d4
                        ; d3 := d3 + d4 + d4
                        add.b                   d4,d3
                        add.b                   d4,d3
                        bra                     .commitBall
                        ; ========
.processBallReboundXY   ; -- d1 : case 2
                        ; -- do rebound according to the value of d2
                        ; -- 0:nothing ; 1:y ; 2:x+y; 3:y ; 4:x ; 5:x+y ; 6:x ; 7:x+y
                        ; -- we will reuse doBallReboundX and doBallReboundY
                        ; -- when we need to do both rebounds, we do the rebound x here then
                        ; -- go to doBallReboundY (closer to this point)
                        ; // TODO : use a vectors of jumps, should be better for highest values of d2 (do the math before)
                        ; switch d2 : case 0
                        tst.b                   d2
                        beq                     .commitBall
                        ; switch d2 : case 1
                        cmp.b                   #1,d2
                        beq                     .doBallReboundY
                        ; switch d2 : case 2
                        cmp.b                   #2,d2
                        beq                     .doBallReboundXY
                        ; switch d2 : case 3
                        cmp.b                   #3,d2
                        beq                     .doBallReboundY
                        ; switch d2 : case 4
                        cmp.b                   #4,d2
                        beq                     .doBallReboundX
                        ; switch d2 : case 5
                        cmp.b                   #5,d2
                        beq                     .doBallReboundXY
                        ; switch d2 : case 6
                        cmp.b                   #6,d2
                        beq                     .doBallReboundX
                        ; switch d2 : case 7
                        ; -> .doBallReboundXY
.doBallReboundXY        ; --
                        ; -- There is no rebound when the ball has Juggernaut behaviour.
                        ; d0 := ball behavior
                        move.w                  GameState_Ball_behavior(a6),d0
                        cmp.b                   #BALL_BEHAVIOR_JUGGERNAUT,d0
                        beq                     .commitBall
                        ; d7 := -d7
                        neg.b                   d7
                        ; d6 := d6 + d7 + d7
                        add.b                   d7,d6
                        add.b                   d7,d6
                        ; --
                        bra                     .doBallReboundY
                        ; ========
.commitBall
                        ; -- save new dx
                        move.b                  d7,GameState_Ball_dx(a6)
                        ; -- save new dy
                        move.b                  d4,GameState_Ball_dy(a6)
                        ; -- save next x
                        move.b                  d6,GameState_Ball_xNext(a6)
                        ; -- save next y
                        move.b                  d3,GameState_Ball_yNext(a6)
                        ; ======== ======== ======== ========
                        ; == Player update
                        ; ========
.startUpdatePlayer
                        ; -- load player status
                        ; d7 := GameState_Player.x
                        moveq                   #0,d7
                        move.b                  GameState_Player_x(a6),d7
                        ; d6 := dx, prepared with -x
                        moveq                   #0,d6
                        sub.w                   d7,d6
                        ; d5 := GameState_Player.y
                        moveq                   #0,d5
                        move.b                  GameState_Player_y(a6),d5
                        ; d4 := dy, prepared with -y
                        moveq                   #0,d4
                        sub.w                   d5,d4
                        ; ========
                        ; -- compute next status using mouse
                        ; a0 := pointer to updated mouse state
                        bsr                     srA_mshandlr_update
                        ; -- next x and dx
                        ; d7 := next x = mouse x / 4
                        move.w                  MouseState_x(a0),d7
                        lsr.w                   #2,d7
                        ; d6 := dx = d7 - x
                        add.w                   d7,d6
                        ; -- next y and dy
                        ; d5 := next y = mouse y / 4
                        move.w                  MouseState_y(a0),d5
                        ; d4 := dx = d5 - y
                        add.w                   d5,d4
                        ; ========
                        ; -- Save updated model
                        ; -- GameState_Player.nextX
.doUpdatePlayer         move.b                  d7,GameState_Player_xNext(a6)
                        ; -- GameState_Player.nextY
                        move.b                  d5,GameState_Player_yNext(a6)
                        ; -- GameState_Player.dx
                        move.b                  d6,GameState_Player_dx(a6)
                        ; -- GameState_Player.dy
                        move.b                  d4,GameState_Player_dy(a6)

                        ; ======== ======== ======== ========
                        ; == update captive ball
                        ; ========
.doUpdateBallCaptive
                        ; reuse d7 = Player.xNext and d6 = Player.yNext from previous section.
                        ; reuse d5 = Player.dx and d4 = Player.dy from previous section.
                        ; reuse a0 = MouseState
                        ; -- check if ball is captive
                        ; d3 := captive state
                        moveq                   #0,d3
                        move.b                  GameState_Ball_cptvState(a6),d3
                        tst.b                   d3
                        ; -- skip if free (0)
                        beq                     .doUpdateLevel
                        ; -- else
                        ; -- update ball.nextY
                        ; d5 := decrement (-1) and translate to full freedom matrix (+40)
                        add.b                   #39,d5
                        move.b                  d5,GameState_Ball_yNext(a6)
                        ; -- test left button
                        btst                    #0,MouseState_buttons(a0)
                        ; -- if not pressed
                        beq                     .doCaptvHandleNoFire
                        ; -- else pressed
                        cmp.b                   #BALL_CAPTV_WAIT_FIRE,d3
                        ; -- skip if not in waiting for fire
                        bne                     .doneCaptvHandleFire
                        ; -- else update state
                        move.b                  #BALL_CAPTV_WAIT_RELEASE,d3
                        move.b                  d3,GameState_Ball_cptvState(a6)
                        bra                     .doneCaptvHandleFire
.doCaptvHandleNoFire
                        cmp.b                   #BALL_CAPTV_WAIT_RELEASE,d3
                        ; -- skip if not waiting fire release
                        bne                     .doneCaptvHandleFire
                        ; -- else update state
                        move.b                  #BALL_CAPTV_FREE,d3
                        move.b                  d3,GameState_Ball_cptvState(a6)
.doneCaptvHandleFire
                        ; -- if waiting for release fire, react to joystick left/right
                        cmp.b                   #BALL_CAPTV_WAIT_RELEASE,d3
                        ; -- skip if released
                        bne                     .doneCaptvHandleSteer
                        ; -- else test dx
                        tst.b                    d5
                        ; -- skip altogether if dx == 0
                        beq                     .doneCaptvHandleSteer
                        ; -- skip to handle right when dx >= 0
                        bpl                     .doCaptvHandleRight
                        ; -- else update ball target and direction
                        move.b                  #BALL_POSCAPTV_LEFT,GameState_Ball_cptvPosT(a6)
                        move.b                  #$ff,GameState_Ball_dx(a6)
                        bra                     .doneCaptvHandleSteer
.doCaptvHandleRight
                        ; -- update ball target and direction
                        move.b                  #BALL_POSCAPTV_RIGHT,GameState_Ball_cptvPosT(a6)
                        move.b                  #1,GameState_Ball_dx(a6)
.doneCaptvHandleSteer
                        ; -- update relative position
                        ; d3 := target position
                        moveq                   #0,d3
                        move.b                  GameState_Ball_cptvPosT(a6),d3
                        ; d2 := current relative position
                        moveq                   #0,d2
                        move.b                  GameState_Ball_cptvPos(a6),d2
                        cmp.b                   d3,d2
                        ; -- skip update if not needed
                        beq                     .doPlaceCaptiveBall
                        ; -- else if current position < target position
                        bmi                     .captiveBallGoesRight
                        ; -- else target position < current position
                        subq.b                  #1,d2
                        move.b                  d2,GameState_Ball_cptvPos(a6)
                        bra                     .doPlaceCaptiveBall
.captiveBallGoesRight
                        ; increment d2
                        addq.b                  #1,d2
                        move.b                  d2,GameState_Ball_cptvPos(a6)
.doPlaceCaptiveBall
                        ; -- update ball next x
                        ; d7 := Player.xNext + Ball.captvPos = d7 + d2
                        add.b                   d2,d7
                        move.b                  d7,GameState_Ball_xNext(a6)
                        ; ======== ======== ======== ========
                        ; == update level
                        ; ========
.doUpdateLevel
                        ; -- only if ball is not shallow
                        ; FIXME
                        ; d5 := behavior
                        moveq                   #0,d5
                        move.w                  GameState_Ball_behavior(a6),d5
                        cmp.w                   #BALL_BEHAVIOR_SHALLOW,d5
                        beq                     .doUpdateFreedomMatrix
                        ; REORDERING : a5 free
                        ; a4 := start of the list of the tiles to delete
                        lea                     GameState_Level_eraseList(a6),a4
                        ; a3 := status matrix
                        DerefPtrToPtr           PtrBrickStatusMatrix,a3
                        ; d5 := start of the list of collision points (not enough address registers)
                        move.l                  a6,d5
                        add.l                   #GameState_Ball_cldList,d5
                        ; clear d7,d6
                        moveq                   #0,d7
                        moveq                   #0,d6
                        ; -- reset the counter of bricks to erase
                        ; d3 := actual count of bricks to erase
                        moveq                   #0,d3
                        move.b                  d3,GameState_Level_cntToErase(a6)
.nextCldPoint
                        ; a2 := Pointer to collision point
                        move.l                  d5,a2
                        ; d7 := x of collision point
                        move.b                  (a2)+,d7
                        cmp.b                   #$ff,d7
                        ; -- if (x == $ff) (end of list)
                        beq                     .doneCldList
                        ; -- else convert to cell column in status matrix (div by 2)
                        lsr.b                   #1,d7
                        ; d6 := y of collision point converted to row in column matrix (div by 2)
                        move.b                  (a2)+,d6
                        lsr.b                   #1,d6
                        ; update d5 for next iteration
                        move.l                  a2,d5
                        ; -- Test whether the ball collided a brick
                        ; a2,d2 := spare register for the macro
                        TstModelToStatusMatrix  d7,d6,a3,a2,d2
                        ; -- if no brick
                        beq                     .nextCldPoint
                        ; -- else store in list first tiles to erase, extends of the erasure, and pointers
                        ; a1,d1,d0,a0 : spare registers
                        Game_scanBrkToDelete    a2,d2,d7,a1,d1,d0,a0
                        ; -- before storing, find out whether the brick sprite offset is a locked exit
                        ; d2 := sprite index
                        moveq                   #0,d2
                        move.w                  (a0),d2
                        ; d0 := multicell bit #0 = (d2 >> 8) & 1
                        move.l                  d2,d0
                        lsr.w                   #8,d0
                        and.b                   #1,d0
                        ; d2 := sprite index minus multicell bit 0 = (d2 & $ff) - d0
                        and.w                   #$ff,d2
                        sub.b                   d0,d2
                        ;
                        cmp.b                   #BRICK_SPROFF_EXIT_OFF,d2
                        ; -- if disabled exit, no deletion, next collision.
                        beq                     .nextCldPoint
                        ; -- else restore sprite offset, register tiles to erase and handle special bricks
                        ; d2 := d2 + multicell bit #0
                        add.b                   d0,d2
                        ;
                        move.b                  d7,(a4)+
                        move.b                  d6,(a4)+
                        move.b                  d1,(a4)+
                        move.b                  #0,(a4)+
                        move.l                  a0,(a4)+
                        move.l                  a1,(a4)+
                        ; -- update counter of bricks to delete
                        addq.b                  #1,d3
                        move.b                  d3,GameState_Level_cntToErase(a6)
                        ; -- FIXME update BrickStatus to avoid trouble when counting remaining bricks (may require save/restore registers)
                        ; -- test the tile to erase for special effect
                        cmp.b                   #BRICK_STAR_TILE_OFFSET,d2
                        ; -- skip if not special brick
                        bmi                     .nextCldPoint
                        ; -- process disabled stars
                        beq                     .hitDisabledStar
                        ; -- convert to brick type
                        ; d2 := (d2 - BRICK_TO_SPECIAL_OFFST)/2
                        sub.w                   #BRICK_TO_SPECIAL_OFFST,d2
                        lsr.l                   #1,d2
                        ; -- select brick type
                        tst.b                   d2
                        bne                     .notEnabledStar
                        ; -- case active star, decrement the remaining stars counter and test whether all stars has been collected
                        ; d1 := remaining stars
                        moveq                   #0,d1
                        move.w                  GameState_Level_rmnStars(a6),d1
                        subq.w                  #1,d1
                        move.w                  d1,GameState_Level_rmnStars(a6)
                        tst.w                   d1
                        ; -- skip if there are still remaining stars
                        bhi                     .nextCldPoint
                        ; -- else level is cleared
                        ; a2 : spare register
                        GameIsCleared           a6,a2
                        ; -- continue
                        bra                     .nextCldPoint
                        ; -- case enabled star
.notEnabledStar
                        ; -- select brick type
                        cmp.b                   #BrickType_SHALLOW,d2
                        bne                     .notShallowBrick
                        ; -- case 'shallow' brick
                        ; d1 := spare data register
                        GameState_Ball_setBehavior a6,#BALL_BEHAVIOR_SHALLOW,d1
                        ; -- continue
                        bra                     .nextCldPoint
.notShallowBrick
                        ; -- select brick type
                        cmp.b                   #BrickType_JUGGERNAUT,d2
                        bne                     .notJuggernautBrick
                        ; -- case 'Juggernaut' brick
                        GameState_Ball_setBehavior a6,#BALL_BEHAVIOR_JUGGERNAUT,d1
                        ; -- continue
                        bra                     .nextCldPoint
.notJuggernautBrick
                        ; -- select brick type
                        cmp.b                   #BrickType_GLUE,d2
                        bne                     .notGlueBrick
                        ; -- case 'Glue' brick
                        GameState_Ball_setBehavior a6,#BALL_BEHAVIOR_GLUE,d1
                        ; -- continue
                        bra                     .nextCldPoint
.notGlueBrick
                        ; -- select brick type
                        cmp.b                   #BrickType_EXIT,d2
                        bne                     .notExitBrick
                        ; -- case enabled exit brick : level clear
                        ; a2 : spare register
                        GameIsCleared           a6,a2
                        ; -- continue
                        bra                     .nextCldPoint
.notExitBrick
                        ; -- select brick type
                        cmp.b                   #BrickType_KEY,d2
                        bne                     .notKeyBrick
                        ; -- case key : decrease remaining key, start unlocking exit if no more keys
                        ; d1 := remaining keys, to decrement and update
                        moveq                   #0,d1
                        move.w                  GameState_Level_rmnKeys(a6),d1
                        subq.w                  #1,d1
                        ; -- skip if it remains more keys
                        bne                     .hasRemainingKeys
                        ; -- else activate unlocking of exit bricks
                        move.b                  #1,GameState_Level_doneKeys(a6)
                        move.b                  #10,GameState_Level_unlckRow(a6)
                        ; -- init the pointer to the next cell to scan/unlock
                        ; a1 := End of current level - 40 cells (word) = HposCurrentLvlBase + Size - 80
                        SetupHeapAddress        HposCurrentLvlBase,a1
                        lea                     SIZEOF_Level(a1),a1
                        lea                     -80(a1),a1
                        move.l                  a1,GameState_Level_ptrUnlckCell(a6)
.hasRemainingKeys
                        move.w                  d1,GameState_Level_rmnKeys(a6)
.notKeyBrick
                        ; -- continue
                        bra                     .nextCldPoint
.hitDisabledStar
                        ; -- continue
                        bra                     .nextCldPoint
.doneCldList
                        ; -- do sound if some bricks have been broken this time
                        tst.w                   d3
                        ; skip if no break broken
                        beq                     .doUpdateFreedomMatrix
                        DoSoundBallRebound
                        ; -- Get count of remaining bricks
                        ; a4 := Ptr current level
                        SetupHeapAddress        HposCurrentLvlBase,a4
                        ; d2 := count broken bricks
                        moveq                   #0,d2
                        move.w                  Level_CntBroken(a4),d2
                        add.w                   d3,d2
                        move.w                  d2,Level_CntBroken(a4)
                        cmp.w                   Level_CntBrkabl(a4),d2
                        ; -- skip if not level not clear
                        blo                     .doUpdateFreedomMatrix
                        ; -- else level is cleared
                        ; a4 : spare register
                        GameIsCleared           a6,a4



.doUpdateFreedomMatrix  ; ======== ======== ======== ========
                        ; == update freedom matrix
                        ; ========
                        ; a5 := freedom matrix
                        DerefPtrToPtr           PtrBallFreedomMatrix,a5
                        ; ========
                        ; -- erase player occupation
                        ; d7 := player.x,
                        moveq                   #0,d7
                        move.b                  GameState_Player_x(a6),d7
                        ; d6 := player.y+40
                        moveq                   #40,d6
                        add.b                   GameState_Player_y(a6),d6
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
                        move.b                  GameState_Player_xNext(a6),d7
                        ; d6 := player.y+40
                        moveq                   #40,d6
                        add.b                   GameState_Player_yNext(a6),d6
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
                        ; -- erase bricks in the erasure list
                        ; d7 := the count of bricks to erase
                        moveq                   #0,d7
                        move.b                  GameState_Level_cntToErase(a6),d7
                        tst.b                   d7
                        ; -- if count == 0
                        beq                     .thatsAll
                        ; -- else cycle through bricks to erase
                        lea                     GameState_Level_eraseList(a6),a4
                        ; d7 := loop counter = count - 1
                        subq.b                  #1,d7
.doEraseNextBrick       ; -- load brick position, converted for PosToFreedomMatrix ( mul by 2)
                        ; d6 := x * 2
                        moveq                   #0,d6
                        move.b                  (a4)+,d6
                        BtMul2                  d6
                        ; d5 := y * 2
                        moveq                   #0,d5
                        move.b                  (a4)+,d5
                        BtMul2                  d5
                        ; a3,d4,d3 := spare register for the macro
                        PosToFreedomMatrix d6,d5,a5,a3,d4,d3
                        ; a2 := second line to erase in the matrix = a3 + 10
                        lea                     10(a3),a2
                        ; d4 := brick's width - 1 to loop over
                        moveq                   #0,d4
                        move.b                  (a4)+,d4
                        subq                    #1,d4
                        ; d3 := d6 & %111 (keep 3 least significant bits for rotating)
                        move.b                  d6,d3
                        and.b                   #7,d3
                        ; d2 := mask to erase = %00111111 ror d3 = $3f ror d3
                        moveq                   #$3f,d2
                        ror.b                   d3,d2
.doEraseNextTile
                        ; -- erase the brick
                        and.b                   d2,(a3)
                        and.b                   d2,(a2)
                        ; -- prepare for next tile
                        ; d2 := rotated by 2 bits to the right
                        ror.b                   #2,d2
                        ; d3 := (d3 + 2) & 7 => advance a2/a3 when 0
                        addq.b                  #2,d3
                        and.b                   #7,d3
                        ; -- if (d3 != 0) no need to bump a3/a2
                        bne                     .noPtrBump
                        ; -- else bump a3/a2
                        addq.l                  #1,a3
                        addq.l                  #1,a2
.noPtrBump
                        ; -- next tile
                        dbf                     d4,.doEraseNextTile
                        ; -- by the way, erase the bricks in the level
                        ; a4 : skip unused byte -> ptr to ptr to first cell to clear
                        addq.l                  #1,a4
                        ; a1 := ptr to first cell to clear
                        move.l                  (a4)+,a1
                        ; a0 := ptr after last cell to clear
                        move.l                  (a4)+,a0
.doClearBrickData
                        move.w                  #0,(a1)+
                        cmp.l                   a0,a1
                        bmi                     .doClearBrickData
                        ; -- next brick
                        dbf                     d7,.doEraseNextBrick
                        ; ======== ======== ======== ========



.thatsAll               rts
; ----------------------------------------------------------------------------------------------------------------
; redraw
; ----------------------------------------------------------------------------------------------------------------
PhsGameRedraw:          ; ========
                        ; -- is game not over ?
                        ; a6 := the game
                        SetupHeapAddress        HposGameStateBase,a6
                        tst.b                   GameState_isOver(a6)
                        bne                     .startEraseRemainingBall
                        ; -- else do nothing
                        rts
                        ; ======== ======== ======== ========
                        ; -- erase the remaining balls
                        ; a4 := start of the display = a5 + 196 * 160  = a5 + 31360
.startEraseRemainingBall:
                        lea                     31360(a5),a4
                        rept 4
                        move.l                  #$ffff0000,(a4)+
                        move.l                  #0,(a4)+
                        lea                     152(a4),a4
                        endr
.testForUnlockingExit
                        ; ======== ======== ======== ========
                        ; -- is there a row to scan for locked exit bricks ?
                        ; d7 := doneKeys
                        moveq                   #0,d7
                        move.b                  GameState_Level_doneKeys(a6),d7
                        tst.b                   d7
                        ; -- skip if not done/disabled
                        beq                     .startRedrawBricks
                        ; -- else scan and convert/redraw next line
                        ; d6 := previous Row (10 downto 0)
                        moveq                   #0,d6
                        move.b                  GameState_Level_unlckRow(a6),d6
                        tst.b                   d6
                        ; -- go to scan/convert/redraw if the previous row was not 0
                        bne                     .doUnlockExitForRow
                        ; -- else disable unlocking
                        moveq                   #0,d7
                        move.b                  d7,GameState_Level_doneKeys(a6)
                        bra                     .startRedrawBricks
.doUnlockExitForRow
                        ; -- update row
                        ; d7 := current row = d6 - 1
                        move.l                  d6,d7
                        subq.b                  #1,d7
                        move.b                  d7,GameState_Level_unlckRow(a6)
                        ; -- START scan/convert/redraw
                        ; -- init ptr blitter list
                        ; a4 := start of blit list
                        SetupHeapAddress        HposBlitListBase,a4
                        ; a3 := PtrBlitterList
                        move.l                  #PtrBlitterList,a3
                        move.l                  a4,(a3)
                        ; a3 free
                        ; -- setup sprite for tile 0 and tile 1 of exit brick
                        ; a2 := start of sprite datas
                        lea                     SpritesBricksDat,a2
                        ; a3 := start of index tables
                        lea                     IndexBricksTbl,a3
                        ; d6 := Offset in index table for tile 0 = BRICK_SPROFF_EXIT * 2
                        move.l                  #BRICK_SPROFF_EXIT,d6
                        WdMul2                  d6
                        ; d5 := Offset in index table for tile 1 = d6 + 2
                        move.l                  d6,d5
                        addq.w                  #2,d5
                        ; d6 := address of tile 0 = a2 + word at (a3 + d6)
                        move.w                  (a3,d6),d6
                        add.l                   a2,d6
                        ; d5 := address of tile 1 = a2 + word at (a3 + d5)
                        move.w                  (a3,d5),d5
                        add.l                   a2,d5
                        ; a2,a3 free
                        ; -- setup start line address
                        ; a3 := table of offsets
                        lea                     OffsTbl_RowScreenLines,a3
                        ; d4 := offset for current row
                        OffsTbl_getLongAtWdIndx a3,d7,d4
                        ; a3 := start address of row screen line
                        lea                     (a5,d4),a3
                        ; d4 free
                        ; -- setup start address in bricks cells
                        ; a2 : pointer to the next cell
                        move.l                  GameState_Level_ptrUnlckCell(a6),a2
                        ; -------
                        ; context so far
                        ; a6 - ptr to Game state
                        ; a5 - ptr to start of screen
                        ; a4 - ptr to blit list
                        ; a3 - pointer to current row address at screen memory
                        ; a2 - pointer to next cell
                        ; d7 - current row
                        ; d6 - pointer to sprite 0
                        ; d5 - pointer to sprite 1
                        ;
                        ; TODO
                        ; --
                        ;
                        ;
                        ; -------
                        ; -- loop over each brick
                        ; loop 40 times over d4
                        moveq                   #0,d4
                        move.w                  #39,d4
                        ; d3 := offset for the sprite, will switch between #0 and #8
                        moveq                   #0,d3
                        bra                     .nextCellToScan_start
.nextCellToScan
                        ; -- book keeping after each iteration.
                        InitLevel_updtNextTileRegs a3,d3
.nextCellToScan_start
                        ; -- get base sprite index
                        ; d2 : sprite index base
                        moveq                   #0,d2
                        move.b                  1(a2),d2
                        cmp.b                   #BRICK_SPROFF_EXIT_OFF,d2
                        ; -- convert if unlocked exit brick
                        beq                     .doUnlockBrick
                        ; -- else next cell
                        addq.l                  #2,a2
                        dbf                     d4,.nextCellToScan
                        bra                     .doneCellToScan
.doUnlockBrick
                        ; -- else convert this cell and the next one...
                        move.l                  #$31413141,d1
                        moveq                   #0,d1
                        ; d2 := unlocked sprite index for the first tile = d2 - BRICK_DELTA_EXIT_OFF
                        sub.b                   #BRICK_DELTA_EXIT_OFF,d2
                        move.b                  d2,1(a2)
                        ; d2 := unlocked sprite index for the next tile = d2 + 1
                        addq.b                  #1,d2
                        move.b                  d2,3(a2)
                        ; d2 free
                        ; -- ... and program the redraw in the blitter list
                        ; -- put sprite 0 into blitter list
                        ; d2 : working copy of d6
                        move.l                  d6,d2
                        ; a1 : working copy of a3
                        move.l                  a3,a1
                        ; d1 : spare data register
                        InitLevel_PushFirstBb   d2,a1,d3,a4,d1
                        rept 3
                        addq.l                  #2,d2
                        addq.l                  #2,a1
                        InitLevel_PushNextBb    d2,a1,a4
                        endr
                        ; -- put sprite 1 into blitter list
                        ; d2 : working copy of d6
                        move.l                  d5,d2
                        ; update values of a3,d3
                        InitLevel_updtNextTileRegs a3,d3
                        ; a1 : working copy of a3
                        move.l                  a3,a1
                        ; d1 : spare data register
                        InitLevel_PushFirstBb   d2,a1,d3,a4,d1
                        rept 3
                        addq.l                  #2,d2
                        addq.l                  #2,a1
                        InitLevel_PushNextBb    d2,a1,a4
                        endr
                        ; -- skip next brick cell then continue
                        addq.l                  #4,a2
                        subq.w                  #1,d4
                        dbf                     d4,.nextCellToScan
                        ; -- done
.doneCellToScan
                        ; -- terminate blitter list
                        move.w                  #0,(a4)
                        ; -- setup pointer to next previous line
                        ; a2 -= 160 (it has advanced by 40 cells, must go back, and then go back 40 cells back for previous line)
                        lea                     -160(a2),a2
                        move.l                  a2,GameState_Level_ptrUnlckCell(a6)
                        ; -- Ready to blit
                        _xos_Supexec                #BlitRunList
.startRedrawBricks      ; ======== ======== ======== ========
                        ; == Redraw (erase only) bricks
                        ; d7 := number of bricks to erase
                        moveq                   #0,d7
                        move.b                  GameState_Level_cntToErase(a6),d7
                        tst.b                   d7
                        ; -- if no brick to erase, skip
                        beq                     .startRedrawPlayer
                        ; -- else do the erase
                        ; a1 := start of blit list
                        SetupHeapAddress        HposBlitListBase,a1
                        ; -- setup PtrBlitterList
                        ; a0 := PtrBlitterList
                        move.l                  #PtrBlitterList,a0
                        move.l                  a1,(a0)
                        ; d7 := d7 - 1 to loop over
                        subq.b                  #1,d7
                        ; a4 := start of bricks erasure list
                        lea                     GameState_Level_eraseList(a6),a4
.nextBrickToErase
                        ; -- compute offset from start of line and skew
                        ; d6 := column of the first tile
                        moveq                   #0,d6
                        move.b                  (a4)+,d6
                        ; d5 := (bit 0 of d6) << 3 = skew
                        ; d1 := bit 0 of d6 ; backup to compute xcount
                        moveq                   #0,d5
                        move.b                  d6,d5
                        and.b                   #$1,d5
                        move.l                  d5,d1
                        lsl.b                   #3,d5
                        ; d6 := 2*d6 (column to model x)
                        WdMul2                  d6
                        ; d4,d3 : spare data registers, offset in d4
                        ModelToScreenX          d6,d4,d3
                        ; d6 := offset to first word in screen line
                        move.w                  d4,d6
                        ; -- compute offset from start of screen
                        ; d4 := row of the first tile * 2 (row to model y)
                        moveq                   #0,d4
                        move.b                  (a4)+,d4
                        WdMul2                  d4
                        ; d3,d2 : spare registers, offset in d3
                        ModelToScreenY          d4,d3,d2
                        ; d6 := offset from start of screen
                        add.w                   d3,d6
                        ; a3 := start of screen to update
                        lea                     (a5,d6),a3
                        ; a2 := start of source data
                        lea                     SpritesLinesDat,a2
                        ; -- compute width and mask of blit
                        ; d6 := width of the brick
                        moveq                   #0,d6
                        move.b                  (a4)+,d6
                        ; d4 := (1 == d6) ? $ff000000 ; then shift mask
                        cmp.b                   #1,d6
                        bne                     .wideBrick
                        move.l                  #$ff000000,d4
                        bra                     .shiftMask
.wideBrick
                        btst                    #0,d6
                        ; -- skip if d6 even
                        beq                     .maskForEvenWidth
                        ; d4 := unskewed mask for odd width
                        move.l                  #$ffffff00,d4
                        bra                     .shiftMask
.maskForEvenWidth
                        tst.b                   d1
                        ; d4 := full mask when no skewing
                        AssignVaElseVbTo        eq,#$ffffffff,#$ffff0000,l,d4
.shiftMask
                        lsr.l                   d5,d4
                        ; d6 := blit xcount = (d6 + d1 + 1) / 2
                        add.b                   d1,d6
                        addq.b                  #1,d6
                        lsr.w                   #1,d6
                        ; d3 := dest y increment = 160 - 2*xcount = 2* (20 - d6)
                        moveq                   #0,d3
                        move.w                  #20,d3
                        sub.w                   d6,d3
                        addq.w                  #1,d3
                        lsl.w                   #3,d3
                        ; -- prepare blit type #2 (bitplan 1)
                        DoBlitClrBrickFirst     a2,a3,a1,d4,d3,d6
                        ; -- prepare blit type #3 (other bit plan and second half)
                        rept 3
                        addq.l                  #2,a2
                        addq.l                  #2,a3
                        DoBlitClrBrickNext      a2,a3,a1
                        endr
                        subq.l                  #6,a2
                        lea                     634(a3),a3
                        DoBlitClrBrickNext      a2,a3,a1
                        rept 3
                        addq.l                  #2,a2
                        addq.l                  #2,a3
                        DoBlitClrBrickNext      a2,a3,a1
                        endr
                        ; -- next item
                        lea                     9(a4),a4
                        dbf                     d7,.nextBrickToErase
                        ; -- terminate and execute blit list
                        move.w                  #0,(a1)+
                        _xos_Supexec                #BlitRunList
                        ; ========
                        ; ======== ======== ======== ========
                        ; -- do nothing if dx, dy are 0 (//NOT YET, what about the first redraw ?)
                        ; -- if dy != 0, erase all player parts at old pos then draw all player parts at new pos
                        ; -- if dx != 0, draw the sequence {erase,1,skip,2,3} (minus) or {1,2,skip,3,erase} (plus) at new pos.
                        ; -- commit new position
                        ; a6 := Player
.startRedrawPlayer      SetupHeapAddress        HposGameStateBase,a6
                        ; a4 := start of the Player screen area
                        lea                     25600(a5),a4
                        ; a3 := current place to redraw in the screen memory
                        move.l                  a4,a3
                        ; -- erase conditionally
                        move.b                  GameState_Player_dx(a6),d7
                        tst.b                   d7
                        bne                     .erasePlayer
                        move.b                  GameState_Player_dy(a6),d7
                        beq.w                   .drawPlayer
.erasePlayer            ; ========
                        ; -- offset to first line
                        ; d5 := offset to the start of the line
                        ; d2 := temp
                        ModelToScreenY          GameState_Player_y(a6),d5,d2
                        ; update offset a3
                        add.l                   d5,a3
                        ; ========
                        ; -- offset and shift to the first column
                        ; d5,d4 := offset and shift value to the screen x (shift value will be 0 or 2)
                        ModelToScreenX          GameState_Player_x(a6),d5,d4
                        ; -- update offset a3
                        add.l                   d5,a3
                        ; ========
                        tst.w                   d4
                        bne                     .eraseOdd
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
                        dbf                     d3,.loopEraseEven
                        bra                     .drawPlayer
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
                        dbf                     d3,.loopEraseOdd
.drawPlayer             ; ========
                        ; -- reset a3 := start of the drawable area
                        move.l                  a4,a3
                        ; -- offset to first line
                        ; d5 := offset to the start of the line
                        ; d2 := temp
                        ModelToScreenY           GameState_Player_yNext(a6),d5,d2
                        ; -- update offset a3
                        add.l                   d5,a3
                        ; ========
                        ; -- offset and shift to the first column
                        ; d5,d4 := offset and shift value to the screen x (shift value will be 0 or 2)
                        ModelToScreenX           GameState_Player_xNext(a6),d5,d4
                        ; -- update offset a3
                        add.l                   d5,a3
                        ; ========
                        tst.w                   d4
                        bne                     .drawPlayerOdd
                        ; -- else the player is aligned to 16px positions
                        ; -- setup register for calling the display macro
                        ; a2 := a3 (dest)
                        move.l                  a3,a2
                        ; a3 := sprite player
                        move.l                  #SpritesDat,a3
                        lea                     DatSprtsPlayerBase(a3),a3
                        ; d1 := 0
                        moveq                   #0,d1
                        bsr.w                   ExecShowPlayer
                        bra                     .doneDrawPlayer
.drawPlayerOdd          ; ========
                        ; d3 := loop counter
                        ; -- setup register for calling the display macro
                        ; a2 := a3 (dest)
                        move.l                  a3,a2
                        ; a3 := sprite player
                        move.l                  #SpritesDat,a3
                        lea                     DatSprtsPlayerBase(a3),a3
                        ; d1 := 0
                        moveq                   #8,d1
                        bsr.w                   ExecShowPlayer
.doneDrawPlayer         ; ========
                        ; -- done, commit model update
                        move.b                  GameState_Player_xNext(a6),GameState_Player_x(a6)
                        move.b                  GameState_Player_yNext(a6),GameState_Player_y(a6)


                        ; ========
RedrawBall:
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
                        ModelToScreenY          GameState_Ball_y(a6),d7,d2
                        cmp.l                   #32000,d7
                        ; -- if out of screen
                        bpl.w                   .draw
                        ; -- update offset a3
                        add.l                   d7,a3
                        ; ======
                        ; -- Offset to actual drawing start address and shifting of the pattern
                        ;
                        ModelToScreenX          GameState_Ball_x(a6),d7,d6
                        ; ========
                        ; -- update offset a3
                        add.w                   d7,a3
                        ; ========
                        ; draw using the right shift
                        dbf                     d6,.caseEraseShift4
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
.caseEraseShift4        dbf                     d6,.caseEraseShift8
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
.caseEraseShift8        dbf                     d6,.caseEraseShift12
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
                        bra                     .draw
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
                        ModelToScreenY          GameState_Ball_yNext(a6),d7,d2
                        cmp.l                   #32000,d7
                        ; -- if out of screen
                        bpl                     .commitBall
                        ; -- update offset
                        add.l                   d7,a3
                        ; ======
                        ; d7,d6 := new x -> offset to actual drawing start address and shifting of the pattern, resp.
                        ModelToScreenX          GameState_Ball_xNext(a6),d7,d6
                        ; ========
                        ; -- update offset a3
                        add.w                   d7,a3
                        ; ========
                        ; -- setup register for calling the display macro
                        ; a2 := a3 (dest)
                        move.l                  a3,a2
                        ; a3 := sprite ball
                        move.l                  #SpritesBallsDat,a3
                        ; -- blink the ball between normal and behavior during last period
                        ; d2 := offset to sprite, default to 0
                        moveq                   #0,d2
                        ; d1 := behavior
                        moveq                   #0,d1
                        move.w                  GameState_Ball_behavior(a6),d1
                        tst.w                   d1
                        ; -- skip if normal behavior
                        beq                     .setBallSprtOffset
                        ; -- else check behavior ttl
                        ; d1 := behavior ttl
                        move.w                  GameState_Ball_bhvrTtl(a6),d1
                        tst.w                   d1
                        ; -- use sprite offset if not 0
                        bne                     .useSpriteOffset
                        ; -- else check bit #2 of phase
                        ; d1 := phase
                        moveq                   #0,d1
                        move.b                  GameState_Ball_phase(a6),d1
                        btst.l                  #3,d1
                        ; -- skip if bit is set
                        beq                     .setBallSprtOffset
                        ; -- else
.useSpriteOffset
                        move.w                  GameState_Ball_sprOffst(a6),d2
.setBallSprtOffset
                        lea                     (a3,d2),a3
                        ; d1 := d6 * 4
                        move.w                  d6,d1
                        WdMul4                  d1
                        bsr.w                   ExecShowBall
                        ; -- done, commit new coordinates
.commitBall             move.b                  GameState_Ball_xNext(a6),GameState_Ball_x(a6)
                        move.b                  GameState_Ball_yNext(a6),GameState_Ball_y(a6)

.DrawRemainingBalls:     ; ========
                        ; -- draw the remainng balls
                        ; d7 := remaining balls
                        moveq                   #0,d7
                        move.b                  GameState_Ball_remning(a6),d7
                        tst.b                   d7
                        ; a4 := start of the display = a5 + 196 * 160 = a5 + 31360
                        lea                     31360(a5),a4
                        ; -- if (d7 == 0)
                        beq                     .thatsAll
                        ; -- else display some balls (up to 2)
                        ; -- setup register for calling the display macro
                        ; a2 := start of the display = a5 + 196 * 160 = a5 + 31360
                        lea                     31360(a5),a2
                        ; a3 := sprite ball
                        move.l                  #SpritesBallsDat,a3
                        ; d1 := 0
                        move.w                  #0,d1
                        bsr.w                   ExecShowBall
                        cmp.b                   #2,d7
                        ; -- if (d7 < 2)
                        bmi                     .thatsAll
.drawTwoRemaining       ; ========
                        ; -- else display some balls (up to 2)
                        ; a2 := start of the display = a5 + 196 * 160 = a5 + 31360
                        lea                     31360(a5),a2
                        ; a3 := sprite ball
                        move.l                  #SpritesDat,a3
                        lea                     DatSprtsBallBase(a3),a3
                        ; d1 := 8
                        move.w                  #8,d1
                        bsr.w                   ExecShowBall
                        ; ========
.thatsAll
                        rts                     ; comment this line to debug freedom matrix
                        ; ========
                        ; -- debug freedom matrix
                        ; a4 := freedom matrix
                        DerefPtrToPtr           PtrBallFreedomMatrix,a4
                        ; a3 := screen + 16000
                        lea                     16000(a5),a3
                        ; -- for 50 lines
                        rept 50
                        ; -- for 5 words per line
                        rept 5
                        ; -- for 4 bitplans
                        move.w                  (a4),(a3)+
                        move.w                  (a4),(a3)+
                        move.w                  (a4),(a3)+
                        move.w                  (a4)+,(a3)+
                        endr
                        lea                     120(a3),a3
                        endr
                        rts
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
; Brick status model : direct access to the cell array (1 word per cell)
; ================================================================================================================
PtrBrickStatusMatrix    dc.l                    0
; ================================================================================================================
; Ball freedom matrix model : a bitmap, 50 lines of 80 bits = 10 bytes per line => 500 bytes
; ================================================================================================================
PtrBallFreedomMatrix    dc.l                    0
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; Sound descriptors
Game_sndGetReady        ds.b                    SIZEOF_DmaSound
Game_sndGameOver        ds.b                    SIZEOF_DmaSound
Game_sndGameClear       ds.b                    SIZEOF_DmaSound
Game_sndOhNo            ds.b                    SIZEOF_DmaSound
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
