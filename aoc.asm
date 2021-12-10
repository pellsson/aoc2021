	;
	; INES header
	;
	.inesprg 8
	.ineschr 2
	.inesmap 1
	.inesmir 0

; QUICK_RUN .equ 1

BANK_DAYS_1 .equ $0
BANK_MUSIC  .equ $1
BANK_DAYS_2 .equ $2
BANK_DAYS_3 .equ $3
BANK_DAYS_4 .equ $4
BANK_DAYS_5 .equ $5
BANK_DAYS_6 .equ $6
BANK_FIXED  .equ $7

CHR_AOC   .equ $0
CHR_INTRO .equ $2

TMP .equ $30
ClobberWord0 .equ $32 ; and $3
IntClobberWord0 .equ $34 ; and $5
Param0 .equ $36

Src .equ $38
SrcEnd .equ $3A
Dst .equ $3C

TaskResetStart .equ $40
MathLhs .equ $40
MathRhs .equ $48
MathOut .equ $50
Result .equ $58  ; Hack.
WORK .equ $60
TaskResetEnd .equ $F0
TaskIter .equ $600
TaskPtr .equ $601
; ...
TaskWait .equ $604

Day9_SaveShit .equ 610 ; 611, 612, 614

PrintPPU .equ $680
PrintQueue .equ $682
PrintData .equ $683
PrintBColor .equ $6EF
PrintColor .equ $6F0
PrintSaveX .equ $6F1
PrintSaveY .equ $6F2
PrintScrollDisabled .equ $6F3
PrintScrollTo .equ $6F4
PrintScrollAt .equ $6F5
Mirror2000 .equ $6F6
IntrX .equ $6F7
IntrY .equ $6F8
FrameStartLo .equ $6F9
FrameStartHi .equ $6FA
; FrameEndLo .equ $6FB
; FrameEndHi .equ $6FC
FrameCounterLo .equ $6FD
FrameCounterHi .equ $6FE
CurrentBank .equ $6FF

SCROLL_SPEED    .equ 2
NUM_X_TILES     .equ 32
FONT_MAP_SIZE	.equ 77
FONT_MAP_START	.equ 21
MAX_MESSAGE_LEN	.equ 32

	include "macros.asm"

	; ### BANK 1 ###
	.bank BANK_DAYS_1
	.org $8000
	db "Bank Days 1",0
	include "day1.asm"
	include "day1_input.asm"
	include "day2.asm"
	include "day2_input.asm"
	include "day3.asm"
	include "day3_input.asm"
	include "day4.asm"
	include "day4_input.asm"
	include "day6.asm"
	include "day6_input.asm"

	.bank BANK_MUSIC
	.org $8000

	music_base: .equ $8D1C
	music_init: .equ $A672
	music_play: .equ $A675
	incbin "musicbank-8000.bin"

	.bank BANK_DAYS_2
	.org $8000
	db "Bank Days 2"
	include "day5.asm"
	include "day5_input.asm"
	; day 6 moved ot bank1
	include "day7.asm"
	include "day7_input.asm"

	.bank BANK_DAYS_3
	.org $8000
	db "Bank Days 3"
	include "day8.asm"
	include "day8_input.asm"
	include "day9.asm"
	include "day9_input.asm"

	.bank BANK_DAYS_4
	.org $8000
	db "Bank Days 4"

	.bank BANK_DAYS_5
	.org $8000
	db "Bank Days 5"

	.bank BANK_DAYS_6
	.org $8000
	db "Bank Days 6"

	.bank BANK_FIXED
	.org $C000

nmi_vector:
	pha
		stx IntrX
		sty IntrY
		inc FrameCounterLo
		bne .no_hi
		inc FrameCounterHi
.no_hi:
		dec TaskWait
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
		lda #0
		ldx #0
.clear_next:
		sta $2007
		inx
		cpx #NUM_X_TILES
		bne .clear_next
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

ppu_on:
.wait_vbl0:
		lda $2002
		bpl .wait_vbl0
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
		cli
		rts

ppu_off:
		sei
		sta Mirror2000
		sta $2000
.wait_vbl0:
		lda $2002
		bpl .wait_vbl0
		lda #0
		sta $2001
		rts

