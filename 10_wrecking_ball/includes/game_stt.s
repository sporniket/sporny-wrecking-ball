; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Ball behaviors codes
BALL_BEHAVIOR_NORMAL    = 0
BALL_BEHAVIOR_GLUE      = 1
BALL_BEHAVIOR_JUGGERNAUT = 2
BALL_BEHAVIOR_SHALLOW   = 3

BALL_BEHAVIOR_TTL       = 7 ; number of rebounds on the paddle before the special behavior wears off.
;
; Ball capture states
BALL_CAPTV_FREE         = 0 ; the ball is free
BALL_CAPTV_WAIT_FIRE    = 1 ; the ball is captured, waiting for fire press -and hold-
BALL_CAPTV_WAIT_RELEASE = 2 ; the ball is captured, waiting for fire release that makes it free.
; Ball capture positions
BALL_POSCAPTV_LEFT      = 1 ; Target X position of the captive ball, relative from the paddle, when on the left
BALL_POSCAPTV_RIGHT     = 14 ; Target X position of the captive ball, relative from the paddle, when on the right.
;
; Level clear conditions
LEVEL_CLRCOND_STARS     = 1 ; set this bit to allow clear level when all the stars have been collected
LEVEL_CLRCOND_EXIT      = 2 ; set this bit to allow clear level when an exit brick has been broken

; ================================================================================================================
; Game state
; Note : a '-' mark is put at each even offset when single byte fields are declared, to spot where a word or long word
; field may be declared.
; ================================================================================================================
                        rsreset
