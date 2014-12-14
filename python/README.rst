=====================
Benchmarker.py README
=====================


| $Release: 0.0.0 $
| $License: Public Domain $
| $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved. $


Overview
========

Benchmarker.py is an awesome benchmarking tool for Python.

* Easy to use
* Pretty good output (including JSON format)
* Available on Python >= 2.5 and >= 3.0

ATTENTION: I'm sorry, Benchmarker.py ver 4 is not compatible with ver 3.


Install
-------

http://pypi.python.org/pypi/Benchmarker/

::

    $ sudo pip install Benchmarker
    ## or
    $ sudo easy_install Benchmarker
    ## or
    $ wget http://pypi.python.org/packages/source/B/Benchmarker/Benchmarker-X.X.X.tar.gz
    $ tar xzf Benchmarker-X.X.X.tar.gz
    $ cd Benchmarker-X.X.X/
    $ sudo python setup.py install


Step by Step Tutorial
=====================


Basic Usage
-----------

Example (ex1.py)::

    {{*from benchmarker import Benchmarker*}}
    try:
        xrange
    except NameError:
        xrange = range       # for Python3

    loop = 1000 * 1000
    {{*with Benchmarker(width=20) as bench:*}}
        s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"

        {{*@bench("join")*}}
        def _({{*bm*}}):
            for _ in xrange(loop):
                sos = ''.join((s1, s2, s3, s4, s5))

        {{*@bench("concat")*}}
        def _({{*bm*}}):
            for _ in xrange(loop):
                sos = s1 + s2 + s3 + s4 + s5

        {{*@bench("format")*}}
        def _({{*bm*}}):
            for _ in xrange(loop):
                sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output example::

    $ python ex1.py
    ## benchmarker:         release 0.0.0 (for python)
    ## python version:      3.4.2
    ## python compiler:     GCC 4.8.2
    ## python platform:     Linux-3.13.0-36-generic-x86_64-with-debian-jessie-sid
    ## python executable:   /opt/vs/python/3.4.2/bin/python
    ## cpu model:           Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz  # 2494.050 MHz
    ## parameters:          loop=1, cycle=1, extra=0

    ##                        real    (total    = user    + sys)
    join                    0.2892    0.2900    0.2900    0.0000
    concat                  0.3889    0.3800    0.3800    0.0000
    format                  0.4496    0.4500    0.4500    0.0000

    ## Ranking                real
    join                    0.2892  (100.0) ********************
    concat                  0.3889  ( 74.4) ***************
    format                  0.4496  ( 64.3) *************

    ## Matrix                 real    [01]    [02]    [03]
    [01] join               0.2892   100.0   134.5   155.5
    [02] concat             0.3889    74.4   100.0   115.6
    [03] format             0.4496    64.3    86.5   100.0


Number of Loop
--------------

You can specify number of loop in script and/or command-line option.

Example (ex2.py)::

    from benchmarker import Benchmarker

    ## specify number of loop
    with Benchmarker({{*1000*1000*}}, width=20) as bench:
        s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"

        @bench("join")
        def _(bm):
            for i in {{*bm*}}:      ## instead of xrange(N)
                sos = ''.join((s1, s2, s3, s4, s5))

        @bench("concat")
        def _(bm):
            for i in {{*bm*}}:
                sos = s1 + s2 + s3 + s4 + s5

        @bench("format")
        def _(bm):
            for i in {{*bm*}}:
                sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output Example::

    $ python ex2.py   # or python ex2.py {{*-n 1000000*}}
    ## benchmarker:         release 0.0.0 (for python)
    ## python version:      3.4.2
    ## python compiler:     GCC 4.8.2
    ## python platform:     Linux-3.13.0-36-generic-x86_64-with-debian-jessie-sid
    ## python executable:   /opt/vs/python/3.4.2/bin/python
    ## cpu model:           Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz  # 2494.050 MHz
    ## parameters:          loop=1000000, cycle=1, extra=0

    ##                        real    (total    = user    + sys)
    join                    0.2960    0.3000    0.3000    0.0000
    concat                  0.3946    0.3900    0.3900    0.0000
    format                  0.4430    0.4500    0.4500    0.0000

    ## Ranking                real
    join                    0.2960  (100.0) ********************
    concat                  0.3946  ( 75.0) ***************
    format                  0.4430  ( 66.8) *************

    ## Matrix                 real    [01]    [02]    [03]
    [01] join               0.2960   100.0   133.3   149.7
    [02] concat             0.3946    75.0   100.0   112.3
    [03] format             0.4430    66.8    89.1   100.0


