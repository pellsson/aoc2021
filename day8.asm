INPUT .equ WORK
D8_W .equ WORK+2
D8_Num .equ WORK+3
D8_it .equ WORK+4
D8_M .equ WORK+5
D8_IsB .equ WORK+6

decoded_nums .equ $6010

macro_decode .macro
		lda #9
		sta D8_it
.read_more\@:
		ldx D8_it
		lda $6000, x
		sta D8_Num
		jsr \1
		ldx D8_it
		dex
		stx D8_it
		bpl .read_more\@
		.endm


macro_translat_mult .macro	 ; this... is so retarded.
		jsr translate_digit
		sta MathLhs
		lda #LOW(\1)
		sta MathRhs
		lda #HIGH(\1)
		sta MathRhs+1
		jsr math_mul32
		macro_add16 Result, MathOut
		.endm


decode_easy:
		jsr bits_set
		cmp #2
		bne .not_1
		lda D8_Num
		sta decoded_nums+1
		rts
.not_1:
		cmp #4
		bne .not_4
		lda D8_Num
		sta decoded_nums+4
		rts
.not_4:
		cmp #3
		bne .not_7
		lda D8_Num
		sta decoded_nums+7
		rts
.not_7:
		cmp #7
		bne .not_8
		lda D8_Num
		sta decoded_nums+8
.not_8:
		rts

decode_hard:
		jsr bits_set
		cmp #6
		bne .not_len6
		lda D8_Num
		and decoded_nums+4
		cmp decoded_nums+4
		bne .not_9
		lda D8_Num
		sta decoded_nums+9
		rts
.not_9:
		lda D8_Num
		and decoded_nums+1
		cmp decoded_nums+1
		bne .is_6
		lda D8_Num
		sta decoded_nums+0
		rts
.is_6:
		lda D8_Num
		sta decoded_nums+6
		rts
.not_len6:
		cmp #5
		bne .exit
		lda D8_Num
		and decoded_nums+1
		cmp decoded_nums+1
		bne .exit
		lda D8_Num
		sta decoded_nums+3
.exit:
		rts

decode_two_five:
		jsr bits_set
		cmp #5
		bne .exit
		lda D8_Num
		and decoded_nums+1
		cmp decoded_nums+1
		beq .exit
		lda D8_Num
		and decoded_nums+6
		cmp D8_Num
		bne .is_2
		lda D8_Num
		sta decoded_nums+5
		rts
.is_2:
		lda D8_Num
		sta decoded_nums+2
.exit:
		rts

bits_set:
		ldx #0
		sta D8_W
		lda #$80
		sta D8_M
.next:
		and D8_W
		beq .not_set
		inx
.not_set:
		lda D8_M
		lsr a
		sta D8_M
		bne .next
		txa
		rts

chr_to_n:
		sta D8_W
		lda #'g'
		sec
		sbc D8_W
		sta D8_W
		lda #1
		ldx D8_W
		beq .done
.more:
		asl a
		dex
		bne .more
.done:
		ora D8_Num
		sta D8_Num
		rts

translate_digit:
		jsr read_word
		ldx #0
.gogo:
		cmp decoded_nums, x
		beq .done
		inx
		bne .gogo
.done:
		txa
		rts

read_word:
		lda #0
		sta D8_Num
.next_chr:
		jsr read_next
		cmp #' '
		beq .done
		cmp #0
		beq .done
		jsr chr_to_n
		jmp .next_chr
.done:
		lda D8_Num
		rts

count_if_1478:
		jsr read_word
		cmp decoded_nums+1
		beq .count
		cmp decoded_nums+4
		beq .count
		cmp decoded_nums+7
		beq .count
		cmp decoded_nums+8
		beq .count
		rts
.count:
		macro_add16_imm8 Result, 1
		rts

d8_do_b_stuff:
		macro_translat_mult 1000
		macro_translat_mult 100
		macro_translat_mult 10
		jsr translate_digit
		sta MathLhs
		macro_add16 Result, MathLhs
		rts

day8_solve:
		lda #LOW(day8_input)
		sta INPUT
		lda #HIGH(day8_input)
		sta INPUT+1
.next_line:
		lda INPUT
		cmp #LOW(day8_input_end)
		bne .do_next_line
		lda INPUT+1
		cmp #HIGH(day8_input_end)
		bne .do_next_line
		rts
.do_next_line:
		lda #10
		sta D8_it
.read_more:
		jsr read_word
		ldx D8_it
		dex
		stx D8_it
		sta $6000, x
		bne .read_more
		macro_decode decode_easy
		macro_decode decode_hard
		macro_decode decode_two_five
		; Everything decoded now. Solve.
		lda D8_IsB
		beq .not_b
		jsr d8_do_b_stuff
		jmp .next_line
.not_b:
		jsr count_if_1478
		jsr count_if_1478
		jsr count_if_1478
		jsr count_if_1478
		jmp .next_line

day8_solve_a:
		jmp day8_solve

day8_solve_b:
		inc D8_IsB
		jmp day8_solve