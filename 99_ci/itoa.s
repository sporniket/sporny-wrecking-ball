; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Test suite for itoa.s'
; ================================================================================================================
; Before all
;
                        PrintNewLine
                        PrintHeader             ITOA_messHead
                        bra                     ITOA_test1
ITOA_messHead           dc.b                    "itoa tests",0
                        even

; ================================================================================================================
; test factory : test enum
ITOA_makePrintHexFromByte macro
                        ; 1 - address register to use
                        ; 2 - data register to use
                        ; 3 - value to print
                        ; 4 - expected string
                        ; 5 - second address register to use for comparaison
                        ; ---
                        ; prepare
                        ;
                        ; \1 : strbuf
                        lea .strbuf_\@,\1
                        ; \2 : value
                        moveq #0,\2
                        move.b \3,\2
                        ; ---
                        ; execute
                        ;
                        jsrA_itoa_appHexUint8   \1,\2
                        ; ---
                        ; verify
                        ;
                        lea .strbuf_\@,\1
                        lea .strexpected_\@,\5 
.compare_\@             move.b  (\1)+,\2
                        cmp.b   (\5)+,\2
                        beq     .sameChar_\@
                        ; ---
                        ; failed
                        PrintFail       .messDesc_\@
                        PrintContinue2  .messGot_\@,.strbuf_\@
                        bra             .end_\@
                        ; --- 
                        ; repeat until end of string
.sameChar_\@            tst.b   \2
                        beq     .pass_\@
                        bra     .compare_\@ ; next
                        ; ---
                        ; pass
.pass_\@                PrintPass .messDesc_\@
                        bra .end_\@
.messDesc_\@            dc.b "appHexUint8(\3) = '",\4,"'",0
.messGot_\@             dc.b "...got ",0
.strbuf_\@              ds.b 20
.strexpected_\@         dc.b \4,0
                        even
.end_\@                 nop
                        endm

; ================================================================================================================
; test 1 : get expected strings
ITOA_test1
                        ITOA_makePrintHexFromByte a5,d5,#0,"$00",a4
                        ITOA_makePrintHexFromByte a5,d5,#1,"$01",a4
                        ITOA_makePrintHexFromByte a5,d5,#2,"$02",a4
                        ITOA_makePrintHexFromByte a5,d5,#3,"$03",a4
                        ITOA_makePrintHexFromByte a5,d5,#4,"$04",a4
                        ITOA_makePrintHexFromByte a5,d5,#5,"$05",a4
                        ITOA_makePrintHexFromByte a5,d5,#6,"$06",a4
                        ITOA_makePrintHexFromByte a5,d5,#7,"$07",a4
                        ITOA_makePrintHexFromByte a5,d5,#8,"$08",a4
                        ITOA_makePrintHexFromByte a5,d5,#9,"$09",a4
                        PromptForKey
                        ITOA_makePrintHexFromByte a5,d5,#10,"$0a",a4
                        ITOA_makePrintHexFromByte a5,d5,#11,"$0b",a4
                        ITOA_makePrintHexFromByte a5,d5,#12,"$0c",a4
                        ITOA_makePrintHexFromByte a5,d5,#13,"$0d",a4
                        ITOA_makePrintHexFromByte a5,d5,#14,"$0e",a4
                        ITOA_makePrintHexFromByte a5,d5,#15,"$0f",a4
                        ITOA_makePrintHexFromByte a5,d5,#16,"$10",a4
                        ITOA_makePrintHexFromByte a5,d5,#17,"$11",a4
                        ITOA_makePrintHexFromByte a5,d5,#18,"$12",a4
                        ITOA_makePrintHexFromByte a5,d5,#19,"$13",a4
                        ITOA_makePrintHexFromByte a5,d5,#20,"$14",a4
                        PrintNewLine
                        PromptForKey
ENDOF_ITOA_test1