#  h0:6    x1:2     2:5    h3:5    x4:4
#  aaaa    ....    aaaa    aaaa    ....
# b    c  .    c  .    c  .    c  b    c
# b    c  .    c  .    c  .    c  b    c
#  ....    ....    dddd    dddd    dddd
# e    f  .    f  e    .  .    f  .    f
# e    f  .    f  e    .  .    f  .    f
#  gggg    ....    gggg    gggg    ....

#   5:5    h6:6    x7:3    x8:7    h9:6
#  aaaa    aaaa    aaaa    aaaa    aaaa
# b    .  b    .  .    c  b    c  b    c
# b    .  b    .  .    c  b    c  b    c
#  dddd    dddd    ....    dddd    dddd
# .    f  e    f  .    f  e    f  .    f
# .    f  e    f  .    f  e    f  .    f
#  gggg    gggg    ....    gggg    gggg


def num_to_val(s):
	n = 0
	for c in s:
		n |= 1<<(ord('g')-ord(c))
	return n

def bits_set(v):
	n = 0x80
	s = 0
	while n:
		if n & v:
			s += 1
		n >>= 1
	return s

def decode_easy(translated, n):
	if len(n) == 2:
		translated[1] = num_to_val(n)
	elif len(n) == 4:
		translated[4] = num_to_val(n)
	elif len(n) == 3:
		translated[7] = num_to_val(n)
	elif len(n) == 7:
		translated[8] = num_to_val(n)
	return 0

def decode_hard(translated, n):
	nv = num_to_val(n)
	if len(n) == 6:
		if translated[4] == (nv & translated[4]):
			translated[9] = nv
		elif translated[1] == (nv & translated[1]):
			translated[0] = nv
		else:
			translated[6] = nv
	elif len(n) == 5:
		if translated[1] == (nv & translated[1]):
			translated[3] = nv

def decode_two_five(translated, n):
	nv = num_to_val(n)
	if len(n) == 5:
		if translated[1] == (nv & translated[1]):
			return
		if nv == (nv & translated[6]):
			translated[5] = nv
		else:
			translated[2] = nv

def translate(translated, n):
	nv = num_to_val(n)
	for i in range(0, len(translated)):
		if nv == translated[i]:
			return i
	return -1

def run():
	data = [ it.split('|') for it in open('day8.test', 'r').readlines() ]
	v = []
	for it in data:
		v.append(dict(
			L=[ it.strip() for it in it[0].strip().split(' ') ],
			R=[ it.strip() for it in it[1].strip().split(' ') ]
		))
	a_score = 0
	b_score = 0
	for it in v:
		translated = [0]*10
		for num in it['L']:
			decode_easy(translated, num)
		for num in it['L']:
			decode_hard(translated, num)
		for num in it['L']:
			decode_two_five(translated, num)
		display = 0
		for x in it['R']:
			v = translate(translated, x)
			if v in [1,4,7,8]:
				a_score += 1
			display *= 10
			display += v
		b_score += display
	print('A', a_score, hex(a_score))
	print('B', b_score, hex(b_score))

run()