run_intro:
		lda #CHR_INTRO
		jsr set_chr_bank
		lda $2002
		ldx #$3F
		stx $2006
		ldx #$00
		stx $2006
.loadpal:
		lda intro_palette, X
		sta $2007 ; bkgr
		inx
		cpx #$20
		bne .loadpal
		;
		; Load NT & Attr
		;
		lda $2002
		lda #$20
		sta $2006
		lda #$00
		sta $2006

		ldx #0
.more_0
		lda intro_nt_0, x
		sta $2007
		inx
		bne .more_0
.more_1
		lda intro_nt_1, x
		sta $2007
		inx
		bne .more_1
.more_2
		lda intro_nt_2, x
		sta $2007
		inx
		bne .more_2
.more_3
		lda intro_nt_3, x
		sta $2007
		inx
		bne .more_3
		jsr ppu_on
.wait_intro_hi:
		lda FrameCounterHi
		beq .wait_intro_hi
.wait_intro_lo:
		lda FrameCounterLo
		cmp #$80
		bne .wait_intro_lo
		jmp ppu_off

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

wait_flush:
.wait_scroll:
		lda PrintScrollAt
		cmp PrintScrollTo
		bne .wait_scroll
		lda #$80
		ora PrintQueue
		sta PrintQueue
.wait:
		lda PrintQueue
		bmi .wait
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
		ldx PrintBColor
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

banner_top:
	db "    ",1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,0
banner_pre:
	db "    ",6,0
day_nr:
	db "      Day ",0
banner_post:
	db "        ",6,0
banner_bottom:
	db "    ",4,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,5,0

begin_task:
		stx Param0
		sty Param0+1
		ldx #(TaskResetEnd-TaskResetStart)
		lda #0
.more_reset:
		sta TaskResetStart-1, X
		dex
		bne .more_reset
		sta PrintColor
		lda PrintBColor
		eor #1
		sta PrintBColor
		macro_putstr banner_top
		jsr wait_flush
		macro_putstr banner_pre
		macro_putstr_inline " Advent of Code 2021 "
		lda #6
		jsr _putchar
		jsr wait_flush
		macro_putstr banner_pre
		macro_putstr day_nr
		lda Param0
		jsr _putchar
		lda #'.'
		jsr _putchar
		lda Param0+1
		jsr _putchar
		macro_putstr banner_post
		jsr wait_flush
		macro_putstr banner_bottom
		jsr wait_flush
		jsr wait_flush
		lda #0
		sta PrintColor
		macro_putstr_inline "    Starting on frame #"
		lda #2
		sta PrintColor
		lda FrameCounterHi
		jsr _puthex
		lda FrameCounterLo
		jsr _puthex
		jsr wait_flush
		lda FrameCounterHi
		sta FrameStartHi
		lda FrameCounterLo
		sta FrameStartLo
		rts

end_task:
		lda #0
		sta PrintColor
		macro_putstr_inline "    Finished on frame #"
		inc PrintColor
		lda FrameCounterHi
		jsr _puthex
		lda FrameCounterLo
		jsr _puthex
		jsr wait_flush
		jsr wait_flush
		dec PrintColor
		macro_putstr_inline "     NES says: "
		inc PrintColor
		lda Result+5
		jsr _puthex
		lda Result+4
		jsr _puthex
		lda Result+3
		jsr _puthex
		lda Result+2
		jsr _puthex
		lda Result+1
		jsr _puthex
		lda Result
		jsr _puthex
		jsr wait_flush
		jsr wait_flush
		jsr wait_flush
		lda #$60
		sta TaskWait
.wait_next:
		lda TaskWait
		bne .wait_next
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

set_chr_bank: ; Use $C000 if we decide to splite to 4/4 instead of 8
		sta $A000
		lsr a
		sta $A000
		lsr a
		sta $A000
		lsr a
		sta $A000
		lsr a
		sta $A000
		rts

reset_vector:
		; 
		; Setup stack
		;
		sei
		ldx #$ff
		txs
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
		; Init music
		;
		lda #BANK_MUSIC
		jsr set_bank_a
		lda #0
		ldx #0
	IFNDEF QUICK_RUN
		jsr music_init
		lda #$40
		sta $4017
		jsr run_intro
	ENDIF
		;
		; Clear NT & Attr
		;
		lda $2002
		lda #$20
		sta $2006
		lda #$00
		sta $2006

		sta TMP
		lda #$10
		sta TMP+1
		lda #0
