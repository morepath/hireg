from reg import mapply as reg_mapply
from hireg import mapply as hireg_mapply
import timeit

def foo(a, b):
    pass

def main():
    print "hireg mapply:"
    hireg_time = timeit.timeit('hireg_mapply(foo, a=1, b=2, c=3)',
                               'from __main__ import hireg_mapply, foo')
    print hireg_time
    print "reg mapply:"
    reg_time = timeit.timeit('reg_mapply(foo, a=1, b=2, c=3)',
                             'from __main__ import reg_mapply, foo')
    print reg_time
    print "plain call:"
    call_time = timeit.timeit('foo(a=1, b=2)',
                              'from __main__ import foo')
    print call_time
    speedup = reg_time / hireg_time

    slowdown = hireg_time / call_time

    print "speedup above reg: %s (%s)" % (round(speedup, 2), speedup)
    print "slowdown below call: %s (%s)" % (round(slowdown, 2), slowdown)
if __name__ == '__main__':
    main()

