
INPUT .equ WORK
SAVED_SEQUENCE .equ WORK+$4

read_next:
		ldy #0
		lda [INPUT], Y
		inc INPUT
		bne .no_high
		inc INPUT+1
.no_high:
		rts

rewind_word:
		lda #2
		sta Param0
rewind_by:
		sec
		lda INPUT
		sbc Param0
		sta INPUT
		lda INPUT+1
		sbc #$0
		sta INPUT+1
		rts

do_pass_a:
		jsr read_next
		sta MathLhs
		jsr read_next
		sta MathLhs+1
		jsr read_next
		sta MathRhs
		jsr read_next
		sta MathRhs+1
		jsr rewind_word
		jsr math_sub16

		lda MathOut+1
		bpl .decreased
		inc Result
		bne .decreased
		inc Result+1
.decreased:
		rts
		
day1_solve_a:
		lda #LOW(day1_input_a)
		sta INPUT
		lda #HIGH(day1_input_a)
		sta INPUT+1
.keep_solving:
		jsr do_pass_a
		lda #LOW(day1_input_a_end-2)
		cmp INPUT
		bne .keep_solving
		lda #HIGH(day1_input_a_end-2)
		cmp INPUT+1
		bne .keep_solving
		rts

add_series:
		; in[0]+in[1]
		jsr read_next
		sta MathLhs
		jsr read_next
		sta MathLhs+1
		jsr read_next
		sta MathRhs
		jsr read_next
		sta MathRhs+1
		jsr math_add16
		;
		; (in[0]+in[1])+in[2]
		;
		lda MathOut
		sta MathLhs
		lda MathOut+1
		sta MathLhs+1
		jsr read_next
		sta MathRhs
		jsr read_next
		sta MathRhs+1
		jmp math_add16

do_pass_b:
		jsr add_series
		;
		; Rewind by 4 to find the next series
		;
		lda #4
		sta Param0
		jsr rewind_by
		lda MathOut
		sta SAVED_SEQUENCE
		lda MathOut+1
		sta SAVED_SEQUENCE+1
		jsr add_series
		;
		; Rewind to head of this series (to make it the new first series for next pass)
		;
		lda #6
		sta Param0
		jsr rewind_by
		lda MathOut
		sta MathRhs
		lda MathOut+1
		sta MathRhs+1
		lda SAVED_SEQUENCE
		sta MathLhs
		lda SAVED_SEQUENCE+1
		sta MathLhs+1
		jsr math_sub16
		lda MathOut+1
		bpl .decreased
		inc Result
		bne .decreased
		inc Result+1
.decreased:
		rts

day1_solve_b:
		lda #LOW(day1_input_b)
		sta INPUT
		lda #HIGH(day1_input_b)
		sta INPUT+1
.keep_solving:
		jsr do_pass_b
		lda #LOW(day1_input_b_end-6)
		cmp INPUT
		bne .keep_solving
		lda #HIGH(day1_input_b_end-6)
		cmp INPUT+1
		bne .keep_solving
		rts
