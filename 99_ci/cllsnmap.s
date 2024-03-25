; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Test suite for 'collsion.map/macros.s' and 'collsion.map/lib.s'
; ================================================================================================================
; Before all
;
                        PrintNewLine
                        PrintHeader             CLLSNMAP_messHead
                        bra                     CLLSNMAP_test1
CLLSNMAP_messHead       dc.b                    "collision map tests",0
                        even

; ================================================================================================================
; Initialisation of the module
; ================================================================================================================
; test 1 -- swb_clsnmp_init WILL initialize the content of swb_clsnmp, swb_clsnmp_offsetbytes_grid_lines, 
;           and swb_clsnmp_offsetbytes_lines.
;
CLLSNMAP_test1
                        PromptForKey
ENDOF_CLLSNMAP_test1

; ================================================================================================================
; test 2 -- swb_clsnmp_reset WILL initialize the content of swb_clsnmp.
;
CLLSNMAP_test1
                        PromptForKey
ENDOF_CLLSNMAP_test1

; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
