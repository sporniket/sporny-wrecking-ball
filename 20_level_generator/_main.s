; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
                        opt d+
; converts the included level set descriptor (basically a markdown file following some rules
; , see file format description) into a set of binary blobs to be included in the source of the game.
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
                        _xos_ikbdws                 1, ikbdMsOffJoyOn
                        endm
;
MouseOn                 macro
                        _xos_ikbdws                 1, ikbdJoyOnMsOnRel
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
;
;
SetupAbnormalTerm       macro
                        move.l                  #HastilyTerminateHandler,-(sp)
                        move.w                  #258,-(sp)
                        ___bios                 5,8
                        endm

;
U8ToAsciiPad0           macro
                        ; convert an unsigned byte value into a sequence of 3 ascii chars to be printed added to a string
                        ; of characters. Not optimized for when value/quotient is zero.
                        ; 1 - value to convert
                        ; 2 - address register, ptr to working buffer, MUST be at least 3 bytes long
                        ; 3 - address register, ptr to destination buffer, MUST be at least 3 bytes long. Will point a the end after macro
                        ; 4 - spare address register
                        ; 5 - spare data register
                        ; 6 - spare data register
                        ; 7 - spare data register
                        ; --
                        ; /4 := cursor at working buffer
                        move.l                  \2,\4
                        ; /5 := divisor
                        moveq                   #0,\5
                        move.w                  #10,\5
                        ; /6 := start with value
                        moveq                   #0,\6
                        move.b                  \1,\6
                        ; /7 := loop downcounter for 3 digit
                        moveq                   #2,\7
.nextDigitCompute\@
                        divu                    \5,\6
                        ; -- get,convert and push remainder into working buffer
                        swap                    \6
                        add.b                   #$30,\6
                        move.b                  \6,(\4)+
                        ; -- clean the remainder and get back to the quotient
                        sub.b                   \6,\6
                        swap                    \6
                        ; -- default (not 0)
                        dbf                     \7,.nextDigitCompute\@
.copyToDest\@
                        rept 3
                        move.b                  -(\4),(\3)+
                        endr
                        endm
;
; ================================================================================================================
SIZEOF_LvlHandlr_TxtDat = 160 ; size of textual data.
SIZEOF_LvlHandlr_BrkDat = 400 ; size of brick data.
; ================================================================================================================
                        ; -- Init
                        MouseOff
                        SetupAbnormalTerm
                        Print                   messCls
                        ; -- prepare to call parser
                        ; LvlParser_parse(ptr streamStart, ptr streamEnd, ptr levelHandler,ptr charQualMap,ptr charMap,ptr dataLevel, ptr charToBrickMap)
                        ; @param streamStart : start of the byte stream to parse (included).
                        ; @param streamEnd : end of the byte stream (excluded).
                        ; @param levelHandler : subroutine to jump to when one level data is completely parsed
                        ; @param charQualMap : mapping source byte -> char qualifier (byte), see 'character qualifier'
                        ; @param charMap : the transcoding map to encode ascii chars into ingame text data.
                        ; @param dataLevel : start ptr to the level data. Basically 4x42 bytes of encoded text data followed by 400 bytes of brick layout.
                        ; @param charToBrickMap : map to convert character to normalized brick code.
                        ; --
                        move.l                  #LvlParser_MAP_BRICKS,-(sp)
                        move.l                  #buffParsedLevelData,-(sp)
                        move.l                  #LvlParser_MAP_CHAR,-(sp)
                        move.l                  #LvlParser_MAP_CHAR_QUAL,-(sp)
                        move.l                  #dumpDataInFile,-(sp)
                        move.l                  #SourceAssetTop,-(sp)
                        move.l                  #SourceAsset,-(sp)
                        bsr                     LvlParser_parse
                        lea                     28(sp),sp
                        ; --

thatsAll                Print                   messThatsAll
                        WaitInp
                        MouseOn
                        Terminate

