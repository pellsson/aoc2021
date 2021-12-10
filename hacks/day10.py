o = ['(','[','{','<']
c = { ')': '(', ']': '[', '}': '{', '>': '<' }
x = { '(': 1, '[': 2, '{': 3, '<': 4 }
s = { ')': 3, ']': 57, '}': 1197, '>': 25137 }

score_a = 0
line_nr = 1
scores_b = []

for line in [it.strip() for it in open('day10.a', 'r').readlines()]:
	score_b = 0
	print("Line: %d" % (line_nr))
	line_nr += 1
	stack = []
	corrupt = False
	for i in range(0, len(line)):
		it = line[i]
		if it in o:
			stack.append(it)
		elif stack[-1] != c[it]:
			corrupt = True
			# print('bugged %s @ %d "%s" - %c but want %c' % (line, i, str(''.join(stack)), it, stack[-1]))
			score_a += s[it]
			break
		else:
			stack = stack[:-1]
	if not corrupt:
		while len(stack):
			score_b *= 5
			v = x[stack.pop()]
			score_b += v
		scores_b.append(score_b)

print(stack)
print(score_a)
print(scores_b)
print(sorted(scores_b)[int(len(scores_b)/2)])