.memset_nt:
		sta $2007
		dec TMP
		bne .memset_nt
		dec TMP+1
		bne .memset_nt

		lda $2002
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

		lda #CHR_AOC
		jsr set_chr_bank

		jsr ppu_on

		;
		; Initialize game data
		;
		lda #29
		sta PrintScrollDisabled

		lda #BANK_DAYS_1
		jsr set_bank_a

		ldx #5
.scroll:
		jsr wait_flush
		dex
		bne .scroll

		lda #0
		sta TaskIter
.run_task:
		tax
		clc
		adc #5
		sta TaskIter
		lda day_table+2,x
		jsr set_bank_a
		lda day_table+3, x
		sta TaskPtr
		lda day_table+4, x
		sta TaskPtr+1 ; Func ptr
		lda day_table+1, x
		tay
		lda day_table, x 
		tax
		jsr begin_task
		lda #HIGH((.return_to-1))
		pha
		lda #LOW((.return_to-1))
		pha
		jmp [TaskPtr]
.return_to:
		jsr end_task
		lda TaskIter
		cmp #(day_table_end - day_table)
		bne .run_task
all_solved
		jmp all_solved

_memcpy:
		ldy #0
.check_next:
		lda Src
		cmp SrcEnd
		bne .not_end
		lda Src+1
		cmp SrcEnd+1
		beq .end
.not_end:
		lda [Src], Y
		sta [Dst], Y
		inc Src
		bne .no_high_src
		inc Src+1
.no_high_src:
		inc Dst
		bne .no_high_dst
		inc Dst+1
.no_high_dst:
		jmp .check_next
.end:
		rts

day_table:
	IFNDEF QUICK_RUN
	db '1', 'a', BANK_DAYS_1
	dw day1_solve_a
	db '1', 'b', BANK_DAYS_1
	dw day1_solve_b
	db '2', 'a', BANK_DAYS_1
	dw day2_solve_a
	db '2', 'b', BANK_DAYS_1
	dw day2_solve_b
	db '3', 'a', BANK_DAYS_1
	dw day3_solve_a
	db '3', 'b', BANK_DAYS_1
	dw day3_solve_b
	db '4', 'a', BANK_DAYS_1
	dw day4_solve_a
	db '4', 'b', BANK_DAYS_1
	dw day4_solve_b
	db '5', 'a', BANK_DAYS_2
	dw day5_solve_a
	db '5', 'b', BANK_DAYS_2
	dw day5_solve_b
	db '6', 'a', BANK_DAYS_1
	dw day6_solve_a
	db '6', 'b', BANK_DAYS_1
	dw day6_solve_b
	db '7', 'a', BANK_DAYS_2
	dw day7_solve_a
	db '7', 'b', BANK_DAYS_2
	dw day7_solve_b
	ENDIF
	db '8', 'a', BANK_DAYS_3
	dw day8_solve_a
	db '8', 'b', BANK_DAYS_3
	dw day8_solve_b
	IFNDEF QUICK_RUN
	db '9', 'a', BANK_DAYS_3
	dw day9_solve_a
	db '9', 'b', BANK_DAYS_3
	dw day9_solve_b
	ENDIF
day_table_end:

day_unsolved:
		lda #$ff
		sta Result
		sta Result+1
		sta Result+2
		sta Result+3
		rts

mathout_to_res:
		tmm32 Result, MathOut
		rts

peek_next:
		ldy #0
		lda [INPUT], Y
		rts

read_next:
		jsr peek_next
skip_next:
		inc INPUT
		bne .no_high
		inc INPUT+1
.no_high:
		rts

	include "math.asm"

intro_nt_0:
	incbin "nss/intro-0.nam"
intro_nt_1:
	incbin "nss/intro-1.nam"
intro_nt_2:
	incbin "nss/intro-2.nam"
intro_nt_3:
	incbin "nss/intro-3.nam"

intro_palette:
	incbin "nss/intro.pal" ; bkgr
	incbin "nss/intro.pal" ; sprite


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
