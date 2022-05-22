; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; ================================================================================================================
; Level model
; ================================================================================================================
;
BrickCode_STAR          = $10 ; In binary data level, special bricks code without multitile bits start from this value.
;
BrickType_STAR          = 0
BrickType_KEY           = 1
BrickType_EXIT          = 2
BrickType_GLUE          = 3
BrickType_JUGGERNAUT    = 4
BrickType_SHALLOW       = 5
;
BRICK_TO_SPECIAL_OFFST  = 21 ; The code of special bricks is mul by 2 and added to this to get the first of the 2 tiles brick
BRICK_STAR_TILE_OFFSET  = 20 ; use this to detect a star bricks
;
BRICK_SPROFF_EXIT       = 25 ; base sprite offset of exit bricks
BRICK_SPROFF_EXIT_OFF   = 33 ; base sprite offset of disabled exit bricks
BRICK_DELTA_EXIT_OFF    = 8  ; offset to add/substract to toggle an exit brick.
; ================================================================================================================
                        rsreset
; -- Counters initialized at level initialization
; static counters
Level_CntKeys:          rs.w 1                  ; Count number of keys
Level_CntStars:         rs.w 1                  ; Count number of stars (should be 3 at most)
Level_CntExits:         rs.w 1                  ; Count number of exits (should be 1 at most)
; counters that may be updated while playing
Level_CntBrkabl:        rs.w 1                  ; Count number of breakable bricks (may change in juggernaut mode)
; -- Status counters
Level_CntBroken:        rs.w 1                  ; Count bricks actually broken
Level_CntStarsAct:      rs.w 1                  ; Count of stars broken while active
Level_CntDownFx:        rs.w 1                  ; When a special effect is active, count down before returning to normal.
Level_CrtFx:            rs.w 1                  ; The current special effect (0 : none, 1 : glue, 2 : juggernaut, 3 : shallow)
; current level data (static except Level_CntBrkabl)
Level_Line1:            rs.b 40                 ; 40 encoded chars (1 byte/char)
Level_Line2:            rs.b 40                 ; 40 encoded chars (1 byte/char)
Level_Line3:            rs.b 40                 ; 40 encoded chars (1 byte/char)
Level_Line4:            rs.b 40                 ; 40 encoded chars (1 byte/char)
Level_Bricks:           rs.w 400                ; 10 lines of 40 bricks ([multicell bits | sprite index]/brick)
SIZEOF_Level:           rs.w 0
; ================================================================================================================
; ================================================================================================================
;
Level_incField          macro ; (field offset, this)
                        ; increment one of the field (should be counters) ; load/modify/store.
                        ; 1 - field offset, e.g. Level_CntBrkabl
                        ; 2 - address register, destination (level structure)
                        ; 3 - spare data register
                        ; ---
                        moveq                   #0,\3
                        move.w                  \1(\2),\3
                        addq.w                  #1,\3
                        move.w                  \3,\1(\2)
                        endm
;
;
Level_decField          macro ; (field offset, this)
                        ; decrement one of the field (should be counters) ; load/modify/store.
                        ; 1 - field offset, e.g. Level_CntBrkabl
                        ; 2 - address register, destination (level structure)
                        ; 3 - spare data register
                        ; ---
                        moveq                   #0,\3
                        move.w                  \1(\2),\3
                        subq.w                  #1,\3
                        move.w                  \3,\1(\2)
                        endm
