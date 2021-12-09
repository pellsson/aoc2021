BX .equ WORK
BY .equ WORK+1
SaveX .equ WORK+2
SaveY .equ WORK+3
CurrTile .equ WORK+4
NumValley .equ WORK+5
SumValley .equ WORK+6 ; and 7
SizeBasin .equ WORK+8
ItBasin .equ WORK+9
PX .equ WORK+$a
PY .equ WORK+$b
TX .equ WORK+$c
TY .equ WORK+$d
BigBasins .equ Day9_SaveShit ; +1, +2

oob:
		lda #9
		rts
d9_readtile:
		cpx #100
		bcs oob ; solves negative numbers too (unsigned)
		cpy #100
		bcs oob ; --||--
		stx SaveX
		sty MathLhs
		lda #100 ; Width
		sta MathRhs
		lda #0
		sta MathLhs+1
		sta MathRhs+1
		jsr math_mul32
		; Y * 100
		lda MathOut
		sta MathRhs
		lda MathOut+1
		sta MathRhs+1 ; 100x100 is max 16-bit...
		lda SaveX
		sta MathLhs
		lda #0
		sta MathLhs+1 ; Save X
		jsr math_add16 ; out = x + y*100
		lda MathOut
		sta MathRhs
		lda MathOut+1
		sta MathRhs+1
		lda #LOW(day9_matrix)
		sta MathLhs
		lda #HIGH(day9_matrix)
		sta MathLhs+1
		jsr math_add16
		; out = matrix + x + y*100
		ldy #0
		lda [MathOut], Y
		rts

is_valley:
		ldx BX
		ldy BY
		jsr d9_readtile
		sta CurrTile
		;
		; -1,0
		;
		ldx BX
		dex
		ldy BY
		jsr d9_readtile
		cmp CurrTile
		beq .too_low
		bmi .too_low
		;
		; 1,0
		;
		ldx BX
		inx
		ldy BY
		jsr d9_readtile
		cmp CurrTile
		beq .too_low
		bmi .too_low
		;
		; 0,-1
		;
		ldx BX
		ldy BY
		dey
		jsr d9_readtile
		cmp CurrTile
		beq .too_low
		bmi .too_low
		;
		; 0,1
		;
		ldx BX
		ldy BY
		iny
		jsr d9_readtile
		cmp CurrTile
		beq .too_low
		bmi .too_low
		lda #1
		rts
.too_low:
		lda #0
		rts

add_basin_tile:
		stx SaveX
		sty SaveY
		ldx #0
.check_next:
		cpx SizeBasin
		beq .at_end
		lda $6000,x
		cmp SaveX
		bne .not_equal
		lda $6001,x
		cmp SaveY
		bne .not_equal
		rts ; Already in list.
.not_equal:
		inx
		inx
		jmp .check_next
.at_end:
		lda SaveX
		sta $6000, x
		lda SaveY
		sta $6001, x
		inx
		inx
		stx SizeBasin
		rts

set_tx_ty:
		ldx PX
		stx TX
		ldy PY
		sty TY
		rts

calc_basin_inner:
		jsr set_tx_ty
.scan_up:
		ldx TX
		ldy TY
		dey
		sty TY
		jsr d9_readtile
		cmp #9
		beq .scan_down_start
		ldx TX
		ldy TY
		jsr add_basin_tile
		jmp .scan_up
.scan_down_start:
		jsr set_tx_ty
.scan_down:
		ldx TX
		ldy TY
		iny
		sty TY
		jsr d9_readtile
		cmp #9
		beq .scan_left_start
		ldx TX
		ldy TY
		jsr add_basin_tile
		jmp .scan_down
.scan_left_start:
		jsr set_tx_ty
.scan_left:
		ldx TX
		dex
		stx TX
		ldy TY
		jsr d9_readtile
		cmp #9
		beq .scan_right_start
		ldx TX
		ldy TY
		jsr add_basin_tile
		jmp .scan_left
.scan_right_start:
		jsr set_tx_ty
.scan_right:
		ldx TX
		inx
		stx TX
		ldy TY
		jsr d9_readtile
		cmp #9
		beq .scan_done
		ldx TX
		ldy TY
		jsr add_basin_tile
		jmp .scan_right
.scan_done:
		rts

calc_basin:
		lda #0
		sta SizeBasin
		sta ItBasin
		ldx BX
		ldy BY
		jsr add_basin_tile
		ldx ItBasin
.next_tile:
		lda $6000,x
		sta PX
		lda $6001,x
		sta PY
		jsr calc_basin_inner
		ldx ItBasin
		inx
		inx
		stx ItBasin
		cpx SizeBasin
		bne .next_tile
		; Save it sortedly.
		lda SizeBasin
		lsr a
		cmp BigBasins
		bcc .not_max
		ldx BigBasins+1
		stx BigBasins+2
		ldx BigBasins
		stx BigBasins+1
		sta BigBasins
		rts
.not_max:
		cmp BigBasins+1
		bcc .not_mid
		ldx BigBasins+1
		stx BigBasins+2
		sta BigBasins+1
		rts
.not_mid:
		cmp BigBasins+2
		bcc .not_min
		sta BigBasins+2
.not_min:
		rts

process_valley:
		jsr is_valley
		beq .not_a_valley
		inc NumValley
		ldx CurrTile
		inx
		stx MathLhs
		lda #0
		sta MathLhs+1
		tmm16 MathRhs, SumValley
		jsr math_add16
		tmm16 SumValley, MathOut
		jmp calc_basin
.not_a_valley:
		rts

day9_solve_a:
		lda #0
		sta BX
		sta BY
.next_tile:
		jsr process_valley
		ldx BX
		inx
		stx BX
		cpx #100
		bne .next_tile
		lda #0
		sta PrintColor
		macro_putstr_inline "    Finished row "
		inc PrintColor
		lda BY
		jsr _puthex
		jsr wait_flush
		ldx #0
		stx BX
		ldx BY
		inx
		stx BY
		cpx #100
		bne .next_tile
		tmm16 Result, SumValley
		rts

day9_solve_b:
		lda BigBasins
		sta MathLhs
		lda BigBasins+1
		sta MathRhs
		jsr math_mul32
		tmm16 MathLhs, MathOut
		lda BigBasins+2
		sta MathRhs
		jsr math_mul32
		tmm32 Result, MathOut
		rts

