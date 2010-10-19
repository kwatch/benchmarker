======
README
======

$Release: 1.1.0 $


Overview
--------

Benchmarker is a small utility for benchmarking.


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


Examples
--------

Basic example (ex1.py)::

    from __future__ import with_statement
    if 'xrange' not in globals():
        xrange = range
    
    ## start benchmark
    from benchmarker import Benchmarker
    bm = Benchmarker()     # or Benchmarker(width=30, out=sys.stderr)
    print(bm.platform())   # python version, os information, ...
    
    ## Python 2.5 or later
    loop = 1000 * 1000
    with bm.empty():              # optional: empty loop results are
        for i in xrange(loop):    # subtracted automatically from
            pass                  # other benchmark results.
    with bm('"".join((s,s,s))'):
        for i in xrange(loop):
            sos = "".join(("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"))
    with bm('s+s+s'):
        for i in xrange(loop):
            sos = "Haruhi" + "Mikuru" + "Yuki" + "Itsuki" + "Kyon"
    with bm('"%s%s%s" % (s,s,s)'):
        for i in xrange(loop):
            sos = "%s%s%s%s%s" % ("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon")
    
    ### Python 2.4
    #def f0(n):
    #    for i in xrange(n):
    #        pass
    #def f1(n):
    #    """''.join((s,s,s))"""
    #    for i in xrange(n):
    #        sos = "".join(("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"))
    #def f2(n):
    #    """s+s+s"""
    #    for i in xrange(n):
    #        sos = "Haruhi" + "Mikuru" + "Yuki" + "Itsuki" + "Kyon"
    #def f3(n):
    #    """'%s%s%s' % (s,s,s)"""
    #    for i in xrange(n):
    #        sos = "%s%s%s%s%s" % ("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon")
    #bm.empty().run(f0, loop)
    #bm().run(f1, loop)
    #bm().run(f2, loop)
    #bm().run(f3, loop)
    
    ## statistics
    print(bm.stat.all())


Output example::

    $ python ex1.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
    ## python version:    2.5.5
    ## python executable: /usr/local/python/2.5.5/bin/python2.5
    
    ## Benchmark                        user       sys     total      real
    (Empty)                           0.1100    0.0300    0.1400    0.1441
    "".join((s,s,s))                  0.4200   -0.0300    0.3900    0.3961
    s+s+s                             0.2500   -0.0300    0.2200    0.2197
    "%s%s%s" % (s,s,s)                0.5700   -0.0300    0.5400    0.5423
    
    ## Ranking                          real  ratio  chart
    s+s+s                             0.2197 (100.0) ********************
    "".join((s,s,s))                  0.3961 ( 55.5) ***********
    "%s%s%s" % (s,s,s)                0.5423 ( 40.5) ********
    
    ## Matrix                           real   [01]   [02]   [03]
    [01] s+s+s                        0.2197  100.0  180.3  246.8
    [02] "".join((s,s,s))             0.3961   55.5  100.0  136.9
    [03] "%s%s%s" % (s,s,s)           0.5423   40.5   73.0  100.0


Notice that benchmark results are subtracted by '(Empty)' loop results.
For example: 0.3961 = 0.5402 - 0.1441; -0.0300 = 0.0000 - 0.0300; and so on.

If you pass 'loop=N' to Benchmarker(), benchmark code can be more simple.

Example (ex2.py)::

    from __future__ import with_statement
    
    ## start benchmark
    from benchmarker import Benchmarker
    bm = Benchmarker(loop=1000*1000)    ## specify loop count (default: 1)
    print(bm.platform())
    
    ## use for-statement instead of with-statement
    for i in bm.empty():
        pass
    for i in bm('"".join((s,s,s))'):
        sos = "".join(("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"))
    for i in bm('s+s+s'):
        sos = "Haruhi" + "Mikuru" + "Yuki" + "Itsuki" + "Kyon"
    for i in bm('"%s%s%s" % (s,s,s)'):
        sos = "%s%s%s%s%s" % ("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon")
    
    ### or
    #def f0():
    #    pass
    #def f1():
    #    """''.join((s,s,s))"""
    #    sos = "".join(("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"))
    #def f2():
    #    """s+s+s"""
    #    sos = "Haruhi" + "Mikuru" + "Yuki" + "Itsuki" + "Kyon"
    #def f3():
    #    """'%s%s%s' % (s,s,s)"""
    #    sos = "%s%s%s%s%s" % ("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon")
    #bm.empty().run(f0)
    #bm().run(f1)
    #bm().run(f2)
    #bm().run(f3)
    
    ## statistics
    print(bm.stat.all())


You can repeat benchmarks and calculate average of them.
If you specify 'extra=1' parameter, Benchmarker will remove min and max values from benchmarks to remove abnormal result.

Example (ex3.py)::

    from __future__ import with_statement
    
    ## start benchmark
    from benchmarker import Benchmarker
    bm = Benchmarker(loop=1000*1000)    ## specify loop count
    print(bm.platform())
    
    ## repeat benchmark 3 times + 2*1 times
    for b in bm.repeat(3, extra=1):
        for i in b.empty():
            pass
        for i in b('"".join((s,s,s))'):
            sos = "".join(("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"))
        for i in b('s+s+s'):
            sos = "Haruhi" + "Mikuru" + "Yuki" + "Itsuki" + "Kyon"
        for i in b('"%s%s%s" % (s,s,s)'):
            sos = "%s%s%s%s%s" % ("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon")
    
    ## or
    #def f0():
    #    pass
    #def f1():
    #    """''.join((s,s,s))"""
    #    sos = "".join(("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"))
    #def f2():
    #    """s+s+s"""
    #    sos = "Haruhi" + "Mikuru" + "Yuki" + "Itsuki" + "Kyon"
    #def f3():
    #    """'%s%s%s' % (s,s,s)"""
    #    sos = "%s%s%s%s%s" % ("Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon")
    #for b in bm.repeat(5, extra=1):
    #    b.empty().run(f0)
    #    b().run(f1)
    #    b().run(f2)
    #    b().run(f3)
    
    ## statistics
    print(bm.stat.all())


