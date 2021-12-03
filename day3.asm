INPUT .equ WORK
HighMask .equ WORK+$4
Diff .equ WORK+$6 ; and 7
V .equ WORK+$8
CountMask .equ WORK+$9
IsHigh .equ WORK+$a
Mask .equ WORK+$10 ; and 11
G .equ WORK+$12

count_for_bit:
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
		jsr count_for_bit
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
		tmm32 Result, MathOut
		rts

day3_solve_b:
		macro_memcpy day3_input, day3_input_end, $6000 ; Array to RAM
		
		rts

