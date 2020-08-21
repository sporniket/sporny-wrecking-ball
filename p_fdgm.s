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
; Phase : Fade to Game
; ---
; This phase fills the screen with black 8x8 blocs as in a grid of 40x25=1000 cells, from top to bottom, with
; randomness. And also fills the top 5 lines with colored blocs being the bricks (=125 cells)
;
; Each vbl, 20 new blocs are displayed. The shuffle is done as following:
; ---
;begin
;  grid := reserve[1125]
;  for index := 0 to 1125
;    grid[index] := index
;  next index
;  index_min := 0
;  time_to_display := 4
;  while index_min <= 1109 //more than 15 elements remaining
;    rnd := xbios(?) //24bits random value, use 4bits at a time
;    for tmp :=0 to 5
;      index_swap := rnd & $F
;      index_swap := index_swap + index_min
;
;      tmp_val := grid[index_min]
;      grid[index_min] := grid[index_swap]
;      grid[index_swap] := tmp_val
;
;      rnd := rnd >> 4
;      index_min := index_min + 1
;
;    next tmp
;
;    time_to_display := time_to_display - 1
;    if time_to_display = 0
;      exec display
;      time_to_display := 4
;    endif
;  loop

;  rnd := xbios(?)
;  for tmp := 0 to 7
;    //swap the next 8 elements using 3bits of rnd per iteration
;  next tmp
;
;  while not_finished_to_display
;    exec display
;  loop
;end
; ---
; The random sequence will be kept for reuse
;
; ---
; ================================================================================================================
; ----------------------------------------------------------------------------------------------------------------
; before all
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToGameBeforeAll:
                        ; -- Init grid memory settings
                        move.l                  MmHeapBase,a6
                        move.l                  a6,GridPtrBase
                        lea                     HposGridTop(a6),a5
                        move.l                  a5,GridPtrTop
                        ; -- Init all cursors and work pointers
                        move.l                  a6,PtrInit
                        move.w                  #0,CrsInit
                        move.l                  a6,PtrShuffle
                        move.l                  GridSize,d7
                        move.w                  d7,CrsShuffle        ; no shuffle for now
                        rts
; ----------------------------------------------------------------------------------------------------------------
; before each
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToGameBeforeEach:
                        ; -- Init display cursor and pointers only
                        move.l                  GridPtrBase,a6
                        move.l                  a6,PtrShow
                        move.w                  #0,CrsShow
                        ; -- init Fade is Running
                        move.w                  #1,FadeIsRunning
                        rts
; ----------------------------------------------------------------------------------------------------------------
; update
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToGameUpdate:
                        ; ======== ======== ======== ========
                        ; d7 := grid size
                        move.l                  GridSize,d7
                        ; ========
                        ; -- Task : init cell values
                        ; d6 := next cell
                        move.w                  CrsInit,d6
                        cmp.w                   d7,d6
                        bhs.s                   .doShuffle
                        ; ========
                        ; a6 := Ptr to the next cell
                        move.l                  PtrInit,a6
                        ; d5 := next raw value
                        moveq                   #0,d5
                        move.b                  InitNextRow,d5
                        ; d4 := next cell value, put raw in high byte.
                        move.w                  d5,d4
                        lsl.w                   #8,d4
                        ; d3 := loop counter
                        move.w                  #39,d3
                        ; ========
.initNextCell
                        move.w                  d4,(a6)+
                        addq.w                  #1,d4
                        addq.w                  #1,d6                   ; update cursor
                        dbf.s                   d3,.initNextCell
                        ; ========
                        ; -- update cursor and pointer
                        move.l                  a6,PtrInit
                        move.w                  d6,CrsInit
                        ; ========
                        ; -- Prepare next row
                        cmp.b                   #24,d5
                        beq.s                   .setLevelBit
                        addq.b                  #1,d5
                        bra.s                   .doUpdateNextRow
.setLevelBit            move.b                  #$20,d5
.doUpdateNextRow        move.b                  d5,InitNextRow
                        ; ========
                        ; ========
                        ; ======== ======== ======== ========
                        ; -- Task : shuffle cell values
.doShuffle
                        move.w                  CrsShuffle,d6
                        cmp.w                   d7,d6
                        bhs.s                   .doCheckCompletion
                        nop
                        ; ========
                        ; ========
                        ; ======== ======== ======== ========
                        ; -- Task : verify display advance
.doCheckCompletion
                        move.w                  CrsShow,d6
                        cmp.w                   d7,d6
                        blo.s                   .thatsAll
                        ; -- To the next phase...
                        move.w                  #0,FadeIsRunning
                        move.l                  #PhsFadeToGameAfterEach,a2
                        jsr                     (a2)
                        move.l                  #PhsGameBeforeEach,a2
                        jsr                     (a2)
                        move.l                  #PhsGameUpdate,PtrNextUpdate
                        move.l                  #PhsGameRedraw,PtrNextRedraw
                        ; ========
                        ; ========
                        ; ========
.thatsAll               ; ========
                        rts
; ----------------------------------------------------------------------------------------------------------------
; redraw
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToGameRedraw:
                        ; ======== ======== ======== ========
                        ; -- check if it is meaningful
                        move.w                  FadeIsRunning,d7
                        tst.w                   d7
                        beq.w                   .thatsAll
                        ; -- proceed
                        ; a6 := Ptr to next cell
                        move.l                  PtrShow,a6
                        ; d7 := grid size
                        move.l                  GridSize,d7
                        ; d6 := next cell index
                        move.w                  CrsShow,d6
                        ; d5 := loop counter
                        move.w                  #9,d5
                        ; ========