; -- [Game] general state
GameState_score         rs.l 1
; -
GameState_isOver        rs.b 1
GameState_isClear       rs.b 1
; -
GameState_level         rs.b 1
; -- [Ball] state
; position before update
GameState_Ball_x        rs.b 1
; -
GameState_Ball_y        rs.b 1
; next displacement and position -- COLOCALIZED
GameState_Ball_dx       rs.b 1
; -
GameState_Ball_dy       rs.b 1
GameState_Ball_xNext    rs.b 1
; -
GameState_Ball_yNext    rs.b 1
; Half speed management
GameState_Ball_hlfSpd   rs.b 1                  ; half speed flag (1 = half speed mode)
; -
GameState_Ball_phase   rs.b 1                  ; ball phase counter (bit #0 = freeze if half speed mode, bit #3 : blink ball on last ttl of special behavior)
GameState_Ball_freeze   rs.b 1                  ; countdown before letting the ball move
; -
GameState_Ball_remning  rs.b 1                  ; remaining balls
; list of collision points
GameState_Ball_cldList  rs.b 6                  ; 2 byte per collision point (row, column), 2 collision points at most, the list terminate with $ff
; -- [Player] state
; Current position
GameState_Player_x      rs.b 1
; -
GameState_Player_y      rs.b 1
GameState_Player_w      rs.b 1
; -
GameState_Player_h      rs.b 1
; Next position
GameState_Player_xNext  rs.b 1
; -
GameState_Player_yNext  rs.b 1
GameState_Player_dx     rs.b 1
; -
GameState_Player_dy     rs.b 1
; width management (not in this version)
GameState_Player_wNext  rs.b 1
; -
GameState_Player_dw     rs.b 1
; -- [Level] state
GameState_Level_cntToErase rs.b 1               ; 0,1 or 2 bricks to erase
; -
; !! MUST BE EVEN !!
GameState_Level_eraseList  rs.b 40              ; buffer, bricks position in the bricks status model (col, row, extends,0,ptr first cell, ptr last cell + 1) , 12 bytes each
; -
; Source list of levels
GameState_Level_srcSize rs.w 1                  ; Size of the list
; -
GameState_Level_srcPtr  rs.l 1                  ; Pointer to the elements
; -
GameState_Level_srcCur  rs.w 1                  ; Current level in source list
; -
GameState_Level_rmnStars rs.w 1                 ; Count the remaining stars to erase for clearing the level
; -
GameState_Level_rmnKeys rs.w 1                  ; Remaining keys before activating the exit bricks
; -
GameState_Level_clrCond rs.b 1                  ; bit fields to activate clear conditions, 0 to require delete all bricks. see LEVEL_CLRCOND_STARS, LEVEL_CLRCOND_EXIT
GameState_Level_actExit rs.b 1                  ; signal set to 1 when all the keys are collected, to visually activate the exit bricks
; -
; TODO
; FIXME -- putting the following with the other '_Ball_' fields trigger a bus error. BECAUSE ODD ADDRESS !
GameState_Ball_behavior rs.w 1                  ; 0 - normal ; 1 - glue ; 2 - juggernaut ; 3 - shallow
; -
GameState_Ball_bhvrTtl  rs.w 1                  ; behavior Time To Live, at 0 the behavior MUST go back to normal
; -
GameState_Ball_sprOffst rs.w 1                  ; offset to get the right sprite
; -
; -- Glue effect
GameState_Ball_cptvState rs.b 1                 ; @see BALL_CAPTV_FREE, BALL_CAPTV_WAIT_FIRE, BALL_CAPTV_WAIT_RELEASE.
GameState_Ball_cptvSteer rs.b 1                 ; -1 / +1, dx on launch
; -
GameState_Ball_cptvPos  rs.b 1                  ; x pos of the captive ball, relative to the paddle
GameState_Ball_cptvPosT rs.b 1                  ; Target x pos of the captive ball, relative to the paddle. see BALL_POSCAPTV_LEFT, BALL_POSCAPTV_RIGHT
; -
; -- Handling of collected all keys signal
GameState_Level_doneKeys rs.b 1                 ; Set to 1 ('not 0') as soon as the last keys is collected, set to 0 again after scanning the whole level.
GameState_Level_unlckRow rs.b 1                 ; when doneKeys is not 0, the row being scanned for locked bricks, one line of effective unlocking per redraw.
; -
GameState_Level_ptrUnlckCell rs.l 1             ; Pointer to the first cell of the line to scan for unlocking exit bricks.
; -
;
; -- that's all
; FIX EVENNESS
SIZEOF_GameState        rs.b 0
; ================================================================================================================
; ================================================================================================================
; macros
; ================================================================================================================
; Collision list management ; the list is terminated with $ff elements.
; The tricky part : we test the next position first (diagonal), then replace it with whatever other collision point
; that may arise.
; So each at each update :
; * clear the list set (GameState_clearCldList)
; * init a pointer to the first slot of the list
; * test the diagonal, set collision point if appliable (GameState_setCldPoint) (pointer does not move)
; * test other points, push each collision points if appliable (GameState_pushCldPoint) (pointer does move to the next slot)
;
GameState_clearCldList  macro
                        ; fill the collision list with $ff
                        ; 1 - pointer to gamestate
                        ; 2 - Spare address register ; on return will point to the start of the list.
                        ; --
                        lea                     GameState_Ball_cldList(\1),\2
                        rept 6
                        move.b                  #$ff,(\2)+
                        endr
                        subq.l                  #6,\2
                        endm
;
GameState_setCldPoint   macro
                        ; Set/replace a collision point to the collision list ; no termination of the list.
                        ; 1 - address register, ptr to collision list slot
                        ; 2 - data register, x value (byte)
                        ; 3 - data register, y value (byte)
                        ; --
                        move.b                  \2,(\1)
                        move.b                  \3,1(\1)
                        endm
;
;
GameState_pushCldPoint  macro
                        ; Set/replace a collision point in the collision list ; terminate of the list
                        ; 1 - address register, ptr to collision list slot => will point to next slot
                        ; 2 - data register, x value (byte)
                        ; 3 - data register, y value (byte)
                        ; --
                        move.b                  \2,(\1)+
                        move.b                  \3,(\1)+
                        move.b                  #$ff,(\1)
                        endm
;
; ================================================================================================================
GameState_Ball_setBehavior macro
                        ; Set the behavior value and corresponding offset of the sprite to use for the ball.
                        ; 1 - address register, ptr GameState
                        ; 2 - effective value, byte, index of the behavior (0,1,2,3)
                        ; 3 - spare data register
                        ; --
                        move.w                  \2,GameState_Ball_behavior(\1)
                        ; \3 := offset = 32 * \2 = \2 << 5
                        moveq                   #0,\3
                        move.b                  \2,\3
                        lsl.l                   #5,\3
                        move.w                  \3,GameState_Ball_sprOffst(\1)
                        move.w                  #BALL_BEHAVIOR_TTL,GameState_Ball_bhvrTtl(\1)
                        endm
;
GameState_Ball_updateBehavior macro
                        ; If the behaviour is not normal (0), decrease ttl if greater than 0, otherwise reset behavior to normal.
                        ; 1 - address register, const, ptr to GameState.
                        ; 2 - spare data register.
                        ; --
                        ; \2 := current behaviour
                        moveq                   #0,\2
                        move.w                  GameState_Ball_behavior(\1),\2
                        tst.w                   \2
                        ; -- do nothing if normal behavior
                        beq                     .thatsAll\@
                        ; -- else verify ttl
                        ; \2 := current ttl
                        move.w                  GameState_Ball_bhvrTtl(\1),\2
                        tst.w                   \2
                        ; -- reset to normal if ttl 0 or below
                        bls                     .doReset\@
                        ; -- else decrease ttl
                        subq.w                  #1,\2
                        move.w                  \2,GameState_Ball_bhvrTtl(\1)
                        bra                     .thatsAll\@
.doReset\@
                        GameState_Ball_setBehavior \1,#0,\2
.thatsAll\@
                        endm
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