;
;
; ================================================================================================================
; Termination on error handler.
HastilyTerminateHandler:
                        MouseOn
                        rts

;
; ================================================================================================================
; Level data handler.
dumpDataInFile:         ; dumpDataInFile(data)
                        ; Save the level data into a file, the name has a numerical suffix that is incremented at
                        ; each call
                        ; @param data ptr to the level data to handle.
                        ; --
                        ; -- compute file name
                        ; a6 := filename
                        lea                     messLvlFileName,a6
                        ; a5 := ptr to the sequence number of the filename
                        lea                     5(a6),a5
                        ; a4 := ptr to working buffer for converting index to string
                        lea                     buffU8ToAsciiPad0,a4
                        ; d7 := counter value
                        moveq                   #0,d7
                        move.b                  lvlHandlr_Counter,d7
                        ; a3,d6,d5,d4 : spare data registers
                        U8ToAsciiPad0           d7,a4,a5,a3,d6,d5,d4
                        ; -- update counter
                        addq.b                  #1,d7
                        move.b                  d7,lvlHandlr_Counter
                        ; -- save data into filename
                        ; a5 := ptr to data
                        move.l                  4(sp),a5
                        lea                     LvlParser_Data_Text(a5),a5
                        ; a4 := ptr to brick data
                        lea                     SIZEOF_LvlHandlr_TxtDat(a5),a4
                        ; -- save data : bricks
                        _dos_fcreate                a6,#0
                        tst.l                   d0
                        ; -- if (d0 < 0) error
                        bmi.w                   thatsAll
                        ; -- else write data
                        ; d7 := d0 (file handler)
                        moveq                   #0,d7
                        move.w                  d0,d7
                        _dos_fwrite                 d7,#SIZEOF_LvlHandlr_BrkDat,a4
                        _dos_fwrite                 d7,#SIZEOF_LvlHandlr_TxtDat,a5
                        _dos_fclose                 d7
                        ; -- print success
                        Print                   messDidSave
                        Print                   messLvlFileName
                        Print                   messNewLine
                        ; -- done
                        rts


.error
                        Print                   messCannotSave
                        Print                   messLvlFileName
                        Print                   messNewLine
                        ; -- done
                        rts
;
; ================================================================================================================
; Parser lib
                        include                 'libs/lvl_pars.s'
; ================================================================================================================
; Level data handler context.
lvlHandlr_Counter       dc.b                    0
messLvlFileName         dc.b                    "wblv_xxx.dat",0
buffU8ToAsciiPad0       ds.b                    4
messDidSave             dc.b                    "Saved data into ",0
messCannotSave          dc.b                    "Cannot save data into ",0
                        even
;
; ================================================================================================================
; Test save handler.
TestLevelData           dc.b                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras ante tortor, sodales at vehicula in, bibendum ut risus. Sed in lorem eu massa elementum egestas. Proin quis justo in mi maximus bibendum. Vivamus ex arcu, porta non hendrerit sed, accumsan vel lectus. Nulla sed pretium ante. Nunc nec orci tincidunt, euismod elit ut, cursus neque. Aliquam eu diam tellus. Cras eget risus molestie, accumsan nisi non, egestas nibh. Aliquam eget nunc quis neque aliquet aliquet vitae in neque. Morbi malesuada lorem et ligula mattis efficitur. Morbi iaculis, est id mollis cursus, augue quam malesuada proin.",0
                        even
; ================================================================================================================
; Source of the builtins levels
SourceAsset:            incbin                  'assets/lvl_src.md'
SourceAssetTop:
                        even
;
; ================================================================================================================
; Buffer to save system palette and restore after all
buffParsedLevelData     ds.b                    SIZEOF_LvlParser_Data
                        even
;
; ================================================================================================================
; messages
messCls:                dc.b                    27,"E",0
messNewLine:            dc.b                    10,13,0
messThatsAll:           dc.b                    "Done. Press any key.",0
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