Empty Loop
----------

'Empty loop' is used to subtract time for loop from entire time.

Example (ex3.py)::

    from benchmarker import Benchmarker

    ## specify number of loop
    with Benchmarker(1000*1000, width=20) as bench:
        s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"

        {{*@bench(None)*}}                ## !!!!! empty loop
        {{*def _(bm):*}}
            {{*for i in bm:*}}
                {{*pass*}}

        @bench("join")
        def _(bm):
            for i in bm:
                sos = ''.join((s1, s2, s3, s4, s5))

        @bench("concat")
        def _(bm):
            for i in bm:
                sos = s1 + s2 + s3 + s4 + s5

        @bench("format")
        def _(bm):
            for i in bm:
                sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output Example::

    $ python ex3.py
    ## benchmarker:         release 0.0.0 (for python)
    ## python version:      3.4.2
    ## python compiler:     GCC 4.8.2
    ## python platform:     Linux-3.13.0-36-generic-x86_64-with-debian-jessie-sid
    ## python executable:   /opt/vs/python/3.4.2/bin/python
    ## cpu model:           Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz  # 2494.050 MHz
    ## parameters:          loop=1000000, cycle=1, extra=0

    ##                        real    (total    = user    + sys)
    {{*(Empty)                 0.0236    0.0200    0.0200    0.0000*}}
    join                    {{*0.2779*}}    0.2800    0.2800    0.0000
    concat                  {{*0.3792*}}    0.3800    0.3800    0.0000
    format                  {{*0.4233*}}    0.4300    0.4300    0.0000

    ## Ranking                real
    join                    0.2779  (100.0) ********************
    concat                  0.3792  ( 73.3) ***************
    format                  0.4233  ( 65.6) *************

    ## Matrix                 real    [01]    [02]    [03]
    [01] join               0.2779   100.0   136.5   152.3
    [02] concat             0.3792    73.3   100.0   111.6
    [03] format             0.4233    65.6    89.6   100.0


For example, actual time of 'join' entry is 0.3015 (= 0.2779 + 0.0236).
In other words, real time (0.2779) is already subtracted empty loop time (0.0236).

+---------+----------------------------+
| join    | 0.3015 (= 0.2779 + 0.0236) |
+---------+----------------------------+
| concat  | 0.4028 (= 0.3792 + 0.0236) |
+---------+----------------------------+
| format  | 0.4469 (= 0.4233 + 0.0236) |
+---------+----------------------------+


Iteration and Average
---------------------

It is possible to iterate all benchmarks. Average of results are calculated
automatically.

* ``Benchmark(cycle=3)`` or ``-c 3`` option iterates all benchmarks 3 times
  and reports average of benchmarks.
* ``Benchmark(extra=1)`` or ``-x 1`` option increases number of iterations
  by ``2*1`` times, and excludes min and max result from average.
* ``Benchmark(cycle=3, extra=1)`` or ``-c 3 -x 1`` option iterates benchmarks
  5 (= 3+2*1) times, excludes min and max results, and calculates averages
  from 3 results.

Example (ex4.py)::

    from benchmarker import Benchmarker

    with Benchmarker(1000*1000, width=25, {{*cycle=3, extra=1*}}) as bench:
        s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"

        @bench(None)
        def _(bm):
            for i in bm:
                pass

        @bench("join")
        def _(bm):
            for i in bm:    ## !!!!! instead of xrange(N)
                sos = ''.join((s1, s2, s3, s4, s5))

        @bench("concat")
        def _(bm):
            for i in bm:
                sos = s1 + s2 + s3 + s4 + s5

        @bench("format")
        def _(bm):
            for i in bm:
                sos = '%s%s%s%s%s' % (s1, s2, s3, s4, s5)

