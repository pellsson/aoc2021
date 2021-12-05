INPUT .equ WORK
HighMask .equ WORK+$4
Diff .equ WORK+$6 ; and 7
V .equ WORK+$8
CountMask .equ WORK+$9
IsHigh .equ WORK+$a
Mask .equ WORK+$10 ; and 11
G .equ WORK+$12
Remaining .equ WORK+$14 ; and 15
KeepValue .equ WORK+$16
PtrHighByte .equ WORK+$18 ; and 19
WantMany .equ WORK+$1A
Oxygen .equ WORK+$20 ; and 21

save_input_pos:
		lda INPUT
		sta PtrHighByte
		lda INPUT+1
		sta PtrHighByte+1
		rts

filter_array:
		lda #0
		sta Remaining
		sta Remaining+1
		; sty IsHigh
		; stx CountMask
.next:
		lda IsHigh
		beq .is_low
		jsr read_next ; lo
		sta TMP
		jsr save_input_pos ; input points to high
		jsr read_next ; hi
		sta V ; Value to check
		jmp .check_end
.is_low:
		jsr read_next ; lo
		sta V ; Value to check
		jsr save_input_pos ; input points to high
		jsr read_next ; hi
		sta TMP
.check_end:
		; Check if the elment is deleted
		and #$80
		bne .next
		lda V
		ora TMP
		bne .count_next
		rts
.count_next:
		lda CountMask
		and V
		cmp KeepValue
		beq .keep
		ldy #0
		lda #$80
		sta [PtrHighByte],Y
		jmp .next
.keep:
		macro_add16_imm8 Remaining, 1
		jmp .next		

count_bits:
		sty IsHigh
		stx CountMask
		ldx #0
		stx Diff
		stx Diff+1
.next:
		lda IsHigh
		beq .is_low
		jsr read_next ; lo
		sta TMP
		jsr read_next ; hi
		sta V ; Value to check
		jmp .check_end
.is_low:
		jsr read_next ; lo
		sta V ; Value to check
		jsr read_next ; hi
		sta TMP
.check_end:
		and #$80
		bne .next ; Ignore deleted values
		lda V
		ora TMP
		bne .count_next
		rts
.count_next
		lda CountMask
		and V
		beq .clear
		; set
		macro_add16_imm8 Diff, 1
		jmp .next
.clear:
		macro_sub16_imm8 Diff, 1
		jmp .next

next_mask:
		lda IsHigh
		beq .next_low
		lda Mask+1
		lsr a
		sta Mask+1
		bne .done
		lda #$80
		sta Mask
		rts
.next_low:
		lda Mask
		lsr a
		sta Mask
.done:
		rts

day3_solve_a:
		lda #0
		sta G
		sta G+1
		sta Mask
		lda #8
		sta Mask+1 ; 0x800
.next_bit:
		lda #LOW(day3_input)
		sta INPUT
		lda #HIGH(day3_input)
		sta INPUT+1

		ldy #1
		lda Mask+1
		bne .do_high
		lda Mask
		beq .done
		dey
.do_high:
		tax
		jsr count_bits
		lda Diff+1
		bmi .not_counted
		bne .counted
.check_zero:
		lda Diff
		beq .not_counted
.counted:
		; It is more prominently 1 than 0 in this position
		lda G
		ora Mask
		sta G
		lda G+1
		ora Mask+1
		sta G+1
.not_counted:
		jsr next_mask
		jmp .next_bit
.done:
		lda G
		sta MathRhs
		eor #$ff
		sta MathLhs
		lda G+1
		sta MathRhs+1
		eor #$f
		sta MathLhs+1
		jsr math_mul32
		jmp mathout_to_res

solve_b:
		lda #0
		sta Mask
		lda #8
		sta Mask+1 ; 0x800
		macro_memcpy day3_input, day3_input_end, $6000 ; Array to RAM
.next_pass:
		lda #LOW($6000)
		sta INPUT
		lda #HIGH($6000)
		sta INPUT+1
		ldy #1
		lda Mask+1
		bne .do_high
		lda Mask
		beq impossible
		dey
.do_high:
		tax
		jsr count_bits
		jsr figure_filter
		lda #LOW($6000)
		sta INPUT
		lda #HIGH($6000)
		sta INPUT+1
		jsr filter_array
		lda Remaining+1
		bne .go_next_mask
		lda #$01
		cmp Remaining
		bne .go_next_mask
		rts

.go_next_mask:
		jsr next_mask
		jmp .next_pass

impossible:
		jmp impossible

figure_filter:
		lda WantMany
		beq .want_few
		jmp filter_want_many
.want_few:
		lda Diff+1
		bmi .more_zeros
		bne .more_ones
		lda Diff
		bne .more_ones
		lda #0
		sta KeepValue
		rts
.more_zeros:
		lda CountMask
		sta KeepValue
		rts
.more_ones:
		lda #0
		sta KeepValue
		rts

filter_want_many:
		lda Diff+1
		bmi .more_zeros
		bne .more_ones
		lda Diff
		bne .more_ones
		lda CountMask
		sta KeepValue
		rts
.more_zeros:
		lda #0
		sta KeepValue
		rts
.more_ones:
		lda CountMask
		sta KeepValue
		rts

find_remaining:
		lda #LOW($6000)
		sta INPUT
		lda #HIGH($6000)
		sta INPUT+1
.keep_searching:
		jsr read_next
		sta TMP
		jsr read_next
		sta V
		and #$80
		bne .keep_searching
		rts

day3_solve_b:
		lda #1
		sta WantMany
		jsr solve_b
		jsr find_remaining
		lda TMP
		sta Oxygen
		lda V
		sta Oxygen+1
		lda #0
		sta WantMany
		jsr solve_b
		jsr find_remaining
		lda TMP
		sta MathRhs
		lda V
		sta MathRhs+1
		lda Oxygen
		sta MathLhs
		lda Oxygen+1
		sta MathLhs+1
		jsr math_mul32
		jmp mathout_to_res
