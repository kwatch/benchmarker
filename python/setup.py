###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

import sys, re, os
arg1 = len(sys.argv) > 1 and sys.argv[1] or None
if arg1 == 'egg_info':
    from ez_setup import use_setuptools
    use_setuptools()
if arg1 == 'bdist_egg':
    from setuptools import setup
else:
    from distutils.core import setup


name     = 'Benchmarker'
version  = '2.0.0'
author   = 'makoto kuwata'
email    = 'kwa@kuwata-lab.com'
maintainer = author
maintainer_email = email
url      = 'http://pypi.python.org/pypi/Benchmarker/'
desc     = 'a small utility for benchmarking'
detail   = r'''
Benchmarker is a small utility to benchmark your code.

See `CHANGES.txt <http://bitbucket.org/kwatch/benchmarker/annotate/tip/python/CHANGES.txt>`_
for details of changes and enhancements.


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


Example for Busy People
-----------------------

ex0.py::

    from __future__ import with_statement
    from benchmarker import Benchmarker
    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    with Benchmarker(loop=1000*1000) as bm:
        for i in bm.empty():    ## empty loop
            pass
        for i in bm('"".join((s,s,s))'):
            sos = "".join((s1, s2, s3, s4, s5))
        for i in bm('s+s+s'):
            sos = s1 + s2 + s3 + s4 + s5
        for i in bm('"%s%s%s" % (s,s,s)'):
            sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)

Output::

    $ python ex0.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
    ## python version:    2.5.5
    ## python executable: /usr/local/python/2.5.5/bin/python
    
    ## Benchmark                        user       sys     total      real
    (Empty)                           0.1200    0.0300    0.1500    0.1605
    "".join((s,s,s))                  0.7300   -0.0300    0.7000    0.6992
    s+s+s                             0.6600   -0.0200    0.6400    0.6321
    "%s%s%s" % (s,s,s)                0.8700   -0.0300    0.8400    0.8305
    
    ## Ranking                          real  ratio  chart
    s+s+s                             0.6321 (100.0) ********************
    "".join((s,s,s))                  0.6992 ( 90.4) ******************
    "%s%s%s" % (s,s,s)                0.8305 ( 76.1) ***************
    
    ## Ratio Matrix                     real    [01]    [02]    [03]
    [01] s+s+s                        0.6321   100.0   110.6   131.4
    [02] "".join((s,s,s))             0.6992    90.4   100.0   118.8
    [03] "%s%s%s" % (s,s,s)           0.8305    76.1    84.2   100.0

Notice that empty loop times (user, sys, total, and real) are subtracted from other benchmark times automatically.
For example, 0.6992 = 0.8597 - 0.1605.


Step by Step Examples
---------------------

Basic example (ex1.py)::

    from __future__ import with_statement
    if 'xrange' not in globals():
        xrange = range
    
    ## benchmarker object
    from benchmarker import Benchmarker
    bm = Benchmarker()     # or Benchmarker(width=30, out=sys.stderr)
    print(bm.platform())   # python version, os information, ...
    
    ## Python 2.5 or later
    loop = 1000 * 1000
    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    with bm.empty():              # optional: empty loop results are
        for i in xrange(loop):    # subtracted automatically from
            pass                  # other benchmark results.
    with bm('"".join((s,s,s))'):
        for i in xrange(loop):
            sos = "".join((s1, s2, s3, s4, s5))
    with bm('s+s+s'):
        for i in xrange(loop):
            sos = s1 + s2 + s3 + s4 + s5
    with bm('"%s%s%s" % (s,s,s)'):
        for i in xrange(loop):
            sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)
    
    ### Python 2.4
    #def f0(n):
    #    for i in xrange(n):
    #        pass
    #def f1(n):
    #    """''.join((s,s,s))"""
    #    for i in xrange(n):
    #        sos = "".join((s1, s2, s3, s4, s5))
    #def f2(n):
    #    """s+s+s"""
    #    for i in xrange(n):
    #        sos = s1 + s2 + s3 + s4 + s5
    #def f3(n):
    #    """'%s%s%s' % (s,s,s)"""
    #    for i in xrange(n):
    #        sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)
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
    ## python executable: /usr/local/python/2.5.5/bin/python
    
    ## Benchmark                        user       sys     total      real
    (Empty)                           0.1200    0.0300    0.1500    0.1605
    "".join((s,s,s))                  0.7300   -0.0300    0.7000    0.6992
    s+s+s                             0.6600   -0.0200    0.6400    0.6321
    "%s%s%s" % (s,s,s)                0.8700   -0.0300    0.8400    0.8305
    
    ## Ranking                          real  ratio  chart
    s+s+s                             0.6321 (100.0) ********************
    "".join((s,s,s))                  0.6992 ( 90.4) ******************
    "%s%s%s" % (s,s,s)                0.8305 ( 76.1) ***************
    
    ## Ratio Matrix                     real    [01]    [02]    [03]
    [01] s+s+s                        0.6321   100.0   110.6   131.4
    [02] "".join((s,s,s))             0.6992    90.4   100.0   118.8
    [03] "%s%s%s" % (s,s,s)           0.8305    76.1    84.2   100.0
    

Notice that benchmark results are subtracted by '(Empty)' loop results.
For example: 0.7300 = 0.8500 - 0.1200; -0.0300 = 0.000 - 0.0300; 0.7000 = 0.8500 - 0.1500; 0.6992 = 0.8597 - 0.1605; and so on.

If you pass 'loop=N' to Benchmarker(), benchmark code can be more simple.

Example (ex2.py)::

    from __future__ import with_statement
    
    ## start benchmark
    from benchmarker import Benchmarker
    bm = Benchmarker(loop=1000*1000)    ## specify loop count (default: 1)
    print(bm.platform())
    
    ## use for-statement instead of with-statement
    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    for i in bm.empty():
        pass
    for i in bm('"".join((s,s,s))'):
        sos = "".join((s1, s2, s3, s4, s5))
    for i in bm('s+s+s'):
        sos = s1 + s2 + s3 + s4 + s5
    for i in bm('"%s%s%s" % (s,s,s)'):
        sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)
    
    ### or
    #def f0():
    #    pass
    #def f1():
    #    """''.join((s,s,s))"""
    #    sos = "".join((s1, s2, s3, s4, s5))
    #def f2():
    #    """s+s+s"""
    #    sos = s1 + s2 + s3 + s4 + s5
    #def f3():
    #    """'%s%s%s' % (s,s,s)"""
    #    sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)
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
    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    for b in bm.repeat(3, extra=1):
        for i in b.empty():
            pass
        for i in b('"".join((s,s,s))'):
            sos = "".join((s1, s2, s3, s4, s5))
        for i in b('s+s+s'):
            sos = s1 + s2 + s3 + s4 + s5
        for i in b('"%s%s%s" % (s,s,s)'):
            sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)
    
    ## or
    #def f0():
    #    pass
    #def f1():
    #    """''.join((s,s,s))"""
    #    sos = "".join((s1, s2, s3, s4, s5))
    #def f2():
    #    """s+s+s"""
    #    sos = s1 + s2 + s3 + s4 + s5
    #def f3():
    #    """'%s%s%s' % (s,s,s)"""
    #    sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)
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
    ## python executable: /usr/local/python/2.5.5/bin/python
    
    ## Benchmark #1                     user       sys     total      real
    (Empty)                           0.1600    0.0000    0.1600    0.1637
    "".join((s,s,s))                  0.7400    0.0000    0.7400    0.7474
    s+s+s                             0.6400    0.0000    0.6400    0.6394
    "%s%s%s" % (s,s,s)                0.9000    0.0000    0.9000    0.9071
    
    ## Benchmark #2                     user       sys     total      real
    (Empty)                           0.1700    0.0000    0.1700    0.1715
    "".join((s,s,s))                  0.7200    0.0000    0.7200    0.7289
    s+s+s                             0.6400    0.0000    0.6400    0.6537
    "%s%s%s" % (s,s,s)                0.8600    0.0000    0.8600    0.8662
    
    ## Benchmark #3                     user       sys     total      real
    (Empty)                           0.1600    0.0000    0.1600    0.1679
    "".join((s,s,s))                  0.7500    0.0000    0.7500    0.7416
    s+s+s                             0.6400    0.0000    0.6400    0.6315
    "%s%s%s" % (s,s,s)                0.8800    0.0000    0.8800    0.8829
    
    ## Benchmark #4                     user       sys     total      real
    (Empty)                           0.1600    0.0000    0.1600    0.1588
    "".join((s,s,s))                  0.7400    0.0100    0.7500    0.7465
    s+s+s                             0.6300    0.0000    0.6300    0.6440
    "%s%s%s" % (s,s,s)                0.9000    0.0000    0.9000    0.9057
    
    ## Benchmark #5                     user       sys     total      real
    (Empty)                           0.1500    0.0000    0.1500    0.1589
    "".join((s,s,s))                  0.7500    0.0000    0.7500    0.7549
    s+s+s                             0.6400    0.0000    0.6400    0.6317
    "%s%s%s" % (s,s,s)                0.9100    0.0000    0.9100    0.9147
    
    ## Remove min & max                  min    bench#       max    bench#
    "".join((s,s,s))                  0.7289        #2    0.7549        #5
    s+s+s                             0.6315        #3    0.6537        #2
    "%s%s%s" % (s,s,s)                0.8662        #2    0.9147        #5
    
    ## Average of 3 (=5-2*1)            user       sys     total      real
    "".join((s,s,s))                  0.7433    0.0033    0.7467    0.7452
    s+s+s                             0.6367    0.0000    0.6367    0.6384
    "%s%s%s" % (s,s,s)                0.8933    0.0000    0.8933    0.8986
    
    ## Ranking                          real  ratio  chart
    s+s+s                             0.6384 (100.0) ********************
    "".join((s,s,s))                  0.7452 ( 85.7) *****************
    "%s%s%s" % (s,s,s)                0.8986 ( 71.0) **************
    
    ## Ratio Matrix                     real    [01]    [02]    [03]
    [01] s+s+s                        0.6384   100.0   116.7   140.8
    [02] "".join((s,s,s))             0.7452    85.7   100.0   120.6
    [03] "%s%s%s" % (s,s,s)           0.8986    71.0    82.9   100.0
    

In the above example, minimum and maximum results are removed automatically before calculate average result because 'extra=1' is specified.

If you needs only average result, redirect stderr to /dev/null or dummy file. ::

    $ python ex3.py > /dev/null
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
    ## python version:    2.5.5
    ## python executable: /usr/local/python/2.5.5/bin/python
    
    ## Average of 3 (=5-2*1)            user       sys     total      real
    "".join((s,s,s))                  0.7433    0.0033    0.7467    0.7452
    s+s+s                             0.6367    0.0000    0.6367    0.6384
    "%s%s%s" % (s,s,s)                0.8933    0.0000    0.8933    0.8986
    
    ## Ranking                          real  ratio  chart
    s+s+s                             0.6384 (100.0) ********************
    "".join((s,s,s))                  0.7452 ( 85.7) *****************
    "%s%s%s" % (s,s,s)                0.8986 ( 71.0) **************
    
    ## Ratio Matrix                     real    [01]    [02]    [03]
    [01] s+s+s                        0.6384   100.0   116.7   140.8
    [02] "".join((s,s,s))             0.7452    85.7   100.0   120.6
    [03] "%s%s%s" % (s,s,s)           0.8986    71.0    82.9   100.0

If you always print platform information and statistics, you can simplify code by with-statement.

Example (ex4.py)::

    from __future__ import with_statement
    from benchmarker import Benchmarker
    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    with Benchmarker(loop=1000*1000) as bm:
        for b in bm.repeat(3, extra=1):
            for i in b.empty():
                pass
            for i in b('"".join((s,s,s))'):
                sos = "".join((s1, s2, s3, s4, s5))
            for i in b('s+s+s'):
                sos = s1 + s2 + s3 + s4 + s5
            for i in b('"%s%s%s" % (s,s,s)'):
                sos = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)

    
    
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

'''[1:]
license  = 'Public Domain'
platforms = 'any'
#download = 'http://downloads.sourceforge.net/oktest/Benchmarker-%s.tar.gz' % version
download = 'http://pypi.python.org/packages/source/B/Benchmarker/Benchmarker-%s.tar.gz' % version
classifiers = [
    'Development Status :: 5 - Production/Stable',
    'Environment :: Console',
    'Intended Audience :: Developers',
    'License :: Public Domain',
    'Operating System :: OS Independent',
    'Programming Language :: Python',
    'Programming Language :: Python :: 2.3',
    'Programming Language :: Python :: 2.4',
    'Programming Language :: Python :: 2.5',
    'Programming Language :: Python :: 2.6',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.0',
    'Programming Language :: Python :: 3.1',
    'Programming Language :: Python :: 3.2',
    'Topic :: Software Development :: Libraries :: Python Modules',
    'Topic :: System :: Benchmark',
]


setup(
    name=name,
    version=version,
    author=author,  author_email=email,
    maintainer=maintainer, maintainer_email=maintainer_email,
    description=desc,  long_description=detail,
    url=url,  download_url=download,  classifiers=classifiers,
    license=license,
    #platforms=platforms,
    #
    py_modules=['benchmarker'],
    #package_dir={'': 'lib'},
    #scripts=['bin/pytenjin'],
    #packages=['tenjin'],
    #zip_safe = False,
)
