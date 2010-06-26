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
        return n <= 2 and 1 or fib(n-1) + fib(n-2)
    from benchmarker import Benchmarker
    bm = Benchmarker(30)  # or Benchmarker(width=30, out=sys.stderr, header=True)
    ## Python 2.5 or later
    with bm('fib(n) (n==33)'):  fib(33)
    with bm('fib(n) (n==34)'):  fib(34)
    with bm('fib(n) (n==35)'):  fib(35)
    ## Python 2.4
    bm('fib(n) (n==33)').run(fib, 33)   # or .run(lambda: fib(33))
    bm('fib(n) (n==34)').run(fib, 34)   # or .run(lambda: fib(34))
    bm('fib(n) (n==35)').run(fib, 35)   # or .run(lambda: fib(35))
    ## print compared matrix
    bm.print_compared_matrix(sort=False, transpose=False)

Output::

    $ python ex.py
                             utime      stime      total       real
    fib(n) (n==33)           1.890      0.000      1.890      1.900
    fib(n) (n==34)           3.030      0.010      3.040      3.058
    fib(n) (n==35)           4.930      0.010      4.940      4.963
    ---------------------------------------------------------------
                               real      [01]     [02]     [03]
    [01] fib(n) (n==33)      1.900s        -     60.9%   161.2%
    [02] fib(n) (n==34)      3.058s    -37.9%       -     62.3%
    [03] fib(n) (n==35)      4.963s    -61.7%   -38.4%       - 


Download
--------

http://pypi.python.org/pypi/Benchmarker/

Installation::

    ## if you have installed easy_install:
    $ sudo easy_install Benchmarker
    ## or download Benchmarker-X.X.X.tar.gz and install it
    $ wget http://pypi.python.org/packages/source/B/Benchmarker/Benchmarker-X.X.X.tar.gz
    $ tar xzf Benchmarker-X.X.X.tar.gz
    $ cd Benchmarker-X.X.X/
    $ sudo python setup.py install


Tips
----

* (experimental) If you don't set title, function name is used instead.::

    def fib34(): fib(34)
    bm = Benchmarker()
    bm.run(fib34)     # same as bm('fib34').run(fib34)

* You can get benchmark results by bm.results.::

    bm = Benchmarker()
    bm('fib(34)').run(fib, 34)
    bm('fib(35)').run(fib, 35)
    for result in bm.results:
        print result
    ## output example:
    #('fib(34)', 4.37, 0.02, 4.39, 4.9449)
    #('fib(35)', 7.15, 0.05, 7.20, 8.0643)


License
-------

$License: Public Domain $


Copyright
---------

$Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
