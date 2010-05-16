# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

"""
benchmark utility

Example:
>>> from benchmarker import Benchmarker
>>> def fib(n):  return 1 if n <= 2 else fib(n-1) + fib(n-2)
>>> b = Benchmarker()   # or Benchmarker(width=30, out=sys.stderr, header=True)
>>> with b('fib(n) with n=34'):  fib(34)        # Python 2.5 or later
>>> b('fib(n) with n=34').run(lambda: fib(34))  # Python 2.4
                                   utime      stime      total       real
fib(n) with n=34                  3.7600     0.0100     3.7700     3.8425
"""

import sys, os, time

__all__ = ('Benchmarker', )


class Benchmarker(object):

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
        return 1 if n <= 2 else fib(n-1) + fib(n-2)

    b = Benchmarker(width=30, out=sys.stderr, header=True)
    #for n in range(30, 35+1):
    #    with b('fib(%s)' % n):
    #        fib(n)
    for n in range(30, 35+1):
        b('fib(%s)' % n).run(lambda: fib(n))
