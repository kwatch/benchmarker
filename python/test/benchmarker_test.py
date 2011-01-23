# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

from __future__ import with_statement

import sys
try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO

from oktest import ok, not_ok, run, spec
from oktest.tracer import Tracer
from oktest.helper import dummy_io

import benchmarker
from benchmarker import Format, Echo, Benchmarker, Result, Task, Statistics, CommandOption


def _set_output():
    sio = StringIO()
    benchmarker.echo._out = sio
    return sio

def _get_output():
    return benchmarker.echo._out.getvalue()


class Format_TC(object):

    def before(self):
        self.fmt = Format()

    def test___init__(self):
        fmt = self.fmt
        with spec("sets 'label_width' property."):
            spec (fmt.label_width) == 30
        with spec("sets 'time' property."):
            spec (fmt.time) == '%9.4f'

    def test__get_label_width(self):
        fmt = self.fmt
        with spec("returns '__label_with' attribute."):
            spec (fmt.label_width) == fmt._Format__label_width

    def test__set_label_width(self):
        fmt = self.fmt
        with spec("sets both '__label_width' and 'label' attributes."):
            fmt.label_width = 25
            spec (fmt.label_width) == 25

    def test_get_time(self):
        fmt = self.fmt
        with spec("returns '__time' attribute."):
            ok (fmt.time) == fmt._Format__time

    def test_set_time(self):
        fmt = self.fmt
        with spec("sets '__time', 'time_label', 'times' and 'times_label' attrs."):
            fmt.time = '%7.3f'
            ok (fmt.time)        == '%7.3f'
            ok (fmt.time_label)  == '%7s'
            ok (fmt.times)       == '%7.3f %7.3f %7.3f %7.3f'
            ok (fmt.times_label) == '%7s %7s %7s %7s'


class Echo_TC(object):

    def test_create_dummy(self):
        with spec("returns Echo object with dummy I/O."):
            ret = Echo.create_dummy()
            ok (ret).is_a(Echo)
            ok (ret._out).is_a(benchmarker.StringIO)

    def test_flush(self):
        with spec("calls _out.flush() only if _out has 'flush' method."):
            tr = Tracer()
            echo = Echo(tr.fake_obj())
            echo.flush()
            ok (len(tr)) == 0
            echo = Echo(tr.fake_obj(flush=None))
            echo.flush()
            ok (len(tr)) == 1
            ok (tr[0].name) == 'flush'

    def test_str(self):
        sio = StringIO()
        echo = Echo(sio)
        with spec("does nothing if argument is empty."):
            echo.prev = False
            echo.str('')
            ok (sio.getvalue()) == ''
            ok (echo.prev) == False
        with spec("writes argument and keep it to prev attribute."):
            echo.str('SOS')
            ok (sio.getvalue()) == 'SOS'
            ok (echo.prev) == 'SOS'

    def test_text(self):
        sio, sio2 = StringIO(), StringIO()
        echo, echo2 = Echo(sio), Echo(sio2)
        with spec("does nothing if argument is empty."):
            echo.prev = False
            echo.text('')
            ok (sio.getvalue()) == ''
            ok (echo.prev) == False
        with spec("adds '\n' at the end of argument if it doesn't end with '\n'."):
            echo.text("SOS")
            ok (sio.getvalue()) == "SOS\n"
            echo2.text("TPDD\n")
            ok (sio2.getvalue()) == "TPDD\n"
        with spec("writes argument and keep it to prev attribute."):
            ok (echo.prev) == "SOS\n"
            ok (echo2.prev) == "TPDD\n"

    def test_task_label(self):
        sio = StringIO()
        echo = Echo(sio)
        tr = Tracer()
        tr.trace_method(sio, 'flush')
        with spec("shrinks too long label."):
            echo.task_label("123456789|123456789|123456789|123456789")
            ok (sio.getvalue()) == "123456789|123456789|1234567..."
            ok (len(sio.getvalue())) == benchmarker.format.label_width
        with spec("prints label."):
            ok (sio.getvalue()) == "123456789|123456789|1234567..."
        with spec("flushes output."):
            ok (len(tr)) == 1
            ok (tr[0].name) == 'flush'

    def test_task_times(self):
        sio = StringIO()
        echo = Echo(sio)
        with spec("prints times."):
            echo.task_times(1.5, 2.5, 3.5, 4.5)
            ok (sio.getvalue()) == "   1.5000    2.5000    3.5000    4.5000\n"


