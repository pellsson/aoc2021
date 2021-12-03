for it in [ it.split() for it in open('dag2.a', 'r').readlines() ]:
	print("\tdb '%c', %s" % (it[0][0], it[1]))
