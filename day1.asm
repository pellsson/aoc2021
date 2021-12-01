
read_next:
		ldy #0
		lda [$20], Y
		inc $20
		bne .no_high
		inc $20+1
.no_high:
		rts

rewind_word:
		lda #2
		sta Param0
rewind_by:
		sec
		lda $20
		sbc Param0
		sta $20
		lda $21
		sbc #$0
		sta $21
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
		inc $22
		bne .decreased
		inc $23
.decreased:
		rts
		
day1_solve_a:
		lda #LOW(day1_input_a)
		sta $20
		lda #HIGH(day1_input_a)
		sta $21
		lda #0
		sta $22 ; Result.
		sta $23
.keep_solving:
		jsr do_pass_a
		lda #LOW(day1_input_a_end-2)
		cmp $20
		bne .keep_solving
		lda #HIGH(day1_input_a_end-2)
		cmp $21
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
		sta $600
		lda MathOut+1
		sta $601
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
		lda $600
		sta MathLhs
		lda $601
		sta MathLhs+1
		jsr math_sub16
		lda MathOut+1
		bpl .decreased
		inc $22
		bne .decreased
		inc $23
.decreased:
		rts

day1_solve_b:
		lda #LOW(day1_input_b)
		sta $20
		lda #HIGH(day1_input_b)
		sta $21
		lda #0
		sta $22 ; Result.
		sta $23
.keep_solving:
		jsr do_pass_b
		lda #LOW(day1_input_b_end-6)
		cmp $20
		bne .keep_solving
		lda #HIGH(day1_input_b_end-6)
		cmp $21
		bne .keep_solving
		rts
