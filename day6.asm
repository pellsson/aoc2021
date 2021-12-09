INPUT .equ WORK ; 
IsB .equ WORK+2

d6_lookup_80:
		db $8D, $05, $00, $00, $00, $00, $00, $00
		db $79, $05, $00, $00, $00, $00, $00, $00
		db $A7, $04, $00, $00, $00, $00, $00, $00
		db $82, $04, $00, $00, $00, $00, $00, $00
		db $0A, $04, $00, $00, $00, $00, $00, $00
		db $B6, $03, $00, $00, $00, $00, $00, $00
		db $89, $03, $00, $00, $00, $00, $00, $00
		db $0B, $03, $00, $00, $00, $00, $00, $00
		db $00, $03, $00, $00, $00, $00, $00, $00

d6_lookup_256:
		db $3C, $FE, $88, $8F, $01, $00, $00, $00
		db $A9, $92, $F4, $71, $01, $00, $00, $00
		db $7C, $FA, $CD, $4E, $01, $00, $00, $00
		db $4A, $82, $F8, $36, $01, $00, $00, $00
		db $8A, $93, $B2, $19, $01, $00, $00, $00
		db $49, $EE, $5D, $04, $01, $00, $00, $00
		db $2E, $75, $CA, $ED, $00, $00, $00, $00
		db $70, $D5, $8C, $D9, $00, $00, $00, $00
		db $DA, $B5, $D1, $C8, $00, $00, $00, $00



day6_solve:
		lda #LOW(day6_input)
		sta INPUT
		lda #HIGH(day6_input)
		sta INPUT+1
.gogo:
		jsr read_next
		cmp #$ff
		bne .add_more
		rts
.add_more:
		asl a ; *= 2
		asl a ; *= 4
		asl a ; *= 8
		tax
		lda IsB
		bne .do_256
		clc
		lda d6_lookup_80, x
		adc Result
		sta Result
		lda d6_lookup_80+1, x
		adc Result+1
		sta Result+1
		lda d6_lookup_80+2, x
		adc Result+2
		sta Result+2
		lda d6_lookup_80+3, x
		adc Result+3
		sta Result+3
		lda d6_lookup_80+4, x
		adc Result+4
		sta Result+4
		lda d6_lookup_80+5, x
		adc Result+5
		sta Result+5
		lda d6_lookup_80+6, x
		adc Result+6
		sta Result+6
		lda d6_lookup_80+7, x
		adc Result+7
		sta Result+7
		jmp .gogo
.do_256:
		clc
		lda d6_lookup_256, x
		adc Result
		sta Result
		lda d6_lookup_256+1, x
		adc Result+1
		sta Result+1
		lda d6_lookup_256+2, x
		adc Result+2
		sta Result+2
		lda d6_lookup_256+3, x
		adc Result+3
		sta Result+3
		lda d6_lookup_256+4, x
		adc Result+4
		sta Result+4
		lda d6_lookup_256+5, x
		adc Result+5
		sta Result+5
		lda d6_lookup_256+6, x
		adc Result+6
		sta Result+6
		lda d6_lookup_256+7, x
		adc Result+7
		sta Result+7
		jmp .gogo

day6_solve_a:
		jmp day6_solve

day6_solve_b:
		inc IsB
		jmp day6_solve

