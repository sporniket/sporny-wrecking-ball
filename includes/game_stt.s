; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; ================================================================================================================
; Game state
; ================================================================================================================
                        rsreset
; -- [Game] general state
GameState_score         rs.l 1
GameState_isOver        rs.b 1
GameState_isClear       rs.b 1
GameState_level         rs.b 1
; -- [Ball] state
; position before update
GameState_Ball_x        rs.b 1
GameState_Ball_y        rs.b 1
; next displacement and position -- COLOCALIZED
GameState_Ball_dx       rs.b 1
GameState_Ball_dy       rs.b 1
GameState_Ball_xNext    rs.b 1
GameState_Ball_yNext    rs.b 1
; Half speed management
GameState_Ball_hlfSpd   rs.b 1                  ; half speed flag (1 = half speed mode)
GameState_Ball_hlfPhs   rs.b 1                  ; half speed phase flag (1 = freeze if half speed mode)
GameState_Ball_freeze   rs.b 1                  ; countdown before letting the ball move
GameState_Ball_remning  rs.b 1                  ; remaining balls
; list of collision points
GameState_Ball_cldList  rs.b 6                  ; 2 byte per collision point (row, column), 2 collision points at most, the list terminate with $ff
; -- [Player] state
; Current position
GameState_Player_x      rs.b 1
GameState_Player_y      rs.b 1
GameState_Player_w      rs.b 1
GameState_Player_h      rs.b 1
; Next position
GameState_Player_xNext  rs.b 1
GameState_Player_yNext  rs.b 1
GameState_Player_dx     rs.b 1
GameState_Player_dy     rs.b 1
; width management (not in this version)
GameState_Player_wNext  rs.b 1
GameState_Player_dw     rs.b 1
; -- [Level] state
GameState_Level_cntToErase rs.b 1               ; 0,1 or 2 bricks to erase
; !! MUST BE EVEN !!
GameState_Level_eraseList  rs.b 40              ; buffer, bricks position in the bricks status model (col, row, extends,0,ptr first cell, ptr last cell + 1) , 12 bytes each
; TODO
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
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
