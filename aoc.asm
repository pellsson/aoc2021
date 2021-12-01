ClobberWord0 .equ $2 ; and $3
IntClobberWord0 .equ $4 ; and $5
MathLhs .equ $10
MathRhs .equ $14
MathOut .equ $18

FrameCounterLo .equ $7FE
FrameCounterHi .equ $7FF

PrintQueue .equ $780
PrintData .equ $781
PrintLine .equ $7EF
PrintColor .equ $7F0
PrintSaveX .equ $7F1
PrintSaveY .equ $7F2
IntrX .equ $7F3
IntrY .equ $7F4

FONT_MAP_SIZE	.equ 77
FONT_MAP_START	.equ 21
MAX_MESSAGE_LEN	.equ 32
	
	;
	; INES header
	;
	.inesprg 1
	.ineschr 2
	.inesmap 0
	.inesmir 0

macro_wait_flush .macro
	lda #$80
	ora PrintQueue
	sta PrintQueue
.wait\@:
	lda PrintQueue
	bmi .wait\@ 
	.endm

macro_putstr .macro
	jmp .p\@
.str\@:
	db \1, 0
.p\@:
	lda #LOW(.str\@)
	sta $0
	lda #HIGH(.str\@)
	sta $1
	jsr putstr
	.endm

	;
	; ### BANK 0 ###
	;
	.bank 0
	.org $8000

nmi_vector:
	pha
		stx IntrX
		sty IntrY
		inc FrameCounterLo
		bne .no_hi
		inc FrameCounterHi
.no_hi:
		lda PrintQueue
		bpl .exit
		jsr fflush
.exit:
		ldy IntrY
		ldx IntrX
	pla
		rti

line_to_off:
	dw 0x020, 0x040, 0x060, 0x080, 0x0A0, 0x0C0, 0x0E0
	dw 0x100, 0x120, 0x140, 0x160, 0x180, 0x1A0, 0x1C0, 0x1E0
	dw 0x200, 0x220, 0x240, 0x260, 0x280, 0x2A0, 0x2C0, 0x2E0
	dw 0x300, 0x320, 0x340, 0x360, 0x380, 0x3A0


fflush:
		lda #$20
		sta IntClobberWord0
		ldx #$88 ; assume low nt
		lda PrintLine
		cmp #30
		bmi .low_nt
		ldx #$8B
		lda #$28
		sta IntClobberWord0
.low_nt:
		stx $2000
		ldy $2002
		cmp #60
		bmi .no_overflow
.no_overflow:
		inc PrintLine
		asl a
		tax
		lda line_to_off+1, x
		adc IntClobberWord0
		sta $2006
		lda line_to_off, x
		sta $2006
		; Loop count
		lda PrintQueue
		and #$7F
		tay	
		ldx #0
.more:
		lda PrintData, x
		sta $2007
		inx
		dey
		bne .more
		sty PrintQueue
		lda $2002
		sty $2005
		sty $2005
		rts

irq_vector:
		rti

_bin_to_hex:
		cmp #$0A
		bpl .is_hex
		clc
		adc #'0'
		rts
.is_hex:
		sec
		sbc #$0a
		clc
		adc #'A'
		rts

_puthex:
		pha
		lsr A
		lsr A
		lsr A
		lsr A
		jsr _bin_to_hex
		jsr _putchar
		pla
		and #$0f
		jsr _bin_to_hex
_putchar:
		ldx PrintColor
		tay
		cpy #FONT_MAP_START
		bmi .is_border
		lda fontmap, Y
		dex
		clc
		bmi .solved
		beq .map_1
		adc #FONT_MAP_SIZE
.map_1:
		adc #FONT_MAP_SIZE
		jmp .solved
.is_border:
		dex
		bmi .solved
		clc
		adc #(FONT_MAP_START-1)/2
.solved:
		ldx PrintQueue
		cpx #MAX_MESSAGE_LEN  
		bpl .too_long
		sta PrintData, x
		inx
		stx PrintQueue
.too_long:
		rts

_putstr:
		ldy #00
.next
		lda [$0], Y
		beq .done
		sty ClobberWord0
		jsr _putchar
		ldy ClobberWord0
		iny
		bne .next ; too long?
.done:
		rts

puthex:
		sty PrintSaveY
		stx PrintSaveX
		jsr _puthex
		ldx PrintSaveX
		ldy PrintSaveY
		rts

putchar:
		sty PrintSaveY
		stx PrintSaveX
		jsr _putchar
		ldx PrintSaveX
		ldy PrintSaveY
		rts

putstr:
		sty PrintSaveY
		stx PrintSaveX
		jsr _putstr
		ldx PrintSaveX
		ldy PrintSaveY
		rts

reset_vector:
		; 
		; Setup stack
		;
		sei
		ldx #$ff
		txs
		;
		; Disable PPU & interrupts
		;
		inx
		stx $2000
		stx $2001
		lda #$40
		sta $4017
		;
		; Sync PPU
		;
.wait_vbl0:
		lda $2002
		bpl .wait_vbl0
.wait_vbl1:
		lda $2002
		bpl .wait_vbl1
		;
		; Memset
		;
.memset:
		lda #$FE ; Sprite outside of screen
		sta $200, x
		lda #$00
		sta $000, x
		sta $100, x
		sta $300, x
		sta $400, x
		sta $500, x
		sta $600, x
		sta $700, x
		inx
		bne .memset
		;
		; Clear NT & Attr
		;
		lda $2002
		lda #$20
		sta $2006
		stx $2006

		stx $00
		lda #$10
		sta $01
.memset_nt:
		stx $2007
		dec $00
		bne .memset_nt
		dec $01
		bne .memset_nt
		;
		; Copy the one palette we use ;)
		;
		ldx #$3F
		stx $2006
		ldx #$00
		stx $2006

.loadpal:
		lda palette, X
		sta $2007
		inx
		cpx #$20
		bne .loadpal

		;
		; Init PPU registers
		;
		; Enable everything (except gray scale)
		;
		lda #$1E
		sta $2001
		;
		; Base NT $2000
		; BG in 0x0000
		; Sprite 0x1000
		; PPU inc 1b
		; Enable NMI
		;
		lda #$88
		sta $2000

		cli
		jsr day1_solve
.done:
		jmp .done

	include "math.asm"
	include "day1.asm"

palette:
	.db $0f, $20, $2A, $16
	.db $0f, $2A, $20, $1C
	.db $0f, $16, $20, $1C
	.db $0f, $1C, $20, $1C
	.db $0f, $0f, $0f, $20
	.db $0f, $0f, $0f, $2A
	.db $0f, $0f, $0f, $16
	.db $0f, $0f, $0f, $1C

fontmap:
	incbin "biosfnt.map"

	;
	; ### BANK 1 ###
	;
	.bank 1
	.org $FFFA

	.dw nmi_vector
	.dw reset_vector
	.dw irq_vector

	;
	; ### BANK 2 ###
	;
	.bank 2
	.org $0000
	.incbin "biosfnt.chr"
	.incbin "biosfnt.chr"