class Benchmarker_TC(object):

    def before(self):
        self.bm = Benchmarker()
        self._echo_bkup = benchmarker.echo
        benchmarker.echo = Echo.create_dummy()

    def after(self):
        benchmarker.echo = self._echo_bkup

    def test___init__(self):
        with spec("sets format.label_with if 'wdith' option is specified."):
            try:
                bkup = benchmarker.format.label_width
                assert bkup == 30
                bm = Benchmarker(width=20)
                ok (benchmarker.format.label_width) == 20
            finally:
                benchmarker.format.label_width = bkup
        bm = self.bm
        with spec("sets 'loop' attribute."):
            ok (bm.loop) == 1
            bm2 = Benchmarker(loop=100)
            ok (bm2.loop) == 100
        with spec("sets 'verbose' attribute if its option is specified."):
            ok (bm.verbose) == True
            bm2 = Benchmarker(verbose=False)
            ok (bm2.verbose) == False
        with spec("creates Statistics object using STATISTICS variable."):
            ok (bm.stats).is_a(benchmarker.Statistics)
            try:
                bkup = benchmarker.STATISTICS
                bases = (benchmarker.Statistics, )
                def _init(self, *args, **kwargs):
                    self._args = args
                    self._kwargs = kwargs
                dummy_class = type('DummyStatistics', bases, {'__init__': _init})
                benchmarker.STATISTICS = dummy_class
                bm2 = Benchmarker()
                ok (bm2.stats).is_a(dummy_class)
                ok (bm2.stats._args) == ()
                ok (bm2.stats._kwargs) == {}
            finally:
                benchmarker.STATISTICS = bkup

    def test__setup(self):
        pass

    def test___enter__(self):
        bm = self.bm
        ret = bm.__enter__()
        with spec("prints platform information."):
            s = _get_output()
            lines = s.splitlines()
            ok (lines[0]).matches(r'## benchmarker:')
            ok (lines[1]).matches(r'## python platform:')
            ok (lines[2]).matches(r'## python version:')
            ok (lines[3]).matches(r'## python executable:')
        with spec("returns self."):
            ok (ret).is_(bm)

    def test___exit__(self):
        bm = self.bm
        bm.results = [
            Result('Haruhi')._set(1.50, 2.50, 3.50, 4.50),
            Result('Mikuru')._set(1.75, 2.75, 3.75, 4.75),
            Result('Yuki'  )._set(1.25, 2.25, 3.25, 4.25),
        ]
        bm.__exit__()
        s = _get_output()
        with spec("prints separator and ranking."):
            expected = r"""
## Ranking                         real
Yuki                             4.2500 (100.0%) *************************
Haruhi                           4.5000 ( 94.4%) ************************
Mikuru                           4.7500 ( 89.5%) **********************
"""
            ok (s.startswith(expected)) == True
        with spec("prints separator and ratio matrix."):
            expected = r"""

## Ratio Matrix                    real    [01]    [02]    [03]
[01] Yuki                        4.2500  100.0%  105.9%  111.8%
[02] Haruhi                      4.5000   94.4%  100.0%  105.6%
[03] Mikuru                      4.7500   89.5%   94.7%  100.0%
"""
            ok (s.endswith(expected)) == True

    def test___iter__(self):
        bm = self.bm
        bm.results = [ Result('')._set(0.0, 0.0, 0.0, 0.1) ]
        with spec("emulates with-statement."):
            tr = Tracer()
            tr.trace_method(bm, '__enter__', '__exit__')
            for x in bm:
                ok (len(tr)) == 1
                ok (tr[0]) == [bm, '__enter__', (), {}, bm]
            ok (len(tr)) == 2
            ok (tr[1]) == [bm, '__exit__', (None, None, None), {}, None]
            ok (x).is_(bm)

    def test___call__(self):
        bm = Benchmarker(loop=10)
        assert bm.results == []
        ret = bm('SOS')
        with spec("prints section title if called at the first time."):
            s = _get_output()
            ok (s) == '\n##                                 user       sys     total      real\n'
        with spec("creates new Result object and saves it."):
            ok (len(bm.results)) == 1
            ok (bm.results[0]).is_a(Result)
            ok (bm.results[0].label) == "SOS"
        with spec("returns Task object with Result object."):
            ok (ret).is_a(Task)
            ok (ret.result).is_(bm.results[0])
            ok (ret.loop) == 10
            ok (ret._empty) == None
        with spec("passes current empty result to task object."):
            dummy = Result('dummy')
            bm._current_empty_result = dummy
            task = bm('TPDD')
            ok (task._empty).is_(dummy)

    def test_empty(self):
        bm = self.bm
        assert bm._current_empty_result == None
        ret = bm.empty()
        with spec("returns a Task object."):
            ok (ret).is_a(Task)
        with spec("creates a task for empty loop and keeps it."):
            ok (ret.result.label) == '(Empty)'
            ok (bm._current_empty_result).is_(ret.result)
        with spec("created task should not be included in self.results."):
            not_ok (ret.result).in_(bm.results)

    def test_repeat(self):
        bm = self.bm
        echo = benchmarker.echo
        assert echo != benchmarker.echo_error
        with spec("replaces 'echo' object to stderr temporarily if verbose."):
            bm.verbose = True
            for _ in bm.repeat(1):
                not_ok (benchmarker.echo).is_(echo)
                ok (benchmarker.echo).is_(benchmarker.echo_error)
            ok (benchmarker.echo).is_(echo)
        with spec("replaces 'echo' object to dummy I/O temporarily if not verbose."):
            bm.verbose = False
            for _ in bm.repeat(1):
                not_ok (benchmarker.echo).is_(echo)
                not_ok (benchmarker.echo).is_(benchmarker.echo_error)
                ok (benchmarker.echo).is_a(Echo)
            ok (benchmarker.echo).is_(echo)
        with spec("invokes block for 'ntimes + 2*extra' times."):
            i = 0
            for _ in bm.repeat(5, 2):
                i += 1
                ok (_) == i
            ok (i) == 5 + 2*2
        with spec("resets some properties for each repetition."):
            tr = Tracer()
            tr.trace_method(bm, '_setup')
            for _ in bm.repeat(3):
                pass
            ok (tr[0]) == [bm, '_setup', ("## (#1)",), {}, None]
            ok (tr[1]) == [bm, '_setup', ("## (#2)",), {}, None]
            ok (tr[2]) == [bm, '_setup', ("## (#3)",), {}, None]
        with spec("keeps all results."):
            bm2 = Benchmarker(verbose=False)
            for _ in bm2.repeat(3):
                bm2('SOS')
            ok (len(bm2.all_results)) == 3
            for results in bm2.all_results:
                ok (results).is_a(list)
                ok (len(results)) == 1
                ok (results[0]).is_a(Result)
        with spec("restores 'echo' object after block."):
            tmp = benchmarker.echo
            for _ in bm.repeat(1):
                ok (benchmarker.echo) != tmp
            ok (benchmarker.echo) == tmp
        #
        bm2 = Benchmarker()
        tr = Tracer()
        tr.trace_method(bm2, '_calc_average_results', '_echo_average_section')
        extra = 5
        for _ in bm2.repeat(100, extra):
            pass
        with spec("calculates average of results."):
            ok (tr[0].list()) == [bm2, '_calc_average_results', (bm2.all_results, extra), {}, []]
        with spec("prints averaged results."):
            ok (tr[1]) == [bm2, '_echo_average_section', (bm2.results, extra, len(bm2.all_results)), {}, None]

    def test__calc_average_results(self):
        bm = self.bm
        all_results = [
            [Result('Haruhi')._set(1.50, 2.50, 3.50, 4.50),
             Result('Sasaki')._set(1.25, 2.25, 3.25, 4.25),],
            [Result('Haruhi')._set(1.25, 2.25, 3.25, 4.25),
             Result('Sasaki')._set(1.75, 2.75, 3.75, 4.75),],
        ]
        bm.all_results = all_results
        #
        tr = Tracer()
        tr.trace_method(bm, '_remove_min_and_max')
        #
        extra = 0
        avg_results0 = bm._calc_average_results(all_results, extra)
        output0 = _get_output()
        tr_len0 = len(tr)
        extra = 1
        avg_results1 = bm._calc_average_results(all_results, extra)
        output1 = _get_output()
        tr_len1 = len(tr)
        #
        with spec("prints min-max section title if extra is specified."):
            expected = r"^\n## Remove min & max *min *repeat *max *repeat\n"
            ok (output0) == ""             # when extra == 0
            ok (output1).matches(expected) # when extra != 1
        with spec("calculates average of results and returns it."):
            ok (repr(avg_results0[0])) == "<Result label='Haruhi' user=1.375 sys=2.375 total=3.375 real=4.375>"
            ok (repr(avg_results0[1])) == "<Result label='Sasaki' user=1.500 sys=2.500 total=3.500 real=4.500>"
        with spec("prints min-max section if extra is specified."):
            ok (tr_len0) == 0   # not called when extra == 0
            ok (tr_len1) == 2   # called when extra == 1
            ok (tr[0].name) == '_remove_min_and_max'
            ok (tr[1].name) == '_remove_min_and_max'

    def test__echo_average_section(self):
        bm = Benchmarker()
        avg_results = [
            Result('Haruhi')._set(1.50, 2.50, 3.50, 4.50),
            Result('Mikuru')._set(1.25, 2.25, 3.25, 4.25),
            Result('Yuki')  ._set(1.00, 2.00, 3.00, 4.00),
        ]
        def f(bm, *args):
            sio = _set_output()
            bm._echo_average_section(*args)
            return sio.getvalue()
        with spec("prints average section title."):
            extra = 0
            output = f(bm, avg_results, extra, 5)
            ok (output).matches(r'\n## Average of 5 *user *sys *total *real\n')
            extra = 2
            output = f(bm, avg_results, extra, 5)
            ok (output).matches(r'\n## Average of 1 \(=5-2\*2\) *user *sys *total *real\n')
        with spec("prints averaged results."):
            extra = 0
            output = f(bm, avg_results, extra, 5)
            ok (output) == r"""
## Average of 5                    user       sys     total      real
Haruhi                           1.5000    2.5000    3.5000    4.5000
Mikuru                           1.2500    2.2500    3.2500    4.2500
Yuki                             1.0000    2.0000    3.0000    4.0000
"""
            extra = 2
            output = f(bm, avg_results, extra, 5)
            ok (output) == r"""
## Average of 1 (=5-2*2)           user       sys     total      real
Haruhi                           1.5000    2.5000    3.5000    4.5000
Mikuru                           1.2500    2.2500    3.2500    4.2500
Yuki                             1.0000    2.0000    3.0000    4.0000
"""

    def test__remove_min_and_max(self):
        bm = Benchmarker()
        r1 = Result('SOS')._set(1.00, 2.00, 3.00, 4.00)   # min2
        r2 = Result('SOS')._set(1.25, 2.25, 3.25, 4.25)
        r3 = Result('SOS')._set(1.75, 2.75, 3.75, 4.75)   # max2
        r4 = Result('SOS')._set(1.50, 2.50, 3.50, 3.99)   # min1
        r5 = Result('SOS')._set(1.50, 2.50, 3.50, 4.50)
        r6 = Result('SOS')._set(1.50, 2.50, 3.50, 4.99)   # max1
        result_list = [r1, r2, r3, r4, r5, r6]
        # extra == 1
        def f(extra):
            sio = _set_output()
            results = bm._remove_min_and_max(result_list, extra)
            return results, sio.getvalue()
        results1, output1 = f(1)
        results2, output2 = f(2)
        with spec("removes min and max result."):
            ok (results1) == [r1, r2, r3, r5]
            ok (results2) == [r2, r5]
        with spec("prints removed data."):
            ok (output1) == "SOS                              3.9900      (#4)    4.9900      (#6)\n"
            ok (output2) == "SOS                              3.9900      (#4)    4.9900      (#6)\n" \
                          + "                                 4.0000      (#1)    4.7500      (#3)\n"
        with spec("returns new results."):
            ok (results1) != result_list
            ok (results2) != result_list

    def test_run(self):
        bm = Benchmarker()
        def foo(n):
            """an example"""
            n = n + 1
        def bar(n):
            n = n + 1
        with spec("uses func doc string or name as label."):
            task = bm.run(foo, 123)
            ok (task.result.label) == "an example"
            task = bm.run(bar, 123)
            ok (task.result.label) == 'bar'
        with spec("same as 'self.__call__(label).run(func)'."):
            pass

    def test_platform(self):
        bm = Benchmarker()
        with spec("returns platform information."):
            lines = bm.platform().splitlines()
            ok (lines[0]).matches(r'## benchmarker:       ')
            ok (lines[1]).matches(r'## python platform:   ')
            ok (lines[2]).matches(r'## python version:    ')
            ok (lines[3]).matches(r'## python executable: ')
        #
        ok (bm.platform()) == Benchmarker.platform()

    def test_FUNC_with_statement(self):
        expected1 = r"""
## benchmarker:       release \d\.\d\.\d \(for python\)
## python platform:   .*
## python version:    .*
## python executable: .*

##                                 user       sys     total      real
bench\d                           0\.000\d    0\.000\d    0\.000\d    0\.000\d
bench\d                           0\.000\d    0\.000\d    0\.000\d    0\.000\d

## Ranking                         real
bench\d                           0\.00\d\d \(100.0%\) \*+
bench\d                           0\.00\d\d \( *\d+.\d+%\) \*+

## Ratio Matrix                    real    \[01\]    \[02\]
\[01\] bench\d                      0\.00\d\d  100\.0%  *\d+\.\d%
\[02\] bench\d                      0\.00\d\d  *\d+\.\d%  100\.0%
"""[1:]
        with spec(""):
            with Benchmarker() as bm:
                with bm('bench8'):
                    x = 1
                with bm('bench9'):
                    x = 2
            actual = _get_output()
            ok (actual).matches(expected1)


