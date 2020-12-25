; ================================================================================================================
; (C) 2020 David SPORN
; Distributed AS IS, in the hope that it will be useful, but WITHOUT ANY WARRANTY
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; ================================================================================================================
; Parser of a set of level in textual representation (human readable)
; ================================================================================================================
; It's a bit complex, so it will use the C calling convention (parameters stacked in reverse orders), so that
; calling the parser will use all available registers in fixed manners.
;
; * stack your registers before,
; * stack the parameters
; * call/jump to the subroutine
; * unstack parameters
; * use or ditch return values
; * restore your registers after.
;
; The parser will ignore any character beyond the 40th of each line.
; ================================================================================================================
; # character qualifier
;
; Each character (Basic latin range only : 1..127 / $01..$7f) is mapped to a qualifier that allows deciding
; what to do with it :
;
; |Qualifier|Description                      |
; |---------|---------------------------------|
; |0        |Ignore, scan next char           |
; |1        |This char marks the end of a line|
; |2        |Blank, use ' ' as the char       |
; |3        |Use the char as is               |
;
; The parser will use the LF control character as line ending, and ignore the CR control character.
; Thus it will not support old MacOs convention (CR control character as line ending).
;
; Only valid characters, as well as some special characters for the parser ('#', '>', '*', '`'), will be tagged with qualifier 3.
;
; ================================================================================================================
; # character map
;
; See the level specification to see the list of displayable characters and their index.
;
; Each character is converted to an index. To accomodate 'formatting' (here, it will be using a different font),
; the real index is preshifted to the left by 2 bits. The 2 least significant bits will be coding the font to use :
;
; * 0 : normal
; * 1 : 'italic'
; * 2 : 'bold'
; * 3 : 'bold italic'
;
; The 'italic' is encoded by surrounding emphasized text with '*'. The 'bold' is encoded by surrounding emphasized
; text with '**'
;
; ================================================================================================================
; # Text encoding
;
; There are 48 codepoints (c), from $0 to $29. A character may be in bold (b) and/or italic (i). An character
; is thus encoded with one byte following this bit layout : ccccccbi.
;
; e.g. 'a' without emphasis is $28 = $a << 2 | $0 = %1010 << 2 | %0 = %101000
; e.g. 'a' with bold emphasis is $2a = $a << 2 | $2 = %1010 << 2 | %10 = %101010
;
; ================================================================================================================
; # Parser state machine
;
; A full word will be used to store the state of the parser state machine. The most significant byte will
; be the main state, and the least significant byte will store a counter.
;
; In other words, the actual state and a counter are packed together.
;
; The states and transition are the following :
;
; * 0 : Wait for level data.
;   * Line starta with token '#' : ignore, go to state 1, reset counter
;   * Other lines are ignored
; * 1 : Valid lines are added to the level text data, counter is incremented with each valid line.
;   * Empty lines, line starting with token '>' are ignored
;   * Line starting with token '```' : ignore, go to state 3, reset counter
;   * Valid line : convert and add text line to level data, increment counter, if counter is 4, go to state 2
; * 2 : Wait for brick layout data
;  * Line starting with token '```' : ignore, go to state 3, reset counter
;  * Other lines are ignored
; * 3 : Valid lines are added to the level brick layout data, counter is incremented with each valid line.
;  * Each line : convert and add brick layout to level data, increment counter, if counter is 10, go to state 4
;  * Line starting with token '```' : ignore, go to state 0.
; * 4 : Wait for end of layout data
;  * Line starting with token '```' : ignore, go to state 0.
;  * Other lines are ignored.
;
; ================================================================================================================
; # level handler
;
; A subroutine using C calling convention, to use the level data that has just been parsed into ingame binary data.
;
; void handleLevel(ptr levelData)
; ================================================================================================================
; Special brick values, preshifted by 2 bits to the left (mul by 4) to be combined with limit bits
LvlParser_BRICK_NORMAL_1 = $4
LvlParser_BRICK_STAR    = $40
LvlParser_BRICK_KEY     = $44
LvlParser_BRICK_EXIT    = $48
LvlParser_BRICK_GLUE    = $4c
LvlParser_BRICK_JUGG    = $50
LvlParser_BRICK_SHALLOW = $54
;
; ================================================================================================================
; Line structure
; At the same time a Pascal string and a C string.
LvlParser_TxtLine_MAXSIZE = 40
                        rsreset
