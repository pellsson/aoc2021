INPUT .equ WORK
D12_Name .equ WORK+2 ; until WORK+8?
D12_NameOff .equ WORK+$10
D12_LeftId .equ WORK+$11
D12_RightId .equ WORK+$12
D12_Index .equ WORK+$13 
D12_P .equ WORK+$14
D12_Tmp .equ WORK+$15
D12_SC .equ WORK+$17
D12_SV .equ WORK+$18
D12_IsB .equ WORK+$19
D12_IsTwice .equ WORK+$1A
D12_Prog .equ WORK+$1B
D12_GraphSize .equ WORK+$20
D12_Current .equ WORK+$22
D12_Graph .equ $6000
D12_StackCurrent .equ $6100
D12_StackVisited .equ $6180

D12_START_OFF .equ $10
D12_END_OFF .equ $20

; idx, name[7], <links>
d12_start_graph:
	; id
	db $00
	; name
	db "invalid"
	; links
	db $00, $00, $00, $00, $00, $00, $00, $00
	; id
	db D12_START_OFF
	; name
	db "start"
	db $00, $00
	; links
	db $00, $00, $00, $00, $00, $00, $00, $00
	; id
	db D12_END_OFF
	; name
	db "end"
	db $00, $00, $00, $00
	; links
	db $00, $00, $00, $00, $00, $00, $00, $00
d12_start_graph_end:



d12_get_id_by_name:
		lda #$10
		sta D12_P
.new_search:
		tax
		ldy #0
.next_char:
		lda D12_Graph+1, x
		cmp D12_Name, y
		bne .next_entry
		inx
		iny
		cpy D12_NameOff
		bne .next_char
		lda D12_P
		rts
.next_entry:
		lda D12_P
		clc
		adc #$10
		sta D12_P
		cmp D12_GraphSize
		bne .new_search
		; Cave is new, create it.
		tax
		sta D12_Graph,x
		clc
		adc #$10
		sta D12_GraphSize
		ldy #0
.copy_name:
		lda D12_Name,y 
		sta D12_Graph+1,x
		inx
		iny
		cpy D12_NameOff
		bne .copy_name
		lda D12_P
		rts

d12_make_graph:
		lda #LOW(day12_input)
		sta INPUT
		lda #HIGH(day12_input)
		sta INPUT+1
.next_word:
		lda #0
		sta D12_NameOff
.next:
		lda INPUT
		cmp #LOW(day12_input_end)
		bne .not_end
		lda INPUT+1
		cmp #HIGH(day12_input_end)
		bne .not_end
		rts
.not_end:
		jsr read_next
		cmp #'-'
		beq .left_full
		cmp #0
		beq .right_full
		ldx D12_NameOff
		sta D12_Name, x
		inc D12_NameOff
		jmp .next 
.left_full:
		jsr d12_get_id_by_name
		sta D12_LeftId
		jmp .next_word
.right_full:
		jsr d12_get_id_by_name
		sta D12_RightId
		ldx D12_LeftId
		jsr d12_add_link
		lda D12_LeftId
		ldx D12_RightId
		jsr d12_add_link
		jmp .next_word

d12_add_link:
		sta D12_Tmp
.find:
		lda D12_Graph+$8,x
		beq .found_free
		inx
		bne .find
.found_free:
		lda D12_Tmp
		sta D12_Graph+$8,x
		rts

d12_visit_push:
		lda D12_Current
		ldx D12_SV
		sta D12_StackVisited,x
		inx
		stx D12_SV
		rts

d12_visit_pop:
		ldx D12_SV
		dex
		; pop (dont care about value, we are done here...)
		stx D12_SV
		rts

d12_first_visit:
		jsr d12_visit_push
		jsr d12_walk_links
		ldx D12_SV
		jmp d12_visit_pop

d12_walk_small:
		lda D12_Current
		ldx #0
.check_next:
		cpx D12_SV
		beq .not_in_stack
		cmp D12_StackVisited, x
		beq .in_stack
		inx
		jmp .check_next
.not_in_stack:
		jmp d12_first_visit
.in_stack:
		cmp #D12_START_OFF
		bne .not_start
		rts
.not_start:
		lda D12_IsB
		bne .is_b
		rts
.is_b:
		lda D12_IsTwice
		beq .not_twice
		rts
.not_twice:
		inc D12_IsTwice
		jsr d12_visit_push
		jsr d12_walk_links
		jsr d12_visit_pop
		dec D12_IsTwice
		rts

d12_walk_links:
		ldx D12_Current
.next_link:
		lda D12_Graph+8,x ; next link
		bne .not_done
		rts
.not_done:
	pha
		inx
		txa
		ldy D12_SC
		sta D12_StackCurrent, y
		iny
		sty D12_SC
	pla
		sta D12_Current
		jsr d12_walk_graph
		ldy D12_SC
		dey
		lda D12_StackCurrent,y
		tax
		sty D12_SC
		jmp .next_link  

d12_log_prog:
		lda Result+1
		and #$E0
		cmp D12_Prog
		bne .update
		rts
.update:
		sta D12_Prog
		lda #0
		sta PrintColor
		macro_putstr_inline "        Found #"
		inc PrintColor
		lda Result+2
		jsr _puthex
		lda Result+1
		jsr _puthex
		lda Result+0
		jsr _puthex
		jmp wait_flush

d12_walk_graph:
		lda D12_Current
		cmp #D12_END_OFF
		bne .not_end
		macro_inc32 Result
		lda D12_IsB
		beq .not_b
		jmp d12_log_prog
.not_b:
		rts
.not_end:
    	tax
    	lda D12_Graph+1,x ; first char
    	and #$20
    	beq .isuppercase
    	jmp d12_walk_small
.isuppercase:
		jmp d12_walk_links

day12_solve:
		lda #0
		ldx #0
.more_reset:
		sta D12_Graph, x
		sta D12_StackCurrent, x
		inx
		bne .more_reset
.not_end:
		lda d12_start_graph, x
		sta D12_Graph, x
		inx
		cpx #(d12_start_graph_end-d12_start_graph)
		bne .not_end
		lda #(d12_start_graph_end-d12_start_graph)
		sta D12_GraphSize
		jsr d12_make_graph
		lda #D12_START_OFF
		sta D12_Current
		jmp d12_walk_graph

day12_solve_a:
		jmp day12_solve
day12_solve_b:
		inc D12_IsB
		jmp day12_solve