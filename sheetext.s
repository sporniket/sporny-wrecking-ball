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


;
Terminate               macro
                        ___gemdos               0,0
                        endm

; ================================================================================================================
                        ; -- copy picture to screen
                        ; d0 := logbase
                        _Logbase
                        ; a6 := d0 + 32 to prepare movem
                        move.l                  d0,a6
                        lea                     32(a6),a6
                        ; a5 := start of source asset + 34
                        move.l                  #SourceAsset,a5
                        lea                     34(a5),a5
                        ; -- do the move (visual check)
                        rept 48
                        ; -- copy 32 pixels
                        movem.l                 (a5)+,d0-d7
                        movem.l                 d0-d7,-(a6)
                        lea                     64(a6),a6
                        ; -- copy 32 pixels, next line
                        movem.l                 (a5)+,d0-d7
                        movem.l                 d0-d7,-(a6)
                        lea                     160(a6),a6
                        lea                     96(a5),a5
                        endr

                        ; -- extract the bricks
                        ; a6 := start of data buffer for bricks
                        move.l                  #DatAssetBricks,a6
                        ; a5 := start of source asset + 34 + (offset at 7th column of 16 px = 56) = start + 90
                        move.l                  #SourceAsset,a5
                        lea                     90(a5),a5
                        ; -- copy 8 lines x 5 bricks = 40 lines of 8 bytes (16 px)
                        rept 40
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     152(a5),a5
                        endr

                        ; -- extract the ball
                        ; a6 := start of data buffer for ball
                        move.l                  #DatAssetBall,a6
                        ; a5 := start of source asset + 34 + (offset at 2nd column of 16 px = 8) + (4 lines = 640) = start + 682
                        move.l                  #SourceAsset,a5
                        lea                     682(a5),a5
                        ; -- copy 4 lines of 8 bytes (16 px)
                        rept 4
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     152(a5),a5
                        endr

                        ; -- extract the player
                        ; a6 := start of data buffer for player
                        move.l                  #DatAssetPlayer,a6
                        ; a5 := start of source asset + 34 + (offset at 3rd column of 16 px = 16) = start + 50
                        move.l                  #SourceAsset,a5
                        lea                     50(a5),a5
                        ; -- copy 8 lines of 64 px = 8 lines of 4 columns of 16px (8 bytes per column)
                        rept 8
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     128(a5),a5
                        endr

                        ; -- visual check
                        ; d0 := logbase
                        _Logbase
                        ; a6 := start of screen
                        move.l                  d0,a6
                        lea                     16000(a6),a6
                        ; a5 := DatAssetBricks, followed by the ball
                        move.l                  #DatAssetBricks,a5
                        rept 44
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     152(a6),a6
                        endr
                        ; -- followed by the player
                        move.l                  #DatAssetPlayer,a5
                        rept 8
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     128(a6),a6
                        endr

                        ; -- save data
                        _fcreate                #DestAssetSprites,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.s                   thatsAll
                        ; -- else write data
                        ; d7 := d0
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _fwrite                 d7,#608,#DatAssetBricks
                        _fclose                 d7



thatsAll                WaitInp
                        Terminate


;
; ================================================================================================================
SourceAsset:            incbin                  'assets/sprt_wb.pi1'
DestAssetSprites:       dc.b                    "sprt.dat",0
DatAssetBricks:         ds.l                    80                      ;16x40 px = 2 long words x 40
DatAssetBall:           ds.l                    8                       ;16x4  px = 2 long words x 4
DatAssetPlayer:         ds.l                    64                      ;64x8  px = 4 x 2 long words x 8
