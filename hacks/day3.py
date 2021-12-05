NUM_BITS = 12
def count_pos(arr, mask):
	v = 0
	for it in arr:
		if it & mask:
			v += 1
		else:
			v -= 1
	return v

def day3_a():
	v = [ int(it, 2) for it in open('day3.a', 'r').readlines() ]
	g = 0
	for i in range(0, NUM_BITS):
		if count_pos(v, 1<<i) > 0:
			g |= 1<<i

	e = 0xFFF^g
	print(hex(g))
	print(e)
	print(e * g) # A ans: 3895776 

def day3_b():
	most = [ int(it, 2) for it in open('day3.a', 'r').readlines() ]
	least = [ int(it, 2) for it in open('day3.a', 'r').readlines() ]
	i = NUM_BITS-1
	M = 0
	L = 0
	while i >= 0:
		m = count_pos(most, 1 << i)
		if 0 == m:
			print('EQUAL')
			v = 1<<i
		elif m < 0:
			v = 0<<i
		else:
			v = 1<<i
		most = [ it for it in most if v == (it&(1<<i)) ]
		print('Pass: %d (%x) - m was: %d (First %04X, last %04X)' % (len(most), len(most), m, most[0], most[-1]))
		m = count_pos(least, 1 << i)
		if 0 == m:
			v = 0<<i
		elif m < 0:
			v = 1<<i
		else:
			v = 0<<i
		least = [ it for it in least if v == (it&(1<<i)) ]
		i -= 1
		if len(most) == 1:
			M = most[0]
			print('M: %d, 0x%04x' % (M, M))
			most = []
		if len(least) == 1:
			L = least[0]
			print('L: %d, 0x%04x' % (L, L))
			least = []
	# L: 3982
	# M: 1991
	# 7928162
	print(M*L)

day3_b()
'''
day3_b()
out = []
for it in open('day3.a', 'r').readlines():
	out.append('\t.dw $%04X' % (int(it, 2)))
open('day3_input.asm', 'w').write('\n'.join(out))
'''