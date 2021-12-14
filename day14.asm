INPUT .equ WORK
D14_PtrCurrent .equ WORK+$2 ; and 3 
D14_C .equ WORK+$4 ; 5,6,7,8,9,a,b
D14_Find .equ WORK+$10 ; and 5
D14_CX .equ WORK+$18 ; => $20

D14_E .equ WORK+$20
D14_P .equ WORK+$22 ; And 23

D14_Iter .equ WORK+$24 ; And 25

D14_PassLeft .equ WORK+$28

D14_Min .equ WORK+$30
D14_Max .equ WORK+$38

D14_Pairs .equ $6000
D14_PairsCopy .equ $6800
D14_Elems .equ $7000

d14_get_pair_copy:
		lda #LOW(D14_PairsCopy)
		sta D14_PtrCurrent
		lda #HIGH(D14_PairsCopy)
		sta D14_PtrCurrent+1
		jmp d14_get_any

d14_get_pair:
		lda #LOW(D14_Pairs)
		sta D14_PtrCurrent
		lda #HIGH(D14_Pairs)
		sta D14_PtrCurrent+1
		jmp d14_get_any

d14_get_element:
		lda #0
		sta D14_Find+1
		lda #LOW(D14_Elems)
		sta D14_PtrCurrent
		lda #HIGH(D14_Elems)
		sta D14_PtrCurrent+1
d14_get_any:
		ldy #0
		lda [D14_PtrCurrent], Y
		bne .not_end
		; New pair, insert it.
		lda D14_Find
		sta [D14_PtrCurrent], Y
		iny
		lda D14_Find+1
		sta [D14_PtrCurrent], Y 
		jmp .return_this
.not_end:
		cmp D14_Find
		bne .next
		iny
		lda [D14_PtrCurrent], Y
		cmp D14_Find+1
		bne .next
.return_this:
		iny
		macro_add16_imm8 D14_PtrCurrent, 2
		rts
.next:
		macro_add16_imm8 D14_PtrCurrent, 10 ;2+8
		jmp d14_get_any

d14_load_current:
		ldy #0
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+0
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+1
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+2
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+3
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+4
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+5
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+6
		lda [D14_PtrCurrent], Y
		iny
		sta D14_C+7
		rts

d14_save_current:
		ldy #0
		lda D14_C
		sta [D14_PtrCurrent],Y
		iny
		lda D14_C+1
		sta [D14_PtrCurrent],Y
		iny
		lda D14_C+2
		sta [D14_PtrCurrent],Y
		iny
		lda D14_C+3
		sta [D14_PtrCurrent],Y
		iny
		lda D14_C+4
		sta [D14_PtrCurrent],Y
		iny
		lda D14_C+5
		sta [D14_PtrCurrent],Y
		iny
		lda D14_C+6
		sta [D14_PtrCurrent],Y
		iny
		lda D14_C+7
		sta [D14_PtrCurrent],Y
		rts

d14_current_inc32:
		jsr d14_load_current
		macro_inc32 D14_C
		jmp d14_save_current

d14_get_combined_element:
		lda #LOW(day14_poly)
		sta INPUT
		lda #HIGH(day14_poly)
		sta INPUT+1
.read:
		jsr read_next
		cmp D14_Find
		bne .not_skip_2
		jsr read_next
		cmp D14_Find+1
		bne .not_skip_1
		jmp read_next
.not_skip_2:
		jsr skip_next
.not_skip_1:
		jsr skip_next
		jmp .read

d14_add_cx:
		jsr d14_load_current
		macro_add64 D14_C, D14_CX
		jmp d14_save_current

d14_initialize:
		macro_memset_pb $6000, 0, $2000 ; all ex-ram memset(0)
		ldx #0
.init_more:
		lda day14_input, x
		sta D14_Find
		lda day14_input+1, x
		sta D14_Find+1
		jsr d14_get_pair
		jsr d14_current_inc32
		jsr d14_get_element
		jsr d14_current_inc32
		inx
		cpx #(day14_poly-day14_input-1)
		bne .init_more
		; Count last element of start config
		lda day14_input, x
		sta D14_Find
		jsr d14_get_element
		jmp d14_current_inc32

d14_step:
		; Solve.
		macro_memcpy D14_Pairs, D14_Pairs+0x400, D14_PairsCopy ; Again, the argument list is reversed :( so dumb. I should just fix it...
		lda #LOW(D14_PairsCopy)
		sta D14_Iter
		lda #HIGH(D14_PairsCopy)
		sta D14_Iter+1
.next:
		ldy #0
		lda [D14_Iter],Y
		bne .not_done
		rts
.not_done:
		sta D14_Find
		iny
		lda [D14_Iter],Y
		sta D14_Find+1
		macro_add16_imm8 D14_Iter, 10 ; 2+8
		tmm16 D14_P, D14_Find 
		jsr d14_get_pair_copy
		jsr d14_load_current
		tmm64 D14_CX, D14_C
		; Translate to !copy array
		macro_sub16_imm16 D14_PtrCurrent, D14_PairsCopy-D14_Pairs
		jsr d14_load_current
		macro_sub64 D14_C, D14_CX
		jsr d14_save_current
		jsr d14_get_combined_element
		sta D14_E
		sta D14_Find
		jsr d14_get_element
		jsr d14_add_cx
		lda D14_P
		sta D14_Find
		lda D14_E
		sta D14_Find+1
		jsr d14_get_pair
		jsr d14_add_cx
		lda D14_E
		sta D14_Find
		lda D14_P+1
		sta D14_Find+1
		jsr d14_get_pair
		jsr d14_add_cx
		jmp .next

d14_find_minmax:
		lda #$FF
		sta D14_Min+7 ; MSB
		lda #LOW(D14_Elems)
		sta D14_Iter
		lda #HIGH(D14_Elems)
		sta D14_Iter+1
.next:
		ldy #0
		lda [D14_Iter], Y
		bne .not_end
		rts
.not_end:
		tmm64 MathLhs, D14_Min
		iny
		iny
		lda [D14_Iter], Y
		sta MathRhs
		iny
		lda [D14_Iter], Y
		sta MathRhs+1
		iny
		lda [D14_Iter], Y
		sta MathRhs+2
		iny
		lda [D14_Iter], Y
		sta MathRhs+3
		iny
		lda [D14_Iter], Y
		sta MathRhs+4
		iny
		lda [D14_Iter], Y
		sta MathRhs+5
		iny
		lda [D14_Iter], Y
		sta MathRhs+6
		iny
		lda [D14_Iter], Y
		sta MathRhs+7
		jsr math_min64
		tmm64 D14_Min, MathOut
		tmm64 MathLhs, D14_Max
		jsr math_max64
		tmm64 D14_Max, MathOut
		macro_add16_imm8 D14_Iter, 10
		jmp .next

day14_solve_a:
		jsr d14_initialize
		lda #10
		sta D14_PassLeft
.more:
		jsr d14_step
		dec D14_PassLeft
		bne .more
		jsr d14_find_minmax
		macro_sub64_out Result, D14_Max, D14_Min
		rts

day14_solve_b:
		jsr d14_initialize
		lda #40
		sta D14_PassLeft
.more:
		jsr d14_step
		dec D14_PassLeft
		bne .more
		jsr d14_find_minmax
		macro_sub64_out Result, D14_Max, D14_Min
		rts

