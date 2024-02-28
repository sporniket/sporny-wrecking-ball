; ================================================================================================================
; (C) 2020..2024 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Collision Map -- Library
; ================================================================================================================

; memory buffer
; const swb_clsnmp:u16[4752]
swb_clsnmp                          ds.w    4752
; LUTs
; const swb_clsnmp_offsetbytes_grid_lines:u16[20] // = [354 + 44*8*i for i in range(0,20)]
swb_clsnmp_offsetbytes_grid_lines   ds.w    20
; const swb_clsnmp_offsetbytes_lines:u16[216] // = [1 + 44*i for i in range(0,216)]
swb_clsnmp_offsetbytes_lines        ds.w    216
