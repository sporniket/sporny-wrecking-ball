; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES macro/dmasnd.s,
; ================================================================================================================
; DMA Sound subroutine
; ---
; The pointer DmaSound_PtrDesc MUST be filled with the pointer to a sound sample descriptor to replay
; (see macro/dmasnd.s)
;
DmaSound_playOnce:
                        ; -- save registers
                        move.l                  a6,-(sp)
                        move.l                  #DmaSound_BuffSavRegTop,a6
                        movem                   a0-a5/d0-d7,-(a6)
                        move.l                  (sp)+,a6
                        ; -- start
                        ; a5 := pointer to the dma sound descriptor
                        DerefPtrToPtr           DmaSound_PtrDesc,a5
                        ; a4,d7,d6 := spare registers
                        DmaSound_doPlayOnce     DmaSound_base(a5),DmaSound_top(a5),a4,d7,d6
                        ; -- restore registers
                        move.l                  a6,-(sp)
                        move.l                  #DmaSound_BuffSavRegBase,a6
                        movem                   (a6)+,a0-a5/d0-d7
                        move.l                  (sp)+,a6
                        ; -- done
                        rts
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
; ================================================================================================================
DmaSound_PtrDesc        dc.l                    0                       ; pointer to the descriptor of the sound to play
DmaSound_BuffSavRegBase ds.l                    14                      ; buffer to save registers and restore after
DmaSound_BuffSavRegTop  dc.l                    0                       ;
