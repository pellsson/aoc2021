
math_sub16:
	sec
	lda MathLhs
	sbc MathRhs
	sta MathOut
	lda MathLhs+1
	sbc MathRhs+1
	sta MathOut+1
	rts
