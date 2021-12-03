x = open('nss/intro.nam', 'rb').read()
x = list(x)
for i in range(0x3C0+32+1, len(x)):
	x[i] = 0
x = bytearray(x)
open('nss/intro-0.nam', 'wb').write(x[0x000:0x100])
open('nss/intro-1.nam', 'wb').write(x[0x100:0x200])
open('nss/intro-2.nam', 'wb').write(x[0x200:0x300])
open('nss/intro-3.nam', 'wb').write(x[0x300:])