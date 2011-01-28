.=title:	Benchmarker README
.?stylesheet:	docstyle.css


$Release: $.^
$License: Public Domain $.^
$Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved. $.^



.$ Overview

Benchmarker is a small utility for benchmarking.

.? Quick Example (ex0.py)
.-------------------- ex0.py
from benchmarker import Benchmarker, cmdopt
cmdopt.parse()

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
.--------------------

.? Output example
.====================
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

$ python ex0.py -h           # show help message of command-line optins
$ python ex0.py -n 10000     # override number of loop
$ python ex0.py concat join  # do only 'concat' and 'join' benchmarks
.====================

Notice that empty loop times (user, sys, total, and real) are subtracted from other benchmark times automatically.
For example:

.+========================================
  benchmark label   ., real (second)
.----------------------------------------
  join              ., 0.6483 (= 0.8122 - 0.1639)
  concat            ., 0.5711 (= 0.7350 - 0.1639)
  format            ., 0.7568 (= 0.9207 - 0.1639)
.+========================================

{{!NOTICE:!}} This release doesn't have compatibility with previous version.
See {{<CHANGES.txt>}} for details.


.$ Download and Install

{{<http://pypi.python.org/pypi/Benchmarker/>}}

.? Installation
.====================
## if you have installed easy_install:
$ sudo easy_install Benchmarker
## or download Benchmarker-X.X.X.tar.gz and install it
$ wget http://pypi.python.org/packages/source/B/Benchmarker/Benchmarker-X.X.X.tar.gz
$ tar xzf Benchmarker-X.X.X.tar.gz
$ cd Benchmarker-X.X.X/
$ sudo python setup.py install
.====================



.$ Step by Step Examples


.$$ Basic Example

.? ex1.py
.-------------------- ex1.py
{{*from benchmarker import Benchmarker*}}

s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
loop = 1000 * 1000
{{*with Benchmarker(width=20) as bm:*}}
    {{*with bm('join'):*}}
        for i in xrange(loop):
            sos = ''.join((s1, s2, s3, s4, s5))
    {{*with bm('concat'):*}}
        for i in xrange(loop):
            sos = s1 + s2 + s3 + s4 + s5
    {{*with bm('format'):*}}
        for i in xrange(loop):
            sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)
.--------------------

.? Output example
.====================
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
.====================


.$$ Empty Loop

If you want to get more accurate results, add empty loop benchmark.

.? ex2.py
.-------------------- ex2.py
from benchmarker import Benchmarker

s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
loop = 1000 * 1000
with Benchmarker(width=20) as bm:
    {{*with bm.empty():*}}
        {{*for i in xrange(loop):*}}
            {{*pass*}}
    with bm('join'):
        for i in xrange(loop):
            sos = ''.join((s1, s2, s3, s4, s5))
    with bm('concat'):
        for i in xrange(loop):
            sos = s1 + s2 + s3 + s4 + s5
    with bm('format'):
        for i in xrange(loop):
            sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)
.--------------------

.? Output Example
.====================
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
.====================

Notice that benchmark results are subtracted by '(Empty)' loop results.
For example:

.+========================================
  benchmark label   ., real (second)
.----------------------------------------
  join              ., 0.6541 (= 0.7365 - 0.0824)
  concat            ., 0.5592 (= 0.6416 - 0.0824)
  format            ., 0.7603 (= 0.8427 - 0.0824)
.+========================================


.$$ Loop

It is possible to simpily benchmark script by {{,loop,}} parameter.

.? ex3.py
.-------------------- ex3.py
from benchmarker import Benchmarker

s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
with Benchmarker(width=20, {{*loop=1000*1000*}}) as bm:
    {{*for _ in bm.empty():*}}
        pass
    {{*for _ in bm('join'):*}}
        sos = ''.join((s1, s2, s3, s4, s5))
    {{*for _ in bm('concat'):*}}
        sos = s1 + s2 + s3 + s4 + s5
    {{*for _ in bm('format'):*}}
        sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)
.--------------------

.? Output Example
.====================
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
.====================

Hint: You can specify {{,loop,}} parameter by {{,-n,}} command-line option.


.$$ Cycle

If you want to repeat benchmarks several times and calculate average time, pass {{,cycle,}} and optional {{,extra,}} parameters, and use for-statement instead of with-statement.
If you specify {{,extra,}} parameter, minimum and maximum values are removed from benchmark results.
This is intended to remove abnormal results or to ignore setup time.

.? ex4.py
.-------------------- ex4.py
from benchmarker import Benchmarker

s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
{{*for bm in*}} Benchmarker(width=25, loop=1000*1000, {{*cycle=3, extra=1*}}):
    for _ in bm.empty():
        pass
    for _ in bm('join'):
        sos = ''.join((s1, s2, s3, s4, s5))
    for _ in bm('concat'):
        sos = s1 + s2 + s3 + s4 + s5
    for _ in bm('format'):
        sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)
.--------------------

.? Output Example
.====================
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

## Remove min & max            min     cycle       max     cycle
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
.====================

You can see that average time are calculated automatically after minimun and maximum values are removed.

If you prefer to print only average time, pass {{,verbose=False,}} to {{,Benchmark(),}}.

.--------------------
for bm in Benchmark(loop=1000*1000, cycle=3, extra=1, {{*verbose=False*}}):
    ....
.--------------------

Or just ignore standard error.

.====================
$ python ex4.py 2>/dev/null
.====================

Hint: You can specify {{,cycle,}} and {{,extra,}} parameter by {{,-c,}} and {{,-X,}} command-line option.


.$$ Command-line Options

Calling {{,benchmarker.cmdopt.parse(),}}, you can specify parameters in command-line.

