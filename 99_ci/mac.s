; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Test suite for mac.s
; ================================================================================================================
; Before all
;
                        PrintNewLine
                        PrintHeader             TSTMAC_messHead
                        bra                     TSTMAC_test1
TSTMAC_messHead         dc.b                    "MAC (Multiply-ACcumulate) tests",0
                        even

; ================================================================================================================
; test factory : test one macro
; will use d0-d2/a0-a2
; 
TSTMAC_makeTest         macro
                        ; 1 - litteral value to multiply
                        ; 2 - litteral multiplication factor (0..31)
                        ; 3 - expected value
                        ; 4 - size of operands (b,w,l)
                        move.\4     #\1,d0
                        mac_\2_\4   d0,d1
                        cmp.\4      #\3,d1
                        beq         .pass_\@
                        PrintFail               .messDesc_\@
                        ; a5 := string buffer
                        lea                     strbufIntToAscii,a5
                        jsrA_itoa_appHexUint8   a5,d1
                        PrintContinue2          messGot,strbufIntToAscii
                        bra                     .end_\@
.pass_\@                PrintPass               .messDesc_\@ 
                        bra                     .end_\@                       
.messDesc_\@            dc.b                    "(.\4) \1 * \2 = \3",0
                        even
.end_\@                 nop
                        endm

; ================================================================================================================
; test 1 -- Byte sized multiplication test
;
TSTMAC_test1
                        TSTMAC_makeTest     7,0,0,b
                        TSTMAC_makeTest     7,1,7,b
                        TSTMAC_makeTest     7,2,14,b
                        TSTMAC_makeTest     7,3,21,b
                        TSTMAC_makeTest     7,4,28,b
                        TSTMAC_makeTest     7,5,35,b
                        TSTMAC_makeTest     7,6,42,b
                        TSTMAC_makeTest     7,7,49,b
                        PromptForKey

                        TSTMAC_makeTest     7,8,56,b
                        TSTMAC_makeTest     7,9,63,b
                        TSTMAC_makeTest     7,10,70,b
                        TSTMAC_makeTest     7,11,77,b
                        TSTMAC_makeTest     7,12,84,b
                        TSTMAC_makeTest     7,13,91,b
                        TSTMAC_makeTest     7,14,98,b
                        TSTMAC_makeTest     7,15,105,b
                        PromptForKey

                        TSTMAC_makeTest     7,16,112,b
                        TSTMAC_makeTest     7,17,119,b
                        TSTMAC_makeTest     7,18,126,b
                        TSTMAC_makeTest     7,19,133,b
                        TSTMAC_makeTest     7,20,140,b
                        TSTMAC_makeTest     7,21,147,b
                        TSTMAC_makeTest     7,22,154,b
                        TSTMAC_makeTest     7,23,161,b
                        PromptForKey

                        TSTMAC_makeTest     7,24,168,b
                        TSTMAC_makeTest     7,25,175,b
                        TSTMAC_makeTest     7,26,182,b
                        TSTMAC_makeTest     7,27,189,b
                        TSTMAC_makeTest     7,28,196,b
                        TSTMAC_makeTest     7,29,203,b
                        TSTMAC_makeTest     7,30,210,b
                        TSTMAC_makeTest     7,31,217,b
                        PromptForKey

ENDOF_TSTMAC_test1


; ================================================================================================================
; test 2 -- Word sized multiplication test
;
TSTMAC_test2
                        TSTMAC_makeTest     7,0,0,w
                        TSTMAC_makeTest     7,1,7,w
                        TSTMAC_makeTest     7,2,14,w
                        TSTMAC_makeTest     7,3,21,w
                        TSTMAC_makeTest     7,4,28,w
                        TSTMAC_makeTest     7,5,35,w
                        TSTMAC_makeTest     7,6,42,w
                        TSTMAC_makeTest     7,7,49,w
                        PromptForKey

                        TSTMAC_makeTest     7,8,56,w
                        TSTMAC_makeTest     7,9,63,w
                        TSTMAC_makeTest     7,10,70,w
                        TSTMAC_makeTest     7,11,77,w
                        TSTMAC_makeTest     7,12,84,w
                        TSTMAC_makeTest     7,13,91,w
                        TSTMAC_makeTest     7,14,98,w
                        TSTMAC_makeTest     7,15,105,w
                        PromptForKey

                        TSTMAC_makeTest     7,16,112,w
                        TSTMAC_makeTest     7,17,119,w
                        TSTMAC_makeTest     7,18,126,w
                        TSTMAC_makeTest     7,19,133,w
                        TSTMAC_makeTest     7,20,140,w
                        TSTMAC_makeTest     7,21,147,w
                        TSTMAC_makeTest     7,22,154,w
                        TSTMAC_makeTest     7,23,161,w
                        PromptForKey

                        TSTMAC_makeTest     7,24,168,w
                        TSTMAC_makeTest     7,25,175,w
                        TSTMAC_makeTest     7,26,182,w
                        TSTMAC_makeTest     7,27,189,w
                        TSTMAC_makeTest     7,28,196,w
                        TSTMAC_makeTest     7,29,203,w
                        TSTMAC_makeTest     7,30,210,w
                        TSTMAC_makeTest     7,31,217,w
                        PromptForKey

ENDOF_TSTMAC_test2


; ================================================================================================================
; test 3 -- Long sized multiplication test
;
TSTMAC_test3
                        TSTMAC_makeTest     7,0,0,l
                        TSTMAC_makeTest     7,1,7,l
                        TSTMAC_makeTest     7,2,14,l
                        TSTMAC_makeTest     7,3,21,l
                        TSTMAC_makeTest     7,4,28,l
                        TSTMAC_makeTest     7,5,35,l
                        TSTMAC_makeTest     7,6,42,l
                        TSTMAC_makeTest     7,7,49,l
                        PromptForKey

                        TSTMAC_makeTest     7,8,56,l
                        TSTMAC_makeTest     7,9,63,l
                        TSTMAC_makeTest     7,10,70,l
                        TSTMAC_makeTest     7,11,77,l
                        TSTMAC_makeTest     7,12,84,l
                        TSTMAC_makeTest     7,13,91,l
                        TSTMAC_makeTest     7,14,98,l
                        TSTMAC_makeTest     7,15,105,l
                        PromptForKey

                        TSTMAC_makeTest     7,16,112,l
                        TSTMAC_makeTest     7,17,119,l
                        TSTMAC_makeTest     7,18,126,l
                        TSTMAC_makeTest     7,19,133,l
                        TSTMAC_makeTest     7,20,140,l
                        TSTMAC_makeTest     7,21,147,l
                        TSTMAC_makeTest     7,22,154,l
                        TSTMAC_makeTest     7,23,161,l
                        PromptForKey

                        TSTMAC_makeTest     7,24,168,l
                        TSTMAC_makeTest     7,25,175,l
                        TSTMAC_makeTest     7,26,182,l
                        TSTMAC_makeTest     7,27,189,l
                        TSTMAC_makeTest     7,28,196,l
                        TSTMAC_makeTest     7,29,203,l
                        TSTMAC_makeTest     7,30,210,l
                        TSTMAC_makeTest     7,31,217,l
                        PromptForKey

ENDOF_TSTMAC_test3

