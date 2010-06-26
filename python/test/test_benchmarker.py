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
from benchmarker import Benchmarker, ComparedMatrix
try:
    from StringIO import StringIO    # Python 2.x
except ImportError:
    from io import StringIO          # Python 3.x

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
        r'fib\(n\) \(n==20\)( *\d+\.\d\d\d){4}' + "\n",
        r'fib\(n\) \(n==25\)( *\d+\.\d\d\d){4}' + "\n",
        r'fib\(n\) \(n==30\)( *\d+\.\d\d\d){4}' + "\n",
    ))
    pattern = '^' + pattern + '$'

    def test_with_statement(self):
        bm = self.bm
        with bm('fib(n) (n==20)'):  fib(20)
        with bm('fib(n) (n==25)'):  fib(25)
        with bm('fib(n) (n==30)'):  fib(30)
        actual = self.out.getvalue()
        ok (actual).matches(self.pattern)

    def test_run(self):
        bm = self.bm
        bm('fib(n) (n==20)').run(fib, 20)
        bm('fib(n) (n==25)').run(fib, 25)
        bm('fib(n) (n==30)').run(lambda: fib(30))
        actual = self.out.getvalue()
        ok (actual).matches(self.pattern)

    def test_run_2(self):
        if "called without setting title then use func name as title":
            bm = self.bm
            def fib10(): fib(10)
            def fib15(): fib(15)
            bm.run(fib10)
            bm.run(fib15)
            actual = self.out.getvalue()
            pattern = ''.join(('^',
                ' ' * 30 + '     utime      stime      total       real' "\n",
                r'fib10 ( *\d+\.\d\d\d){4}' + "\n",
                r'fib15 ( *\d+\.\d\d\d){4}' + "\n",
            '$'))
            ok (actual).matches(pattern)

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
            ok (len(T)) == 5
            ok (type(T[0])) == str
            ok (type(T[1])) == float
            ok (type(T[2])) == float
            ok (type(T[3])) == float
            ok (type(T[4])) == float

    def test_compared_matrix(self):
        bm = self.bm
        bm.results = [
            ("benchX", 0, 0, 0, 7.50),
            ("benchY", 0, 0, 0, 2.50),
            ("benchZ", 0, 0, 0, 5.00),
        ]
        exptected_default = [
            [  None, 100.00, 200.00],
            [-50.00,   None,  50.00],
            [-66.66, -33.33,   None]
        ]
        expected1_transported = [
            [  None, -50.00, -66.66],
            [100.00,   None, -33.33],
            [200.00,  50.00,   None],
        ]
        if "called then returns ComparedMatrix object":
            matrix = bm.compared_matrix()
            ok (type(matrix)) == ComparedMatrix
            ok (matrix.titles) == ["benchX", "benchY", "benchZ"]
            ok (matrix.values) == [7.50, 2.50, 5.00]
            ok (str(matrix)) == """
                   real      [01]     [02]     [03]
[01] benchX      7.500s        -    -66.7%   -33.3%
[02] benchY      2.500s    200.0%       -    100.0%
[03] benchZ      5.000s     50.0%   -50.0%       - 
"""[1:]
        if "called with sort=True then sort by values":
            matrix = bm.compared_matrix(sort=True)
            ok (type(matrix)) == ComparedMatrix
            ok (matrix.titles) == ["benchY", "benchZ", "benchX"]
            ok (matrix.values) == [2.50, 5.00, 7.50]
            ok (str(matrix)) == """
                   real      [01]     [02]     [03]
[01] benchY      2.500s        -    100.0%   200.0%
[02] benchZ      5.000s    -50.0%       -     50.0%
[03] benchX      7.500s    -66.7%   -33.3%       - 
"""[1:]
        if "called with transpose=True then transport matrix":
            matrix = bm.compared_matrix(transpose=True, sort=True)
            ok (type(matrix)) == ComparedMatrix
            ok (str(matrix)) == """
                   real      [01]     [02]     [03]
[01] benchY      2.500s        -    -50.0%   -66.7%
[02] benchZ      5.000s    100.0%       -    -33.3%
[03] benchX      7.500s    200.0%    50.0%       - 
"""[1:]

    def test_print_compared_matrix(self):
        bm = self.bm
        #bm('fib(20)').run(fib, 20)
        #bm('fib(10)').run(fib, 10)
        #bm('fib(15)').run(fib, 15)
        bm.results = [
            ("benchX", 0, 0, 0, 7.50),
            ("benchY", 0, 0, 0, 2.50),
            ("benchZ", 0, 0, 0, 5.00),
        ]
        bm.print_compared_matrix()
        actual = self.out.getvalue()
        ok (actual) == """
-------------------------------------------------------------------------------
                   real      [01]     [02]     [03]
[01] benchX      7.500s        -    -66.7%   -33.3%
[02] benchY      2.500s    200.0%       -    100.0%
[03] benchZ      5.000s     50.0%   -50.0%       - 
"""[1:]


if __name__ == '__main__':
    run(BenchmarkerTest)
