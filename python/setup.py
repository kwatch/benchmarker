###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
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
Overview
========

Benchmarker is a small utility for benchmarking.

Quick Example (ex0.py)::

    from benchmarker import Benchmarker

    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    with Benchmarker(width=20, loop=1000*1000) as bm:
        for _ in bm.empty():     ## empty loop
            pass
        for _ in bm('join'):
            sos = ''.join((s1, s2, s3, s4, s5))
        for _ in bm('concat'):
            sos = s1 + s2 + s3 + s4 + s5
        for _ in bm('format'):
            sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output example::

    $ python ex0.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5664)]
    ## python version:    2.7.1
    ## python executable: /usr/local/python/2.7.1/bin/python

    ##                       user       sys     total      real
    (Empty)                0.1600    0.0000    0.1600    0.1639
    join                   0.6500    0.0000    0.6500    0.6483
    concat                 0.5700    0.0000    0.5700    0.5711
    format                 0.7600    0.0000    0.7600    0.7568

    ## Ranking               real
    concat                 0.5711 (100.0%) *************************
    join                   0.6483 ( 88.1%) **********************
    format                 0.7568 ( 75.5%) *******************

    ## Ratio Matrix          real    [01]    [02]    [03]
    [01] concat            0.5711  100.0%  113.5%  132.5%
    [02] join              0.6483   88.1%  100.0%  116.7%
    [03] format            0.7568   75.5%   85.7%  100.0%

Notice that empty loop times (user, sys, total, and real) are subtracted
from other benchmark times automatically.
For example::

               +------------------------------------------+
               |benchmark label|      real (second)       |
               |---------------+--------------------------|
               |join           |0.6483 (= 0.8122 - 0.1639)|
               |---------------+--------------------------|
               |concat         |0.5711 (= 0.7350 - 0.1639)|
               |---------------+--------------------------|
               |format         |0.7568 (= 0.9207 - 0.1639)|
               +------------------------------------------+

NOTICE: This release doesn't have compatibility with previous version.
See CHANGES.txt for details.


Download and Install
====================

http://pypi.python.org/pypi/Benchmarker/

Installation::

    ## if you have installed easy_install:
    $ sudo easy_install Benchmarker
    ## or download Benchmarker-X.X.X.tar.gz and install it
    $ wget http://pypi.python.org/packages/source/B/Benchmarker/Benchmarker-X.X.X.tar.gz
    $ tar xzf Benchmarker-X.X.X.tar.gz
    $ cd Benchmarker-X.X.X/
    $ sudo python setup.py install


Step by Step Examples
=====================


Basic Example
-------------

ex1.py::

    from benchmarker import Benchmarker

    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    loop = 1000 * 1000
    with Benchmarker(width=20) as bm:
        with bm('join'):
            for i in xrange(loop):
                sos = ''.join((s1, s2, s3, s4, s5))
        with bm('concat'):
            for i in xrange(loop):
                sos = s1 + s2 + s3 + s4 + s5
        with bm('format'):
            for i in xrange(loop):
                sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output example::

    $ python ex1.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5664)]
    ## python version:    2.7.1
    ## python executable: /usr/local/python/2.7.1/bin/python

    ##                       user       sys     total      real
    join                   0.7300    0.0000    0.7300    0.7358
    concat                 0.6500    0.0000    0.6500    0.6482
    format                 0.8400    0.0000    0.8400    0.8442

    ## Ranking               real
    concat                 0.6482 (100.0%) *************************
    join                   0.7358 ( 88.1%) **********************
    format                 0.8442 ( 76.8%) *******************

    ## Ratio Matrix          real    [01]    [02]    [03]
    [01] concat            0.6482  100.0%  113.5%  130.2%
    [02] join              0.7358   88.1%  100.0%  114.7%
    [03] format            0.8442   76.8%   87.2%  100.0%


Empty Loop
----------

