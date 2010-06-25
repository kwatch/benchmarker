###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

from __future__ import with_statement

import sys, os
_ = os.path.dirname
sys.path.append(_(_(__file__)))

from oktest import ok, not_ok, run
from benchmarker import Benchmarker
from StringIO import StringIO

def fib(n):
    if n <= 2:
        return 1
    else:
        return fib(n-1) + fib(n-2)


class BenchmarkerTest(object):

    def before(self):
        out = StringIO()
        self.bm = Benchmarker(out=out) # or Benchmarker(width=30, out=sys.stderr, header=True)
        self.out = out

    pattern = ''.join((
        ' ' * 30 + '     utime      stime      total       real' "\n",
        r'fib\(n\) \(n==25\)( *\d+\.\d\d\d\d){4}' + "\n",
        r'fib\(n\) \(n==30\)( *\d+\.\d\d\d\d){4}' + "\n",
        r'fib\(n\) \(n==35\)( *\d+\.\d\d\d\d){4}' + "\n",
    ))
    pattern = '^' + pattern + '$'

    def test_with_statement(self):
        bm = self.bm
        with bm('fib(n) (n==25)'):  fib(25)
        with bm('fib(n) (n==30)'):  fib(30)
        with bm('fib(n) (n==35)'):  fib(35)
        actual = self.out.getvalue()
        ok (actual).matches(self.pattern)

    def test_run(self):
        bm = self.bm
        bm('fib(n) (n==25)').run(lambda: fib(25))
        bm('fib(n) (n==30)').run(lambda: fib(30))
        bm('fib(n) (n==35)').run(lambda: fib(35))
        actual = self.out.getvalue()
        ok (actual).matches(self.pattern)

    def test_results(self):
        ## results
        bm = self.bm
        bm('fib(n) (n==10)').run(fib, 10)
        bm('fib(n) (n==15)').run(fib, 15)
        ok (type(bm.results)) == list
        ok (len(bm.results)) == 2
        ok (bm.results[0][0]) == 'fib(n) (n==10)'
        ok (bm.results[1][0]) == 'fib(n) (n==15)'
        for i in range(0, 2):
            T = bm.results[i]
            ok (type(T)) == tuple
            ok (len (T)) == 5
            ok (type(T[0])) == str
            ok (type(T[1])) == float
            ok (type(T[2])) == float
            ok (type(T[3])) == float
            ok (type(T[4])) == float


if __name__ == '__main__':
    run(BenchmarkerTest)
