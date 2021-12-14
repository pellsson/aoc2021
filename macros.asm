macro_putstr_inline .macro
	jmp .p\@
.str\@:
	db \1, 0
.p\@:
	lda #LOW(.str\@)
	sta TMP
	lda #HIGH(.str\@)
	sta TMP+1
	jsr putstr
	.endm

macro_putstr .macro
	lda #LOW(\1)
	sta TMP
	lda #HIGH(\1)
	sta TMP+1
	jsr putstr
	.endm

macro_add16_imm8 .macro
	clc
	lda \1
	adc #\2
	sta \1
	lda \1+1
	adc #0
	sta \1+1
	.endm

macro_add16_imm16 .macro
	clc
	lda \1
	adc #LOW(\2)
	sta \1
	lda \1+1
	adc #HIGH(\2)
	sta \1+1
	.endm

macro_sub16_imm8 .macro
	sec
	lda \1
	sbc #\2
	sta \1
	lda \1+1
	sbc #0
	sta \1+1
	.endm

macro_sub16_imm16 .macro
	sec
	lda \1
	sbc #LOW(\2)
	sta \1
	lda \1+1
	sbc #HIGH(\2)
	sta \1+1
	.endm

macro_abs16 .macro
	lda \1+1
	bpl .done\@
	lda \1
	eor #$FF
	sta \1
	lda \1+1
	eor #$ff
	sta \1+1
	inc \1
	bne .done\@
	inc \1+1
.done\@:
	.endm

macro_sub16_out .macro
	sec
	lda \2
	sbc \3
	sta \1
	lda \2+1
	sbc \3+1
	sta \1+1
	.endm

macro_sub16 .macro
	macro_sub16_out \1, \1, \2
	.endm

macro_sub32_out .macro
	macro_sub16_out \1, \2, \3
	lda \2+2
	sbc \3+2
	sta \1+2
	lda \2+3
	sbc \3+3
	sta \1+3
	.endm

macro_sub32 .macro
	macro_sub32_out \1, \1, \2
	.endm

macro_sub64_out .macro
	macro_sub32_out \1, \2, \3
	lda \2+4
	sbc \3+4
	sta \1+4
	lda \2+5
	sbc \3+5
	sta \1+5
	lda \2+6
	sbc \3+6
	sta \1+6
	lda \2+7
	sbc \3+7
	sta \1+7
	.endm

macro_sub64 .macro
	macro_sub64_out \1, \1, \2
	.endm

macro_add16_out .macro
	clc
	lda \2
	adc \3
	sta \1
	lda \2+1
	adc \3+1
	sta \1+1
	.endm

macro_add16 .macro
	macro_add16_out \1, \1, \2
	.endm

macro_add32_out .macro
	macro_add16_out \1, \2, \3
	lda \2+2
	adc \3+2
	sta \1+2
	lda \2+3
	adc \3+3
	sta \1+3
	.endm

macro_add32 .macro
	macro_add32_out \1, \1, \2
	.endm

macro_add64_out .macro
	macro_add32_out \1, \2, \3
	lda \2+4
	adc \3+4
	sta \1+4
	lda \2+5
	adc \3+5
	sta \1+5
	lda \2+6
	adc \3+6
	sta \1+6
	lda \2+7
	adc \3+7
	sta \1+7
	.endm

macro_add64 .macro
	macro_add64_out \1, \1, \2
	.endm

macro_inc32 .macro
	inc \1
	bne .done
	inc \1+1
	bne .done
	inc \1+2
	bne .done
	inc \1+3
.done:	
	.endm

macro_mul16 .macro
	lda \1
	sta MathLhs
	lda \1+1
	sta MathLhs+1
	lda \2
	sta MathRhs
	lda \2+1
	sta MathRhs+1
	jsr math_mul32
	.endm

macro_mul16_imm16 .macro
	lda #LOW(\2)
	sta MathRhs
	lda #HIGH(\2)
	sta MathRhs+1
	lda \1
	sta MathLhs
	lda \1+1
	sta MathLhs+1
	jsr math_mul32
	.endm

macro_max_u16 .macro
	lda \2+1
	cmp \3+1
	beq .check_low\@
	bcs .lhs_bigger\@
.rhs_bigger\@:
	lda \3
	sta \1
	lda \3+1
	sta \1+1
	jmp .end\@
.check_low\@:
	lda \2
	cmp \3
	bcc .rhs_bigger\@
.lhs_bigger\@:
	lda \2
	sta \1
	lda \2+1
	sta \1+1
.end\@:
	.endm

macro_min_u16 .macro
	lda \2+1
	cmp \3+1
	beq .check_low\@
	bcs .lhs_bigger\@
.rhs_bigger\@:
	lda \2
	sta \1
	lda \2+1
	sta \1+1
	jmp .end\@
.check_low\@:
	lda \2
	cmp \3
	bcc .rhs_bigger\@
.lhs_bigger\@:
	lda \3
	sta \1
	lda \3+1
	sta \1+1
.end\@:
	.endm



tmm16 .macro
	lda \2
	sta \1
	lda \2+1
	sta \1+1
	.endm

tmm32 .macro
	tmm16 \1, \2
	tmm16 \1+2, \2+2
	.endm

tmm64 .macro
	tmm32 \1, \2
	tmm32 \1+4, \2+4
	.endm

tmm40 .macro
	tmm32 \1, \2
	lda \2+4
	sta \1+4
	.endm

macro_memcpy .macro
	lda #LOW(\1)
	sta Src
	lda #HIGH(\1)
	sta Src+1
	lda #LOW(\2)
	sta SrcEnd
	lda #HIGH(\2)
	sta SrcEnd+1
	lda #LOW(\3)
	sta Dst
	lda #HIGH(\3)
	sta Dst+1
	jsr _memcpy
	.endm

macro_memset_pb .macro
	lda #LOW(\1)
	sta Dst
	lda #HIGH(\1)
	sta Dst+1
	lda #\2
	ldx #HIGH((\3+$FF) & $FF00)
	ldy #0
.next\@:
	sta [Dst], Y
	iny
	bne .next\@
	macro_add16_imm16 Dst, $100
	lda #\2
	dex
	bne .next\@
	.endm

macro_is_less_u16 .macro
	lda \1+1
	cmp \2+1
	bcc \3 ; Lower!
	bne .higher\@
	lda \1
	cmp \2
	bcc \3 ; Lower!
	; Higher or equal
.higher\@:
	.endm

macro_is_less_u32 .macro
	lda \1+3
	cmp \2+3
	bcc \3 ; Lower!
	bne .higher_x\@
	lda \1+2
	cmp \2+2
	bcc \3 ; Lower!
	macro_is_less_u16 \1, \2, \3
.higher_x\@
	.endm

macro_is_less_u40 .macro
	lda \1+4
	cmp \2+4
	bcc \3
	bne .higher_xx\@
	macro_is_less_u32 \1, \2, \3
.higher_xx\@:
	.endm
