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
;
CopyFromScreenColumn    macro
                        ; copy 8 lines of one column (16 pixels) from screen like memory to buffer
                        ; 1 - address register, source
                        ; 2 - address register, destination
                        ; --
                        rept 8
                        move.l                  (\1)+,(\2)+
                        move.l                  (\1)+,(\2)+
                        lea                     152(\1),\1
                        endr
                        endm
;
CopyToScreenColumn      macro
                        ; copy 16 characters data vertically on screen
                        ; 1 - address register, source cursor
                        ; 2 - address register, destination cursor
                        ; --
                        rept 128 ; 16x8 lines, show 16 chars
                        move.l                  (\1)+,(\2)+
                        move.l                  (\1)+,(\2)+
                        lea                     152(\2),\2
                        endr
                        endm
;
ExtractFontData         macro ; (from,to)
                        ; Extract data from a start point in a memory organized as a screen to destination storage
                        ; 1 - effective address, source start
                        ; 2 - effective address, destination start
                        ; 3 - spare address register
                        ; 4 - spare address register
                        ; 5 - spare address register
                        ; 6 - spare address register
                        ; --
                        ; -- setup source cursor
                        ; \3 := source cursor, starts at \1
                        move.l                  \1,\3
                        ; -- setup destination cursors
                        ; \4 := cursor for chars 0 to 15, starts at \2
                        move.l                  \2,\4
                        ; \5 := cursor for chars 16 to 31, starts at \4 + (16x8x2=1024)
                        lea                     1024(\4),\5
                        ; \6 := cursor for chars 32 to 47, starts at \5 + (16x8x2=1024)
                        lea                     1024(\5),\6
                        ; -- copy
                        rept 16 ; 16 columns
                        CopyFromScreenColumn    \3,\4
                        CopyFromScreenColumn    \3,\5
                        CopyFromScreenColumn    \3,\6
                        ; next column := \3 - 1280x3+8 = \3 - 3832
                        lea                     -3832(\3),\3
                        endr
                        endm
;
VisualCheck             macro
                        ; Display the character set to check the font data
                        ; 1 - effective address, screen start in memory
                        ; 2 - effective address, font data start in memory
                        ; 3 - spare address register
                        ; 4 - spare address register
                        ; --
                        ; \3 := screen start
                        _xos_Logbase
                        move.l                  \1,\3
                        ; \4 := cursor font data
                        move.l                  \2,\4
                        rept 3
                        CopyToScreenColumn      \4,\3
                        lea                     -20472(\3),\3 ; next group of 16 chars
                        endr

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

                        ; -- extract the first font
                        ; a6 := start of source asset + 34
                        move.l                  #SourceAsset,a6
                        lea                     34(a6),a6
                        ; a5 := start of destination buffer
                        move.l                  #DatAssetFont,a5
                        ; a4,a3,a2,a1 : spare address registers
                        ExtractFontData         a6,a5,a4,a3,a2,a1
                        ; -- visual check
                        ; a4 := screen start
                        _xos_Logbase
                        VisualCheck             d0,a5,a4,a3

                        ; -- save data : bricks
                        _dos_fcreate                #DestAssetFont0,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#3072,#DatAssetFont
                        _dos_fclose                 d7
                        WaitInp

                        ; -- extract the next font
                        ; a6 := advance by (8x4=32) screen lines = 160x32=5120
                        lea                     5120(a6),a6
                        ; a4,a3,a2,a1 : spare address registers
                        ExtractFontData         a6,a5,a4,a3,a2,a1
                        ; -- visual check
                        ; a4 := screen start
                        _xos_Logbase
                        VisualCheck             d0,a5,a4,a3

                        ; -- save data : bricks
                        _dos_fcreate                #DestAssetFont1,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#3072,#DatAssetFont
                        _dos_fclose                 d7
                        WaitInp

                        ; -- extract the next font
                        ; a6 := advance by (8x4=32) screen lines = 160x32=5120
                        lea                     5120(a6),a6
                        ; a4,a3,a2,a1 : spare address registers
                        ExtractFontData         a6,a5,a4,a3,a2,a1
                        ; -- visual check
                        ; a4 := screen start
                        _xos_Logbase
                        VisualCheck             d0,a5,a4,a3

                        ; -- save data : bricks
                        _dos_fcreate                #DestAssetFont2,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#3072,#DatAssetFont
                        _dos_fclose                 d7
                        WaitInp

                        ; -- extract the next font
                        ; a6 := advance by (8x4=32) screen lines = 160x32=5120
                        lea                     5120(a6),a6
                        ; a4,a3,a2,a1 : spare address registers
                        ExtractFontData         a6,a5,a4,a3,a2,a1
                        ; -- visual check
                        ; a4 := screen start
                        _xos_Logbase
                        VisualCheck             d0,a5,a4,a3

                        ; -- save data : bricks
                        _dos_fcreate                #DestAssetFont3,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#3072,#DatAssetFont
                        _dos_fclose                 d7
                        WaitInp

                        ; -- extract the next font
                        ; a6 := advance by (8x4=32) screen lines = 160x32=5120
                        lea                     5120(a6),a6
                        ; a4,a3,a2,a1 : spare address registers
                        ExtractFontData         a6,a5,a4,a3,a2,a1
                        ; -- visual check
                        ; a4 := screen start
                        _xos_Logbase
                        VisualCheck             d0,a5,a4,a3

                        ; -- save data : bricks
                        _dos_fcreate                #DestAssetFontMask,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#3072,#DatAssetFont
                        _dos_fclose                 d7


thatsAll                WaitInp
                        Terminate


;
; ================================================================================================================
SourceAsset:            incbin                  'assets/fontset.pi1'
DestAssetFont0:         dc.b                    'font_0.dat',0
DestAssetFont1:         dc.b                    'font_1.dat',0
DestAssetFont2:         dc.b                    'font_2.dat',0
DestAssetFont3:         dc.b                    'font_3.dat',0
DestAssetFontMask:      dc.b                    'font_msk.dat',0
DatAssetFont:           ds.l                    768                     ; 48 sprites of 16x8 px = 48 x 2.l x 8 = 768.l