;
;
Level_setField          macro ; (field offset, this, value)
                        ; increment one of the field (should be counters).
                        ; 1 - field offset, e.g. Level_CntBrkabl
                        ; 2 - address register, destination (level structure)
                        ; 3 - effective value (e.g. #3, #symbol, register)
                        ; ---
                        move.w                  \3,\1(\2)
                        endm
;
;
Level_addToField       macro ; (field offset, this, value)
                        ; add a value to the field (should be counters).
                        ; 1 - field offset, e.g. Level_CntBrkabl
                        ; 2 - address register, destination (level structure)
                        ; 3 - effective value (e.g. #3, #symbol, register)
                        ; 4 - spare data register
                        ; ---
                        moveq                   #0,\4
                        move.w                  \1(\2),\4
                        add.w                   \3,\4
                        move.w                  \4,\1(\2)
                        endm
;
;
Level_subToField       macro ; (field offset, this, value)
                        ; substract a value to the field (should be counters).
                        ; 1 - field offset, e.g. Level_CntBrkabl
                        ; 2 - address register, destination (level structure)
                        ; 3 - effective value (e.g. #3, #symbol, register)
                        ; 4 - spare data register
                        ; ---
                        moveq                   #0,\4
                        move.w                  \1(\2),\4
                        sub.w                   \3,\4
                        move.w                  \4,\1(\2)
                        endm
;
;
Level_addqToField       macro ; (field offset, this, value)
                        ; add a small value (addq compatible) to the field (should be counters).
                        ; 1 - field offset, e.g. Level_CntBrkabl
                        ; 2 - address register, destination (level structure)
                        ; 3 - litteral value (e.g. 3)
                        ; 4 - spare data register
                        ; ---
                        moveq                   #0,\4
                        move.w                  \1(\2),\4
                        addq.w                  #\3,\4
                        move.w                  \4,\1(\2)
                        endm
;
;
Level_subqToField       macro ; (field offset, this, value)
                        ; substract a small value (subq compatible) to the field (should be counters).
                        ; 1 - field offset, e.g. Level_CntBrkabl
                        ; 2 - address register, destination (level structure)
                        ; 3 - litteral value (e.g. 3)
                        ; 4 - spare data register
                        ; ---
                        moveq                   #0,\4
                        move.w                  \1(\2),\4
                        subq.w                  #\3,\4
                        move.w                  \4,\1(\2)
                        endm
;

; Loading v0 : simple copy and counting
Level_init_v0           macro ; (from,this)
                        ; 1 - address register, source
                        ; 2 - address register, destination (level structure)
                        ; 3 - spare address register
                        ; 4 - spare data register
                        ; 5 - spare data register
                        ; 6 - spare data register
                        ; 7 - spare data register
                        ; 8 - spare data register
                        ; 9 - spare data register
                        ; --
                        ; -- Reset the level
                        ; \3 := the level
                        move.l                  \2,\3
                        rept 5
                        move.l                  #0,(\3)+
                        endr
                        ; \3 := next brick to setup
                        lea                     Level_Bricks(\2),\3
                        ; -- init all spare data registers
                        moveq                   #0,\4
                        moveq                   #0,\5
                        moveq                   #0,\6
                        ; \4 := loop over 10 times (lines)
                        move.w                  #9,\4
.nextLine\@:
                        ; -- compute base index for normal bricks
                        ; \5 := base index
                        cmp.w                   #5,\4
                        ; -- if line is 0 to 4, use the counter directly
                        bmi.s                   .useCounterAsBaseIndex\@
                        ; -- else use (9 - counter) i.e. 4 down to 0
                        move.w                  #9,\5
                        sub.w                   \4,\5
                        bra.s                   .computeBaseIndex\@
.useCounterAsBaseIndex\@
                        move.w                  \4,\5
.computeBaseIndex\@
                        ; for each normal brick color, there is 4 sprites to accomodate multicell bits combinations.
                        WdMul4                  \5
                        ; --
                        ; \6 := loop over 40 times (cells)
                        move.w                  #39,\6
.nextCell\@
                        ; \7 := next value
                        moveq                   #0,\7
                        move.b                  (\1)+,\7
                        ; \8 := reset
                        moveq                   #0,\8
                        ; do stuff...
                        tst.b                   \7
                        ; -- if empty cell
                        beq.s                   .writeCell\@
                        ; -- else
                        ; \8 := multicell bits
                        move.b                  \7,\8
                        and.b                   #%11,\8
                        ; \7 := cell type
                        lsr.b                   #2,\7
                        btst.b                   #1,\8
                        ; -- skip if not start of brick
                        beq                     .notStartOfBrick\@
                        Level_incField          Level_CntBrkabl,\2,\9
                        ; TODO count other things
.notStartOfBrick\@
                        cmp.b                   #BrickCode_STAR,\7
                        ; -- if basic brick
                        bmi.s                   .basicBrick\@
                        ; -- else if star brick
                        beq.s                   .starBrick\@
                        ; -- else other special brick
                        ; \7 := sprite index = 2*type + offset + multicell bit 0
                        sub.w                   #BrickCode_STAR,\7
                        ; \9 := save \7 for special handling
                        moveq                   #0,\9
                        move.w                  \7,\9
                        WdMul2                  \7
                        add.w                   #21,\7
                        btst.b                  #0,\8
                        beq.s                   .writeCell\@
                        ; -- consume \9 to update counters for keys and exits
                        cmp.w                   #BrickType_KEY,\9
                        bne                     .notKeyBrick
                        Level_incField          Level_CntKeys,\2,\9
                        bra                     .doneCountingSpecialBricks
.notKeyBrick
                        cmp.w                   #BrickType_EXIT,\9
                        bne                     .doneCountingSpecialBricks
                        Level_incField          Level_CntExits,\2,\9
.doneCountingSpecialBricks
                        addq.b                  #1,\7
                        bra.s                   .writeCell\@
                        ;
.starBrick\@
                        ; \7 := sprite index = 2*type
                        ;BtMul2                  \7
                        addq.b                  #5,\7
                        Level_incField          Level_CntStars,\2,\9
                        bra.s                   .writeCell\@
.basicBrick\@
                        ; \7 := sprite index = base index + multicell bits
                        move.w                  \5,\7
                        or.b                    \8,\7
                        addq.w                  #1,\7
.writeCell\@
                        move.b                  \8,(\3)+                ; multicell bits
                        move.b                  \7,(\3)+                ; sprite index
                        dbf.s                   \6,.nextCell\@
                        ; end of line...
                        dbf.s                   \4,.nextLine\@
                        endm
; ================================================================================================================
Level_init_disableBricks macro
                        ; visually convert exit bricks to disabled bricks
                        ; 1 - pointer to level
                        ; 2 - spare address register
                        ; 3 - spare data register
                        ; 4 - spare data register
                        ; 5 - spare data register
                        ; 6 - spare data register
                        ; --
                        ; \2 := pointer to bricks
                        lea                     Level_Bricks(\1),\2
                        ; loop 400 times over \3
                        moveq                   #0,\3
                        move.w                  #399,\3
                        ; clear \4, \5, \6
                        moveq                   #0,\4
                        moveq                   #0,\5
                        moveq                   #0,\6
.nextBrick\@
                        ; \4 := brick value to update (or not) = [multicell bits | sprite index]
                        move.w                  (\2),\4
                        ; \5 := sprite index
                        move.b                  1(\2),\5
                        ; \6 := bit #0 of multicell bits
                        move.b                  (\2),\6
                        and.b                   #1,\6
                        ; \5 := correct sprite index for opening of special bricks = \5 - \6
                        sub.b                   \6,\5
                        cmp.b                   #BRICK_SPROFF_EXIT,\5
                        ; -- skip if it is not the base index of exit bricks
                        bne                     .notExitBrick\@
                        ; -- else replace sprite index (add 8)
                        ; \4 := add BRICK_DELTA_EXIT_OFF
                        add.w                   #BRICK_DELTA_EXIT_OFF,\4
                        move.w                  \4,(\2)
.notExitBrick\@
                        addq.l                  #2,\2
                        dbf                     \3,.nextBrick\@
                        endm
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
