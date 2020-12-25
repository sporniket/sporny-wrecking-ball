; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; ================================================================================================================
; Signature fade effect model, like a venetian blind from top to bottom.
; ---
; It deals only with the model management, the actual blitting must be written somewhere else.
; At most 8 lines are to be changed per step.
; ================================================================================================================
                        rsreset
; -- setup
; source data
FadeClr_Src             rs.l 1                  ; Pointer to source data to fill the screen
FadeClr_SrcIncX         rs.w 1                  ; Source X increment value
FadeClr_SrcIncY         rs.w 1                  ; Source Y increment value
FadeClr_SrcNext         rs.l 1                  ; Increment to add to the pointer to the source after each step
FadeClr_SrcNextFinal    rs.l 1                  ; Increment to add to the pointer to the source after each step in the final phase
; dest data
FadeClr_Dest            rs.l 1                  ; Pointer to destination data (the screen to fill)
FadeClr_DestIncX        rs.w 1                  ; Destination X increment value
FadeClr_DestIncY        rs.w 1                  ; Destination Y increment value
FadeClr_DestNext        rs.l 1                  ; Increment to add to the pointer to the destination after each step
FadeClr_DestNextFinal   rs.l 1                  ; Increment to add to the pointer to the destination after each step in the final phase
; -- runtime values
FadeClr_Step            rs.w 1                  ; step counter
FadeClr_PtrSrc          rs.l 1                  ; Pointer to the start of the source to copy
FadeClr_PtrSrcNext      rs.l 1                  ; next value of the pointer
FadeClr_PtrDest         rs.l 1                  ; Pointer to the start of the destination
FadeClr_PtrDestNext     rs.l 1                  ; next value of the pointer
FadeClr_CountY          rs.w 1                  ; Number of lines to display at this step
SIZEOF_FadeClr          rs.b 0

; -- constants
FadeClr_STEP_PHASE_MIDDLE = 7                   ; step counter value from which FadeClr_CountY is 8
FadeClr_STEP_PHASE_FINAL = 25                    ; step counter value from which FadeClr_CountY is 32 - step
FadeClr_STEP_END        = 33                    ; step counter value from which it is finished
; ================================================================================================================
; ================================================================================================================
FadeClr_init            macro
                        ; Initialize the model with litteral values
                        ; 1 - Address register, pointer to the model to initialize
                        ; 2 - litteral, source address
                        ; 3 - litteral, source increment x
                        ; 4 - litteral, source increment y
                        ; 5 - litteral, source increment after each step
                        ; 6 - litteral, source increment for the final phase
                        ; 7 - litteral, destination address
                        ; 8 - litteral, destination increment x
                        ; 9 - litteral, destination increment y
                        ; a - litteral, destination increment after each step
                        ; b - litteral, destination increment for the final phase
                        ; --
                        move.l                  #\2,FadeClr_Src(\1)
                        move.w                  #\3,FadeClr_SrcIncX(\1)
                        move.w                  #\4,FadeClr_SrcIncY(\1)
                        move.l                  #\5,FadeClr_SrcNext(\1)
                        move.l                  #\6,FadeClr_SrcNextFinal(\1)
                        ; --
                        move.l                  #\7,FadeClr_Dest(\1)
                        move.w                  #\8,FadeClr_DestIncX(\1)
                        move.w                  #\9,FadeClr_DestIncY(\1)
                        move.l                  #\a,FadeClr_DestNext(\1)
                        move.l                  #\b,FadeClr_DestNextFinal(\1)
                        ; --
                        move.w                  #0,FadeClr_Step(\1)
                        move.l                  #\2,FadeClr_PtrSrc(\1)
                        move.l                  #0,FadeClr_PtrSrcNext(\1)
                        move.l                  #\7,FadeClr_PtrDest(\1)
                        move.l                  #0,FadeClr_PtrDestNext(\1)
                        move.w                  #0,FadeClr_CountY(\1)
                        endm
