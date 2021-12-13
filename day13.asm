INPUT .equ WORK
D13_TmpLo .equ WORK+$2
D13_TmpHi .equ WORK+$3
D13_AddX .equ WORK+$4 ; and 5
D13_AddY .equ WORK+$6 ; and 7
D13_W .equ WORK+$10 ; and 11
D13_H .equ WORK+$12 ; and 13
D13_X .equ WORK+$14 ; and 15
D13_Y .equ WORK+$16 ; and 17
D13_Fold .equ WORK+$18
D13_FoldAt .equ WORK+$1A
D13_FoldPtr .equ WORK+$1C
D13_Dots .equ $6000

; macro_fold major_coor, dimension
macro_fold .macro
		macro_sub16_imm8 \2, 1
		macro_sub16 \2, D13_FoldAt
		lda #LOW(D13_Dots)
		sta INPUT
		lda #HIGH(D13_Dots)
		sta INPUT+1
.skip\@:
		jsr read_next
		sta D13_X
		jsr read_next
		cmp #$ff
		bne .not_end\@
		rts
.not_end\@:
		sta D13_X+1
		jsr read_next
		sta D13_Y
		jsr read_next
		sta D13_Y+1
		cmp #$80
		beq .skip\@
		lda \1
		cmp D13_FoldAt
		bne .not_in_crest\@
		lda \1+1
		cmp D13_FoldAt
		bne .not_in_crest\@
		; in crest, kill.
		jsr d13_delete_last
		jmp .skip\@
.not_in_crest\@:
		macro_is_less_u16 \1, D13_FoldAt, .skip\@
		macro_sub16 \1, D13_FoldAt
		macro_sub16_out \1, \2, \1
		jsr add_dot
		jmp .skip\@
		.endm

d13_update_dimensions:
		lda #0
		sta D13_W
		sta D13_W+1
		sta D13_H
		sta D13_H+1
		lda #LOW(D13_Dots)
		sta INPUT
		lda #HIGH(D13_Dots)
		sta INPUT+1
.read_more:
		jsr read_next
		sta D13_X
		jsr read_next
		sta D13_X+1
		jsr read_next
		sta D13_Y
		jsr read_next
		sta D13_Y+1
		lda D13_X+1
		cmp #$FF
		bne .not_at_end
		rts
.not_at_end:
		cmp #$80
		beq .read_more
		macro_add16_imm8 D13_X, 1
		macro_max_u16 D13_W, D13_W, D13_X
		macro_add16_imm8 D13_Y, 1
		macro_max_u16 D13_H, D13_H, D13_Y
		jmp .read_more

calc_score_a:
		lda #LOW(D13_Dots)
		sta INPUT
		lda #HIGH(D13_Dots)
		sta INPUT+1
.count_next:
		jsr read_next
		jsr read_next
		cmp #$FF
		beq .done
		jsr read_next
		jsr read_next
		cmp #$80
		beq .count_next
		macro_add16_imm8 Result, 1
		jmp .count_next
.done:
		rts

day13_solve_a:
		macro_memcpy day13_input, day13_dots_end, D13_Dots ; Why are the params backwards... wtf did i do here...?
		lda #$FF
		sta [Dst], Y
		iny
		sta [Dst], Y
		jsr d13_update_dimensions
		lda #LOW(day13_folds)
		sta D13_FoldPtr
		lda #HIGH(day13_folds)
		sta D13_FoldPtr+1
		ldy #0
		sty D13_Fold
.next_fold:
		ldy D13_Fold
		cpy #3
		bne .not_first
		jsr calc_score_a
		ldy D13_Fold
.not_first:
		cpy #(day13_input_end-day13_folds)
		bne .not_done
		rts
.not_done:
		lda [D13_FoldPtr], y
	pha
		iny
		lda [D13_FoldPtr], y
		sta D13_FoldAt
		iny 
		lda [D13_FoldPtr], y
		sta D13_FoldAt+1
		iny
		sty D13_Fold
	pla
		cmp #'y'
		beq .do_fold_horizontal
		jsr fold_vertically
		jmp .next_fold
.do_fold_horizontal:
		jsr fold_horizontal
		jmp .next_fold

fold_horizontal:
		macro_fold D13_Y, D13_H
		; returns

fold_vertically:
		macro_fold D13_X, D13_W
		; returns when its done

d13_delete_last:
		lda #$80
		sta D13_AddX
		sta D13_AddX+1
		sta D13_AddY
		sta D13_AddY+1
d13_overwrite_current:
		macro_sub16_imm8 INPUT, 4
		ldy #0
		lda D13_AddX
		sta [INPUT], Y
		jsr skip_next
		lda D13_AddX+1
		sta [INPUT], Y
		jsr skip_next
		lda D13_AddY
		sta [INPUT], Y
		jsr skip_next
		lda D13_AddY+1
		sta [INPUT], Y
		jmp skip_next

check_if_equal:
		lda D13_X
		cmp D13_AddX
		bne .not_eq
		lda D13_X+1
		cmp D13_AddX+1
		bne .not_eq
		lda D13_Y
		cmp D13_AddY
		bne .not_eq
		lda D13_Y+1
		cmp D13_AddY+1
		bne .not_eq
.not_eq:
		rts

add_dot:
		jsr d13_delete_last
		tmm16 D13_TmpLo, INPUT
		lda #LOW(D13_Dots)
		sta INPUT
		lda #HIGH(D13_Dots)
		sta INPUT+1
.next:
		jsr read_next
		sta D13_AddX
		jsr read_next
		sta D13_AddX+1
		jsr read_next
		sta D13_AddY
		jsr read_next
		sta D13_AddY+1
		lda D13_AddX+1
		cmp #$FF
		bne .not_end
		; Does not already exist, we need to add the new value.
		tmm16 D13_AddX, D13_X
		tmm16 D13_AddY, D13_Y
		tmm16 INPUT, D13_TmpLo
		jmp d13_overwrite_current
.already_exists:
		tmm16 INPUT, D13_TmpLo
		rts
.not_end:
		jsr check_if_equal
		beq .already_exists
		jmp .next

write_dot:
		lda #LOW(D13_Dots)
		sta INPUT
		lda #HIGH(D13_Dots)
		sta INPUT+1
.next:
		jsr read_next
		sta D13_AddX
		jsr read_next
		sta D13_AddX+1
		jsr read_next
		sta D13_AddY
		jsr read_next
		sta D13_AddY+1
		lda D13_AddX+1
		cmp #$FF
		bne .not_end
		lda #'.'
		jmp _putchar
.not_end:
		jsr check_if_equal
		bne .next
		lda #'#'
		jmp _putchar


macro_print_block .macro
		lda #\1
		sta D13_X
		lda #0
		sta D13_Y
		sta D13_Y+1
		sta D13_X+1
.next_x\@:
		lda D13_X
		cmp #\2
		bcs .next_row\@
		jsr write_dot
		inc D13_X
		jmp .next_x\@
.next_row\@:
		jsr wait_flush
		lda #\1
		sta D13_X
		ldx D13_Y
		inx
		stx D13_Y
		cpx #6
		bne .next_x\@
		.endm		

day13_solve_b:
		macro_print_block 0, 20
		jsr wait_flush
		macro_print_block 20, 40
		jmp wait_flush
