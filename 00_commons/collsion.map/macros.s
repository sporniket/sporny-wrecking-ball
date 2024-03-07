; ================================================================================================================
; (C) 2020..2024 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Collision Map -- Macros
; ================================================================================================================
; PROGRAMMING RULES FOR DEVELOPPING MACROS
; ----------------------------------------------------------------------------------------------------------------
; -- 1. a0-a2/d0-d2 are scratch registers
; ----------------------------------------------------------------------------------------------------------------
; > This rule is for acknowledging that saving then restoring registers takes lot of cycles. E.g. to stack/unstack
; > some 32bits registers, there are 2 cycles for reading the instruction (movem + bitmap of registers) then 2 
; > cycles for each saved registers. Double this number of cycles for the full operation (stack + unstack).
;
; From another perspective, it can be said that macros do return a record/struct of at most 3 values and 3 
; pointers.
;
;
; * The developper MUST save and restore any modified registers in a3-a6/d3-d7
; * The developper MUST minimize the number of modified registers by reusing them as most as possible
; * The developper MUST use the registers as needed in order from index 0 to index 7
; * The developper MUST restore a7 (SP) with relation to saving/restoring the registers, so that ONLY intended
;   side effect is applied (e.g. if the intent of the macro is to push some result values into the stack)
; * The developper MUST document **accurately** the list of registers in a0-a2/d0-d2 that are actually modified.
;   Especially : 
;   * The developper MUST tell what is the value contained
;   * The developper MUST expect that the caller WILL find a way to exploit it
; * The developper MAY decide to restore some or all the registers in a0-a2/d0-d2, e.g. to avoid writing
;   documentation mandated previously, or to minimize the amount of side-effect.
; * The developper MUST verify the effective list of modified registers in the test suite
; ================================================================================================================

;
; ================================================================================================================
; Initialisation of the module

; Reset the collision map
swb_clsnmp_reset    macro
                    ; lines 0-7
                    ; lines 8-215
                    endm

; Reset the collision map and the offset tables
swb_clsnmp_init     macro
                    ; initialize the offset table of lines
                    ; initialize the offset table of lines
                    ; initialize the collision map
                    swb_clsnmp_reset
                    endm