LvlParser_TxtLine_Size  rs.b 1
LvlParser_TxtLine_Data  rs.b 41
SIZEOF_LvlParser_TxtLine rs.b 0

LvlParser_TxtLine_clear macro
                        ; Fill with 0 the whole structure. MUST start at word boundary or will crash.
                        ; 1 - address register, start of structure
                        ; 2 - spare data register, will be cleared
                        ; 3 - spare address register, will be the ptr to the next free character
                        ; --
                        ; \2 := 0, to be copied over the full structure
                        moveq                   #0,\2
                        move.l                  \1,\3
                        rept                    10
                        move.l                  \2,(\3)+
                        endr
                        move.w                  \2,(\3)+
                        ; \3 := ptr to the start of data
                        lea                     LvlParser_TxtLine_Data(\1),\3
                        endm
;
; ================================================================================================================
; Level under construction structure
                        rsreset
LvlParser_Data_Curs     rs.w 1 ; displacement to add from the start of the structure to the data to put in.
LvlParser_Data_Text     rs.b 160 ; 4 lines of 40 characters
LvlParser_Data_Layout   rs.b 400 ; 10 lines of 40 bytes.
SIZEOF_LvlParser_Data   rs.b 0

LvlParser_Data_clear    macro
                        ; Fill the text lines with the code for unformatted space, fill the layout with zeros, and init cursor
                        ; 1 - address register, start of structure (MUST be even)
                        ; 2 - spare data register.
                        ; --
                        ; save \1
                        move.l                  \1,-(sp)
                        move.w                  #LvlParser_Data_Text,(\1)+
                        ; \2 := quadruple regular space
                        move.l                  #$90909090,\2
                        rept 40
                        move.w                  \2,(\1)+
                        endr
                        ; \2 := 0
                        moveq                   #0,\2
                        rept 100
                        move.w                  \2,(\1)+
                        endr
                        ; restore \1
                        move.l                  (sp)+,\1
                        endm

LvlParser_Data_nextLine macro
                        ; Update the displacement by 40
                        ; 1 - address register, start of structure (MUST be even)
                        ; 2 - spare data register.
                        ; --
                        ; \2 := displacement
                        moveq                   #0,\2
                        move.w                  (\1),\2
                        ; -- update and save
                        add.w                   #40,\2
                        move.w                  \2,(\1)
                        endm

LvlParser_Data_endOfText macro
                        ; Update the displacement to be at the start of the brick layout data
                        ; 1 - address register, start of structure (MUST be even)
                        ; --
                        move.w                  #LvlParser_Data_Layout,(\1)
                        endm
; ================================================================================================================
; Entry point of the parser
; ================================================================================================================
LvlParser_parse:
                        ; LvlParser_parse(ptr streamStart, ptr streamEnd, ptr levelHandler,ptr charQualMap,ptr charMap)
                        ; @param streamStart : start of the byte stream to parse (included).
                        ; @param streamEnd : end of the byte stream (excluded).
                        ; @param levelHandler : subroutine to jump to when one level data is completely parsed
                        ; @param charQualMap : mapping source byte -> char qualifier (byte), see 'character qualifier'
                        ; @param charMap : the transcoding map to encode ascii chars into ingame text data.
                        ; @param dataLevel : start ptr to the level data. Basically 4x42 bytes of encoded text data followed by 400 bytes of brick layout.
                        ; @param charToBrickMap : map to convert character to normalized brick code.
                        ; --
                        ; -- init
                        ; a6 := charQualMap
                        move.l                  16(sp),a6
                        ; a5 := streamStart, cursor to next byte
                        move.l                  4(sp),a5
                        ; d7 := streamEnd
                        move.l                  8(sp),d7
                        ; -- sanity check
                        cmp.l                   d7,a5
                        ; there is something to parse if (d7 > a5)
                        bmi                     .canParse
                        ; else nothing to do
                        rts
.canParse
                        ; -- start parsing
                        ; d6 := the parser state (low word), and displacement (high word) from the start of the data level..
                        moveq                   #0,d6
                        ; a4 := line structure
                        ; d5 := spare data register for the clearing / line size
                        ; a3 := spare data register / ptr to next free character in line (= where to put next char)
                        lea                     LvlParser_nextLine,a4
                        LvlParser_TxtLine_clear a4,d5,a3
                        ; -- scan the stream
                        ; clear d4-d0
                        moveq                   #0,d4
                        moveq                   #0,d3
                        moveq                   #0,d2
                        moveq                   #0,d1
                        moveq                   #0,d0
                        ; d4 := next byte
