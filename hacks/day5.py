DIM = 50

def write_if_inside(grid, gx, gy, x, y):
	if x < gx or y < gy:
		return
	if x >= (gx+DIM) or y >= (gy+DIM):
		return
	#print(gx, gy, x, y, y-gy, x-gx)
	grid[y-gy][x-gx] += 1

def day5(gx, gy, include_dia):
	grid = []
	for i in range(0, DIM):
		grid.append([0] * DIM)

	for pair in [ it.split(" -> ") for it in open('day5.a', 'r').readlines() ]:
		x0, y0 = [ int(it) for it in pair[0].split(",") ]
		x1, y1 = [ int(it) for it in pair[1].split(",") ]

		diagonal = (x1 != x0 and y0 != y1)
		if diagonal and not include_dia:
			continue
		
		if diagonal:
			x = x0
			y = y0
			while x != x1 and y != y1:
				write_if_inside(grid, gx, gy, x, y)
				x += 1 if x < x1 else -1
				y += 1 if y < y1 else -1
			write_if_inside(grid, gx, gy, x, y)
		else:
			min_x = min(x0, x1)
			max_x = max(x0, x1)
			min_y = min(y0, y1)
			max_y = max(y0, y1)
			x = min_x
			y = min_y
			while y <= max_y:
				while x <= max_x:
					write_if_inside(grid, gx, gy, x, y)
					# grid[y][x] += 1
					x += 1
				x = min_x
				y += 1

	tot = 0
	for row in grid:
		for x in row:
			if x >= 2:
				tot += 1
		# print(' '.join([ str(it) for it in row[0:20] ]))
	return tot

def day5_a():
	tot = 0
	for y in range(0, 1000, DIM):
		for x in range(0, 1000, DIM):
			tot += day5(x, y, False)
			print(hex(tot))
	print('A: ', tot)

def day5_b():
	tot = 0
	for y in range(0, 1000, DIM):
		for x in range(0, 1000, DIM):
			tot += day5(x, y, True)
	print('B: ', tot)
	
# day5_a() # 4655
# day5_b() # 20500
day5_a()
# day5_b()