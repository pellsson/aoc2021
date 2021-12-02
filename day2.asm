INPUT .equ WORK
SAVED_SEQUENCE .equ WORK+$4
Pos .equ WORK+$8
Depth .equ WORK+$C
Aim .equ WORK+$10

_read_next:
		ldy #0
		lda [INPUT], Y
		inc INPUT
		bne .no_high
		inc INPUT+1
.no_high:
		rts

day2_pass_a:
		jsr read_next
		tax
		jsr read_next
		sta MathRhs
		cpx #'f'
		beq .forward
		cpx #'d'
		beq .down
		; up
		tmm32 MathLhs, Depth
		jsr math_sub32
		tmm32 Depth, MathOut
		rts
.forward:
		tmm32 MathLhs, Pos
		jsr math_add32
		tmm32 Pos, MathOut
		rts
.down:
		tmm32 MathLhs, Depth
		jsr math_add32
		tmm32 Depth, MathOut
		rts

day2_solve_a:
		lda #LOW(day2_input_a)
		sta INPUT
		lda #HIGH(day2_input_a)
		sta INPUT+1
.keep_solving:
		jsr day2_pass_a
		lda #LOW(day2_input_a_end)
		cmp INPUT
		bne .keep_solving
		lda #HIGH(day2_input_a_end)
		cmp INPUT+1
		bne .keep_solving
day2_calc_result:
		tmm32 MathLhs, Pos
		tmm32 MathRhs, Depth
		jsr math_mul32
		tmm32 Result, MathOut
		rts

day2_pass_b:
		jsr read_next
		tax
		jsr read_next
		sta MathRhs
		lda #0
		sta MathRhs+1
		sta MathRhs+2
		sta MathRhs+3
		cpx #'f'
		beq .forward
		cpx #'d'
		bne .up
		jmp .down
.up:
		tmm32 MathLhs, Aim
		jsr math_sub32
		tmm32 Aim, MathOut ; aim -= v
		rts
.forward:
		tmm32 MathLhs, Pos
		jsr math_add32
		tmm32 Pos, MathOut ; pos += v
		tmm32 MathLhs, Aim
		jsr math_mul32
		tmm32 MathRhs, MathOut ; tmp = aim*v
		tmm32 MathLhs, Depth
		jsr math_add32
		tmm32 Depth, MathOut
		rts
.down:
		tmm32 MathLhs, Aim
		jsr math_add32
		tmm32 Aim, MathOut ; aim += v
		rts

day2_solve_b:
		lda #LOW(day2_input_a) ; Same input again (Thanks :))
		sta INPUT
		lda #HIGH(day2_input_a)
		sta INPUT+1
.keep_solving:
		jsr day2_pass_b
		lda #LOW(day2_input_a_end)
		cmp INPUT
		bne .keep_solving
		lda #HIGH(day2_input_a_end)
		cmp INPUT+1
		bne .keep_solving
		jmp day2_calc_result