INPUT .equ WORK
D10_Num .equ WORK+$4
D10_Corrupt .equ WORK+$5 ; and 6,7,8
D10_SkipLine .equ WORK+$9
D10_Target .equ WORK+$a
D10_StackOff .equ WORK+$10
D10_PtrScore .equ WORK+$12 ; and 3
D10_I .equ WORK+$18
D10_J .equ WORK+$19
D10_NumBefore .equ WORK+$21
D10_Tmp .equ WORK+$22 ; 23, 24, 25, 26
D10_Stack .equ $6000
D10_ScoreB .equ $6100
D10_NumScore .equ $7000 ;

d10_write_score:
		ldy #0
		sta [D10_PtrScore], Y
		inc D10_PtrScore
		bne .no_high
		inc D10_PtrScore+1
.no_high:
		rts

d10_pop:
		ldx D10_StackOff
		dex
		stx D10_StackOff
		lda D10_Stack,x
		rts

d10_does_open:
		cmp #'('
		beq .does
		cmp #'['
		beq .does
		cmp #'{'
		beq .does
		cmp #'<'
.does:
		rts

d10_close:
		tay
		jsr d10_pop
		cpy #')'
		bne .not_para
		ldx #3 ; score
		ldy #0
		cmp #'('
		bne .is_corrupt
		rts
.not_para:
		cpy #']'
		bne .not_brack
		ldx #57 ; score
		ldy #0
		cmp #'['
		bne .is_corrupt
		rts
.not_brack:
		cpy #'}'
		bne .not_curl
		ldx #LOW(1197) ; score
		ldy #HIGH(1197)
		cmp #'{'
		bne .is_corrupt
.return:
		rts
.not_curl:
		cpy #'>'
		bne .is_corrupt
		ldx #LOW(25137) ; score
		ldy #HIGH(25137)
		cmp #'<'
		beq .return
.is_corrupt:
		stx D10_Corrupt
		sty D10_Corrupt+1
		rts

d10_read_line:
		lda #0
		sta D10_StackOff
.next_byte:
		jsr read_next
		sta D10_Num
		cmp #0
		bne .not_eol
		lda #0
		sta D10_SkipLine
		rts
.not_eol:
		ldx D10_SkipLine
		bne .next_byte
		jsr d10_does_open
		bne .does_not_open
		; just write it to stack
		ldx D10_StackOff
		sta D10_Stack, x
		inx
		stx D10_StackOff
		bne .next_byte ; Always true
.does_not_open:
		jsr d10_close
		lda D10_Corrupt
		beq .not_corrupt
		; Corrupt
		inc D10_SkipLine
.not_corrupt:
		jmp .next_byte

d10_get_score_b:
		cmp #'('	
		bne .not_para
		lda #1
		rts
.not_para:
		cmp #'['
		bne .not_brack
		lda #2
		rts
.not_brack:
		cmp #'{'
		bne .not_curl
		lda #3
		rts
.not_curl:
		lda #4
		rts

day10_solve_a:
		lda #0
		sta D10_NumScore
		lda #LOW(D10_ScoreB)
		sta D10_PtrScore
		lda #HIGH(D10_ScoreB)
		sta D10_PtrScore+1
		lda #LOW(day10_input)
		sta INPUT
		lda #HIGH(day10_input)
		sta INPUT+1
.next:
		lda INPUT
		cmp #LOW(day10_input_end)
		bne .not_end
		lda INPUT+1
		cmp #HIGH(day10_input_end)
		bne .not_end
		rts
.not_end:
		jsr d10_read_line
		lda D10_Corrupt
		beq .not_corrupt
		; Solve for a
		macro_add32 Result, D10_Corrupt
		lda #0
		sta D10_Corrupt
		sta D10_Corrupt+1
		jmp .next
.not_corrupt:
		lda #0
		sta MathLhs
		sta MathLhs+1
		sta MathLhs+2
		sta MathLhs+3
.pop_more:
		jsr d10_hack_patch
		bne .skip_hack
		lda #5
		sta MathRhs
		jsr math_mul32
		jsr d10_pop
		jsr d10_get_score_b
		sta MathRhs
		macro_add32 MathOut, MathRhs
		tmm32 MathLhs, MathOut
		ldx D10_StackOff
		bne .pop_more
.skip_hack:
		lda MathLhs
		jsr d10_write_score
		lda MathLhs+1
		jsr d10_write_score
		lda MathLhs+2
		jsr d10_write_score
		lda MathLhs+3
		jsr d10_write_score
		inc D10_NumScore
		jmp .next

d10_hack_patch:
		; Hack. We dont support 64-bit.
		ldx D10_StackOff
		cpx #1
		bne .dont_skip
		lda MathLhs+3
		and #$F0
		beq .dont_skip
		lda #$F0
		sta MathLhs+3
		rts
.dont_skip:
		lda #0
		rts

d10_score_at:
		sta MathLhs
		lda #0
		sta MathLhs+1
		asl MathLhs+1
		rol MathLhs ; *= 2
		asl MathLhs+1
		rol MathLhs
		lda #LOW(D10_ScoreB)
		sta MathRhs
		lda #HIGH(D10_ScoreB)
		sta MathRhs+1
		macro_add16 MathLhs, MathRhs
		lda MathLhs
		sta INPUT
		lda MathLhs+1
		sta INPUT+1
		jsr read_next
		sta MathLhs
		jsr read_next
		sta MathLhs+1
		jsr read_next
		sta MathLhs+2
		jsr read_next
		sta MathLhs+3
		rts

d10_compare_ij:
		lda D10_J
		jsr d10_score_at
		tmm32 D10_Tmp, MathLhs
		lda D10_I
		jsr d10_score_at
		macro_is_less_u32 MathLhs, D10_Tmp, .is_less
		; if (score[i] < score[j])
		rts
.is_less:
		inc D10_NumBefore
		rts

d10_find_mid:
		; Everything already at zero
		lda D10_NumScore
		lsr a
		sta D10_Target
.gogo:
		lda #0
		sta D10_NumBefore
		sta D10_J
		lda D10_I
		cmp D10_NumScore
		bcs .done
.next_inner:
		lda D10_J
		cmp D10_NumScore
		bcs .next_outer
		jsr d10_compare_ij
		inc D10_J
		jmp .next_inner
.next_outer:
		lda D10_NumBefore
		cmp D10_Target
		beq .done
		inc D10_I
		jmp .gogo
.done:
		; This is the guy (or somehting broke completely)...
		rts

day10_solve_b:
		jsr d10_find_mid
		lda D10_I
		jsr d10_score_at
		tmm32 Result, MathLhs
		rts
