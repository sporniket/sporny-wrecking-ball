; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES rnbuf.s
; ================================================================================================================
; custom mouse handler to replace the one in kbdvbase.
; ================================================================================================================
; Struct : MouseState -- to store the actual state.
; 
                        rsreset
MouseState_buttons      rs.w 1 ; unsigned WORD : button states (bit 0 : left ; bit 1 : right)
MouseState_x            rs.w 1 ; signed WORD : x position/move
MouseState_y            rs.w 1 ; signed WORD : y position/move
MouseState_x_min        rs.w 1 ; signed WORD : min x position (inclusive)
MouseState_x_max        rs.w 1 ; signed WORD : max x position (exclusive)
MouseState_y_min        rs.w 1 ; signed WORD : min y position (inclusive)
MouseState_y_max        rs.w 1 ; signed WORD : max y position (exclusive)

SIZEOF_MouseState       rs.b 0 ;
EVENSIZEOF_MouseState   rs.b 0 ;

; ----------------------------------------------------------------------------------------------------------------
; Update position value : sign extend byte-sized difference to word, accumulate and cap
; typical usage -- given that a3 points to the struct, and d4 contains the move to add (signed byte)
;
;                       MouseState_update_pos   a3,MouseState_x,d4,MouseState_x_min,MouseState_x_max
;
MouseState_update_pos   macro
                        ; 1 - <<this>>, address register pointing to the structure
                        ; 2 - field to update, e.g. MouseState_x
                        ; 3 - data register containing the signed byte, to work as accumulator
                        ; 4 - field used as minimum limit
                        ; 5 - field used as maximum limit
                        ; ---
                        ; sign extends \3
                        tst.b                   #7,\3
                        beq                     .done_sign_extend_\@
                        or.w                    #ff00,\3 ; sign-extends value
                        ; ---
                        ; accumulate and cap
.done_sign_extend_\@    add.w                   \2(\1),\3 
                        cmp.w                   \4(\1),\3
                        blo                     .use_min_\@     ; force to minimum value if it's under this minimum
                        cmp.w                   \5(\1),\3
                        blo                     .write_back_\@  ; value is in range
                        move.w                  \5(\1),\3       ; else forse to max - 1
                        subq.w                  #1,\3
                        bra                     .write_back_\@
.use_min_\@             move.w                  \4(1),\3
.write_back_\@          move.w                  \3,\2(\1)
                        endm
; ================================================================================================================
; Struct : MsIkbdEvt -- Describe of the IKBD report.
; 
                        rsreset
MsIkbdEvt_buttons       rs.b 1 ; unsigned BYTE : button states (bit 0 : left ; bit 1 : right)
MsIkbdEvt_x             rs.b 1 ; signed BYTE : x position/move
MsIkbdEvt_y             rs.b 1 ; signed BYTE : y position/move

SIZEOF_MsIkbdEvt        rs.b 1 ;
EVENSIZEOF_MsIkbdEvt    rs.b 0 ;

; ================================================================================================================
; Initialization subroutine
;
sr_mshandlr_init        movem.l                 a0-a1,-(sp) ; backup registers
                        rnbuf_withRingBuffer    a0,#mshandlr_rbuf
                        rnbuf_init              a0,a1,#mshandlr_rbuf_store
                        movem.l                 (sp)+,a0-a1 ; restore
                        rts

; ================================================================================================================
; handler subroutine
;
sr_mshandlr_handler     movem.l                 a0-a2,-(sp)             ; save context
                        ; ---
                        ; a0 (given) : pointer to the 3 word long report
                        ; a1 := pointer to the ring buffer
                        rnbuf_withRingBuffer    a1,#mshandlr_rbuf
                        ; a2 := pointer to the destination of memory copy
                        move.l                  RingBuffer_adrPush(a1),a2
                        ; ---
                        ; push data from report into the buffer
                        ; ---
                        move.b                  (a0)+,(a2)+             ;button states
                        move.b                  (a0)+,(a2)+             ;x move
                        move.b                  (a0)+,(a2)+             ;y move
                        ; update the ring buffer
                        rnbuf_donePush          a1,a2,#EVENSIZEOF_MsIkbdEvt
                        movem.l                 (sp)+,a0-a2             ; restore context
                        rts

; ================================================================================================================
; client subroutine -- setup position, reset button states
; d0 : signed word, x position
; d1 : signed word, y position
;
sr_mshandlr_reset       movem.l                 a0,-(sp)        ; save context
                        ; a0 := mouse state to setup
                        lea                     mshandler_ms_state,a0
                        move.w                  #0,MouseState_buttons(a0)
                        move.w                  d0,MouseState_x(a0)
                        move.w                  d1,MouseState_y(a0)
                        movem.l                 (sp)+,a0        ; restore context
                        rts

; ================================================================================================================
; client subroutine -- update mouse state
; side effects :
; a0 -- pointer to the MouseState
srA_mshandlr_update      movem.l                 a1-a2/d0,-(sp)        ; save context
                        ; a0 := mouse state
                        lea                     mshandler_ms_state,a0
                        ; a1 := pointer to the ring buffer
                        rnbuf_withRingBuffer    a1,#mshandlr_rbuf
                        ; a2 := pointer to the destination of memory copy
                        move.l                  RingBuffer_adrPop(a1),a2
                        ; d0 := tmp data registry
                        moveq                   #0,d0
                        ; extract button events
                        move.b                  (a2)+,d0
                        move.w                  d0,MouseState_buttons(a0)
                        ; extract mouse move along x, update
                        move.b                  (a2)+,d0
                        MouseState_update_pos   a3,MouseState_x,d0,MouseState_x_min,MouseState_x_max
                        ; extract mouse move along y, update
                        moveq                   #0,d0
                        move.b                  (a2)+,d0
                        MouseState_update_pos   a3,MouseState_y,d0,MouseState_y_min,MouseState_y_max
                        ; done, restore context
                        movem.l                 (sp)+,a1-a2/d0
                        rts


; ================================================================================================================
; Memory area to be used by the handler and client code
;
mshandlr_rbuf           dc.l    0,16,0,0 ; to init by adding #mshandlr_rbuf_store to each value
mshandlr_rbuf_store     ds.l    4,0 ; enough for 3 reports (pushing a forth one will drop the oldest one)
                        even 

; ================================================================================================================
; Memory area to be used by the client code
;
mshandler_ms_state      ds.b    EVENSIZEOF_MouseState,0