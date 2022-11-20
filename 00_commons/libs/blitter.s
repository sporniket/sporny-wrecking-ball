; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES macro/blitter.s,
; ================================================================================================================
; Blitter subroutine
; ---
; A buffer (a 'run list') contains a description of several blit actions ('run items'), the list is terminated
; with a zero.
;
; |Buffer  |
; |--------|
; |action 1|
; |action 2|
; |...     |
; |action N|
; |0 (EOL) |
;
; A run item is described as an opcode (word) followed by a variable length data to be used to setup the
; blitter registers. The data for the control registers do not change the busy bit. When the opcode is
; a blit operation, it will be performed once the data has been loaded to the blitter registers.
;
; |Opcode|Description|Data, in order|
; |---|---|---|
; |1|Setup halftone pattern|16 words of the pattern (32 bytes)|
; |2|Blit with full setup|src(x/y inc,address),masks,dest(x/y inc,address),counts(x/y),hop,op,ctrl(1/2) (30bytes)|
; |3|Blit again|src address,dest address, count y (10 bytes)|
;
; ================================================================================================================
; -- Blitter run item handling --
; in/out a5 := cursor to the next data
; in     d7 := the opcode

; Opcode 1 : Setup halftone pattern
BlitRunItem_1:
                        move.w                  #BlitterBase,a4
                        rept 8
                        move.l                  (a5)+,(a4)+
                        endr
                        rts
;

; Opcode 2 : Blit with full setup
BlitRunItem_2:
                        move.w                  #BlitterBase,a4
                        lea                     Blitter_SrcIncX(a4),a4
                        rept 7
                        move.l                  (a5)+,(a4)+
                        endr
                        ; d6 := control data, without bit 15 (busy bit)
                        moveq                   #0,d6
                        move.w                  (a5)+,d6
                        and.w                   #$7fff,d6
                        ; set control registers
                        and.w                   #$8000,(a4)
                        or.w                    d6,(a4)
                        ; execute
                        DoBlitAndWait
                        rts
;

; Opcode 3 : Blit again
BlitRunItem_3:
                        move.w                  #BlitterBase,a4
                        move.l                  (a5)+,Blitter_SrcAddress(a4)
                        move.l                  (a5)+,Blitter_DestAddress(a4)
                        move.w                  (a5)+,Blitter_CountY(a4)
                        ; execute
                        DoBlitAndWait
                        rts
;
; -- Get the list and execute the operations --
; Put the pointer to the start of the list into PtrBlitterList,
; then call `_xos_Supexec #BlitRunList`

BlitRunList:
                        ; -- save registers
                        move.l                  a6,-(sp)
                        move.l                  #BufferBlitSaveRegTop,a6
                        movem                   a0-a5/d0-d7,-(a6)
                        move.l                  (sp)+,a6
                        ; -- do stuff...
                        ; a5 := start of the blit list
                        DerefPtrToPtr           PtrBlitterList,a5
                        moveq                   #0,d7
.next
                        move.w                  (a5)+,d7
                        ; -- select(d7)
                        dbf                     d7,.opcode1
                        bra.s                   .eol
.opcode1
                        dbf                     d7,.opcode2
                        bsr.w                   BlitRunItem_1
                        bra.s                   .next
.opcode2
                        dbf                     d7,.opcode3
                        bsr.w                   BlitRunItem_2
                        bra.s                   .next
.opcode3
                        bsr.w                   BlitRunItem_3
                        bra.s                   .next
.eol
                        ; -- restore registers
                        move.l                  a6,-(sp)
                        move.l                  #BufferBlitSaveRegBase,a6
                        movem                   (a6)+,a0-a5/d0-d7
                        move.l                  (sp)+,a6
                        ; -- done
                        rts


; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
PtrBlitterList          dc.l                    0                       ; pointer to the start of a blit list
BufferBlitSaveRegBase   ds.l                    14
BufferBlitSaveRegTop    dc.l                    0                       ;