.nextChar               move.b                  (a5)+,d4
                        bsr                     LvlParser_handleChar
                        ; -- boundary check
                        cmp.l                   d7,a5
                        bmi                     .nextChar
                        rts
;
;
LvlParser_handleChar:
                        ; process a character (ignore it, append it to the current line, ...)
                        ; when reaching the end of line, gives the control to the line handler.
                        ; -- context
                        ; a6 - charQualMap
                        ; a5 - ptr next stream byte
                        ; a4 - line structure
                        ; a3 - ptr to next character position in line (where to put next character)
                        ; d7 - streamEnd
                        ; d6 - parser state
                        ; d5 - current size of the accumulated line data
                        ; d4 - char to process
                        ; --
                        btst.b                  #7,d4
                        ; -- accept character codes that are < 128 (inside basic latin range)
                        beq                     .isInRange
                        rts
.isInRange
                        ; d3 := character qualifier
                        move.b                  (a6,d4),d3
                        ; -- switch (d3)
                        tst.b                   d3
                        ; -- not 0
                        bne                     .notIgnore
                        rts
.notIgnore
                        cmp.b                   #1,d3
                        bne                     .notEndOfLine
                        ; -- save line size and zero-terminate line
                        move.b                  d5,(a4)
                        move.b                  #0,(a3)
                        ; -- proccess line
                        bsr                     LvlParser_handleLine
                        ; -- reset line
                        LvlParser_TxtLine_clear a4,d5,a3
                        ; -- clear d4-d0
                        moveq                   #0,d4
                        moveq                   #0,d3
                        moveq                   #0,d2
                        moveq                   #0,d1
                        moveq                   #0,d0
                        rts
.notEndOfLine
                        cmp.b                   #LvlParser_TxtLine_MAXSIZE,d5
                        ; if line is not full, one can push another char inside
                        bmi                     .hasCapacity
                        rts
.hasCapacity
                        cmp.b                   #2,d3
                        ; push the character as is if it is not blank
                        bne                     .pushChar
                        ; else force ' ' (allows tabulations to be converted into spaces)
                        move.b                  #$20,d3
.pushChar
                        move.b                  d4,(a3)+
                        addq.b                  #1,d5
                        rts
;
;
LvlParser_handleLine:
                        ; Process a line, if not empty.
                        ; - Look for a starting token (like '#', '```', '>')
                        ; - if a line is to be included in level data, dispatch to LvlParser_handleLineOfText and
                        ;   LvlParser_handleLineOfBrickLayout depending the state of the parsing.
                        ; -- context
                        ; a6 - charQualMap
                        ; a5 - ptr next stream byte
                        ; a4 - line structure
                        ; d7 - streamEnd
                        ; d6 - parser state
                        ; d5 - current size of the accumulated line data
                        ; --
                        tst.b                   d5
                        ; do handle the line if not empty line
                        bne                     .isNotEmpty
                        rts
.isNotEmpty
                        ; -- trim the line on the left
                        ; a3 := start of the line data
                        lea                     LvlParser_TxtLine_Data(a4),a3
                        ; d4 := spare data register to test character
                        moveq                   #0,d4
                        ; fix d5 := loop over the characters of the line.
                        subq.w                  #1,d5
.testForBlank
                        move.b                  (a3)+,d4
                        cmp.b                   #' ',d4
                        ; -- break if not a space
                        bne                     .isNotBlank
                        dbf                     d5,.testForBlank
                        ; -- blank line, ignore
                        rts
.isNotBlank
                        ; fixes d5 := length of the line trimmed on the left
                        addq.w                  #1,d5
                        ; fixes a3 := start of the line trimmed on the left
                        subq.l                  #1,a3
                        ; look for tokens, then do stuff
                        ; -- try to get a token : a sequence of up to 3 non blank characters
                        ; -- if there is no token, the token will be set to 0
                        ; a2 := spare address to compute line limit
                        lea                     (a3,d5),a2
                        ; d4 := end of line
                        move.l                  a2,d4
                        ; a2 := char scanner
                        move.l                  a3,a2
                        ; d3 := to compute and store the token
                        moveq                   #0,d3
                        ; d2 := peek next char
                        moveq                   #0,d2
                        rept 3
                        move.b                  (a2)+,d2
                        cmp.b                   #' ',d2
                        ; -- stop when end of token
                        beq                     .doneScanForToken
                        ; -- else append to token
                        lsl.l                   #8,d3
                        or.b                    d2,d3
                        ; -- check line boundaries
                        cmp.l                   d4,a2
                        beq                     .doneScanForToken
                        endr
                        ; -- peek a last time, it's a token if one get ' '
                        move.b                  (a2),d2
                        cmp.b                   #' ',d2
                        beq                     .doneScanForToken
                        ; -- at this point there is in fact no token
                        moveq                   #0,d3
