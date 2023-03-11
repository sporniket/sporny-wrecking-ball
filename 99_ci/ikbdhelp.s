; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Test suite for ’ikbdhelp.s'
; ================================================================================================================
; Before all
;
                        PrintNewLine
                        PrintHeader             IKBDHELP_messHead
                        bra                     IKBDHELP_test1
IKBDHELP_messHead       dc.b                    "ikbdhelp tests",0
                        even
; ================================================================================================================
; test factory : test enum
IKBDHELP_makeTestEnum   macro
                        ;1 - value to test
                        ;2 - value to compare with
                        ;3 - end of test
                        move.w                  #\1,d0
                        cmp.w                   #\2,d0
                        beq                     .pass_\@
                        PrintFail               .messDesc_\@
                        bra                     .end_\@
.pass_\@                PrintPass               .messDesc_\@ 
                        bra                     .end_\@                       
.messDesc_\@            dc.b                    "\1 = \2",0
                        even
.end_\@                 nop
                        endm
; ================================================================================================================
; test 1 -- Each enum value should have expected value
;
IKBDHELP_test1
                        IKBDHELP_makeTestEnum   IKBD_CMD_,$0
                        IKBDHELP_makeTestEnum   IKBD_CMD_RESET_2,$01
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_ACT,$07
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_REL,$08
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_ABS,$09
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_KCD,$0a
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_THR,$0b
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_SCL,$0c
                        IKBDHELP_makeTestEnum   IKBD_CMD_GT_MS_POS,$0d
                        IKBDHELP_makeTestEnum   IKBD_CMD_LD_MS_POS,$0e
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_Y0B,$0f
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_MS_Y0T,$10
                        PromptForKey

                        IKBDHELP_makeTestEnum   IKBD_CMD_RESUME,$11
                        IKBDHELP_makeTestEnum   IKBD_CMD_MS_OFF,$12
                        IKBDHELP_makeTestEnum   IKBD_CMD_PAUSE,$13
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_JS_EVT,$14
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_JS_ITG,$15
                        IKBDHELP_makeTestEnum   IKBD_CMD_GT_JS,$16
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_JS_MON,$17
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_JS_FBM,$18
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_JS_KCD,$19
                        IKBDHELP_makeTestEnum   IKBD_CMD_JS_OFF,$1a
                        IKBDHELP_makeTestEnum   IKBD_CMD_ST_CLK,$1b
                        IKBDHELP_makeTestEnum   IKBD_CMD_GT_CLK,$1c
                        PromptForKey

                        IKBDHELP_makeTestEnum   IKBD_CMD_LD_MEM,$20
                        IKBDHELP_makeTestEnum   IKBD_CMD_RD_MEM,$21
                        IKBDHELP_makeTestEnum   IKBD_CMD_EXEC,$22
                        IKBDHELP_makeTestEnum   IKBD_CMD_STATUS_BIT,$80
                        IKBDHELP_makeTestEnum   IKBD_CMD_RESET_1,$80
                        PrintNewLine

                        IKBDHELP_makeTestEnum   IkbdString_length,0
                        IKBDHELP_makeTestEnum   IkbdString_firstByte,2
                        IKBDHELP_makeTestEnum   IkbdString_secondByte,3
                        IKBDHELP_makeTestEnum   IkbdString_thirdByte,4
                        IKBDHELP_makeTestEnum   IkbdString_buffer,5
                        IKBDHELP_makeTestEnum   SIZEOF_IkbdString,14
                        IKBDHELP_makeTestEnum   EVENSIZEOF_IkbdString,14
                        PrintNewLine
ENDOF_IKBDHELP_test1


; ================================================================================================================
; test 2 : test of the ikbd string description (offset)
; ================================================================================================================
IKBDHELP_test2
                        ikbd_withString         a6,#.ikbdStrBuffer
                        ikbd_pushFirstByte      a6,#IKBD_CMD_MS_OFF
                        ; then IkbdString_length(a6) == 0
                        moveq           #0,d0
                        move.w          IkbdString_length(a6),d0
                        beq             .lengthIsGood
                        PrintFail       .messDescLength
                        bra             .testByte
.lengthIsGood           PrintPass       .messDescLength
                        ; then IkbdString_firstByte(a6) == IKBD_CMD_MS_OFF
.testByte               move.b          IkbdString_firstByte(a6),d0
                        cmp.b           #IKBD_CMD_MS_OFF,d0
                        beq             .byteIsGood
                        PrintFail       .messDescContent
                        PrintContinue   .messDescContent2
                        ; convert d0 into string and print
                        ; a5 := string buffer
                        lea             strbufIntToAscii,a5
                        jsrA_itoa_appHexUint8   a5,d0
                        PrintContinue   strbufIntToAscii
                        bra             ENDOF_IKBDHELP_test2
.byteIsGood             PrintPass       .messDescContent
                        PrintContinue   .messDescContent2
                        bra             ENDOF_IKBDHELP_test2               
.ikbdStrBuffer          ds.b EVENSIZEOF_IkbdString
.messDescLength         dc.b "IkbdString_firstByte length = 0",0
.messDescContent        dc.b "IkbdString_firstByte byte = ...",0
.messDescContent2       dc.b "...IKBD_CMD_MS_OFF",0
                        even
ENDOF_IKBDHELP_test2    PromptForKey
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