.? ex5.py
.-------------------- ex5.py
{{*import benchmarker*}}
from benchmarker import Benchmarker
{{*benchmarker.cmdopt.parse()*}}

s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
for bm in Benchmarker(width=25, loop=1000*1000, cycle=3, extra=1):
    for _ in bm.empty():
        pass
    for _ in bm('join'):
        sos = ''.join((s1, s2, s3, s4, s5))
    for _ in bm('concat'):
        sos = s1 + s2 + s3 + s4 + s5
    for _ in bm('format'):
        sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)
.--------------------

.? Command-line option example
.====================
### show help
$ python ex5.py -h

### cycle all benchmarks 5 times with 1000,000 loop
$ python ex5.py -c 5 -n 1000000

### invoke bench1, bench2, and so on
$ python ex5.py 'bench*'

### invoke al benchmarks except bench1, bench2, and bench3
$ python ex5.py -x '^bench[1-3]$'

### invoke all branches with user-defined options
$ python ex5.py --name1 --name2=value2
.====================

You can get user-defined options via {{,benchmarker.cmdopt,}} in your script.

.--------------------
import benchmarker
benchmarker.cmdopt.parse()
print({{*benchmarker.cmdopt['name1']*}})   #=> True
print({{*benchmarker.cmdopt['name2']*}})   #=> 'value2'
.--------------------


.$$ Function

You can write benchmark code as function.

.? ex6.py
.-------------------- ex6.py
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
for bm in Benchmarker(width=25, cycle=3, extra=1):
    {{*bm.run(f1, loop)   # or bm('join').run(f1, loop)*}}
    {{*bm.run(f2, loop)   # or bm('concat').run(f2, loop)*}}
    {{*bm.run(f3, loop)   # or bm('format').run(f3, loop)*}}
.--------------------

Benchmarker uses document string of function as a label of benchmark.
If function doesn't have a document string, Benchmarker uses function name as label instead of document string.

.--------------------
## This code...
bm.run(func, arg1, arg2)
## is same as:
bm(func.__doc__ or func.__name__).run(func, arg1, arg2)
.--------------------

.#.? Output Example
.#.====================
.#$ python ex6.py
.### benchmarker:       release 0.0.0 (for python)
.### python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5664)]
.### python version:    2.7.1
.### python executable: /usr/local/python/2.7.1/bin/python
.#
.### (#1)                  user       sys     total      real
.#join                   0.6000    0.0000    0.6000    0.5990
.#concat                 0.5000    0.0000    0.5000    0.5085
.#format                 0.6800    0.0000    0.6800    0.6754
.#
.### (#2)                  user       sys     total      real
.#join                   0.5900    0.0000    0.5900    0.5931
.#concat                 0.5100    0.0000    0.5100    0.5185
.#format                 0.6700    0.0000    0.6700    0.6776
.#
.### (#3)                  user       sys     total      real
.#join                   0.5900    0.0000    0.5900    0.5927
.#concat                 0.5100    0.0000    0.5100    0.5072
.#format                 0.6700    0.0000    0.6700    0.6758
.#
.### (#4)                  user       sys     total      real
.#join                   0.6000    0.0000    0.6000    0.6028
.#concat                 0.5000    0.0000    0.5000    0.5061
.#format                 0.6700    0.0000    0.6700    0.6774
.#
.### (#5)                  user       sys     total      real
.#join                   0.6000    0.0000    0.6000    0.5997
.#concat                 0.5000    0.0000    0.5000    0.5043
.#format                 0.6700    0.0000    0.6700    0.6746
.#
.### Remove min & max       min     cycle       max     cycle
.#join                   0.5927      (#3)    0.6028      (#4)
.#concat                 0.5043      (#5)    0.5185      (#2)
.#format                 0.6746      (#5)    0.6776      (#2)
.#
.### Average of 3 (=5-2*1)     user       sys     total      real
.#join                   0.5967    0.0000    0.5967    0.5973
.#concat                 0.5033    0.0000    0.5033    0.5073
.#format                 0.6733    0.0000    0.6733    0.6762
.#
.### Ranking               real
.#concat                 0.5073 (100.0%) *************************
.#join                   0.5973 ( 84.9%) *********************
.#format                 0.6762 ( 75.0%) *******************
.#
.### Ratio Matrix          real    [01]    [02]    [03]
.#[01] concat            0.5073  100.0%  117.7%  133.3%
.#[02] join              0.5973   84.9%  100.0%  113.2%
.#[03] format            0.6762   75.0%   88.3%  100.0%
.#.====================



.$ Tips


.$$ Output Format

Benchmarker allows you to customize output format through {{,benchmarker.format,}} object.

.--------------------
from benchmarker import format
format.label_width = 30       # same as Benchmark(width=30)
format.time        = '%9.4f'
.--------------------


.$$ Benchmark Results

You can get benchmark results by {{,bm.results,}} or {{,bm.all_results,}}.

.--------------------
for result in bm.results:
    print(result.label)
    print(result.user)
    print(result.sys)
    print(result.total)
    print(result.real)
.--------------------


.$$ Alternative of with-statement in Python 2.4

As you know, with-statement is not available in Python 2.4.
But don't worry, Benchmarker provides an alternative way.

.--------------------
## Instead of with-statement,
with Benchmarker() as bm:
    bm('bench1').run(func, arg1, arg2)
    bm('bench2').run(func, arg3, arg4)

## for-statement is available!
{{*for bm in Benchmarker():*}}
    bm('bench1').run(func, arg1, arg2)
    bm('bench2').run(func, arg3, arg4)

## Above is almost same as:
bm = Benchmarker(width=20)
{{*bm.__enter__()*}}
bm('bench1').run(func, arg1, arg2)
bm('bench2').run(func, arg3, arg4)
{{*bm.__exit__()*}}
.--------------------
