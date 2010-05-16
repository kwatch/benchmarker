======
README
======

$Release: 1.0.0 $


Overview
--------

Benchmarker is a small utility for benchmarking.


Example
-------

ex.py::

    def fib(n):
        if n <= 2:
            return 1
        else:
            return fib(n-1) + fib(n-2)
    
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
    fib(n) (n==34)                    4.3700     0.0200     4.3900     4.9449
    fib(n) (n==35)                    7.1500     0.0500     7.2000     8.0643


Download
--------

http://pypi.python.org/pypi/Benchmarker/

Installation::

    ## if you have installed easy_install:
    $ sudo easy_install Benchmarker
    ## or download Benchmarker-X.X.X.tar.gz and install it
    $ wget http://pypi.python.org/packages/source/O/Benchmarker/Benchmarker-X.X.X.tar.gz
    $ tar xzf Benchmarker-X.X.X.tar.gz
    $ cd Benchmarker-X.X.X/
    $ sudo python setup.py install


License
-------

$License: Public Domain $


Copyright
---------

$Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