.doneScanForToken
; ====
                        ; a2 := level data structure (32 = 20 + 12)
                        ; (the stacks starts with 3 ptr for the 3 rts = 12 bytes.)
                        move.l                  32(sp),a2
                        ; -- select state
                        cmp.w                   #$400,d6
                        bmi                     .case3
                        ; -- case 4
                        ; ---- select token
                        cmp.l                   #'```',d3
                        bne                     .case4_not_end_layout
                        ; ---- case : code fence
                        ; -- prepare to call to level data handler
                        ; (the stacks starts with 3 ptr for the 3 rts = 12 bytes.)
                        ; a1 := pointer to level handler (20 = 12 + 8)
                        DerefPtrToPtr           20(sp),a1
                        ; save registers
                        movem.l                 a0-a6/d0-d7,-(sp)
                        ; -- call level handler
                        ; push a2 (level data structure)
                        move.l                  a2,-(sp)
                        jsr                     (a1)
                        ; fix stack
                        addq.l                  #4,sp
                        ; restore registers
                        movem.l                 (sp)+,a0-a6/d0-d7
                        ; -- prepare parser for next level data
                        ; d6 := change state to #0
                        move.w                  #$0,d6
                        ; reset level Data
                        LvlParser_Data_clear    a2,d2
                        rts
.case4_not_end_layout
                        ; ---- default
                        rts
; ====
.case3
                        ; -- select state
                        cmp.w                   #$300,d6
                        bmi                     .case2
                        ; -- case 3
                        ; ---- select token
                        cmp.l                   #'```',d3
                        bne                     .case3_not_end_layout
                        ; ---- case : code fence
                        ; -- prepare to call to level data handler
                        ; (the stacks starts with 3 ptr for the 3 rts = 12 bytes.)
                        ; a1 := pointer to level handler (20 = 12 + 8)
                        DerefPtrToPtr           20(sp),a1
                        ; save registers
                        movem.l                 a0-a6/d0-d7,-(sp)
                        ; -- call level handler
                        ; push a2 (level data structure)
                        move.l                  a2,-(sp)
                        jsr                     (a1)
                        ; fix stack
                        addq.l                  #4,sp
                        ; restore registers
                        movem.l                 (sp)+,a0-a6/d0-d7
                        ; -- prepare parser for next level data
                        ; d6 := change state to #0
                        move.w                  #$0,d6
                        ; reset level Data
                        LvlParser_Data_clear    a2,d2
                        rts
.case3_not_end_layout
                        ; ---- default
                        ; -- prepare and call to LvlParser_handleLineOfBrickLayout
                        ; (the stacks starts with 3 ptr for the 3 rts = 12 bytes.)
                        ; a6 := charMap (36 = 24 + 12)
                        move.l                  36(sp),a6
                        ; append to level data
                        bsr                     LvlParser_handleLineOfBrickLayout
                        ; -- restore a6 := charQualMap (24 = 12 + 12)
                        move.l                  24(sp),a6
                        ; -- update counter
                        addq.w                  #1,d6
                        cmp.w                   #$310,d6
                        beq                     .case3_layout_data_full
                        rts
.case3_layout_data_full
                        ; d6 := change state to #4
                        move.w                  #$400,d6
                        rts
; ====
.case2
                        ; -- select state
                        cmp.w                   #$200,d6
                        bmi                     .case1
                        ; -- case 3
                        ; ---- select token
                        cmp.l                   #'```',d3
                        bne                     .case2_not_start_layout
                        ; ---- case : code fence
                        ; d6 := change state to #3
                        move.w                  #$300,d6
                        ; point to start of brick layout data
                        LvlParser_Data_endOfText a2
                        rts
.case2_not_start_layout
                        ; ---- default
                        rts
