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
; Constant macros
; ================================================================================================================
; -- 'Heap POSition' aka memory map of the heap
; Grid : 1200 words = 2400 bytes
HposGridBase            equ                     0
HposGridTop             equ                     2400
; Brick status : 25 bytes
HposBrickBase           equ                     2400
HposBrickTop            equ                     2425
; Freedom bitmap : 500 bytes
HposFreedomBase         equ                     2426
HposFreedomTop          equ                     2926
HposEnd                 equ                     2926


; Data of Sprite sets
DatSprtsBricksBase      equ                     0
DatSprtsBricksTop       equ                     320
DatSprtsBallBase        equ                     320
DatSprtsBallTop         equ                     352
DatSprtsPlayerBase      equ                     352
DatSprtsPlayerTop       equ                     608

;
BlitterBase             equ                     $ffff8a00
BlitterMiscReg1         equ                     $ffff8a3c
;
DoBlitAndWait           macro
                        or.b                    #$80,BlitterMiscReg1.w
.waitFinish\@           bset.b                  #7,BlitterMiscReg1.w
                        nop
                        bne.s                   .waitFinish\@
                        endm

SetupMicrowire          DmaSound_setupMicrowire
                        rts
; ================================================================================================================
; App body
; ================================================================================================================
BodyOfApp:              ; Entry point of the application
                        ; Your code start here...
                        ; ========
                        ; -- call 'before all' of each phase
                        move.l                  #PhsMenuBeforeAll,a2
                        jsr                     (a2)
                        move.l                  #PhsFadeToGameBeforeAll,a2
                        jsr                     (a2)
                        move.l                  #PhsGameBeforeAll,a2
                        jsr                     (a2)
                        move.l                  #PhsFadeToEndBeforeAll,a2
                        jsr                     (a2)
                        ; ========
                        ; -- First phase is 'menu'
                        move.l                  #PhsMenuUpdate,PtrCurrentUpdate
                        move.l                  #PhsMenuUpdate,PtrNextUpdate
                        ; ========
                        move.l                  #PhsMenuRedraw,PtrCurrentRedraw
                        move.l                  #PhsMenuRedraw,PtrNextRedraw
                        ;
                        move.l                  #PhsMenuBeforeEach,a2
                        jsr                     (a2)


PhaseRun:               ; ========
                        IsWaitingKey
                        bne.s                   Finish
                        ; ========
                        move.l                  PtrCurrentUpdate,a2
                        jsr                     (a2)

                        ; ========
                        ; prepare redraw
                        _Logbase
                        move.l                  d0,a5
                        ; ========
                        ; wait vbl
                        _Vsync
                        ; ========
                        move.l                  PtrCurrentRedraw,a2
                        jsr                     (a2)
                        ; ========
                        ; apply next Phase
                        move.l                  PtrNextUpdate,PtrCurrentUpdate
                        move.l                  PtrNextRedraw,PtrCurrentRedraw
                        bra.s                   PhaseRun

Finish:

                        ; ----------------------------------------------------------------
                        ; Your code end there
                        rts

PtrCurrentUpdate        dc.l                    0
PtrCurrentRedraw        dc.l                    0
PtrNextUpdate           dc.l                    0
PtrNextRedraw           dc.l                    0

; ================================================================================================================
; Macros for this app
; ================================================================================================================

ModelToScreenX          macro
                        ; Compute a byte offset (even) and an index (0 to 3) from the x position.
                        ; 1 - value
                        ; 2 - data register to store the offset.
                        ; 3 - data register to store the index
                        ; --
                        ; \2,\3 := x
                        moveq                   #0,\2
                        move.b                  \1,\2
                        move.l                  \2,\3
                        ; \2 := x to byte offset := (16align(4 * x))/2 <=> (4 * 4align(x))/2 <=> 2 * 4align(x)
                        and.w                   #$fffc,\2               ; 4align(x)
                        WdMul2                  \2
                        ; \3 := from x to shift pos (0 to 3, which group of 4 pixels to redraw)
                        and.w                   #$3,\3
                        endm