Output Example::

    $ python ex4.py     # or python ex4.py {{*-c 3 -x 1*}}
    ## benchmarker:         release 0.0.0 (for python)
    ## python version:      3.4.2
    ## python compiler:     GCC 4.8.2
    ## python platform:     Linux-3.13.0-36-generic-x86_64-with-debian-jessie-sid
    ## python executable:   /opt/vs/python/3.4.2/bin/python
    ## cpu model:           Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz  # 2494.050 MHz
    ## parameters:          loop=1000000, cycle=3, extra=1

    ## {{*(#1)*}}                        real    (total    = user    + sys)
    (Empty)                      0.0246    0.0300    0.0300    0.0000
    join                         0.2705    0.2600    0.2600    0.0000
    concat                       0.3776    0.3800    0.3800    0.0000
    format                       0.4102    0.4000    0.4000    0.0000

    ## {{*(#2)*}}                        real    (total    = user    + sys)
    (Empty)                      0.0243    0.0200    0.0200    0.0000
    join                         0.2737    0.2800    0.2800    0.0000
    concat                       0.3791    0.3900    0.3900    0.0000
    format                       0.4087    0.4100    0.4100    0.0000

    ## {{*(#3)*}}                        real    (total    = user    + sys)
    (Empty)                      0.0237    0.0200    0.0200    0.0000
    join                         0.2686    0.2700    0.2700    0.0000
    concat                       0.3719    0.3800    0.3800    0.0000
    format                       0.4047    0.4100    0.4100    0.0000

    ## {{*(#4)*}}                        real    (total    = user    + sys)
    (Empty)                      0.0236    0.0200    0.0200    0.0000
    join                         0.2660    0.2700    0.2700    0.0000
    concat                       0.3749    0.3800    0.3800    0.0000
    format                       0.4083    0.4100    0.4100    0.0000

    ## {{*(#5)*}}                        real    (total    = user    + sys)
    (Empty)                      0.0246    0.0300    0.0300    0.0000
    join                         0.2720    0.2600    0.2600    0.0000
    concat                       0.3754    0.3700    0.3700    0.0000
    format                       0.4132    0.4100    0.4100    0.0000

    {{*## Ignore min & max             min     cycle       max     cycle*}}
    {{*join                         0.2660      (#4)    0.2737      (#2)*}}
    {{*concat                       0.3719      (#3)    0.3791      (#2)*}}
    {{*format                       0.4047      (#3)    0.4132      (#5)*}}

    {{*## Average of 3 (=5-2*1)       real    (total    = user    + sys)*}}
    {{*join                         0.2704    0.2633    0.2633    0.0000*}}
    {{*concat                       0.3759    0.3767    0.3767    0.0000*}}
    {{*format                       0.4091    0.4067    0.4067    0.0000*}}

    ## Ranking                     real
    join                         0.2704  (100.0) ********************
    concat                       0.3759  ( 71.9) **************
    format                       0.4091  ( 66.1) *************

    ## Matrix                      real    [01]    [02]    [03]
    [01] join                    0.2704   100.0   139.1   151.3
    [02] concat                  0.3759    71.9   100.0   108.8
    [03] format                  0.4091    66.1    91.9   100.0



Advanced Topics
===============


Output in JSON format
---------------------

Command-line ``-o file`` option will output benchmark data into ``file``
in JSON format. ::

    $ python mybench.py {{*-o result.json*}}
    ....(snip)...
    $ less result.json


Setup and Teardown
------------------

If each benchmark requires setup or teardown code which takes long time,
wrap true-benchmark block by ``with bm:`` in order to exclude setup and
teardown time.

Example::

    from benchmarker import Benchmarker

    with Benchmarker(1000) as bench:

        @bench("Django template engine"):
        def _(bm):
            ## setup
            import django
            import django.template
            with open("example.html") as f:
                tmpl = django.template.Template(f.read())
            context = django.template.Context({"items": ["A", "B", "C"]})

            ## run benchmark, excluding setup and teardown time
            {{*with bm:*}}            # !!!!!
                for _ in bm:
                    output = tmpl.render(context)

            ## teardown
            with open("example.expected") as f:
                expected = f.read()
            assert output == expected


Skip Benchmarks
---------------

You can skip benchmark if you want.
If you want skip benchmark, return a string (= reason to skip).

Example::

    from benchmarker import Benchmarker

    with Benchmarker(1000) as bench:

        @bench("Django template engine"):
        def _(bm):
            ## setup
            try:
                import django
                import django.template
            except ImportError:
                {{*return "skip because not installed"*}}    # !!!!!
            ...
            ...
            ...


Filter Benchmarks
-----------------

Using command-line option ``-f``, you can filter benchmarks by name.

Example::

    $ python mybench.py {{*-f 'name==foo'*}}    # select benchmarks by name
    $ python mybench.py {{*-f 'name!=foo'*}}    # reject benchmarks by name
    $ python mybench.py {{*-f 'name=~^foo$'*}}  # select by pattern (regexp)
    $ python mybench.py {{*-f 'name!~^foo$'*}}  # reject by pattern (regexp)

It is possible to specify default filter::

    with Benchmarker(filter="name!=foo") as bench:
        ....


User-Defined Tags
-----------------

``@bench()`` decorator can take user-defined tags.
They can be string or tuple of strings.

Example::

    from benchmarker import Benchmarker

    with Benchmarker(1000*1000) as bench:

        @bench("Kid template engine", {{*tag="tooslow"*}}):
        def _(bm):
            for i in bm:
                ....

        @bench("Tenjin template engine", {{*tag=("fast","autoescape")*}}):
        def _(bm):
            for i in bm:
                ....

        @bench("Django template engine"):
        def _(bm):
            for i in bm:
                ....

You can filter benchmarks by user-defined tags by ``-f`` option.

Example::

    $ python mybench.py {{*-f 'tag==fast'*}}     # select only tagged as 'fast'
    $ python mybench.py {{*-f 'tag!=tooslow'*}}  # reject all tagged as 'tooslow'
    $ python mybench.py {{*-f 'tag=~^fast$'*}}   # select by pattern
    $ python mybench.py {{*-f 'tag!~^tooslo$'*}} # reject by pattern

It is very useful to skip heavy benchmarks by default::

    ## skip benchmarks tagged as 'heavy'
    with Benchmarker(filter="tag!=heavy") as bench:

        @bench("too heavy benchmark", tag=("heaby",))   # skipped by default
	def _(bm):
	    # do heavy benchmark



Changelog
=========


Release 4.0.0 (2014-12-14)
--------------------------

* Rewrited entirely. This release is not compatible with previous version.


Release 3.0.1 (2011-02-13)
--------------------------

* License is changed again to Public Domain.

* Change Task class to pass 1-origin index to yield block when 'for _ in bm()' .

* Fix a bug that 'for _ in bm()' raised error when loop count was not specified.

* Fix a bug that 'for _ in bm()' raised RuntimeError on Python 3.


Release 3.0.0 (2011-01-29)
--------------------------

* Rewrite entirely.

* License is changed to MIT License.

* Enhanced to support command-line options. ::

      import benchmarker
      benchmarker.cmdopt.parse()

  You can show all command-line options by ``python file.py -h``.
  See README file for details.

* Benchmarker.repeat() is obsolete. ::

      ## Old (obsolete)
      with Benchmarker() as bm:
          for b in bm.repeat(5, 1):
              with b('bench1'):
                  ....

      ## New
      for bm in Benchmarker(cycle=5, extra=1):
          with bm('bench1'):
	      ....

* Changed to specify time (second) format. ::

      import benchmarker
      benchmarker.format.label_with = 30
      benchmarker.format.time       = '%9.4f'

* Followings are removed.

  * Benchmark.stat
  * Benchmark.compared_matrix()
  * Benchmark.print_compared_matrix()


Release 2.0.0 (2010-10-28)
--------------------------

* Rewrited entirely.

* Enhance to support empty loop. Result of empty loop is subtracted
  automatically  automatically from other benchmark result. ::

      bm = Benchmarker()
      with bm.empty():
        for i in xrange(1000*1000):
          pass
      with bm('my benchmark 1'):
        #... do something ...

* Enhance to support for-statement. ::

      bm = Benchmarker(loop=1000*1000)
      for i in bm('example'):
        #... do something ...

      ## the above is same as:
      bm = Benchmarker()
      with bm('example'):
        for i in xrange(1000*1000):
	  #... do something ...

* Enhance to support new feature to repeat benchmarks. ::

      bm = Benchmarker()
      for b in bm.repeat(5):   # repeat benchmark 5 times
        with b('example1'):
	  #... do something ...
        with b('example2'):
	  #... do something ...

* 'compared_matrix()' is replaced by 'stat.all()'.
  'stat.all()' shows benchmark ranking and ratio matrix. ::

       bm = Benchmarker()
       with bm('example'):
          # ....
       print(bm.stat.all())   # ranking and ratio matrix

* Enhance to support 'Benchmark.platform()' which gives you platform
  information. ::

      print bm.platform()
      #### output example
      ## benchmarker:       release 2.0.0 (for python)
      ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
      ## python version:    2.5.5
      ## python executable: /usr/local/python/2.5.5/bin/python2.5

* 'with-statement' for benchmarker object prints platform info and statistics
  automatically. ::

      with Benchmarker() as bm:
        wtih bm('fib(30)'):
          fib(30)
      #### the above is same as:
      # bm = Benchmarker()
      # print(bm.platform())
      # with bm('fib(30)'):
      #   fib(30)
      # print(bm.stat.all())

* Enhance Benchmarker.run() to use function docment (__doc__) as benchmark
  label when label is not specified. ::

      def fib(n):
        """fibonacchi"""
        return n <= 2 and 1 or fib(n-1) + fib(n-2)
      bm = Benchmarker()
      bm.run(fib, 30)    # same as bm("fibonacchi").run(fib, 30)

* Default format of times is changed from '%9.3f' to '%9.4f'.


Release 1.1.0 (2010-06-26)
--------------------------

* Enhance Benchmarker.run() to take function args. ::

    bm = Benchmarker()
    bm('fib(34)').run(fib, 34)   # same as .run(lambda: fib(34))

* (experimental) Enhance Benchmarker.run() to use function name as title
  if title is not specified. ::

    def fib34(): fib(34)
    bm = Benchmarker()
    bm.run(fib34)     # same as bm('fib34').run(fib34)

* Enhanced to support compared matrix of benchmark results. ::

    bm = Benchmarker(9)
    bm('fib(30)').run(fib, 30)
    bm('fib(31)').run(fib, 31)
    bm('fib(32)').run(fib, 32)
    bm.print_compared_matrix(sort=False, transpose=False)
    ## output example
    #                 utime     stime     total      real
    #fib(30)          0.440     0.000     0.440     0.449
    #fib(31)          0.720     0.000     0.720     0.722
    #fib(32)          1.180     0.000     1.180     1.197
    #--------------------------------------------------------------------------
    #                    real      [01]     [02]     [03]
    #[01] fib(30)     0.4487s        -     60.9%   166.7%
    #[02] fib(31)     0.7222s    -37.9%       -     65.7%
    #[03] fib(32)     1.1967s    -62.5%   -39.6%       - 

* Benchmark results are stored into Benchmarker.results as a list of tuples. ::

    bm = Benchmarker()
    bm('fib(34)').run(fib, 34)
    bm('fib(35)').run(fib, 35)
    for result in bm.results:
        print result
    ## output example:
    #('fib(34)', 4.37, 0.02, 4.39, 4.9449)
    #('fib(35)', 7.15, 0.05, 7.20, 8.0643)

* Time format is changed from '%10.4f' to '%9.3f'

* Changed to run full-GC for each benchmarks


Release 1.0.0 (2010-05-16)
--------------------------

* public release