class Result_TC(object):

    def before(self):
        self.result = Result("SOS")
        self.result._set(1.5, 2.5, 3.5, 4.5)

    def test___init__(self):
        with spec("takes label argument."):
            r = Result("SOS")
            ok (r.label) == "SOS"

    def test__set(self):
        r = Result("SOS")
        with spec("sets times values as attributes."):
            r._set(1.5, 2.5, 3.5, 4.5)
            ok (r.user)  == 1.5
            ok (r.sys)   == 2.5
            ok (r.total) == 3.5
            ok (r.real)  == 4.5
        with spec("returns self."):
            ret = r._set(1.5, 2.5, 3.5, 4.5)
            ok (ret).is_(r)

    def test___repr__(self):
        r = self.result
        with spec("returns represented string."):
            ok (repr(r)) == "<Result label='SOS' user=1.500 sys=2.500 total=3.500 real=4.500>"

    def test_to_tuple(self):
        r = self.result
        with spec("returns a tuple with times."):
            ok (r.to_tuple()) == (1.5, 2.5, 3.5, 4.5)

    def test_average(self):
        results = [
            Result('SOS')._set(1.00, 2.00, 3.00, 4.00),
            Result('SOS')._set(1.25, 2.25, 3.25, 4.25),
            Result('SOS')._set(1.75, 2.75, 3.75, 4.75),
            Result('SOS')._set(1.50, 2.50, 3.50, 4.50),
        ]
        avg = Result.average(results)
        with spec("returns averaged result."):
            ok (avg).is_a(Result)
        with spec("calculates averaged result from results."):
            ok (avg.user)  == 1.375
            ok (avg.sys)   == 2.375
            ok (avg.total) == 3.375
            ok (avg.real)  == 4.375


