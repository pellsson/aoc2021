import re
import glob

def expand_symbol(v, syms):
	if isinstance(v, int):
		return v
	v = v.replace('$', '0x')
	if v[0:2] == '0x':
		return int(v, 16)
	elif v[0] >= '0' and v[0] <= '9':
		return eval(v)
	tokens = v.split('+')
	if 1 == len(tokens):
		return expand_symbol(syms[tokens[0]], syms)
	return expand_symbol(tokens[0], syms) + expand_symbol(tokens[1], syms)

def prg_syms():
	for it in [ it.strip() for it in open('aoc.fns', 'r').readlines() ]:
		m = re.match(r'^([_a-zA-Z0-9]+)\s*= \$([a-fA-F0-9]+)$', it)
		if m is not None:
			print('PRG:%s:%s' % (m.group(1), m.group(2)))

def write_syms():
	syms = {}
	for it in ['aoc.asm', 'day11.asm']: # glob.glob('./*.asm'):
		m = re.findall(r'([_a-zA-Z0-9]+)\s*\.equ\s*([^;\n]+)', open(it, 'r').read())
		if m is None:
			continue
		for x in m:
			syms[x[0].strip()] = x[1].strip()
	print('; ram')
	for k, v in syms.items():
		syms[k] = expand_symbol(syms[k], syms)
		# print('WORK:%s:%04X' % (k, syms[k]))
		print('%s = $%04X' % (k, syms[k]))
write_syms()

'''
[('INPUT', 'WORK'), ('SAVED_SEQUENCE', 'WORK+$4')]
[]
[('INPUT', 'WORK'), ('SAVED_SEQUENCE', 'WORK+$4'), ('Pos', 'WORK+$8'), ('Depth', 'WORK+$C'), ('Aim', 'WORK+$10')]
[]
[('BANK_DAY1', '$0'), ('BANK_MUSIC', '$1'), ('CHR_AOC', '$0'), ('CHR_INTRO', '$2'), ('TMP', '$30'), ('ClobberWord0', '$32 ; and $3'), ('IntClobberWord0', '$34 ; and $5'), ('Param0', '$36'), ('Src', '$38'), ('SrcEnd', '$3A'), ('Dst', '$3C'), ('TaskResetStart', '$40'), ('MathLhs', '$40'), ('MathRhs', '$48'), ('MathOut', '$50'), ('Result', '$58  ; Hack.'), ('WORK', '$60'), ('TaskResetEnd', '$F0'), ('TaskIter', '$600'), ('TaskPtr', '$601'), ('TaskWait', '$604'), ('PrintPPU', '$680'), ('PrintQueue', '$682'), ('PrintData', '$683'), ('PrintColor', '$6F0'), ('PrintSaveX', '$6F1'), ('PrintSaveY', '$6F2'), ('PrintScrollDisabled', '$6F3'), ('PrintScrollTo', '$6F4'), ('PrintScrollAt', '$6F5'), ('Mirror2000', '$6F6'), ('IntrX', '$6F7'), ('IntrY', '$6F8'), ('FrameStartLo', '$6F9'), ('FrameStartHi', '$6FA'), ('FrameEndLo', '$6FB'), ('FrameEndHi', '$6FC'), ('FrameCounterLo', '$6FD'), ('FrameCounterHi', '$6FE'), ('CurrentBank', '$6FF'), ('SCROLL_SPEED', '2'), ('NUM_X_TILES', '32'), ('FONT_MAP_SIZE', '77'), ('FONT_MAP_START', '21'), ('MAX_MESSAGE_LEN', '32')]
[('INPUT', 'WORK'), ('HighMask', 'WORK+$4'), ('Diff', 'WORK+$6 ; and 7'), ('V', 'WORK+$8'), ('CountMask', 'WORK+$9'), ('IsHigh', 'WORK+$a'), ('Mask', 'WORK+$10 ; and 11'), ('G', 'WORK+$12'), ('Remaining', 'WORK+$14 ; and 15'), ('KeepValue', 'WORK+$16'), ('PtrHighByte', 'WORK+$18'), ('WantMany', 'WORK+$19')]
'''