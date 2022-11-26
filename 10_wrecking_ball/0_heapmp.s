; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Game Seed by Sporniket : map of the heap
; ----------------------------------------
; Feel the structure of the heap of your application between `rsreset` and `SIZEOF_HEAP_ACTUAL`.
; 
; Usually, one will likely want to store the main structures ('singletons' ?) and some memory for a memory manager.
; ================================================================================================================
                        rsreset
; ----------------------------------------------------------------------------------------------------------------
; Start of the map
; ----------------------------------------------------------------------------------------------------------------
; -- 'Heap POSition' aka memory map of the heap
; Grid : 1200 words = 2400 bytes
HposGridBase            rs.w                    1200
HposGridTop             rs.w                    0
; Freedom bitmap : 500 bytes
HposFreedomBase         rs.b                    500
HposFreedomTop          rs.b                    0
; Blitter list : 2*(70 bytes (= 1 blit item 2 + 3 blit items 3) + 912 bytes (= 19 x 4 blit item 3)) + 2 bytes (terminator)
HposBlitListBase        rs.b                    4000;1966
HposBlitListTop         rs.b                    0
; Game state
HposGameStateBase       rs.b                    SIZEOF_GameState
HposGameStateTop        rs.b                    0
; Level currently being played
HposCurrentLvlBase      rs.b                    SIZEOF_Level
HposCurrentLvlTop       rs.b                    0
; Transition
HposFadeEffectBase      rs.b                    SIZEOF_FadeClr
HposFadeEffectTop       rs.b                    0
HposEnd                 rs.b                    0
; ----------------------------------------------------------------------------------------------------------------
; End of the map
; ----------------------------------------------------------------------------------------------------------------
SIZEOF_HEAP_ACTUAL      rs.b                    0
