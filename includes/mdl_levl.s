; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; ================================================================================================================
; Level model
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
Level_RmnKeys:          rs.w 1                  ; Track count of remaining keys
Level_RmnStars:         rs.w 1                  ; Track count of remaining stars
Level_CntStarsAct:      rs.w 1                  ; Count of stars broken while active
Level_CntDownFx:        rs.w 1                  ; When a special effect is active, count down before returning to normal.
Level_CrtFx:            rs.w 1                  ; The current special effect (0 : none, 1 : glue, 2 : juggernaut, 3 : shallow)
; current level data (static except Level_CntBrkabl)
Level_Line1:            rs.b 40                 ; 40 encoded chars (1 byte/char)
Level_Line2:            rs.b 40                 ; 40 encoded chars (1 byte/char)
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
                        bmi.s                   .useCounterAsBaseIndex\@
                        move.w                  #9,\5
                        sub.w                   \4,\5
                        bra.s                   .computeBaseIndex\@
.useCounterAsBaseIndex\@
                        move.w                  \4,\5
.computeBaseIndex\@
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
                        ; -- if null
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
                        cmp.b                   #$10,\7
                        ; -- if basic brick
                        bmi.s                   .basicBrick\@
                        ; -- else if star brick
                        beq.s                   .starBrick\@
                        ; -- else other special brick
                        ; \7 := sprite index = 2*type + multicell bit 0
                        sub.w                   #$10,\7
                        WdMul2                  \7
                        add.w                   #21,\7
                        btst.b                  #0,\8
                        beq.s                   .writeCell\@
                        addq.b                  #1,\7
                        bra.s                   .writeCell\@
                        ;
.starBrick\@
                        ; \7 := sprite index = 2*type
                        ;BtMul2                  \7
                        addq.b                  #5,\7
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
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
