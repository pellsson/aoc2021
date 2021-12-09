def read(board, x, y):
	if x < 0 or x >= len(board[0]):
		return 9
	if y < 0 or y >= len(board):
		return 9
	return board[y][x]

def is_low(board, x, y):
	v = board[y][x]
	if v >= read(board, x, y-1):
		return False
	if v >= read(board, x, y+1):
		return False
	if v >= read(board, x-1, y):
		return False
	if v >= read(board, x+1, y):
		return False
	# print(x, y, v, read(board, x+1, y))
	return True

def scanned_add(scanned, x, y):
	for it in scanned:
		px, py = it
		if px == x and py == y:
			return
	scanned.append((x, y))

def calc_basin_inner(board, sx, sy, scanned):
	x = sx
	y = sy-1
	while read(board, x, y) < 9:
		scanned_add(scanned, x, y)
		y -= 1
	y = sy+1
	while read(board, x, y) < 9:
		scanned_add(scanned, x, y)
		y += 1
	x = sx-1
	y = sy
	while read(board, x, y) < 9:
		scanned_add(scanned, x, y)
		x -= 1
	x = sx + 1
	while read(board, x, y) < 9:
		scanned_add(scanned, x, y)
		x += 1

def calc_basin(board, sx, sy):
	scanned = [(sx, sy)]
	off = 0
	while off < len(scanned):
		px = scanned[off][0]
		py = scanned[off][1]
		calc_basin_inner(board, px, py, scanned)
		off += 1
	# print(scanned, len(scanned))
	return len(scanned)

def run():
	board = []
	for line in [ it.strip() for it in open('day9.a', 'r').readlines() ]:
		row = []
		for c in line:
			row.append(int(c))
		board.append(row)
	basins = []
	tot = 0
	s = 0
	for y in range(0, len(board)):
		for x in range(0, len(board[0])):
			if is_low(board, x, y):
				basins.append(calc_basin(board, x, y))
				tot += 1
				s += board[y][x]+1
	print(tot, s)
	basins = sorted(basins)[-3:]
	print(basins)
	print('B:', basins[0] * basins[1] * basins[2])


run()
# Day9.a tot: 218, s: 439