ex2.py::

    from benchmarker import Benchmarker

    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    loop = 1000 * 1000
    with Benchmarker(width=20) as bm:
        with bm.empty():
            for i in xrange(loop):
                pass
        with bm('join'):
            for i in xrange(loop):
                sos = ''.join((s1, s2, s3, s4, s5))
        with bm('concat'):
            for i in xrange(loop):
                sos = s1 + s2 + s3 + s4 + s5
        with bm('format'):
            for i in xrange(loop):
                sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output Example::

    $ python ex2.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5664)]
    ## python version:    2.7.1
    ## python executable: /usr/local/python/2.7.1/bin/python

    ##                       user       sys     total      real
    (Empty)                0.0800    0.0000    0.0800    0.0824
    join                   0.6600    0.0000    0.6600    0.6541
    concat                 0.5600    0.0000    0.5600    0.5592
    format                 0.7600    0.0000    0.7600    0.7603

    ## Ranking               real
    concat                 0.5592 (100.0%) *************************
    join                   0.6541 ( 85.5%) *********************
    format                 0.7603 ( 73.6%) ******************

    ## Ratio Matrix          real    [01]    [02]    [03]
    [01] concat            0.5592  100.0%  117.0%  135.9%
    [02] join              0.6541   85.5%  100.0%  116.2%
    [03] format            0.7603   73.6%   86.0%  100.0%

Notice that benchmark results are subtracted by '(Empty)' loop results.
For example::

                   +------------------------------------------+
                   |benchmark label|      real (second)       |
                   |---------------+--------------------------|
                   |join           |0.6541 (= 0.7365 - 0.0824)|
                   |---------------+--------------------------|
                   |concat         |0.5592 (= 0.6416 - 0.0824)|
                   |---------------+--------------------------|
                   |format         |0.7603 (= 0.8427 - 0.0824)|
                   +------------------------------------------+


Loop
----

ex3.py::

    from benchmarker import Benchmarker

    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    with Benchmarker(width=20, loop=1000*1000) as bm:
        for _ in bm.empty():
            pass
        for _ in bm('join'):
            sos = ''.join((s1, s2, s3, s4, s5))
        for _ in bm('concat'):
            sos = s1 + s2 + s3 + s4 + s5
        for _ in bm('format'):
            sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output Example::

    $ python ex3.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5664)]
    ## python version:    2.7.1
    ## python executable: /usr/local/python/2.7.1/bin/python

    ##                       user       sys     total      real
    (Empty)                0.1600    0.0000    0.1600    0.1683
    join                   0.6500    0.0000    0.6500    0.6457
    concat                 0.5700    0.0000    0.5700    0.5660
    format                 0.7500    0.0000    0.7500    0.7440

    ## Ranking               real
    concat                 0.5660 (100.0%) *************************
    join                   0.6457 ( 87.6%) **********************
    format                 0.7440 ( 76.1%) *******************

    ## Ratio Matrix          real    [01]    [02]    [03]
    [01] concat            0.5660  100.0%  114.1%  131.5%
    [02] join              0.6457   87.6%  100.0%  115.2%
    [03] format            0.7440   76.1%   86.8%  100.0%


Repeat
------

