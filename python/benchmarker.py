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
           bm('fib(n) (n==34)').run(lambda: fib(34))
           bm('fib(n) (n==35)').run(lambda: fib(35))

       Output::

           $ python ex.py
                                        utime      stime      total       real
           fib(n) (n==34)              4.3700     0.0200     4.3900     4.9449
           fib(n) (n==35)              7.1500     0.0500     7.2000     8.0643
    """

    header_format = '%10s %10s %10s %10s'
    times_format  = '%10.4f %10.4f %10.4f %10.4f'

    def __init__(self, width=30, out=sys.stderr, header=True):
        self.width = width
        self.out   = out
        self.title_format = '%-' + str(width) + 's'
        if header is True:
            format = self.title_format + self.header_format
            header = format % (' ', 'utime', 'stime', 'total', ' real')
        self.header = header
        self._header_printed = False

    def print_header(self):
        if self.header:
            self.out.write(self.header)
            self.out.write("\n")

    def __call__(self, title):
        self.title = title
        if not self._header_printed:
            self.print_header()
            self._header_printed = True
        return self

    def __enter__(self):
        if not getattr(self, 'title', None):
            raise Exception("call __call__() before __enter__().")
        self.out.write(self.title_format % (self.title or " "))
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
        self.out.write(self.times_format % (utime, stime, total, real))
        self.out.write("\n")
        del self.start_t, self.t1, self.title

    def run(self, func, *args):
        try:
            self.__enter__()
            return func(*args)
        finally:
            self.__exit__(*sys.exc_info())


if __name__ == '__main__':

    def fib(n):
        return n <= 2 and 1 or fib(n-1) + fib(n-2)
    bm = Benchmarker()  # or Benchmarker(width=30, out=sys.stderr, header=True)
    ## Python 2.5 or later
    #with bm('fib(n) (n==34)'):  fib(34)
    #with bm('fib(n) (n==35)'):  fib(35)
    ## Python 2.4
    bm('fib(n) (n==34)').run(lambda: fib(34))
    bm('fib(n) (n==35)').run(lambda: fib(35))
