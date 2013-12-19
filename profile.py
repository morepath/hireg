import pstats, cProfile

from hireg import mapply

def foo(a, b):
    pass

def multiple():
    for i in range(1000000):
        mapply(foo, a=1, b=2, c=3)

cProfile.runctx('multiple()', globals(), locals(), "Profile.prof")

s = pstats.Stats('Profile.prof')
s.strip_dirs().sort_stats('time').print_stats()