; ====
.case1
                        ; -- select state
                        cmp.w                   #$100,d6
                        bmi                     .default
                        ; -- case 1
                        ; ---- select token
                        cmp.l                   #'>',d3
                        bne                     .case1_not_comment
                        ; ---- case : comment
                        rts
.case1_not_comment
                        ; ---- select token
                        cmp.l                   #'```',d3
                        bne                     .case1_not_start_layout
                        ; ---- case : code fence
                        ; d6 := change state to #3
                        move.w                  #$300,d6
                        ; point to start of brick layout data
                        LvlParser_Data_endOfText a2
                        rts
.case1_not_start_layout
                        ; ---- default
                        ; -- prepare and call to LvlParser_handleLineOfText
                        ; (the stacks starts with 3 ptr for the 3 rts = 12 bytes.)
                        ; a6 := charMap (28 = 16 + 12)
                        move.l                  28(sp),a6
                        ; append to level data
                        bsr                     LvlParser_handleLineOfText
                        ; -- restore a6 := charQualMap (24 = 12 + 12)
                        move.l                  24(sp),a6
                        ; -- update counter
                        addq.w                  #1,d6
                        cmp.w                   #$104,d6
                        beq                     .case1_text_data_full
                        rts
.case1_text_data_full
                        ; d6 := change state to #2
                        move.w                  #$200,d6
                        rts
; ====
.default
                        ; -- case 0
                        cmp.l                   #'#',d3
                        beq                     .default_matches_hash
                        ; -- other lines
                        rts
.default_matches_hash
                        ; d6 := change state to #1
                        move.w                  #$100,d6
                        rts
;
;
;
LvlParser_handleLineOfText:
                        ; Encode a line of text.
                        ; -- context
                        ; a6 - charMap
                        ; a5 - ptr next stream byte
                        ; a4 - line structure
                        ; a3 - start of the line trimmed on the left
                        ; a2 - ptr to level data under construction
                        ; d7 - streamEnd
                        ; d6 - parser state
                        ; d5 - length of the line trimmed on the left
                        ; d4 - address of end of line
                        ; --
                        ; d3 := formatting bits, to be combined with or to the encoded char.
                        moveq                   #0,d3
                        ; Clear d2,d1
                        moveq                   #0,d2
                        moveq                   #0,d1
                        ; a1 := character scanner
                        move.l                  a3,a1
                        ; d2 := displacement to the start of destination address
                        move.w                  (a2),d2
                        ; a0 := start of destination data
                        lea                     (a2,d2),a0
                        ; clear d2
                        moveq                   #0,d2
                        ; fix d5 to loop over. (no need to restore)
                        subq.w                  #1,d5
.nextChar
                        ; d2 := next input char
                        move.b                  (a1)+,d2
                        cmp.b                   #'*',d2
                        ; -- if start of formatting sequence of '*'
                        beq                     .manageFormatting
                        ; -- else convert char, apply (OR) d3, push
                        ; d2 := converted char
                        move.b                  (a6,d2),d2
                        or.b                    d3,d2
                        move.b                  d2,(a0)+
                        ; -- continue
                        dbf                     d5,.nextChar
                        bra                     .commitLine
.manageFormatting
                        ; -- process formatting sequences of '*'
                        ; d1 := peek at a1
                        move.b                  (a1),d1
                        cmp.b                   d2,d1
                        ; -- if it's a sequence of 2 '*'
                        beq                     .toggleBold
                        ; -- else toggle italic
                        bchg.l                  #0,d3
                        ; -- continue
                        dbf                     d5,.nextChar
.toggleBold
                        ; -- toggle bold
                        bchg.l                  #1,d3
                        ; -- advance cursor, counter
                        addq.l                  #1,a1
                        subq.w                  #1,d5
                        ; -- continue
                        dbf                     d5,.nextChar
.commitLine
                        ; -- commit line
                        LvlParser_Data_nextLine a2,d2
                        rts