class Task_TC(object):

    def before(self):
        self._echo_bkup = benchmarker.echo
        benchmarker.echo = Echo.create_dummy()

    def after(self):
        benchmarker.echo = self._echo_bkup

    def test___init__(self):
        with spec("takes a Result object, loop, and _empty result."):
            result = Result("SOS")
            loop = 10
            _empty = Result("(Empty)")
            t = Task(result, loop, _empty)
            ok (t.result) == result
            ok (t.loop)   == loop
            ok (t._empty) == _empty

    def _new_task(self, label="SOS", loop=1, require_empty=False):
        result = Result(label)
        _empty = require_empty and Result("(Empty)") or None
        return Task(result, loop, _empty)

    def test___enter__(self):
        t = self._new_task("SOS")
        try:
            tr = Tracer()
            fake = tr.fake_obj(collect=None)
            gc = benchmarker.gc
            benchmarker.gc = fake
            ret = t.__enter__()
        finally:
            benchmarker.gc = gc
        with spec("prints task label."):
            s = _get_output()
            ok (s) == "SOS                           "
        with spec("starts full-GC."):
            ok (tr[0]) == [fake, 'collect', (), {}, None]
        with spec("saves current timestamp."):
            ok (t._times).is_a(tuple)
            ok (t._time).is_a(float)
        with spec("returns self."):
            ok (ret).is_(t)

    def test___exit__(self):
        def f(task):
            try:
                _time_time = benchmarker._time_time
                _os_times  = benchmarker._os_times
                benchmarker._time_time = lambda: 1.75
                benchmarker._os_times  = lambda: (1.25, 2.25, )
                task._time  = 1.00
                task._times = (1.00, 1.50, )
                task.__exit__(*sys.exc_info())
            finally:
                benchmarker._time_time = _time_time
                benchmarker._os_times  = _os_times
        with spec("calculates user, sys, total and real times."):
            task = self._new_task("SOS")
            f(task)
            r = task.result
            ok (r.user)  == 1.25 - 1.00
            ok (r.sys)   == 2.25 - 1.50
            ok (r.total) == r.user + r.sys
            ok (r.real)  == 1.75 - 1.00
        with spec("removes empty loop data if they are specified."):
            task = self._new_task("SOS")
            task._empty = Result("(Empty)")._set(0.25, 0.25, 0.50, 0.25)
            f(task)
            r = task.result
            ok (r.user)  == 1.25 - 1.00     - 0.25
            ok (r.sys)   == 2.25 - 1.50     - 0.25
            ok (r.total) == (1.25 - 1.00) + (2.25 - 1.50) - 0.50
            ok (r.real)  == 1.75 - 1.00     - 0.25
        with spec("prints times."):
            expected = r"""
   0.2500    0.7500    1.0000    0.7500
   0.0000    0.5000    0.5000    0.5000
"""[1:]
            s = _get_output()
            ok (s) == expected

    def test_run(self):
        loop = 3
        task = self._new_task("SOS", 3)
        tr = Tracer()
        tr.trace_method(task, '__enter__', '__exit__')
        count = [0]
        args  = [None]
        def foo(*a):
            args[0] = a
            count[0] += 1
        ret = task.run(foo, 123, 456)
        with spec("calls __enter__() to simulate with-statement."):
            ok (tr[0]) == [task, '__enter__', (), {}, task]
        with spec("calls function with arguments."):
            ok (args[0]) == (123, 456)
        with spec("calls functions N times if 'loop' is specified."):
            ok (count[0]) == loop
        with spec("calls __exit__() to simulate with-statement."):
            ok (tr[1]) == [task, '__exit__', (None, None, None), {}, None]
        with spec("returns self."):
            ok (ret).is_(task)

    def test___iter__(self):
        loop = 3
        task = self._new_task("SOS", 3)
        tr = Tracer()
        tr.trace_method(task, '__enter__', '__exit__')
        count = 0
        for _ in task:
            count += 1
            ok (_) == count - 1
        with spec("calls __enter__() to simulate with-statement."):
            ok (tr[0]) == [task, '__enter__', (), {}, task]
        with spec("executes block for N times if 'loop' is specified."):
            ok (count) == 3
        with spec("executes block only once if 'loop' is not specified.."):
            pass
        with spec("calls __exit__() to simulate with-statement."):
            ok (tr[1]) == [task, '__exit__', (None, None, None), {}, None]


