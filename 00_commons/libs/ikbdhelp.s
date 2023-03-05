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