;
;
;
LvlParser_handleLineOfBrickLayout:
                        ; Encode a line of brick layout.
                        ; -- context
                        ; a6 - charToBrickMap
                        ; a5 - ptr next stream byte
                        ; a4 - line structure
                        ; a3 - start of the line trimmed on the left
                        ; a2 - ptr to level data under construction
                        ; d7 - streamEnd
                        ; d6 - parser state
                        ; d5 - length of the line trimmed on the left
                        ; d4 - address of end of line
                        ; --
                        ; d3 := latest normal bricks started (fixed to normal brick that immediately breaks).
                        moveq                   #LvlParser_BRICK_NORMAL_1,d3
                        ; Clear d2,d1
                        moveq                   #0,d2
                        moveq                   #0,d1
                        ; a1 := character scanner
                        move.l                  a3,a1
                        ; d2 := displacement to the start of destination address
                        move.w                  (a2),d2
                        ; a0 := start of destination data
                        lea                     (a2,d2),a0
                        ; clear d2
                        moveq                   #0,d2
                        ; fix d5 to loop over. (no need to restore)
                        subq.w                  #1,d5
.nextChar
                        ; d2 := next input char
                        move.b                  (a1)+,d2
                        ; d2 := converted char
                        move.b                  (a6,d2),d2
                        ; d1 := clear result byte
                        moveq                   #0,d1
                        ; -- select brick code
                        cmp.b                   #'.',d2
                        bne                     .notDot
                        ; -- case '.' : empty tile
                        move.b                  d1,(a0)+
                        ; -- continue
                        dbf                     d5,.nextChar
                        bra                     .commitLine
.notDot
                        ; -- select brick code
                        cmp.b                   #'*',d2
                        bne                     .notStar
                        ; -- case '*' : brick 'star', fixed width of 1
                        ; setup brick code, combine with limit bits, push
                        ; d2 := combine brick code and limits
                        move.b                  #LvlParser_BRICK_STAR,d2
                        or.b                    #%11,d2
                        move.b                  d2,(a0)+
                        ; -- continue
                        dbf                     d5,.nextChar
                        bra                     .commitLine
.notStar
                        ; -- from this point, deals with bricks of fixed width of 2 tiles,
                        ; -- there will be a common processing (push 2 tiles, adjust scanner and loop)
                        ; -- select brick code
                        cmp.b                   #'G',d2
                        bne                     .notGlue
                        ; -- case special brick 'Glue'
                        move.b                  #LvlParser_BRICK_GLUE,d2
                        bra                     .doPush2TilesBrick
.notGlue
                        ; -- select brick code
                        cmp.b                   #'J',d2
                        bne                     .notJuggernaut
                        ; -- case special brick 'Juggernaut'
                        move.b                  #LvlParser_BRICK_JUGG,d2
                        bra                     .doPush2TilesBrick
.notJuggernaut
                        ; -- select brick code
                        cmp.b                   #'O',d2
                        bne                     .notShallow
                        ; -- case special brick 'Shallow'
                        move.b                  #LvlParser_BRICK_SHALLOW,d2
                        bra                     .doPush2TilesBrick
.notShallow
                        ; -- select brick code
                        cmp.b                   #'W',d2
                        bne                     .notKey
                        ; -- case special brick 'Key'
                        move.b                  #LvlParser_BRICK_KEY,d2
                        bra                     .doPush2TilesBrick
.notKey
                        ; -- select brick code
                        cmp.b                   #'X',d2
                        bne                     .notExit
                        ; -- case special brick ''
                        move.b                  #LvlParser_BRICK_EXIT,d2
.doPush2TilesBrick
                        ; -- setup start of brick and push
                        ; d1 := start of brick (d2 OR %10)
                        moveq                   #%10,d1
                        or.b                    d2,d1
                        move.b                  d1,(a0)+
                        ; -- setup end of brick and push
                        moveq                   #1,d1
                        or.b                    d2,d1
                        move.b                  d1,(a0)+
                        ; -- fix scanner and loop
                        addq.l                  #1,a1
                        subq.l                  #1,d5
                        ; -- continue
                        dbf                     d5,.nextChar
                        bra                     .commitLine
.notExit
                        ;//HERE
                        ; -- from this point, deals with the variable length bricks
                        ; -- select brick code
                        cmp.b                   #'-',d2
                        bne                     .notExtension
                        ; -- else continuation of the regular bricks
                        ; d2 := continuation of latest started regular brick
                        move.b                  d3,d2
                        bra                     .peekNextBeforePush
.notExtension
                        ; -- default : regular brick, no resistance
                        ; d3 := set the type of regular brick (commented out for prelude)
                        ; move.l                #LvlParser_BRICK_NORMAL_1,d3
                        ; d2 := start of new regular bricks = d3 with bit 1 set
                        move.b                  d3,d2
                        bset.l                  #1,d2
