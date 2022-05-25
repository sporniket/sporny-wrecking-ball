DatLevel0:              incbin                  'assets/wblv_000.dat'
DatLevel1:              incbin                  'assets/wblv_001.dat'
DatLevel2:              incbin                  'assets/wblv_002.dat'
DatLevel3:              incbin                  'assets/wblv_003.dat'
DatLevel4:              incbin                  'assets/wblv_004.dat'
DatLevel5:              incbin                  'assets/wblv_005.dat'
DatLevel6:              incbin                  'assets/wblv_006.dat'
DatLevel7:              incbin                  'assets/wblv_007.dat'
DatLevel8:              incbin                  'assets/wblv_008.dat'
DatLevel9:              incbin                  'assets/wblv_009.dat'
DatLevel10:              incbin                  'assets/wblv_010.dat'
DatLevel11:              incbin                  'assets/wblv_011.dat'
DatLevel12:              incbin                  'assets/wblv_012.dat'
DatLevel13:              incbin                  'assets/wblv_013.dat'

DatLevelDemo:
                        ; line 0
                        dc.b 0,0,0,0,6,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,0,0,0,0
                        ; line 1
                        dc.b 0,0,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,0,0
                        ; line 2
                        dc.b 0,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,0
                        ; line 3
                        dc.b 0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0
                        ; line 4
                        dc.b 0,7,67,70,69,74,73,78,77,82,81,86,85,90,89,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0
                        ; line 5
                        dc.b 0,7,6,5,7,6,5,7,6,5,7,6,5,7,6,5,6,5,7,7,7,6,5,7,6,5,7,6,5,7,6,5,7,6,5,7,6,5,7,0
                        ; line 6
                        dc.b 0,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,6,5,0
                        ; line 7
                        dc.b 0,0,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,6,4,4,5,0,0
                        ; line 8
                        dc.b 0,0,0,0,6,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,0,0,0,0
                        ; line 9
                        ds.b 40
;
                        even
DatLevelList:           dc.w 14
                        dc.l DatLevel0,DatLevel1,DatLevel2,DatLevel3,DatLevel4,DatLevel5,DatLevel6,DatLevel7,DatLevel8,DatLevel9
                        dc.l DatLevel10,DatLevel11,DatLevel12,DatLevel13 ; ,DatLevel14,DatLevel15,DatLevel16,DatLevel17,DatLevel18,DatLevel19
