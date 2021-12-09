import sys

def full_col(b, x):
	for y in range(0, 5):
		if 0 == b[y][x] & 0x80:
			return False
	return True

def full_row(b, y):
	for x in range(0, 5):
		if 0 == b[y][x] & 0x80:
			return False
	return True

def check_complete(b, x, y):
	return full_row(b, y) or full_col(b, x)

def unmarked_sum(b):
	v = 0
	for x in range(0, 5):
		for y in range(0, 5):
			if 0 == (b[y][x] & 0x80):
				v += b[y][x]
	return v

def pick_ball(n, boards, solved):
	r = 0
	for i in range(0, len(boards)):
		if solved[i]:
			continue
		b = boards[i]
		for x in range(0, 5):
			for y in range(0, 5):
				if b[y][x] == n:
					b[y][x] |= 0x80
					if check_complete(b, x, y):
						solved[i] = True
						r = unmarked_sum(b) * n
	return r

def day4_parse():
	fp = open('day4.a', 'r')
	numbers = [int(it) for it in fp.readline().split(',')]
	board = []
	boards = []

	for line in [it.strip() for it in fp.readlines()]:
		if 0 == len(line):
			if len(board):
				boards.append(board)
			board = []
			continue
		board.append([int(v) for v in line.split(' ') if len(v)])

	if len(board):
		boards.append(board)
	return numbers, boards

def day4_a():
	numbers, boards = day4_parse()
	solved = [False]*len(boards)
	for n in numbers:
		r = pick_ball(n, boards, solved)
		if 0 != r:
			print('Answer: %d 0x%x' % (r, r))
			break

def day4_b():
	numbers, boards = day4_parse()
	solved = [False]*len(boards)
	last_solve = 0
	for n in numbers:
		r = pick_ball(n, boards, solved)
		if r:
			last_solve = r
	print('Answer: %d 0x%x' % (last_solve, last_solve))

day4_a() # ANSWER: 55770 0xd9da
day4_b() # Answer: 2980 0xba4


