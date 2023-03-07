; ================================================================================================================
; (C) 2023 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; REQUIRES macro/input.s,
; ================================================================================================================
; IKBD Helpers
; ---
;
; A set of macros to send command to the IKBD.
; ================================================================================================================
; IKBD Commands opcod enumeration
; > See https://www.kernel.org/doc/Documentation/input/atarikbd.txt
                        rsreset

IKBD_CMD_               rs.b 1
IKBD_CMD_RESET_2        rs.b 6 ; 0x01 -- Reset -- second byte of the command, to push after IKBD_CMD_RESET_1
IKBD_CMD_ST_MS_ACT      rs.b 1 ; 0x07 -- Set mouse action
IKBD_CMD_ST_MS_REL      rs.b 1 ; 0x08 -- Set relative mouse position reporting
IKBD_CMD_ST_MS_ABS      rs.b 1 ; 0x09 -- Set absolute mouse positioning
IKBD_CMD_ST_MS_KCD      rs.b 1 ; 0x0a -- Set mouse keycode mode
IKBD_CMD_ST_MS_THR      rs.b 1 ; 0x0b -- Set mouse threshold
IKBD_CMD_ST_MS_SCL      rs.b 1 ; 0x0c -- Set mouse scale
IKBD_CMD_GT_MS_POS      rs.b 1 ; 0x0d -- Interrogate mouse position
IKBD_CMD_LD_MS_POS      rs.b 1 ; 0x0e -- Load mouse position
IKBD_CMD_ST_MS_Y0B      rs.b 1 ; 0x0f -- Set mouse y=0 at bottom
IKBD_CMD_ST_MS_Y0T      rs.b 1 ; 0x10 -- Set mouse y=0 at top
IKBD_CMD_RESUME         rs.b 1 ; 0x11 -- Resume
IKBD_CMD_MS_OFF         rs.b 1 ; 0x12 -- Disable mouse
IKBD_CMD_PAUSE          rs.b 1 ; 0x13 -- Pause output
IKBD_CMD_ST_JS_EVT      rs.b 1 ; 0x14 -- Set joystick event reporting mode (enable joystick event reporting) 
IKBD_CMD_ST_JS_ITG      rs.b 1 ; 0x15 -- Set joystick interrogation mode (disable joystick event reporting)
IKBD_CMD_GT_JS          rs.b 1 ; 0x16 -- Interrogate joysticks
IKBD_CMD_ST_JS_MON      rs.b 1 ; 0x17 -- Set joystick monitoring
IKBD_CMD_ST_JS_FBM      rs.b 1 ; 0x18 -- Set fire button monitoring
IKBD_CMD_ST_JS_KCD      rs.b 1 ; 0x19 -- Set joystick keycode mode
IKBD_CMD_JS_OFF         rs.b 1 ; 0x1a -- Disable joystick
IKBD_CMD_ST_CLK         rs.b 1 ; 0x1b -- Set time-of-day clock
IKBD_CMD_GT_CLK         rs.b 4 ; 0x1c -- Interrogate time-of-day clock
IKBD_CMD_LD_MEM         rs.b 1 ; 0x20 -- Memory load
IKBD_CMD_RD_MEM         rs.b 1 ; 0x21 -- Memory read
IKBD_CMD_EXEC           rs.b 94; 0x22 -- Controller execute
IKBD_CMD_STATUS_BIT     rs.b 0 ; 0x80 -- Status inquiry bit -- to be OR-ed with a SET command
IKBD_CMD_RESET_1        rs.b 0 ; 0x80 -- Reset -- first byte of the command

; ================================================================================================================
; IKBD String -- a sequence of command for IKBD
; ---
; Modelisation-wise, it's like a Pascal string. And to avoid the general management of an accumulator in most case
; when one send up to three bytes, the three first bytes are directly accessible.
;
                        rsreset

IkbdString_length       rs.w 1 ; Length in bytes corrected for _ikbdws() (i.e. actual length - 1)
IkbdString_firstByte    rs.b 1 ; Quick access to the first byte
IkbdString_secondByte   rs.b 1 ; Quick access to the second byte
IkbdString_thirdByte    rs.b 1 ; Quick access to the third byte
IkbdString_buffer       rs.b 9 ; Remainder of the buffer

