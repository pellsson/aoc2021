pos = 0
depth = 0
aim = 0

for it in [ it.split() for it in open('dag2.a', 'r').readlines() ]:
	v = int(it[1])
	if 'up' == it[0]:
		aim -= v
	elif 'down' == it[0]:
		aim += v
	elif 'forward' == it[0]:
		pos += v
		depth += v*aim
	else:
		raise 'sko'

# Answers: 1580000, 1251263225
# 1975 633551 1251263225
print(pos, depth, pos * depth) 
