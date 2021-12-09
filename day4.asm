INPUT .equ WORK
Number .equ WORK+3
NumberPos .equ WORK+4
BoardId .equ WORK+5
Col .equ WORK+8
Row .equ WORK+9
BoardHead .equ WORK+$a ; and b
UnmarkedSum .equ WORK+$c
BoardIter .equ WORK+$10 ; and 11

SolvedBoards .equ $6000
BoardsData .equ $6100

BOARD_SIZE .equ 5*5

set_board_solved:
		ldx BoardId
		lda #1
		sta SolvedBoards, x
		rts

check_full_row:
		ldy Col
.next:
		lda [BoardHead], Y
		and #$80
		beq .not_solved
		iny
		iny
		iny
		iny
		iny
		cpy #25
		bmi .next
		jmp set_board_solved
.not_solved:
		rts		

check_full_col:
		lda #0
		ldx Row
.seek_more:
		dex
		bmi .row_found
		clc
		adc #5
		bne .seek_more ; always jumps
.row_found:
		ldx #4
		tay
.gogo:
		lda [BoardHead], Y
		and #$80
		beq .not_solved
		iny
		dex
		bpl .gogo
		jmp set_board_solved
.not_solved:
		rts

add_sum:
		sta MathRhs
		lda #0
		sta MathRhs+1 ; a bit paranoid but w/e
		lda UnmarkedSum
		sta MathLhs
		lda UnmarkedSum+1
		sta MathLhs+1
		jsr math_add16
		lda MathOut
		sta UnmarkedSum
		lda MathOut+1
		sta UnmarkedSum+1
		rts

finalize_result:
		lda Number
		sta MathRhs
		lda #0
		sta MathRhs+1
		lda UnmarkedSum
		sta MathLhs
		lda UnmarkedSum+1
		sta MathLhs+1
		jsr math_mul32
		lda MathOut
		sta Result
		lda MathOut+1
		sta Result+1
		lda MathOut+2
		sta Result+2
		lda MathOut+3
		sta Result+3
		rts

check_solved:
		lda #0
		sta UnmarkedSum
		sta UnmarkedSum+1
		jsr check_full_col
		jsr check_full_row
		ldx BoardId
		lda SolvedBoards, x
		beq .not_solved
		ldy #BOARD_SIZE-1
.count_next:
		lda [BoardHead], Y
		and #$80
		bne .dont_count
		lda [BoardHead], Y	
		jsr add_sum
.dont_count:
		dey
		bpl .count_next
		jmp finalize_result
.not_solved:
		rts

ball_picked_board:
		lda INPUT
		sta BoardHead
		lda INPUT+1
		sta BoardHead+1
		lda #0
		sta Col
		sta Row
.find_number:
		jsr peek_next
		cmp Number
		bne .next_tile
		lda #$80
		ora [INPUT], Y
		sta [INPUT], Y
		jmp check_solved
.next_tile:
		jsr skip_next
		ldx Col
		inx
		stx Col
		cpx #5
		bne .find_number
		ldx #0
		stx Col
		ldx Row
		inx
		stx Row
		cpx #5
		bne .find_number
		rts

ball_picked:
		lda #LOW(BoardsData)
		sta BoardIter
		lda #HIGH(BoardsData)
		sta BoardIter+1
		ldx #0
		stx BoardId
.next_board:
		lda SolvedBoards, x
		bne .inc_board
		lda BoardIter
		sta INPUT
		lda BoardIter+1
		sta INPUT+1
		jsr ball_picked_board
.inc_board:
		macro_add16_imm8 BoardIter, BOARD_SIZE
		ldx BoardId
		inx
		stx BoardId
		cpx #((day4_boards_end-day4_boards)/BOARD_SIZE)
		bne .next_board
		rts

day4_init:
		lda #0
		ldx #0
.init_solved:
		sta SolvedBoards, x
		inx 
		bne .init_solved
		macro_memcpy day4_boards, day4_boards_end, BoardsData
		ldx #0
		rts

day4_solve_a:
		jsr day4_init
.pick_next_number:
		lda day4_numbers, x
		sta Number
		stx NumberPos
		jsr ball_picked
		lda Result
		ora Result+1
		ora Result+2
		ora Result+3
		bne .done
		ldx NumberPos
		inx
		cpx #(day4_numbers_end-day4_numbers) 
		bne .pick_next_number
.done:
		rts

day4_solve_b:
		jsr day4_init
.pick_next_number:
		lda day4_numbers, x
		sta Number
		stx NumberPos
		jsr ball_picked
		ldx NumberPos
		inx
		cpx #(day4_numbers_end-day4_numbers) 
		bne .pick_next_number
.done:
		rts