; ================================================================================================================
; ================================================================================================================
FadeClr_runStep         macro
                        ; execute one step of the transition to prepare redraw
                        ; 1 - pointer to the running model
                        ; 2 - spare data register
                        ; 3 - spare data register
                        ; --
                        ; \2 := current step
                        move.w                  FadeClr_Step(\1),\2
                        cmp.w                   #FadeClr_STEP_END,\2
                        ; -- if finished
                        bpl                     .thatsAll\@
                        cmp.w                   #FadeClr_STEP_PHASE_FINAL,\2
                        ; -- if not final phase
                        bmi.s                   .beforeFinal\@
                        ; -- else compute next step in final mode
                        ; \3 := next source to compute
                        move.l                  FadeClr_PtrSrc(\1),\3
                        add.l                   FadeClr_SrcNextFinal(\1),\3
                        move.l                  \3,FadeClr_PtrSrcNext(\1)
                        ; \3 := next destination to compute
                        move.l                  FadeClr_PtrDest(\1),\3
                        add.l                   FadeClr_DestNextFinal(\1),\3
                        move.l                  \3,FadeClr_PtrDestNext(\1)
                        ; \3 := next y count to compute
                        move.l                  #FadeClr_STEP_END,\3
                        sub.w                   \2,\3
                        bra.s                   .nextStep\@
.beforeFinal\@
                        ; \3 := next source to compute
                        move.l                  FadeClr_PtrSrc(\1),\3
                        add.l                   FadeClr_SrcNext(\1),\3
                        move.l                  \3,FadeClr_PtrSrcNext(\1)
                        ; \3 := next destination to compute
                        move.l                  FadeClr_PtrDest(\1),\3
                        add.l                   FadeClr_DestNext(\1),\3
                        move.l                  \3,FadeClr_PtrDestNext(\1)
                        ; -- y count = step < FadeClr_STEP_PHASE_MIDDLE ? step + 1 : 8
                        cmp.w                   #FadeClr_STEP_PHASE_MIDDLE,\2
                        bpl.s                   .useFixedCountY\@
                        ; \3 := count y to compute
                        moveq                   #0,\3
                        move.w                  \2,\3
                        addq.w                  #1,\3
                        bra.s                   .nextStep\@
.useFixedCountY\@
                        moveq                   #8,\3
.nextStep\@
                        ; \2 := step count to update
                        addq.w                  #1,\2
                        move.w                  \2,FadeClr_Step(\1)
                        move.w                  \3,FadeClr_CountY(\1)
.thatsAll\@
                        endm
; ================================================================================================================
; ================================================================================================================
FadeClr_commit          macro
                        ; update the pointers for the next step
                        ; 1 - address register, pointer to the running model
                        move.l                  FadeClr_PtrSrcNext(\1),FadeClr_PtrSrc(\1)
                        move.l                  FadeClr_PtrDestNext(\1),FadeClr_PtrDest(\1)
                        endm
; ================================================================================================================
; ================================================================================================================
FadeClr_isFinished      macro
                        ; Set the ccr to test for the end of the transition.
                        ; use BPL for reacting to finish, use BMI for reacting to not finished
                        ; 1 - address register, pointer to the running model.
                        ; 2 - spare data register (-> FadeClr_Step)
                        ; 3 - branch destination on finish
                        moveq                   #0,\2
                        move.w                  FadeClr_Step(\1),\2
                        cmp.w                   #FadeClr_STEP_END,\2
                        endm
; ================================================================================================================
; ================================================================================================================
FadeClr_onFinished      macro
                        ; Branch to the given destination if the transition is finished.
                        ; 1 - address register, pointer to the running model.
                        ; 2 - spare data register (-> FadeClr_Step)
                        ; 3 - branch destination on finish
                        FadeClr_isFinished      \1,\2
                        bpl                     \3
                        endm
; ================================================================================================================
; ================================================================================================================
FadeClr_onNotFinished   macro
                        ; Branch to the given destination if the transition is not finished.
                        ; use BPL for reacting to finish, use BMI for reacting to not finished
                        ; 1 - address register, pointer to the running model.
                        ; 2 - spare data register (-> FadeClr_Step)
                        ; 3 - branch destination on finish
                        bmi                     \3
                        endm
; ================================================================================================================
; ================================================================================================================