.peekNextBeforePush
                        ; -- peek next code (fortunately, '-' is encoded as '-'...)
                        ; d1 := next brick
                        move.b                  (a1),d1
                        cmp.b                   #'-',d1
                        beq                     .pushRegularBrick
                        ; -- else terminate the brick (bit 0)
                        bset.l                  #0,d2
.pushRegularBrick
                        move.b                  d2,(a0)+
                        ; -- continue
                        dbf                     d5,.nextChar
                        ;
                        ;
.commitLine
                        LvlParser_Data_nextLine a2,d2
                        rts
;
;

LvlParser_nextLine      ds.b                    SIZEOF_LvlParser_TxtLine
LvlParser_MAP_CHAR_QUAL
                        ; Qualifier by ascii code.
                        ; - map characters from 0 to 127 (Basic latin)
                        ; Range $0x - $09 (horiz. tab.) is blank, $10 (line feed) is end of line
                        dc.b                    0,0,0,0,0,0,0,0,0,2,1,0,0,0,0,0
                        ; Range $1x
                        dc.b                    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                        ; Range $2x - $23 (#) and $2a (*) for the parser
                        dc.b                    2,3,3,3,0,0,0,3,3,3,3,0,3,3,3,3
                        ; Range $3x - $3e (>) for the parser
                        dc.b                    3,3,3,3,3,3,3,3,3,3,0,0,0,0,3,3
                        ; Range $4x
                        dc.b                    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                        ; Range $5x
                        dc.b                    3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0
                        ; Range $6x - $60 (`) for the parser
                        dc.b                    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
                        ; Range $7x
                        dc.b                    3,3,3,3,3,3,3,3,3,3,3,0,0,0,0,0
;
LvlParser_MAP_CHAR
                        ; Character encoding by ascii code.
                        ; - map chars from 0 to 127 (Basic latin)
                        ; - 0 is a valid code, so unsupported ascii codes will be encoded with $ff
                        ; - the value is preshifted to the left by 2 positions.
                        ; Range $0x
                        dc.b                    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
                        ; Range $1x
                        dc.b                    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
                        ; Range $2x
                        dc.b                    $90,$98,$a8,$ff,$ff,$ff,$ff,$ac,$b0,$b4,$ff,$ff,$a0,$a4,$94,$b8
                        ; Range $3x
                        dc.b                    $00,$04,$08,$0c,$10,$14,$18,$1c,$20,$24,$ff,$ff,$ff,$ff,$ff,$9c
                        ; Range $4x
                        dc.b                    $bc,$28,$2c,$30,$34,$38,$3c,$40,$44,$48,$4c,$50,$54,$58,$5c,$60
                        ; Range $5x
                        dc.b                    $64,$68,$6c,$70,$74,$78,$7c,$80,$84,$88,$8c,$ff,$ff,$ff,$ff,$ff
                        ; Range $6x
                        dc.b                    $ff,$28,$2c,$30,$34,$38,$3c,$40,$44,$48,$4c,$50,$54,$58,$5c,$60
                        ; Range $7x
                        dc.b                    $64,$68,$6c,$70,$74,$78,$7c,$80,$84,$88,$8c,$ff,$ff,$ff,$ff,$ff
;
;
LvlParser_MAP_BRICKS
                        ; Bricks code by ascii code.
                        ; - map chars from 0 to 127 (Basic latin)
                        ; - unsupported ascii codes will be encoded with '.' (empty space)
                        ; Range $0x
                        dc.b                    '.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.'
                        ; Range $1x
                        dc.b                    '.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.'
                        ; Range $2x
                        dc.b                    '.','.','.','.','.','.','.','.','.','.','*','.','.','-','.','.'
                        ; Range $3x - digit '1' to '9' are simple bricks
                        dc.b                    '.','1','1','1','1','1','1','1','1','1','.','.','.','.','.','.'
                        ; Range $4x - chars 'A' to 'F' are simple bricks
                        dc.b                    '.','1','1','1','1','1','1','G','.','.','J','.','.','.','.','O'
                        ; Range $5x
                        dc.b                    '.','.','.','.','.','.','.','W','X','.','.','.','.','.','.','.'
                        ; Range $6x
                        dc.b                    '.','1','1','1','1','1','1','G','.','.','J','.','.','.','.','O'
                        ; Range $7x
                        dc.b                    '.','.','.','.','.','.','.','W','X','.','.','.','.','.','.','.'
;
