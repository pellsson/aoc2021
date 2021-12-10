INPUT .equ WORK
D7_Curr .equ WORK+2 ; and 3
D7_CostIter .equ WORK+4 ; and 5
D7_V .equ WORK+$10 ; 11,12,13
D7_SmartCrab .equ WORK+$20
d7_find_min:
		; XXX this fails if the smallest number is the last number.
		;     should add some bounds-check...
		lda #$ff
		sta Result
		sta Result+1
		sta Result+2
		sta Result+3
		ldy #0
		lda #LOW($6000)
		sta INPUT
		lda #HIGH($6000)
		sta INPUT+1
.next:
		jsr read_next
		sta D7_V
		jsr read_next
		sta D7_V+1
		jsr read_next
		sta D7_V+2
		jsr read_next
		sta D7_V+3
		cmp Result+3
		bcc .keep
		lda D7_V+2
		cmp Result+2
		bcc .keep
		lda D7_V+1
		cmp Result+1
		bcc .keep
		lda D7_V
		cmp Result
		bcc .keep
		rts
.keep:
		tmm32 Result, D7_V
		jmp .next

smartify:
		lda #0
		sta MathRhs+2
		sta MathRhs+3
    	; (n*(n+1)/2)
    	lda MathLhs
    	sta MathRhs
    	lda MathLhs+1
    	sta MathRhs+1
		macro_add16_imm8 MathLhs, 1 ; (n+1)
		jsr math_mul32 ; n*(n+1)
		tmm32 MathLhs, MathOut
		lsr MathLhs+3
		ror MathLhs+2
		ror MathLhs+1
		ror MathLhs   ;n*(n+1)/2
		rts

d7_log:
		lda #0
		sta PrintColor
		macro_putstr_inline "        Page "
		inc PrintColor
		lda INPUT+1
		jsr _puthex
		dec PrintColor
		macro_putstr_inline " / "
		inc PrintColor
		inc PrintColor
		lda #HIGH(day7_input_end)
		jsr _puthex
		jmp wait_flush

day7_solve:
		macro_memset_pb $6000, $00, $2000

		lda #LOW(day7_input)
		sta INPUT
		lda #HIGH(day7_input)
		sta INPUT+1
.next_input:
		lda INPUT
		cmp #LOW(day7_input_end)
		bne .not_end
		jsr d7_log
		lda INPUT+1
		cmp #HIGH(day7_input_end)
		bne .not_end
		jmp d7_find_min
.not_end:
		jsr read_next
		sta D7_Curr
		jsr read_next
		sta D7_Curr+1
		lda #LOW($6000)
		sta D7_CostIter
		lda #HIGH($6000)
		sta D7_CostIter+1
		; CostIter => CostIndex
.next_cost:
		lda D7_CostIter
		sta MathLhs
		lda D7_CostIter+1
		sta MathLhs+1
		macro_sub16_imm16 MathLhs, $6000
		; MathLhs -= CostIter-$6000
		lsr MathLhs+1
		ror MathLhs
		lsr MathLhs+1
		ror MathLhs
		; MathLhs /= 4
		macro_sub16 MathLhs, D7_Curr
		macro_abs16 MathLhs
		lda #0
		sta MathLhs+2
		sta MathLhs+3
		lda D7_SmartCrab
		beq .not_smart
		jsr smartify
.not_smart:
		ldy #0
		lda [D7_CostIter],Y
		sta MathRhs
		iny
		lda [D7_CostIter],Y
		sta MathRhs+1
		iny
		lda [D7_CostIter],Y
		sta MathRhs+2
		iny
		lda [D7_CostIter],Y
		sta MathRhs+3
		macro_add32 MathLhs, MathRhs
		ldy #0
		lda MathLhs
		sta [D7_CostIter], Y
		iny
		lda MathLhs+1
		sta [D7_CostIter], Y
		iny
		lda MathLhs+2
		sta [D7_CostIter], Y
		iny
		lda MathLhs+3
		sta [D7_CostIter], Y
		macro_add16_imm8 D7_CostIter, 4
		lda D7_CostIter+1
		cmp #$80
		beq .no_more_cost
		jmp .next_cost
.no_more_cost:
		jmp .next_input

day7_solve_a:
		jmp day7_solve

day7_solve_b:
		inc D7_SmartCrab
		jmp day7_solve

