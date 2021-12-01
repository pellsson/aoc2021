day1_input:
	include "day1_input.asm"
day1_input_end:

read_next:
		ldy #0
		lda [$20], Y
		inc $20
		bne .no_high
		inc $20+1
.no_high:
		rts

rewind_word:
		sec
		lda $20
		sbc #$2
		sta $20
		lda $21
		sbc #$0
		sta $21
		rts

do_pass:
		jsr read_next
		sta MathLhs
		jsr read_next
		sta MathLhs+1
		jsr read_next
		sta MathRhs
		jsr read_next
		sta MathRhs+1
		jsr rewind_word
HACK:
		jsr math_sub16

		lda MathOut+1
		bpl .decreased
		inc $22
		bne .decreased
		inc $23
.decreased:
		rts
		
day1_solve:
		lda #LOW(day1_input)
		sta $20
		lda #HIGH(day1_input)
		sta $21
		lda #0
		sta $22 ; Result.
.keep_solving:
		jsr do_pass
		lda #LOW(day1_input_end-2)
		cmp $20
		bne .keep_solving
		lda #HIGH(day1_input_end-2)
		cmp $21
		bne .keep_solving
fiskapa:
		rts