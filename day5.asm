INPUT .equ WORK
D5_IncludeDiagonal .equ WORK+$2
D5_GX .equ WORK+3 ; and 4
D5_GY .equ WORK+5 ; and 6
D5_Ptr .equ WORK+7 ; and 8

D5_x0 .equ WORK+$10 ; and 11
D5_y0 .equ WORK+$12 ; and 13
D5_x1 .equ WORK+$14 ; and 15
D5_y1 .equ WORK+$16 ; and 17

D5_minx .equ WORK+$20 ; and 21
D5_maxx .equ WORK+$22 ; and 23
D5_miny .equ WORK+$24 ; and 25
D5_maxy .equ WORK+$26 ; and 27
D5_x .equ WORK+$28 ; and 29
D5_y .equ WORK+$2A ; and 2B
D5_relx .equ WORK+$2C ; and 2D

D5_WindowLeft .equ WORK+$32
D5_WindowPtr .equ WORK+$34

D5_WINDOW_SIZE .equ 50
D5_BOARD_SIZE .equ 1000

d5_read_coords:
		jsr read_next
		sta D5_x0
		jsr read_next
		sta D5_x0+1
		jsr read_next
		sta D5_y0
		jsr read_next
		sta D5_y0+1
		jsr read_next
		sta D5_x1
		jsr read_next
		sta D5_x1+1
		jsr read_next
		sta D5_y1
		jsr read_next
		sta D5_y1+1
		rts

d5_get_diagonal:
		lda D5_x0
		cmp D5_x1
		bne .not_same_x
		lda D5_x0+1
		cmp D5_x1+1
		beq .is_same
.not_same_x:
		lda D5_y0
		cmp D5_y1
		bne .not_same
		lda D5_y0+1
		cmp D5_y1+1
		beq .is_same
.not_same:
		lda #1
		rts
.is_same:
		lda #0
		rts

inc_tile:
		; Relative Y already in MathOut
		macro_mul16_imm16 MathOut, D5_WINDOW_SIZE
		macro_add16 MathOut, D5_relx
		macro_add16_imm16 MathOut, $6000
		ldy #0
		lda [MathOut], Y
		clc
		adc #1
		sta [MathOut], Y
		rts

inc_if_inside:
		macro_sub16_out D5_relx, D5_x, D5_GX
		lda D5_relx+1
		bne .too_far
		lda D5_relx
		cmp #D5_WINDOW_SIZE
		bcs .too_far
		macro_sub16_out MathOut, D5_y, D5_GY
		lda MathOut+1
		bne .too_far
		lda MathOut
		cmp #D5_WINDOW_SIZE
		bcs .too_far
		; Within window, increment.
		jmp inc_tile
.too_far:
		rts

d5_solve_straight:
		macro_min_u16 D5_minx, D5_x0, D5_x1
		macro_max_u16 D5_maxx, D5_x0, D5_x1
		macro_min_u16 D5_miny, D5_y0, D5_y1
		macro_max_u16 D5_maxy, D5_y0, D5_y1
		tmm16 D5_x, D5_minx
		tmm16 D5_y, D5_miny
		macro_add16_imm8 D5_maxx, 1
		macro_add16_imm8 D5_maxy, 1
.next_y:
		lda D5_y
		cmp D5_maxy
		bne .next_x
		lda D5_y+1
		cmp D5_maxy+1
		bne .next_x
		rts
.next_x:
		jsr inc_if_inside
		macro_add16_imm8 D5_x, 1
		lda D5_x
		cmp D5_maxx
		bne .next_x
		lda D5_x+1
		cmp D5_maxx+1
		bne .next_x
		tmm16 D5_x, D5_minx
		macro_add16_imm8 D5_y, 1
		jmp .next_y

d5_solve_diagonal:
		tmm16 D5_x, D5_x0
		tmm16 D5_y, D5_y0
.next:
		lda D5_x
		cmp D5_x1
		bne .not_done
		lda D5_x+1
		cmp D5_x1+1
		bne .not_done
		jmp inc_if_inside
.not_done:
		jsr inc_if_inside
		lda #$01
		sta MathRhs
		lda #$00
		sta MathRhs+1
		macro_is_less_u16 D5_x, D5_x1, .x_is_less
		lda #$ff
		sta MathRhs
		sta MathRhs+1
.x_is_less:
		macro_add16 D5_x, MathRhs
		lda #$01
		sta MathRhs
		lda #$00
		sta MathRhs+1
		macro_is_less_u16 D5_y, D5_y1, .y_is_less
		lda #$ff
		sta MathRhs
		sta MathRhs+1
.y_is_less:
		macro_add16 D5_y, MathRhs
		jmp .next

d5_solve_window:
		macro_memset_pb $6000, $00, D5_WINDOW_SIZE * D5_WINDOW_SIZE
		; Grid cleared
		lda #LOW(day5_input)
		sta INPUT
		lda #HIGH(day5_input)
		sta INPUT+1
.next_line:
		lda #LOW(day5_input_end)
		cmp INPUT
		bne .not_end
		lda #HIGH(day5_input_end)
		cmp INPUT+1
		bne .not_end
		rts
.not_end:
		jsr d5_read_coords
		jsr d5_get_diagonal
		beq .is_straight ; Hor & vert lines always included
		lda D5_IncludeDiagonal
		bne .is_diagonal
		beq .next_line
.is_straight:
		jsr d5_solve_straight
		jmp .next_line
.is_diagonal:
		jsr d5_solve_diagonal
		jmp .next_line

d5_sum_window:
		lda #LOW($6000)
		sta D5_WindowPtr
		lda #HIGH($6000)
		sta D5_WindowPtr+1
		ldy #0
.check_next:
		lda #LOW($6000 + D5_WINDOW_SIZE * D5_WINDOW_SIZE + 1)
		cmp D5_WindowPtr
		bne .add_more
		lda #HIGH($6000 + D5_WINDOW_SIZE * D5_WINDOW_SIZE + 1)
		cmp D5_WindowPtr+1
		bne .add_more
		rts
.add_more:
		lda [D5_WindowPtr], Y
		cmp #2
		bmi .dont_count
		macro_add16_imm8 Result, 1
.dont_count:
		inc D5_WindowPtr
		bne .check_next
		inc D5_WindowPtr+1
		jmp .check_next

d5_log:
		lda #0
		sta PrintColor
		macro_putstr_inline "    Window Done. Sum: "
		inc PrintColor
		lda Result+1
		jsr _puthex
		lda Result
		jsr _puthex
		jmp wait_flush

day5_solve:
		lda #0
		sta D5_GX
		sta D5_GX+1
		sta D5_GY
		sta D5_GY+1
.next_window:
		jsr d5_solve_window
		jsr d5_sum_window
		jsr d5_log
		macro_add16_imm8 D5_GX, D5_WINDOW_SIZE
		lda D5_GX
		cmp #LOW(D5_BOARD_SIZE)
		bne .next_window
		lda D5_GX+1
		cmp #HIGH(D5_BOARD_SIZE)
		bne .next_window
		lda #0
		sta D5_GX
		sta D5_GX+1
		macro_add16_imm8 D5_GY, D5_WINDOW_SIZE
		lda D5_GY
		cmp #LOW(D5_BOARD_SIZE)
		bne .next_window
		lda D5_GY+1
		cmp #HIGH(D5_BOARD_SIZE)
		bne .next_window
		rts

day5_solve_a:
		jmp day5_solve
day5_solve_b:
		inc D5_IncludeDiagonal
		jmp day5_solve
