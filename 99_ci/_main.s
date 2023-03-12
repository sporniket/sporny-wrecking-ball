; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Perform a collection of test suites
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
                        ; files under test
                        include                 'libs/ikbdhelp.s'


; ================================================================================================================
; Essential macros
; ================================================================================================================
Print                   macro
                        pea                     \1
                        ___gemdos               9,6
                        endm
;
PrintChar               macro
                        move.w                  \1,-(sp)
                        ___gemdos               2,4
                        endm
;
Terminate               macro
                        ___gemdos               0,0
                        endm
; ================================================================================================================
; Utility macros
; ================================================================================================================
;
PrintNewLine            macro
                        Print                   messNewLine
                        endm
;
Println                 macro
                        Print                   \1
                        PrintNewLine
                        endm
;
PrintPass               macro
                        Print                   messPass
                        Println                 \1
                        endm
;
PrintFail               macro
                        Print                   messFail
                        Println                 \1
                        endm
;
PrintContinue           macro
                        Print                   messContinue
                        Println                 \1
                        endm
;
PrintContinue2          macro
                        Print                   messContinue
                        Print                   \1
                        Println                 \2
                        endm
;
PrintHeader             macro
                        Println                 messVisualBorderTop
                        Print                   messVisualBorderLeft
                        Println                 \1
                        Println                 messVisualBorderLeft
                        endm
;
PrintBottom             macro
                        Println                 messVisualBorderBottom
                        PrintNewLine
                        endm
;
PromptForKey            macro
                        PrintNewLine
                        Println                 messPromptForKey
                        WaitInp
                        endm
; ================================================================================================================
; Main
; ================================================================================================================
                        Print                   messCls
                        jsr                     START_OF_CI 

ThatsAll:
                        PrintNewLine
                        Print                   messThatsAll
                        WaitInp
                        Terminate
; ================================================================================================================
; Libraries includes
; ================================================================================================================
                        include                 'libs/itoa.s'
; ================================================================================================================
; Entry point
; ================================================================================================================
START_OF_CI:
; ----------------------------------------------------------------------------------------------------------------
; Before all tests
; ----------------------------------------------------------------------------------------------------------------
                        Println                 messBannerCi
                        PrintNewLine
; ----------------------------------------------------------------------------------------------------------------
; Each test suite = one file to include
; ----------------------------------------------------------------------------------------------------------------
                        include 'itoa.s'
                        include 'ikbdhelp.s'
; ----------------------------------------------------------------------------------------------------------------
; After all tests
; ----------------------------------------------------------------------------------------------------------------
; ----------------------------------------------------------------------------------------------------------------
; DONE
; ----------------------------------------------------------------------------------------------------------------
                        PrintNewLine
                        Println                 messBannerStats
                        Print                   messStatsTotal
                        ; TODO : print number of total tests
                        PrintNewLine
                        Print                   messStatsFailed
                        ; TODO : print number of failed tests
                        PrintNewLine
                        PrintBottom
                        rts
; ----------------------------------------------------------------------------------------------------------------
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; messages
; ================================================================================================================
messCls                 dc.b                    27,"E",0
messNewLine             dc.b                    10,13,0
messThatsAll            dc.b                    "Done, press any key to quit.",0
messFail                dc.b                    "FAIL ",0
messPass                dc.b                    "ok   ",0
messContinue            dc.b                    "|    ",0
messGot                 dc.b                    "  got ",0
messVisualBorderTop     dc.b                    "########",0
messVisualBorderLeft    dc.b                    "# ",0
messVisualBorderBottom  dc.b                    "--------",0
messBannerCi            dc.b                    "~~~< START Continuous Integration >~~~",0
messBannerStats         dc.b                    "~~~< RESULTS >~~~",0
messStatsTotal          dc.b                    "Tests : ...",0
messStatsFailed         dc.b                    "Fails : ...",0
messPromptForKey        dc.b                    "--< Press a key to continue >--",0
; ----------------------------------------------------------------------------------------------------------------
strbufIntToAscii        ds.b                    32