SIZEOF_IkbdString       rs.b 0 ;
EVENSIZEOF_IkbdString   rs.b 0 ;

MAX_IkbdString_length   = 11 ; The string is 12 bytes long, thus 12 - 1 = 11. 


; ================================================================================================================
; Builder of a sequence of commands for IKBD
; ---
; Typical use, using a0 as pointer to the string :
;       ikbd_withString      a0,#IKBD_CMD_BUFFER
;       ikbd_pushFirstByte   a0,#IKBD_CMD_MS_OFF
;       ikbd_pushSecondByte  a0,#IKBD_CMD_ST_JS_EVT
;       ikbd_send            a0
; ================================================================================================================
; ================================================================================================================
; Init the given address register as a pointer to the given IKBD string
;
ikbd_withString         macro
                        ;1 - <<this>>, address registry to use, will point to the IkbdString
                        ;2 - address of the IkbdString to use
                        move.l \2,\1
                        endm

; ================================================================================================================
; Push the first byte, and reset the size to a one byte long sequence.
;
ikbd_pushFirstByte      macro
                        ;1 - <<this>>, address registry pointing to the string
                        ;2 - first byte to push
                        move.w #0,IkbdString_length(\1)
                        move.b \2,IkbdString_firstByte(\1)
                        endm

; ================================================================================================================
; Push the second byte, and set the size to a two bytes long sequence. 
;
ikbd_pushSecondByte     macro
                        ;1 - <<this>>, address registry pointing to the string
                        ;2 - byte to push
                        move.w #1,IkbdString_length(\1)
                        move.b \2,IkbdString_secondByte(\1)
                        endm

; ================================================================================================================
; Push the third byte, and set the size to a three bytes long sequence. 
;
ikbd_pushThirdByte      macro
                        ;1 - <<this>>, address registry pointing to the string
                        ;2 - byte to push
                        move.w #2,IkbdString_length(\1)
                        move.b \2,IkbdString_thirdByte(\1)
                        endm

ikbd_ifFullGoto         macro
                        ;1 - <<this>>, address registry pointing to the string
                        ;2 - the label to go to when the string is full
                        ;3 - data regitry to work, NOT restored after use
                        moveq   #0,\3
                        move.w  IkbdString_length(\1),\3
                        cmp.w   #MAX_IkbdString_length,\3
                        bhs     \2 ; Branch if \3 is Higher or Same
                        endm

; ================================================================================================================
; General process of pushing a byte and updating the size accordingly, provided that there is still enough space
; to host the supplemental byte.
; When the buffer is full, there is no change.
;
ikbd_pushByte           macro
                        ;1 - <<this>>, address registry pointing to the string
                        ;2 - byte to push
                        ;3 - address registry to work, restored after use
                        ;4 - data registry to work, restored after use
                        ; ---
                        ; save work data register
                        move.l  \4,-(sp)
                        ; --- test whether the string is already full
                        ; REPLACE WITH : ikbd_ifFullGoto \1,.bufferFull\@,\4
                        moveq   #0,\4
                        move.w  IkbdString_length(\1),\4
                        cmp.w   #MAX_IkbdString_length,\4
                        bhs     .bufferFull\@
                        ; ---
                        ; we can push another byte, save work register
                        move.l  \3,-(sp)
                        addq.w  #1,\4 ; pre-compute length after operation
                        ; \3 := start of buffer + updated length
                        lea     IkbdString_firstByte(\1),\3 
                        add.l   \4,\3
                        ; write byte
                        move.b  \2,(\3)
                        ; save updated length
                        move.w  \4,IkbdString_length(\1)
                        ; ---
                        ; done, restore work registers
                        move.l (sp)+,\3
.bufferFull\@           move.l (sp)+,\4
                        endm

ikbd_send               macro
                        ;1 - <<this>>, address registry pointing to the string
                        _xos_ikbdws IkbdString_length(\1),IkbdString_firstByte(\1)
                        endm

; ================================================================================================================

; ================================================================================================================
