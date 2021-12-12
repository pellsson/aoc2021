INPUT .equ WORK
D11_X .equ WORK+$2
D11_Y .equ WORK+$3
D11_Tmp .equ WORK+$4
D11_NX .equ WORK+$5
D11_NY .equ WORK+$6
D11_EX .equ WORK+$7
D11_EY .equ WORK+$8
D11_NumLit .equ WORK+$10
D11_Step .equ WORK+$11 ; and 12
D11_NumLitAll .equ WORK+$13
D11_NumLitStep .equ WORK+$18
D11_Board .equ $6000
D11_ScoreB .equ $7000

macro_walk_board .macro
		lda #0
		sta D11_X
		sta D11_Y
.next\@:
		ldy D11_Y
		ldx D11_X
		jsr \1
		ldx D11_X
		inx 
		stx D11_X
		cpx #12
		bmi .next\@
		ldx #0
		stx D11_X
		ldy D11_Y
		iny
		sty D11_Y
		cpy #12
		bmi .next\@
		.endm


d11_init_board:
		cpx #0
		beq .border
		cpx #11
		beq .border
		cpy #0
		beq .border
		cpy #11
		beq .border
		jsr read_next
		ldx D11_X
		ldy D11_Y
		jmp d11_write_at
.border:
		lda #$FF
		jmp d11_write_at

d11_write_at:
	pha
		txa
.top:
		dey
		bmi .done
		clc
		adc #12
		bne .top
.done:
		tax
	pla
		sta D11_Board,x
		rts

d11_read_at:
		txa
.top:
		dey
		bmi .done
		clc
		adc #12
		bne .top
.done:
		tax
		lda D11_Board,x
		rts

d11_inc_squid:
		jsr d11_read_at
		sta D11_Tmp
		and #$80
		bne .dont
		lda D11_Tmp
		clc
		adc #1
		ldx D11_X
		ldy D11_Y
		jmp d11_write_at
.dont:
		rts

d11_inc_neighbors:
		ldx D11_X
		dex
		stx D11_NX
		inx
		inx
		inx
		stx D11_EX
		ldy D11_Y
		dey
		sty D11_NY
		iny
		iny
		iny
		sty D11_EY
		;
.next_tile:
		ldy D11_NY
		ldx D11_NX
		cpy D11_Y
		bne .not_self
		cpx D11_X
		bne .not_self
		jmp .dont_inc
.not_self:
		jsr d11_read_at
		sta D11_Tmp
		and #$80
		bne .dont_inc
		inc D11_Tmp
		lda D11_Tmp
		ldy D11_NY
		ldx D11_NX
		jsr d11_write_at
.dont_inc:
		ldx D11_NX
		inx
		stx D11_NX
		cpx D11_EX
		bmi .next_tile
		ldx D11_X
		dex
		stx D11_NX
		ldy D11_NY
		iny
		sty D11_NY
		cpy D11_EY
		beq .donedone 
		jmp .next_tile
.donedone:
		rts

d11_light:
		jsr d11_read_at
		sta D11_Tmp
		and #$80
		bne .continue
		lda D11_Tmp
		cmp #10
		bmi .continue
		inc D11_NumLit
		jsr d11_inc_neighbors
		ldx D11_X
		ldy D11_Y
		lda #$80
		jmp d11_write_at
.continue:
		rts

d11_reset_lit:
		jsr d11_read_at
		sta D11_Tmp
		cmp #$80
		bne .nothing
		inc D11_NumLitStep
		ldx D11_X
		ldy D11_Y
		lda #0
		jmp d11_write_at
.nothing:
		rts

d11_do_step:
		lda #0
		sta D11_NumLitStep
		macro_walk_board d11_inc_squid
.next_pass:
		lda #0
		sta D11_NumLit
		macro_walk_board d11_light
		lda D11_NumLit
		beq .done
		jmp .next_pass
.done:
		macro_walk_board d11_reset_lit
		rts

day11_solve_a:
		lda #LOW(day11_input)
		sta INPUT
		lda #HIGH(day11_input)
		sta INPUT+1
		macro_walk_board d11_init_board
.next_step:
		jsr d11_do_step
		inc D11_Step
		bne .no_high
		inc D11_Step+1
.no_high:
		lda D11_NumLitStep
		cmp #(10*10)
		bne .not_all_bois
		tmm16 D11_ScoreB, D11_Step
		rts
.not_all_bois:
		macro_add16 D11_NumLitAll, D11_NumLitStep
		lda D11_Step
		cmp #100
		bne .next_100
		tmm16 Result, D11_NumLitAll
.next_100:
		jmp .next_step

day11_solve_b:
		tmm16 Result, D11_ScoreB
		rts
