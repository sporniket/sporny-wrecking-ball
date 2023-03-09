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
; test 1
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
ENDOF_IKBDHELP_test1


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
; ================================================================================================================
; ================================================================================================================
