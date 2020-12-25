; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; generate a template for a font set, in order to save a reference pi1 to edit with a painting program
; (Degas, Deluxe Paint etc...)
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
; ================================================================================================================
; Input macros
MouseOff                macro
                        _ikbdws                 1, ikbdMsOffJoyOn
                        endm
;
MouseOn                 macro
                        _ikbdws                 1, ikbdJoyOnMsOnRel
                        endm
;
Print                   macro
                        pea                     \1
                        ___gemdos               9,6
                        endm
;
Terminate               macro
                        ___gemdos               0,0
                        endm

; ================================================================================================================
                        ; -- load palette
                        MouseOff
                        ; -- setup palette
                        SaveSysPalette          BufferSysPalette
                        ; a5 := start of source asset
                        move.l                  #SourceAsset,a5
                        _Setpalette             2(a5)
                        ; -- output font set template
                        Print                   messCls
                        rept 4
                        Print                   CharMap
                        Print                   messNewLine
                        endr
                        WaitInp
                        ; -- that's all
                        ; -- copy screen to picture
                        ; d0 := logbase
                        _Logbase
                        ; a6 := d0 = movem source
                        move.l                  d0,a6
                        ; a5 := start of source asset + 34 + 32 = movem destination
                        lea                     66(a5),a5
                        ; -- do the movem for 32000 byte = 8000 long word = 1000 movem of 8 registers
                        rept 1000
                        ; -- copy 32 pixels
                        movem.l                 (a6)+,d0-d7
                        movem.l                 d0-d7,-(a5)
                        lea                     64(a5),a5
                        endr

                        ; -- visual check
                        ; d0 := logbase
                        _Logbase
                        ; a6 := start of screen
                        move.l                  d0,a6
                        lea                     20480(a6),a6
                        ; a5 := DatAssetBricks + 34
                        move.l                  #SourceAsset,a5
                        lea                     34(a5),a5
                        ; -- output the first item of the font set (32 lines of graphics)
                        rept 1280
                        move.l                  (a5)+,(a6)+
                        move.l                  (a5)+,(a6)+
                        endr

                        ; -- save data : bricks
                        _fcreate                #DestFontAsset,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _fwrite                 d7,#32066,#SourceAsset
                        _fclose                 d7

thatsAll                WaitInp
                        RestoreSavedPalette     BufferSysPalette
                        MouseOn
                        Terminate


;
; ================================================================================================================
; Sample pi1 : the picture data will be replaced, use a file having the target palette.
SourceAsset:            incbin                  'assets/sprt_wb.pi1'
DestFontAsset:          dc.b                    "fontset.pi1",0
; the characters that constitute the font will be printed on screen.
; 16 chars per line, one char per group of 16 pixels
CharMap:                dc.b                    "0 1 2 3 4 5 6 7 8 9 A B C D E F",10,13
                        dc.b                    "G H I J K L M N O P Q R S T U V",10,13
                        dc.b                    "W X Y Z   . ! ? , - ",$22," ' ( ) / @",10,13
                        dc.b                    0
                        even
;
; ================================================================================================================
; Buffer to save system palette and restore after all
BufferSysPalette        ds.w                    16                      ;Buffer for system palette
;
; ================================================================================================================
; messages
messCls:                dc.b                    27,"E",0
messNewLine:            dc.b                    10,13,0
;
; ================================================================================================================
; Ikbd instructions for ikbdws, see the Atari compendium
ikbdMsOffJoyOff:        dc.b                    $12, $1a                ; byte count = 2 - 1 = 1
ikbdMsOffJoyOn:         dc.b                    $12, $14                ; byte count = 2 - 1 = 1
ikbdJoyOnMsOnRel:       dc.b                    $14, $08                ; byte count = 2 - 1 = 1
                        even

DestAssetSprites:       dc.b                    "sprt.dat",0
DestAssetSpritesBalls:  dc.b                    "spr_ball.dat",0
DestAssetSpritesBricks: dc.b                    "spr_brck.dat",0
DestAssetSpritesPlayer: dc.b                    "spr_padl.dat",0
DestAssetSpritesLine:   dc.b                    "spr_line.dat",0
DatAssetBricks:         ds.l                    544                     ;34 sprite of 16x8 px = 34 x 2.l x 8 = 544.l
DatAssetBall:           ds.l                    32                      ;4 sprites of 16x4 px = 4 x 2.l x 4 = 32.l
DatAssetPlayer:         ds.l                    64                      ;1 sprite of 64x8  px = 4 x 2.l x 8 = 64.l
DatBlackLine:           ds.l                    40                      ;1 sprite of 320x1 px = 20 x 2.l = 40.l