class Statistics_TC(object):

    r1 = Result('Haruhi' )._set(1.25, 2.25, 3.25, 4.25)
    r2 = Result('Mikuru' )._set(1.75, 2.75, 3.75, 4.75)
    r3 = Result('Yuki'   )._set(1.00, 2.00, 3.00, 4.00)
    r4 = Result('Tsuruya')._set(1.50, 2.50, 3.50, 4.50)
    results = [r1, r2, r3, r4]

    def before(self):
        self.stats = Statistics()

    def test__sorted(self):
        ret = self.stats._sorted(self.results)
        with spec("not modify passed results."):
            ok (ret) != self.results
        with spec("returns sorted results."):
            ok (ret) == [self.r3, self.r1, self.r4, self.r2]

    def test_ranking(self):
        expected = r"""
## Ranking                         real
Yuki                             4.0000 (100.0%) *************************
Haruhi                           4.2500 ( 94.1%) ************************
Tsuruya                          4.5000 ( 88.9%) **********************
Mikuru                           4.7500 ( 84.2%) *********************
"""[1:]
        with spec("returns ranking as string."):
            ret = self.stats.ranking(self.results)
            ok (ret) == expected

    def test_ratio_matrix(self):
        expected = r"""
## Ratio Matrix                    real    [01]    [02]    [03]    [04]
[01] Yuki                        4.0000  100.0%  106.2%  112.5%  118.8%
[02] Haruhi                      4.2500   94.1%  100.0%  105.9%  111.8%
[03] Tsuruya                     4.5000   88.9%   94.4%  100.0%  105.6%
[04] Mikuru                      4.7500   84.2%   89.5%   94.7%  100.0%
"""[1:]
        with spec("returns ratio matrix as string."):
            ret = self.stats.ratio_matrix(self.results)
            ok (ret) == expected


