; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES systraps.s,
; ================================================================================================================
; Blitter macros
;
BlitterBase             = $8a00
BlitterMiscReg1         = $ffff8a3c

                        rsreset
Blitter_Halftone        rs.w                    16
Blitter_SrcIncX         rs.w                    1
Blitter_SrcIncY         rs.w                    1
Blitter_SrcAddress      rs.l                    1
Blitter_Mask1           rs.w                    1
Blitter_Mask2           rs.w                    1
Blitter_Mask3           rs.w                    1
Blitter_DestIncX        rs.w                    1
Blitter_DestIncY        rs.w                    1
Blitter_DestAddress     rs.l                    1
Blitter_CountX          rs.w                    1
Blitter_CountY          rs.w                    1
Blitter_Hop             rs.b                    1
Blitter_Op              rs.b                    1
Blitter_MiscReg1        rs.b                    1
Blitter_MiscReg2        rs.b                    1
SIZEOF_Blitter          rs.w                    0

;
DoBlitAndWait           macro
                        bset.w                  #15,BlitterMiscReg1.w
                        nop
.waitFinish\@           bset.w                  #15,BlitterMiscReg1.w
                        nop
                        bne.s                   .waitFinish\@
                        endm

;
_BlitMode               macro
                        move.w                  \1,-(sp)
                        ___xbios                64,4
                        endm
