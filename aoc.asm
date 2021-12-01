BANK_DAY1_INPUT .equ $0
BANK_MUSIC		.equ $1

TMP .equ $30
ClobberWord0 .equ $32 ; and $3
IntClobberWord0 .equ $34 ; and $5
Param0 .equ $36
MathLhs .equ $40
MathRhs .equ $44
MathOut .equ $48

PrintPPU .equ $680
PrintQueue .equ $682
PrintData .equ $683
PrintColor .equ $6F0
PrintSaveX .equ $6F1
PrintSaveY .equ $6F2
PrintScrollDisabled .equ $6F3
PrintScrollTo .equ $6F4
PrintScrollAt .equ $6F5

Mirror2000 .equ $6FA
IntrX .equ $6FB
IntrY .equ $6FC
FrameCounterLo .equ $6FD
FrameCounterHi .equ $6FE
CurrentBank .equ $6FF

SCROLL_SPEED    .equ 2
NUM_X_TILES     .equ 32
FONT_MAP_SIZE	.equ 77
FONT_MAP_START	.equ 21
MAX_MESSAGE_LEN	.equ 32

macro_wait_flush .macro
.wait_scroll\@:
	lda PrintScrollAt
	cmp PrintScrollTo
	bne .wait_scroll\@
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
	sta TMP
	lda #HIGH(.str\@)
	sta TMP+1
	jsr putstr
	.endm

	;
	; INES header
	;
	.inesprg 4
	.ineschr 2
	.inesmap 1
	.inesmir 0

	; ### BANK 1 ###
	.bank BANK_DAY1_INPUT
	.org $8000
	include "input.asm"

	.bank BANK_MUSIC
	.org $C000

	music_base: .equ $8D1C
	music_init: .equ $A672
	music_play: .equ $A675
	incbin "musicbank-8000.bin"

	.bank 2
	.org $C000
	db "Bank #2 placeholder"

	;
	; ### BANK 1 ###
	;
	.bank 3
	.org $C000

nmi_vector:
	pha
		stx IntrX
		sty IntrY
		inc FrameCounterLo
		bne .no_hi
		inc FrameCounterHi
.no_hi:
		; sprites
		lda #$4
		sta $4014
		; prints
		lda PrintQueue
		bpl .scroll_screen
		jsr fflush
.scroll_screen:
		lda PrintScrollAt
		cmp PrintScrollTo
		beq .do_scroll
		;
		; Figure out how far to scroll 
		;
		jsr update_scroll
.do_scroll:
		;
		lda #00
		sta $2005
		lda PrintScrollAt
		sta $2005
		lda Mirror2000
		sta $2000
		lda #BANK_MUSIC
		jsr set_bank_tmp
		jsr music_play
		jsr set_bank_current
		;
		; Return
		;
		ldy IntrY
		ldx IntrX
	pla
		rti

flip_nt:
		lda Mirror2000
		eor #$2
		sta Mirror2000
		rts

update_scroll:
		sec
		lda PrintScrollTo
		sbc PrintScrollAt
		cmp #SCROLL_SPEED
		bpl .update_scroll
		lda PrintScrollTo
		sta PrintScrollAt
		jmp .check_reset
.update_scroll:
		clc
		lda #SCROLL_SPEED
		adc PrintScrollAt
		sta PrintScrollAt
.check_reset:
		cmp #30*8
		bcc .done
		jsr flip_nt
		lda #0
		sta PrintScrollAt
		sta PrintScrollTo
.done
		rts

fflush:
		lda $2002
		lda PrintPPU+1
		sta $2006
		lda PrintPPU
		sta $2006
		ldx #0
		stx PrintQueue
.more:
		lda PrintData, x
		sta $2007
		lda #0
		sta PrintData, x
		inx
		cpx #NUM_X_TILES
		bne .more
		clc
		lda PrintPPU
		adc #NUM_X_TILES
		sta PrintPPU
		bcc .no_carry
		inc PrintPPU+1
.no_carry:
		; Finally fix PPU address in case it needs to reset
		lda PrintPPU
		cmp #$C0 ; If we are at either 0x23C0 or 0x2BC0 we need to reset
		bne .gogo
		lda PrintPPU+1
		cmp #$23
		bne .check_high_nt
		; We are in low NT attr, skip ahead
		lda #$00
		sta PrintPPU
		lda #$28
		sta PrintPPU+1
		jmp .gogo
.check_high_nt:
		cmp #$2B
		bne .gogo
		lda #$00
		sta PrintPPU
		lda #$20
		sta PrintPPU+1
.gogo:
		lda PrintScrollDisabled
		bne .dont_scroll
		clc
		lda #8
		adc PrintScrollTo
		sta PrintScrollTo
		rts
.dont_scroll:
		dec PrintScrollDisabled
		rts

irq_vector:
		nop
		nop
		nop
		nop
		nop
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
		lda [TMP], Y
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

set_bank_a:
		sta CurrentBank
set_bank_current:
		lda CurrentBank
set_bank_tmp:
		sta $E000
		lsr a
		sta $E000
		lsr a
		sta $E000
		lsr a
		sta $E000
		lsr a
		sta $E000
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
		stx Mirror2000
		stx $2000
		stx $2001
		lda #$40
		sta $4017
		;
		; Init MMC1
		; Switch 0x8000, Fix 0xC000, Horizontal mirroring
		;
		lda #$0F
		sta $8000
		lsr a
		sta $8000
		lsr a
		sta $8000
		lsr a
		sta $8000
		lsr a
		sta $8000
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
		sta $400, x
		lda #$00
		sta $000, x
		sta $100, x
		sta $200, x
		sta $300, x
		; sta $400, x
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

		lda #$00
		sta PrintPPU
		lda #$20
		sta PrintPPU+1
		;
		; Init music
		;
		lda #BANK_MUSIC
		jsr set_bank_a
		lda #0
		ldx #0
		jsr music_init
		lda #$40
		sta $4017
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
		sta Mirror2000
		sta $2000

		;
		; Initialize game data
		;
		lda #29
		sta PrintScrollDisabled

		cli
		ldx #0
.skip_frame:
		lda FrameCounterLo
		and #$7
		bne .skip_frame
		macro_putstr "HI NT HI: "
		txa
		inx
		jsr puthex
		macro_wait_flush
		;lda #BANK_DAY1_INPUT
		;jsr set_bank_a

		;jsr day1_solve_a ; 1711
		;jsr day1_solve_b ; 1743
		jmp .skip_frame

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

	.org $FFFA

	.dw nmi_vector
	.dw reset_vector
	.dw irq_vector