class CommandOption_TC(object):

    def before(self):
        cmdopt = CommandOption()
        cmdopt._user_option_dict['haruhi'] = 'Haruhi Suzumiya'
        cmdopt._user_option_dict['mikuru'] = 'Mikuru Asahina'
        cmdopt._user_option_dict['yuki']   = 'Nagato Yuki'
        self.cmdopt = cmdopt

    def test___getitem__(self):
        cmdopt = self.cmdopt
        with spec("returns user option value if exists."):
            ok (cmdopt['haruhi']) == 'Haruhi Suzumiya'
        with spec("returns None if not exist."):
            ok (cmdopt['kyon']) == None

    def test___setitem__(self):
        cmdopt = self.cmdopt
        with spec("sets user option value."):
            k, v = 'itsuki', 'Itsuki Koizumi'
            cmdopt[k] = v
            ok (cmdopt[k]) == v

    def test_get(self):
        cmdopt = self.cmdopt
        with spec("returns user option value if exists."):
            ok (cmdopt.get('mikuru')) == 'Mikuru Asahina'
        with spec("returns default value if not exist."):
            ok (cmdopt.get('itsuki')) == None
            ok (cmdopt.get('itsuki', 'Koizumi')) == 'Koizumi'

    def test__new_option_parser(self):
        cmdopt = self.cmdopt
        with spec("returns an OptionParser object."):
            import optparse
            parser = cmdopt._new_option_parser()
            ok (parser).is_a(optparse.OptionParser)

    def test__separate_user_options(self):
        cmdopt = self.cmdopt
        with spec("separates args which starts with '--' from argv."):
            argv = ['foo.py', '-h', '--k', 'arg1', '--k=v']
            new_argv, user_options = cmdopt._separate_user_options(argv)
            ok (new_argv) == ['foo.py', '-h', 'arg1']
            ok (user_options) == ['--k', '--k=v']

    def test__populate_opts(self):
        cmdopt = self.cmdopt
        opts = Tracer().fake_obj()
        opts.__dict__.update(dict(quiet=True, loop=3, repeat=5, extra=1, exclude=True))
        with spec("sets attributes according to options."):
            cmdopt._populate_opts(opts)
            ok (cmdopt.verbose) == False
            ok (cmdopt.loop)    == 3
            ok (cmdopt.repeat)  == 5
            ok (cmdopt.extra)   == 1
            ok (cmdopt.exclude) == True

    def test__parse_user_options(self):
        cmdopt = self.cmdopt
        with spec("raises ValueError if user option is invalid format."):
            def f(): cmdopt._parse_user_options(['--sos[]'])
            ok (f).raises(ValueError, "--sos[]: invalid format user option.")
        with spec("if value is not specified then uses True instead."):
            d = cmdopt._parse_user_options(['--sos'])
            ok (d) == {'sos': True}
        with spec("returns a dictionary object."):
            d = cmdopt._parse_user_options(['--sos', '--h=haruhi', '--kyon='])
            ok (d) == {'sos': True, 'h': 'haruhi', 'kyon': ''}

    def test__help_message(self):
        cmdopt = self.cmdopt
        expected = r'''
Usage: benchmarker_test.py [options] [labels...]

Options:
  -h, --help     show help
  -v, --version  show version
  -q             quiet (not verbose)    # same as Benchmarker(verbose=False)
  -n N           loop each benchmark    # same as Benchmarker(loop=N)
  -r N           repeat all benchmarks  # same as bm.repeat(N)
  -e N           ignore N of min/max    # same as bm.repeat(extra=N)
  -x             do all benchmarks except benchmarks specified by args
  --name[=val]   user-defined option
                 ex.
                     # get value of user-defined option
                     from benchmarker import cmdopt
                     print(repr(cmdopt['name']))  #=> 'val'
'''[1:]
        with spec("returns help message."):
            parser = cmdopt._new_option_parser()
            ok (cmdopt._help_message(parser)) == expected

    def test_parse(self):
        with spec("uses sys.argv when argv is not specified."):
            pass
        with spec("parses command line options and sets attributes."):
            cmdopt = CommandOption()
            cmdopt.parse(['foo.py', '-qn100', '-r', '9', '--k1', '--k2=v2', '--k3=', 'foo', 'b*'])
            ok (cmdopt.verbose) == False
            ok (cmdopt.loop) == 100
            ok (cmdopt.repeat) == 9
            ok (cmdopt.exclude) == None
            ok (cmdopt['k1']) == True
            ok (cmdopt['k2']) == 'v2'
            ok (cmdopt['k3']) == ''
            #
            ok (cmdopt.should_skip('foo')) == False
            ok (cmdopt.should_skip('bar')) == False
            ok (cmdopt.should_skip('goo')) == True
            #
            cmdopt = CommandOption()
            cmdopt.parse(['foo.py', '-x', 'foo', 'b*'])
            ok (cmdopt.should_skip('foo')) == True
            ok (cmdopt.should_skip('bar')) == True
            ok (cmdopt.should_skip('goo')) == False
        with spec("if '-h' or '--help' specified then print help message and exit."):
            cmdopt = CommandOption()
            expected = cmdopt._help_message() + "\n"
            with dummy_io():
                def f(): CommandOption().parse(['foo.py', '-h'])
                ok (f).raises(SystemExit)
                ok (sys.stdout.getvalue()) == expected
            with dummy_io():
                def f(): CommandOption().parse(['foo.py', '--help'])
                ok (f).raises(SystemExit)
                ok (sys.stdout.getvalue()) == expected
        with spec("if '-v' or '--version' specified then print version and exit."):
            expected = benchmarker.__version__ + "\n"
            with dummy_io():
                def f(): CommandOption().parse(['foo.py', '-v'])
                ok (f).raises(SystemExit)
                ok (sys.stdout.getvalue()) == expected
            with dummy_io():
                def f(): CommandOption().parse(['foo.py', '--version'])
                ok (f).raises(SystemExit)
                ok (sys.stdout.getvalue()) == expected

    def test_should_skip(self):
        cmdopt = self.cmdopt
        with spec("returns False if no labels specified in command-line."):
            c = CommandOption()
            c.parse(['foo.py',])
            ok (c.should_skip('sos')) == False
        with spec("returns False if task is for empty loop."):
            c = CommandOption()
            c.parse(['foo.py', '(Empty)'])
            ok (c.should_skip('(Empty)')) == False
        with spec("when '-x' specified in command-line..."):
            c = CommandOption()
            c.parse(['foo.py', '-x', 'sasaki',])
            with spec("returns True (should skip) if label found in command-line."):
                ok (c.should_skip('sasaki')) == True
            with spec("returns False (should not skip) if label not found in command-line."):
                ok (c.should_skip('kyon')) == False
        with spec("when '-x' not specified in command-line..."):
            c = CommandOption()
            c.parse(['foo.py', 'sasaki',])
            with spec("returns False (should not skip) if label found in command-line."):
                ok (c.should_skip('sasaki')) == False
            with spec("returns True (should skip) if label not found in command-line."):
                ok (c.should_skip('kyon')) == True


class GlobalFunctions_TC(object):

    def test__meta2rexp(self):
        _meta2rexp = benchmarker._meta2rexp
        with spec("converts a string containing metacharacters into regexp."):
            ok (_meta2rexp('sos')) == r'^sos$'
        with spec("converts '*' into '.*'."):
            ok (_meta2rexp('sos*')) == r'^sos.*$'
        with spec("converts '?' into '.'."):
            ok (_meta2rexp('sos?')) == r'^sos.$'
        with spec("converts '{aa,bb,(cc)}' into '(aa|bb|\(cc\))'."):
            ok (_meta2rexp('sos{aa,bb,(cc)}')) == r'^sos(aa|bb|\(cc\))$'
        with spec("escapes characters with re.escape()."):
            ok (_meta2rexp('.+-()[]')) == r'^\.\+\-\(\)\[\]$'



if __name__ == '__main__':
    run()