ModelToScreenY          macro
                        ; Compute a byte offset from the y position
                        ; 1 - value
                        ; 2 - data register to store the result.
                        ; 3 - data register for intermediary computation (previous data will be lost)
                        ; \2 := y
                        moveq                   #0,\2
                        move.b                  \1,\2
                        ; -- from y to offset := y * 4 * 160 <=> y * 4 * 16 * 2 * (4+1) <=> y * 2^7 * (4 + 1)
                        ; \2 := y * 2^7
                        lsl.w                   #7,\2
                        ; \3 := \2 * 4
                        move.w                  \2,\3
                        WdMul4                  \3
                        ; \2 := offset
                        add.w                   \3,\2
                        endm

; ================================================================================================================
                        ;
                        include                 'p_menu.s'              ; Menu phase
                        include                 'p_fdgm.s'              ; Fade to Game phase
                        include                 'p_gm.s'                ; Game phase
                        include                 'p_fend.s'              ; Fade to end (then cycle)

; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; Sprites : bricks (from top to bottom)
; ================================================================================================================
; -- Mask : the same long to repeat
SprMskBrickEven         dc.l                    $00ff00ff
SprMskBrickOdd          dc.l                    $ff00ff00
; -- row 0 - color 10 = %be.1010 = %le.0101 (orange)
SprDtBrickRow0Even      dc.l                    $0000ff00,$0000ff00
SprDtBrickRow0Odd       dc.l                    $000000ff,$000000ff
; -- row 1 - color 15 = %1111 (light yellow)
SprDtBrickRow1Even      dc.l                    $ff00ff00,$ff00ff00
SprDtBrickRow1Odd       dc.l                    $00ff00ff,$00ff00ff
; -- row 2 - color 12 = %be.1100 = %le.0011 (light green)
SprDtBrickRow2Even      dc.l                    $00000000,$ff00ff00
SprDtBrickRow2Odd       dc.l                    $00000000,$00ff00ff
; -- row 3 - color 7 = %be.0111 = %le.1110 (orange)
SprDtBrickRow3Even      dc.l                    $ff00ff00,$ff000000
SprDtBrickRow3Odd       dc.l                    $00ff00ff,$00ff0000
; -- row 4 - color 4 = %be.0100 = %le.0010 (dark blue)
SprDtBrickRow4Even      dc.l                    $00000000,$ff000000
SprDtBrickRow4Odd       dc.l                    $00000000,$00ff0000
; -- no brick - color 1 = %be.0001 = %le.1000 (black)
SprDtNoBrickEven        dc.l                    $ff000000,$00000000
SprDtNoBrickOdd         dc.l                    $00ff0000,$00000000
; ================================================================================================================
; Sprite vector : bricks
SprVcBrickEven          ds.l                    6
SprVcBrickOdd           ds.l                    6
SprPtrArrayBricks       ds.l                    6
;
; ================================================================================================================
SpritesDat0:            dc.l                    $ff000000,$00000000,$ff000000,$00000000,$ff000000,$00000000,$ff000000,$00000000
                        dc.l                    $ff000000,$00000000,$ff000000,$00000000,$ff000000,$00000000,$ff000000,$00000000
SpritesDat:             incbin                  'assets/sprt.dat'
                        even
;
TitleDat:               incbin                  'assets/title.pi1'
                        even
; ================================================================================================================
SndGetReadyBase         incbin                  'assets/s_gtrdy.dat'
                        even
SndGetReadyTop          dc.w                    0
SndOhNoBase             incbin                  'assets/s_ohno.dat'
                        even
SndOhNoTop              dc.w                    0
SndGameOverBase         incbin                  'assets/s_gmovr.dat'
                        even
SndGameOverTop          dc.w                    0
SndYouWonBase           incbin                  'assets/s_yuwon.dat'
                        even
SndYouWonTop            dc.w                    0
