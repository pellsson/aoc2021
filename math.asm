math_sub16:
	sec
	lda MathLhs
	sbc MathRhs
	sta MathOut
	lda MathLhs+1
	sbc MathRhs+1
	sta MathOut+1
	rts

math_add16:
	clc
	lda MathLhs
	adc MathRhs
	sta MathOut
	lda MathLhs+1
	adc MathRhs+1
	sta MathOut+1
	rts

math_sub32:
	jsr math_sub16
	lda MathLhs+2
	sbc MathRhs+2
	sta MathOut+2
	lda MathLhs+3
	sbc MathRhs+3
	sta MathOut+3
	rts

math_add32:
	jsr math_add16
	lda MathLhs+2
	adc MathRhs+2
	sta MathOut+2
	lda MathLhs+3
	adc MathRhs+3
	sta MathOut+3
	rts

; http://6502.org/source/integers/32muldiv.htm
math_mul32:
	lda #$00
	sta MathOut+4	; Clear upper half of
	sta MathOut+5	; MathOutuct
	sta MathOut+6
	sta MathOut+7
	ldx #$20		; Set binary count to 32
shift_r:
	lsr MathRhs+3	; Shift multiplyer right
	ror MathRhs+2
	ror MathRhs+1
	ror MathRhs
	bcc rotate_r 	; Go rotate right if c = 0
	lda MathOut+4   ; Get upper half of MathOutuct
	clc				; and add multiplicand to it
	adc MathLhs
	sta MathOut+4
	lda MathOut+5
	adc MathLhs+1
	sta MathOut+5
	lda MathOut+6
	adc MathLhs+2
	sta MathOut+6
	lda MathOut+7
	adc MathLhs+3
rotate_r:
	ror a			; Rotate partial MathOutuct
	sta MathOut+7   ; right
	ror MathOut+6
	ror MathOut+5
	ror MathOut+4
	ror MathOut+3
	ror MathOut+2
	ror MathOut+1
	ror MathOut
	dex				; Decrement bit count and
	bne shift_r		; loop until 32 bits are
	rts