Output example::

    $ python ex3.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
    ## python version:    2.5.5
    ## python executable: /usr/local/python/2.5.5/bin/python2.5
    
    ## Benchmark #1                     user       sys     total      real
    (Empty)                           0.1500    0.0100    0.1600    0.1706
    "".join((s,s,s))                  0.4200   -0.0100    0.4100    0.4110
    s+s+s                             0.3000   -0.0100    0.2900    0.2870
    "%s%s%s" % (s,s,s)                0.6000   -0.0100    0.5900    0.5797
    
    ## Benchmark #2                     user       sys     total      real
    (Empty)                           0.1500    0.0000    0.1500    0.1545
    "".join((s,s,s))                  0.4200    0.0000    0.4200    0.4243
    s+s+s                             0.3000    0.0000    0.3000    0.2996
    "%s%s%s" % (s,s,s)                0.6000    0.0000    0.6000    0.5938
    
    ## Benchmark #3                     user       sys     total      real
    (Empty)                           0.1500    0.0000    0.1500    0.1545
    "".join((s,s,s))                  0.4200    0.0000    0.4200    0.4197
    s+s+s                             0.3000    0.0000    0.3000    0.2984
    "%s%s%s" % (s,s,s)                0.6000    0.0000    0.6000    0.5929
    
    ## Benchmark #4                     user       sys     total      real
    (Empty)                           0.1500    0.0000    0.1500    0.1553
    "".join((s,s,s))                  0.4200    0.0100    0.4300    0.4239
    s+s+s                             0.2900    0.0000    0.2900    0.2929
    "%s%s%s" % (s,s,s)                0.5900    0.0000    0.5900    0.5975
    
    ## Benchmark #5                     user       sys     total      real
    (Empty)                           0.1600    0.0000    0.1600    0.1546
    "".join((s,s,s))                  0.4100    0.0000    0.4100    0.4192
    s+s+s                             0.2900    0.0000    0.2900    0.3035
    "%s%s%s" % (s,s,s)                0.5900    0.0000    0.5900    0.5994
    
    ## Remove min & max                  min    bench#       max    bench#
    "".join((s,s,s))                  0.4110        #1    0.4243        #2
    s+s+s                             0.2870        #1    0.3035        #5
    "%s%s%s" % (s,s,s)                0.5797        #1    0.5994        #5
    
    ## Average of 3 (=5-2*1)            user       sys     total      real
    "".join((s,s,s))                  0.4167    0.0033    0.4200    0.4209
    s+s+s                             0.2967    0.0000    0.2967    0.2970
    "%s%s%s" % (s,s,s)                0.5967    0.0000    0.5967    0.5947
    
    ## Ranking                          real  ratio  chart
    s+s+s                             0.2970 (100.0) ********************
    "".join((s,s,s))                  0.4209 ( 70.5) **************
    "%s%s%s" % (s,s,s)                0.5947 ( 49.9) *********
    
    ## Matrix                           real   [01]   [02]   [03]
    [01] s+s+s                        0.2970  100.0  141.7  200.3
    [02] "".join((s,s,s))             0.4209   70.5  100.0  141.3
    [03] "%s%s%s" % (s,s,s)           0.5947   49.9   70.8  100.0

In the above example, minimum and maximum results are removed automatically before calculate average result because 'extra=1' is specified.

If you needs only average result, redirect stderr to /dev/null or dummy file. ::

    $ python ex3.py 2> /dev/null
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
    ## python version:    2.5.5
    ## python executable: /usr/local/python/2.5.5/bin/python2.5
    
    ## Average of 3 (=5-2*1)            user       sys     total      real
    "".join((s,s,s))                  0.4167    0.0033    0.4200    0.4209
    s+s+s                             0.2967    0.0000    0.2967    0.2970
    "%s%s%s" % (s,s,s)                0.5967    0.0000    0.5967    0.5947
    
    ## Ranking                          real  ratio  chart
    s+s+s                             0.2970 (100.0) ********************
    "".join((s,s,s))                  0.4209 ( 70.5) **************
    "%s%s%s" % (s,s,s)                0.5947 ( 49.9) *********
    
    ## Matrix                           real   [01]   [02]   [03]
    [01] s+s+s                        0.2970  100.0  141.7  200.3
    [02] "".join((s,s,s))             0.4209   70.5  100.0  141.3
    [03] "%s%s%s" % (s,s,s)           0.5947   49.9   70.8  100.0

    
    
Tips
----

* If you don't specify benchmark label, function document or name is used as label.
  ::

    def f2():
        """s+s+s"""
        sos = "Haruhi" + "Mikuru" + "Yuki" + "Itsuki" + "Kyon"
    bm = Benchmarker()
    bm().run(f2)     # same as bm('s+s+s').run(f2)


* You can get benchmark results by bm.results.
  ::

    for result in bm.results:
        print(result)
    ## output example:
    #('"".join((s,s,s))', 0.57, 0.0,  0.57, 0.5772)
    #('s+s+s', 0.44, 0.0, 0.44, 0.4340)
    #('"%s%s%s" % (s,s,s)', 0.75, 0.0, 0.75, 0.7666)



License
-------

$License: Public Domain $


Copyright
---------

$Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
