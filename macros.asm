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

macro_sub16_imm8 .macro
	sec
	lda \1
	sbc #\2
	sta \1
	lda \1+1
	sbc #0
	sta \1+1
	.endm

tmm32 .macro
	lda \2
	sta \1
	lda \2+1
	sta \1+1
	lda \2+2
	sta \1+2
	lda \2+3
	sta \1+3
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