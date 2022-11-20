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
                        ; -- load palette
                        ; a5 := start of source asset
                        move.l                  #SourceAsset,a5
                        _xos_Setpalette             2(a5)
                        ; -- copy picture to screen
                        ; d0 := logbase
                        _xos_Logbase
                        ; a6 := d0 + 32 to prepare movem
                        move.l                  d0,a6
                        lea                     32(a6),a6
                        ; a5 := start of source asset + 34
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
                        ; === First column
                        ; a5 := start of source asset + 34
                        move.l                  #SourceAsset,a5
                        lea                     34(a5),a5
                        ; -- copy 8 lines x 22 bricks = 176 lines of 8 bytes (16 px)
                        rept 176
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     152(a5),a5
                        endr
                        ; === Second column
                        ; a5 := start of source asset + 34 + 32 lines + 16 px = start + 34 + 32x160 + 8 = start + 5162
                        move.l                  #SourceAsset,a5
                        lea                     5162(a5),a5
                        ; -- copy 8 lines x 12 bricks = 96 lines of 8 bytes (16 px)
                        rept 96
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     152(a5),a5
                        endr

                        ; -- extract the ball
                        ; a6 := start of data buffer for ball
                        move.l                  #DatAssetBall,a6
                        ; a5 := start of source asset + 34 + 16 px + 4 lines = start + 34 + 8 + 4 x 160 = start + 682
                        move.l                  #SourceAsset,a5
                        lea                     682(a5),a5
                        ; -- copy 4 x 4 lines of 8 bytes (16 px)
                        rept 16
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

                        ; -- generate a screen width black line of 1 px
                        ; a6 := start of data buffer
                        move.l                  #DatBlackLine,a6
                        ; -- 20 times 16 black pixels (color #1 -> bits 1,0,0,0 in respective plans)
                        rept 20
                        move.l                  #$ffff0000,(a6)+
                        move.l                  #$00000000,(a6)+
                        endr

                        ; -- visual check
                        ; d0 := logbase
                        _xos_Logbase
                        ; a6 := start of screen
                        move.l                  d0,a6
                        lea                     16000(a6),a6
                        ; a5 := DatAssetBricks
                        move.l                  #DatAssetBricks,a5
                        rept 40
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        lea                     152(a6),a6
                        endr
                        ; -- followed by the balls
                        move.l                  #DatAssetBall,a5
                        rept 16
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
                        ; -- followed by the line
                        move.l                  #DatBlackLine,a5
                        rept 40
                        move.l                  (a5)+,(a6)+
                        endr

                        ; -- save data : bricks
                        _dos_fcreate                #DestAssetSpritesBricks,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#2176,#DatAssetBricks
                        _dos_fclose                 d7
                        ; -- save data : balls
                        _dos_fcreate                #DestAssetSpritesBalls,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi                     thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#128,#DatAssetBall
                        _dos_fclose                 d7
                        ; -- save data : player
                        _dos_fcreate                #DestAssetSpritesPlayer,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.s                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#256,#DatAssetPlayer
                        _dos_fclose                 d7
                        ; -- save data : line
                        _dos_fcreate                #DestAssetSpritesLine,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.s                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#160,#DatBlackLine
                        _dos_fclose                 d7



thatsAll                WaitInp
                        Terminate


;
; ================================================================================================================
SourceAsset:            incbin                  'assets/sprt_wb.pi1'
DestAssetSprites:       dc.b                    "sprt.dat",0
DestAssetSpritesBalls:  dc.b                    "spr_ball.dat",0
DestAssetSpritesBricks: dc.b                    "spr_brck.dat",0
DestAssetSpritesPlayer: dc.b                    "spr_padl.dat",0
DestAssetSpritesLine:   dc.b                    "spr_line.dat",0
DatAssetBricks:         ds.l                    544                     ;34 sprite of 16x8 px = 34 x 2.l x 8 = 544.l
DatAssetBall:           ds.l                    32                      ;4 sprites of 16x4 px = 4 x 2.l x 4 = 32.l
DatAssetPlayer:         ds.l                    64                      ;1 sprite of 64x8  px = 4 x 2.l x 8 = 64.l
DatBlackLine:           ds.l                    40                      ;1 sprite of 320x1 px = 20 x 2.l = 40.l
