# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


import sys, os, time

__all__ = ('Benchmarker', )


class Benchmarker(object):
    """benchmark utility class

       Example (ex.py)::

           def fib(n):
               return n <= 2 and 1 or fib(n-1) + fib(n-2)
           from benchmarker import Benchmarker
           bm = Benchmarker()  # or Benchmarker(width=30, out=sys.stderr, header=True)
           ## Python 2.5 or later
           with bm('fib(n) (n==34)'):  fib(34)
           with bm('fib(n) (n==35)'):  fib(35)
           ## Python 2.4
           bm('fib(n) (n==34)').run(fib, 34)   # or .run(lambda: fib(34))
           bm('fib(n) (n==35)').run(fib, 35)   # or .run(lambda: fib(35))
           ## You can get benchmark results
           #for items in bm.results: print items

       Output::

           $ python ex.py
                                        utime      stime      total       real
           fib(n) (n==34)              4.3700     0.0200     4.3900     4.9449
           fib(n) (n==35)              7.1500     0.0500     7.2000     8.0643
    """

    header_format = '%10s %10s %10s %10s'
    times_format  = '%10.3f %10.3f %10.3f %10.3f'

    def __init__(self, width=30, out=None, header=True):
        if out is None:  out = sys.stderr
        self.width = width
        self.out   = out
        self.title_format = '%-' + str(width) + 's'
        if header is True:
            format = self.title_format + self.header_format
            header = format % (' ', 'utime', 'stime', 'total', ' real')
        self.header = header
        self.results = []

    def print_header(self):
        if self.header:
            self.out.write(self.header)
            self.out.write("\n")

    _header_printed = False
    def print_header_only_once(self):
        if not self._header_printed:
            self.print_header()
            self._header_printed = True

    def print_title(self):
        self.out.write(self.title_format % (self.title or " "))

    def print_result(self, utime, stime, total, real):
        self.out.write(self.times_format % (utime, stime, total, real))
        self.out.write("\n")

    def __call__(self, title):
        self.title = title
        self.print_header_only_once()
        return self

    def __enter__(self):
        if not getattr(self, 'title', None):
            raise Exception("call __call__() before __enter__().")
        self.print_title()
        self.start_t = time.time()
        self.t1 = os.times()
        return self

    def __exit__(self, type, value, tb):
        end_t = time.time()
        t2    = os.times()
        utime = t2[0] - self.t1[0]    # user time
        stime = t2[1] - self.t1[1]    # system time
        total = utime + stime         # total time
        real  = end_t - self.start_t  # real time
        self.print_result(utime, stime, total, real)
        self.results.append((self.title, utime, stime, total, real))
        del self.start_t, self.t1, self.title

    def run(self, func, *args):
        if not getattr(self, 'title', None):
            self(func.__name__)       # use func name as title
        try:
            self.__enter__()
            return func(*args)
        finally:
            self.__exit__(*sys.exc_info())

    def compared_matrix(self, transpose=False, index=4, formula=None, sort=False):
        if not (1 <= index <= 4):
            raise ArgumentError.new("%r: index should be between 1 and 4." % index)
        if sort:
            results = self.results[:]
            results.sort(key=lambda result: result[index])
        else:
            results = self.results
        values = [ t[index] for t in results ]
        titles = [ t[0] for t in results ]
        return ComparedMatrix(values, titles, transpose, formula)

    separator = "-" * 79

    def print_compared_matrix(self, *args, **kwargs):
        matrix = self.compared_matrix(*args, **kwargs)
        self.out.write(self.separator)
        self.out.write("\n")
        self.out.write(str(matrix))


class ComparedMatrix(object):
    """helper class to build compared matrix from benchmark results"""

    def __init__(self, values, titles, transpose=False, formula=None):
        self.values = values
        self.titles = titles
        self.transpose = transpose
        if not formula:
            formula = self.default_formula(transpose)
        self.formula = formula
        self.matrix = self.build_matrix(values, formula)

    def __getitem__(self, index):
        return self.matrix[index]

    def default_formula(self, transpose=False):
        if transpose:
            return lambda x, y: 100.0 * x / y - 100.0
        else:
            return lambda x, y: 100.0 * y / x - 100.0

    def build_matrix(self, values, formula):
        matrix = []
        for i, x in enumerate(values):
            row = [ formula(x, y) for y in values ]
            row[i] = None
            matrix.append(row)
        return matrix

    def __str__(self):
        buf = []
        write = buf.append
        ## print header
        width = max([ len(s) for s in self.titles ])
        format = "%" + str(4+1+width+10+2) + "s "
        write(format % 'real')
        for i in range(1, len(self.titles)+1):
            s = '[%02d]' % i
            write("%9s" % s)
        write("\n")
        ## print matrix
        for i, row in enumerate(self.matrix):
            format = "[%02d] %"+str(width)+"s %10.3fs "
            write(format % (i+1, self.titles[i], self.values[i]))
            for v in row:
                s = v is None and "       - " or "%8.1f%%" % v
                write(s)
            write("\n")
        ##
        return ''.join(buf)


if __name__ == '__main__':

    def fib(n):
        return n <= 2 and 1 or fib(n-1) + fib(n-2)
    bm = Benchmarker()  # or Benchmarker(width=30, out=sys.stderr, header=True)
    ## Python 2.5 or later
    #with bm('fib(n) (n==34)'):  fib(34)
    #with bm('fib(n) (n==35)'):  fib(35)
    ## Python 2.4
    bm('fib(n) (n==30)').run(fib, 30)  #  or .run(lambda: fib(30))
    bm('fib(n) (n==31)').run(fib, 31)  #  or .run(lambda: fib(31))
    bm('fib(n) (n==32)').run(fib, 32)  #  or .run(lambda: fib(32))
    ## benchmark results are stored into bm.results
    for result in bm.results:
        print result
    ## print compared matrix
    bm.print_compared_matrix()
    bm.print_compared_matrix(transpose=True)