.drawNextCell
                        ; d4 := next cell value
                        move.w                  (a6)+,d4
                        ; ========
                        ; d3 := column pair -> memory screen offset
                        moveq                   #0,d3
                        move.b                  d4,d3                   ; cell column...
                        and.b                   #$fe,d3                 ; ...rounded at even (= index pair of cell *2)
                        add.w                   d3,d3                   ; ...*2 again (=index pair of cells *4)
                        add.w                   d3,d3                   ; ...*2 again (=index pair of cells *8)
                        ; a4 := Ptr to target memory screen
                        move.l                  a5,a4
                        lea                     0(a4,d3),a4
                        ; ========
                        ; d3 := row * line offset
                        move.w                  d4,d3
                        and.w                   #$1f00,d3               ; keep row value without its bit 5
                        lsr.w                   #5,d3                   ; first line = row value * 8 = lsr 8 * lsl 3
                        mulu.b                  #160,d3                 ; done
                        ; -- update a4
                        lea                     0(a4,d3),a4
                        ; ========
                        btst.w                  #0,d4                   ; odd or even column ?
                        bne.s                   .drawOddCell
                        ; -- else draws even cell
                        ; d3 := loop counter
                        move.w                  #7,d3
                        ; ========
                        ; d2 := offset 'no brick' = indeg 5 * 4 = 20
                        moveq                   #20,d2
                        btst.w                  #13,d4                  ; is it not a brick row ?
                        beq.s                   .setupSprBrickEven     ; not a brick
                        ; -- else it's a brick
                        ; d2 := cell value, clear the bit 5 of, to row * 4 = displacement from vector start
                        move.w                  d4,d2
                        and.w                   #$1f00,d2
                        lsr.w                   #6,d2
.setupSprBrickEven      ; ========
                        ; a2 := Ptr to sprite data
                        DerefOffPtrToPtr        SprVcBrickEven,a2,d2
                        ; d2 := bitplan 0,1
                        move.l                  (a2)+,d2
                        ; d1 := bitplan 2,3
                        move.l                  (a2)+,d1
                        ; d0 := mask
                        move.l                  SprMskBrickEven,d0
                        ; ========
.drawNextLineEvBrsh     ; -- bitplan 0,1
                        and.l                   d0,(a4)
                        or.l                    d2,(a4)+
                        ; -- bitplan 2,3
                        and.l                   d0,(a4)
                        or.l                    d1,(a4)+
                        lea                     152(a4),a4              ; next line
                        dbf.s                   d3,.drawNextLineEvBrsh
                        bra.s                   .doneDrawingCell
                        ; ========
.drawOddCell            ; d3 := loop counter
                        move.w                  #7,d3
                        ; ========
                        ; a2 := Sprite vector
                        ; d2 := offset 'no brick' = index 5 * 4 = 20
                        moveq                   #20,d2
                        btst.w                  #13,d4                  ; is it not a brick row ?
                        beq.s                   .setupSprBrickOdd       ; not a brick
                        ; -- else it's a brick
                        ; d2 := cell value, clear the bit 5 of, to row * 4 = displacement from vector start
                        move.w                  d4,d2
                        and.w                   #$1f00,d2
                        lsr.w                   #6,d2
.setupSprBrickOdd      ; ========
                        ; a2 := Ptr to sprite data
                        DerefOffPtrToPtr        SprVcBrickOdd,a2,d2
                        ; d2 := bitplan 0,1
                        move.l                  (a2)+,d2
                        ; d1 := bitplan 2,3
                        move.l                  (a2)+,d1
                        ; d0 := mask
                        move.l                  SprMskBrickOdd,d0
                        ; ========
.drawNextLineOdBrsh     ; -- bitplan 0,1
                        and.l                   d0,(a4)
                        or.l                    d2,(a4)+
                        ; -- bitplan 2,3
                        and.l                   d0,(a4)
                        or.l                    d1,(a4)+
                        lea                     152(a4),a4              ; next line
                        dbf.s                   d3,.drawNextLineOdBrsh
                        ; ========
.doneDrawingCell        ; update counter
                        addq.w                  #1,d6
                        dbf.s                   d5,.drawNextCell
                        ; ========
                        ; -- save counter and pointer
                        move.w                  d6,CrsShow
                        move.l                  a6,PtrShow
                        ; ========
.thatsAll:
                        rts
; ----------------------------------------------------------------------------------------------------------------
; after each
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToGameAfterEach:
                        rts
; ----------------------------------------------------------------------------------------------------------------
; after all
; ----------------------------------------------------------------------------------------------------------------
PhsFadeToGameAfterAll:
                        rts

; ================================================================================================================
; Model
; ================================================================================================================
FadeIsRunning           dc.w                    1                       ; set to 1 to go to game phase
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; Grid model : [PtrBase...]PtrTop ; array of words ; size = 40*(25 + 5) = 1000 + 200 = 1200 cells
; each cell : [Row|Col] with 
; * Row : ..XRRRRR ; X : 0=> black, 1 => brick ; R : X ? [0...]4 : [0...]25
; * Col : [0...]40
; ================================================================================================================
GridPtrBase             dc.l                    0
GridPtrTop              dc.l                    0                       ; usefull ?
GridSize                dc.l                    1200
; ================================================================================================================
; Cursors on the grid
; ================================================================================================================
CrsInit                 dc.w                    0                       ; Fill with the codified cell value
CrsShuffle              dc.w                    0                       ; Swap with another cell to shuffle
CrsShow                 dc.w                    0                       ; Display the cell
; ================================================================================================================
; Ptr on the grid to go back to work
; ================================================================================================================
PtrInit                 dc.l                    0
PtrShuffle              dc.l                    0
PtrShow                 dc.l                    0
; ================================================================================================================
; Working data of init
; ================================================================================================================
InitNextRow             dc.b                    0                       ; Init fills row by row
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
                        even