ex4.py::

    from benchmarker import Benchmarker

    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
    with Benchmarker(width=25, loop=1000*1000) as bm:
        for _ in bm.repeat(3, extra=1):
            for _ in bm.empty():
                pass
            for _ in bm('join'):
                sos = ''.join((s1, s2, s3, s4, s5))
            for _ in bm('concat'):
                sos = s1 + s2 + s3 + s4 + s5
            for _ in bm('format'):
                sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output Example::

    $ python ex4.py
    ## benchmarker:       release 0.0.0 (for python)
    ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5664)]
    ## python version:    2.7.1
    ## python executable: /usr/local/python/2.7.1/bin/python

    ## (#1)                       user       sys     total      real
    (Empty)                     0.1600    0.0000    0.1600    0.1562
    join                        0.6500    0.0000    0.6500    0.6591
    concat                      0.5600    0.0000    0.5600    0.5626
    format                      0.7500    0.0000    0.7500    0.7662

    ## (#2)                       user       sys     total      real
    (Empty)                     0.1600    0.0000    0.1600    0.1561
    join                        0.6500    0.0000    0.6500    0.6520
    concat                      0.5500    0.0000    0.5500    0.5571
    format                      0.7500    0.0000    0.7500    0.7524

    ## (#3)                       user       sys     total      real
    (Empty)                     0.1500    0.0000    0.1500    0.1555
    join                        0.6600    0.0000    0.6600    0.6563
    concat                      0.5600    0.0000    0.5600    0.5593
    format                      0.7500    0.0000    0.7500    0.7536

    ## (#4)                       user       sys     total      real
    (Empty)                     0.1600    0.0000    0.1600    0.1585
    join                        0.6500    0.0000    0.6500    0.6518
    concat                      0.5500    0.0000    0.5500    0.5597
    format                      0.7500    0.0000    0.7500    0.7539

    ## (#5)                       user       sys     total      real
    (Empty)                     0.1600    0.0000    0.1600    0.1601
    join                        0.6500    0.0000    0.6500    0.6482
    concat                      0.5600    0.0000    0.5600    0.5703
    format                      0.7400    0.0000    0.7400    0.7463

    ## Remove min & max            min    repeat       max    repeat
    join                        0.6482      (#5)    0.6591      (#1)
    concat                      0.5571      (#2)    0.5703      (#5)
    format                      0.7463      (#5)    0.7662      (#1)

    ## Average of 3 (=5-2*1)      user       sys     total      real
    join                        0.6533    0.0000    0.6533    0.6534
    concat                      0.5567    0.0000    0.5567    0.5605
    format                      0.7500    0.0000    0.7500    0.7533

    ## Ranking                    real
    concat                      0.5605 (100.0%) *************************
    join                        0.6534 ( 85.8%) *********************
    format                      0.7533 ( 74.4%) *******************

    ## Ratio Matrix               real    [01]    [02]    [03]
    [01] concat                 0.5605  100.0%  116.6%  134.4%
    [02] join                   0.6534   85.8%  100.0%  115.3%
    [03] format                 0.7533   74.4%   86.7%  100.0%

If you prefer to print only averaged data, pass ``verbose=False`` to Benchmark().
::

    with Benchmark(loop=1000*1000, verbose=False) as bm:
        ....

Or just ignore standard error.
::

    $ python ex4.py 2>/dev/null


Function
--------

You can write benchmark code as function.

ex5.py::

    from benchmarker import Benchmarker

    s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"

    def f1(n):
        """join"""
        for _ in xrange(n):
            sos = ''.join((s1, s2, s3, s4, s5))
    def f2(n):
        """concat"""
        for _ in xrange(n):
            sos = s1 + s2 + s3 + s4 + s5
    def f3(n):
        """format"""
        for _ in xrange(loop):
            sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

    loop = 1000 * 1000
    with Benchmarker(width=20) as bm:
        for _ in bm.repeat(3, extra=1):
            bm.run(f1, loop)   # or bm('join').run(f1, loop)
            bm.run(f2, loop)   # or bm('concat').run(f2, loop)
            bm.run(f3, loop)   # or bm('format').run(f3, loop)

Benchmarker uses document string of function as a label of benchmark. If
function doesn't have a document string, Benchmarker uses function name as
label instead of document string.
::

    ## This code...
    bm.run(func, arg1, arg2)
    ## is same as:
    bm(func.__doc__ or func.__name__).run(func, arg1, arg2)



Tips
====


Output Format
-------------

Benchmarker allows you to customize output format through ``benchmarker.format`` object.
::

    from benchmarker import format
    format.label_width = 30       # same as Benchmark(width=30)
    format.time        = '%9.4f'


Benchmark Results
-----------------

You can get benchmark results by ``bm.results`` or ``bm.all_results``.
::

    for result in bm.results:
        print(result.label)
        print(result.user)
        print(result.sys)
        print(result.total)
        print(result.real)


Python 2.4 support
------------------

With-statement is not available in Python 2.4. But don't worry, Benchmarker provides a solution.
::

    ## Instead of with-statement,
    with Benchmarker() as bm:
        for _ in bm.repeat(5):
            bm.run(func, arg1, arg2)

    ## for-statement is available!
    for bm in Benchmarker(width=20):
        for _ in bm.repeat(5):
            bm.run(func, arg1, arg2)

    ## Or if you like:
    bm = Benchmarker(width=20)
    bm.__enter__()
    for _ in bm.repeat(5):
        bm.run(func, arg1, arg2)
    bm.__exit__()
'''
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
