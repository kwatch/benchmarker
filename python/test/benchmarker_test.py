###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

from __future__ import with_statement

import sys, os, re
_ = os.path.dirname
sys.path.append(_(_(__file__)))

from oktest import ok, not_ok, run, spec
from oktest.helper import dummy_io, Interceptor
import benchmarker
from benchmarker import Benchmarker
try:
    from cStringIO import StringIO    # Python 2.x
except ImportError:
    from io import StringIO           # Python 3.x



from benchmarker import Reporter, Result, Task, Benchmark, Runner, Stat


import types

class DummyObject(object):

    class Result(object):
        def __init__(self, name, args, kwargs, ret=None):
            self.name = name
            self.args = args
            self.kwargs = kwargs
            self.ret = ret

    def __init__(self, **kwargs):
        self._results = []
        for name in kwargs:
            setattr(self, name, self.__new_method(name, kwargs[name]))

    def __nonzero__(self):
        return True

    def __len__(self):
        return len(self._results)

    def __getitem__(self, index):
        return self._results[index]

    def __new_method(self, name, val):
        results = self._results
        if isinstance(val, types.FunctionType):
            func = val
            def f(self, *args, **kwargs):
                r = DummyObject.Result(name, args, kwargs, None)
                results.append(r)
                r.ret = func(self, *args, **kwargs)
                return r.ret
        else:
            def f(self, *args, **kwargs):
                r = DummyObject.Result(name, args, kwargs, val)
                results.append(r)
                return val
        f.func_name = f.__name__ = name
        return types.MethodType(f, self, self.__class__)



class ReporterTest(object):


    def test___init__(self):
        with spec("if verbose mode is off then use dummy io for verbose output."):
            r = Reporter()
            ok (r.vout) == sys.stderr
            r = Reporter(verbose=False)
            ok (r.vout).is_a(type(StringIO()))


    def test_start_verbose_mode(self):
        with spec("switch output stream for verbose mode."):
            r = Reporter()
            out, vout = r.out, r.vout
            r.start_verbose_mode()
            ok (r.out).is_(r.vout)


    def test_stop_verbose_mode(self):
        with spec("switch back output stream for normal mode."):
            r = Reporter()
            out, vout = r.out, r.vout
            r.start_verbose_mode()
            assert r.out is vout
            r.stop_verbose_mode()
            ok (r.out).is_(out)


    def test_write(self):
        sout, serr = StringIO(), StringIO()
        r = Reporter(out=sout, vout=serr)
        r.prev_is_separator = True
        ret = r.write("Nyoroon")
        with spec("write argument into output stream."):
            ok (sout.getvalue()) == "Nyoroon"
            ok (serr.getvalue()) == ""
        with spec("clear prev_is_separator flag."):
            # falldown
            ok (r.prev_is_separator) == False
        with spec("return self."):
            # falldown
            ok (ret).is_(r)


    def test_flush(self):
        with spec("if output stream can respond to 'flush()' then call it."):
            sout = DummyObject()
            r = Reporter(out=sout)
            not_ok (lambda: r.flush()).raises(Exception)
            arr = [False]
            def f():
                arr[0] = True
            sout.flush = f
            r.flush()
            ok (arr[0]) == True


    def test_print_header(self):
        with spec("print header title and items."):
            r = Reporter(out=StringIO())
            r.print_header('SOS')
            ok (r.out.getvalue()) == "## SOS                              user       sys     total      real\n"


    def test_print_label(self):
        buf = []
        def write(self, x):
            buf.append(x)
        arr = [False]
        def flush(self, ):
            arr[0] = True
        out = DummyObject(write=write, flush=flush)
        with spec("print benchmark label."):
            r = Reporter(out=out)
            r.print_label('sos')
            ok (buf) == ["%-30s" % "sos"]
        with spec("flush output stream."):
            # falldown
            ok (arr[0]) == True


    def test_print_times(self):
        with spec("print benchmark times."):
            pass
        with spec("print separator if prev is not separator."):
            pass



class ResultTest(object):


    def test___isub__(self):
        with spec("subtract values."):
            r1 = Result('foo', 10.0, 20.0, 30.0, 40.0)
            r2 = Result('bar', 1.0, 2.0, 3.0, 4.0)
            r1 -= r2
            ok ([r1.label, r1.user, r1.sys, r1.total, r1.real]) == ['foo', 9.0, 18.0, 27.0, 36.0]
            ok ([r2.label, r2.user, r2.sys, r2.total, r2.real]) == ['bar', 1.0, 2.0, 3.0, 4.0]


    def test_average(self):
        r1 = Result('foo', 1.0, 2.0, 3.0, 4.0)
        r2 = Result('foo', 2.0, 3.0, 4.0, 5.0)
        r3 = Result('foo', 3.0, 4.0, 5.0, 6.0)
        r4 = Result('foo', 4.0, 5.0, 6.0, 7.0)
        r5 = Result('foo', 5.0, 6.0, 7.0, 8.0)
        r = Result.average([r1, r2, r3, r4, r5])
        with spec("return new Result object."):
            ok (r).is_a(Result)
        with spec("calculate average of results."):
            ok (r.label) == 'foo'
            ok (r.user)  == 3.0
            ok (r.sys)   == 4.0
            ok (r.total) == 5.0
            ok (r.real)  == 6.0



class TaskTest(object):


    def test___enter__(self):
        benchmark = Benchmark(None, None)
        intr = Interceptor()
        intr.intercept(benchmark, _started=lambda self, x: x)
        task = Task(benchmark, "label1")
        ret = task.__enter__()
        with spec("call benchmark._started()."):
            ok (intr[0].name) == '_started'
            ok (intr[0].args) == (task, )
        with spec("start to record times."):
            ok (task._start_t).is_a(float)
            ok (task._t1).is_a(tuple)
        with spec("return self."):
            ok (ret).is_(task)


    def test___exit__(self):
        benchmark = DummyObject(_started=None, _stopped=None)
        task = Task(benchmark, "label1")
        task.__enter__()
        ret = task.__exit__(*sys.exc_info())
        _results = benchmark._results
        with spec("call benchmark._stopped() with Result object."):
            ok (len(_results)) == 2
            ok (_results[0].name) == '_started'
            ok (_results[1].name) == '_stopped'
            ok (_results[1].args[0]) == task
            ok (_results[1].args[1]).is_a(Result)
        with spec("record end times."):
            result = _results[1].args[1]
            ok (result.label) == "label1"
            ok (result.user ).is_a(float)
            ok (result.sys  ).is_a(float)
            ok (result.total).is_a(float)
            ok (result.real ).is_a(float)
        with spec("return None"):
            ok (ret) == None


    def test_run(self):
        benchmark = DummyObject(_started=None, _stopped=None)
        task = Task(benchmark, label=None)
        intr = Interceptor()
        intr.intercept(task, '__enter__', '__exit__')
        args = []
        def hello(arg1, arg2):
            args.append(arg1)
            args.append(arg2)
            return 'sos'
        ret = task.run(hello, "foo", 123)
        with spec("if label is not specified then use function name as label."):
            ok (task.label) == "hello"
        with spec("simulate with-statement."):
            ok (args) == ["foo", 123]
            ok (intr[0].name) == '__enter__'
            ok (intr[1].name) == '__exit__'
        with spec("return the return value of func."):
            ok (ret) == 'sos'



class BenchmarkTest(object):


    def before(self):
        reporter = DummyObject(write=None, print_header=None, print_label=None, print_times=None)
        self.benchmark = Benchmark(reporter)


    def test_bench(self):
        with spec("return new Task object."):
            ret = self.benchmark.bench("sos")
            ok (ret).is_a(Task)
            ok (ret.benchmark).is_(self.benchmark)
            ok (ret.label) == "sos"


    def test__call__(self):
        with spec("return new Task object."):
            ret = self.benchmark("sos")
            ok (ret).is_a(Task)
            ok (ret.benchmark).is_(self.benchmark)
            ok (ret.label) == "sos"


    def test_empty(self):
        obj = self.benchmark.empty()
        with spec("create new Task object and keep it."):
            ok (self.benchmark._empty_task).is_(obj)
        with spec("return Task object."):
            ok (obj).is_a(Task)
            ok (obj.label) == "(Empty)"


    def test_run(self):
        args = []
        def hello(*args_):
            args.extend(args_)
            return "!"
        with spec("same as self.bench(None).run(func, *args)."):
            ret = self.benchmark.run(hello, "sos", 123)
            ok (args) == ["sos", 123]
            ok (ret) == "!"


    def test__started(self):
        b = self.benchmark
        task1 = DummyObject()
        task1.label = "SOS"
        b._started(task1)
        task2 = DummyObject()
        task2.label = "SasakiDan"
        b._started(task2)
        _results = b.reporter._results
        with spec("print header only once."):
            ok (len(_results)) == 3
            ok (_results[0].name) == 'print_header'
            ok (_results[1].name) == 'print_label'
            ok (_results[2].name) == 'print_label'
        with spec("print label."):
            ok (_results[1].args) == ("SOS", )
            ok (_results[2].args) == ("SasakiDan", )


    def test__stopped(self):
        b = self.benchmark
        result = Result("(Empty)", 1.0, 2.0, 3.0, 4.0)
        with spec("if task is for empty loop then keep it."):
            task = b.empty()
            assert b._empty_task is task
            assert b._empty_result is None
            b._stopped(task, result)
            ok (b._empty_result).is_(result)
        with spec("if task is for normal benchmark..."):
            assert len(b.results) == 0
            task = b.bench("label1")
            result = Result("label1", 10.0, 20.0, 30.0, 40.0)
            b._stopped(task, result)
            with spec("keep result."):
                ok (len(b.results)) == 1
                ok (b.results[0]).is_a(Result)
            with spec("if empty loop result exists then substitute it from current result."):
                ok (b.results[0].user)  ==  9.0
                ok (b.results[0].sys)   == 18.0
                ok (b.results[0].total) == 27.0
                ok (b.results[0].real)  == 36.0
        with spec("print benchmark result."):
            results = b.reporter._results
            ok (results[0].name) == 'print_times'
            ok (results[0].args) == (1.0, 2.0, 3.0, 4.0)
            ok (results[1].name) == 'print_times'
            ok (results[1].args) == (9.0, 18.0, 27.0, 36.0)



class RunnerTest(object):


    def before(self):
        def write(self, arg):
            self.out.write(arg)
            return self
        reporter = DummyObject(write=write, print_header=None, print_label=None, print_times=None)
        reporter.out = StringIO()
        reporter.fmt = "%9.4f"
        reporter.width = 30
        self.runner = Runner()
        self.runner.reporter = reporter
        self.runner.benchmark = Benchmark(reporter)


    def test__get_benchmark(self):
        runner = self.runner
        assert runner.results is None
        ret = runner._get_benchmark()
        with spec("return self.benchmark."):
            ok (ret).is_(runner.benchmark)
        with spec("if self.results is None then set self.benchmark.results to it."):
            # falldown
            ok (runner.results).is_(runner.benchmark.results)


    def test_bench(self):
        runner = self.runner
        with spec("same as self.benchmark.bench(label)."):
            ret = runner.bench("Haruhi")
            ok (ret).is_a(Task)
            ok (ret.label) == "Haruhi"


    def test___call__(self):
        runner = self.runner
        with spec("same as self.benchmark.bench(label)."):
            ret = runner("Haruhi")
            ok (ret).is_a(Task)
            ok (ret.label) == "Haruhi"


    def test_empty(self):
        runner = self.runner
        with spec("same as self.benchmark.empty(label)."):
            ret = runner.empty("Mikuru")
            ok (ret).is_a(Task)
            ok (ret.label) == "Mikuru"
            ok (runner.benchmark._empty_task).is_(ret)


    def test_run(self):
        intr = Interceptor()
        runner = self.runner
        intr.intercept(runner.benchmark, 'run')
        def hello(*args):
            pass
        with spec("same as self.benchmark.run(func, *args)."):
            runner.run(hello, 999, None)
            ok (intr[0].name) == 'run'
            ok (intr[0].args) == (hello, 999, None)


    def _results_fixture(self):
        return [
            Result("SOS", 1.0, 5.1, 3.2, 3.3),
            Result("SOS", 2.0, 4.1, 3.2, 4.3),
            Result("SOS", 3.0, 3.1, 3.2, 2.3),
            Result("SOS", 4.0, 2.1, 3.2, 1.3),
            Result("SOS", 5.0, 1.1, 3.2, 5.3),
        ]


    def test__minmax_values_and_indecies(self):
        with spec("search min and max values and indecies."):
            results = self._results_fixture()
            arr = self.runner._minmax_values_and_indecies(results, 'real', 2)
            ok (arr[0]) == (1.3, 3, 5.3, 4)
            ok (arr[1]) == (2.3, 2, 4.3, 1)


    def test__delete_minmax_from(self):
        with spec("return results without min and max results."):
            results = self._results_fixture()
            ret = self.runner._delete_minmax_from(results, 'real', 2, '%9.4f', '%-30s')
            ok (len(ret)) == 1
            ok (ret[0].real) == 3.3
        with spec("print min an max benchmarks."):
            # falldown
            ok (self.runner.reporter.out.getvalue()) == """
SOS                              1.3000        #4   5.3000        #5
                                 2.3000        #3   4.3000        #2
"""[1:]


    def test__average_results(self):
        with spec("calculate average of results."):
            #results = self._results_fixture()
            results = [
                Result("SOS", 1.0, 5.1, 3.2, 3.0),
                Result("SOS", 2.0, 4.1, 3.2, 4.3),
                Result("SOS", 3.0, 3.1, 3.2, 2.6),
                Result("SOS", 4.0, 2.1, 3.2, 1.3),
                Result("SOS", 5.0, 1.1, 3.2, 5.3),
            ]
            ret = self.runner._average_results([results], 'real', 1)
            ok (ret).is_a(list)
            ok (ret[0]).is_a(Result)
            ok (ret[0].user ).in_delta(2.0, 0.0001)
            ok (ret[0].sys  ).in_delta(4.1, 0.0001)
            ok (ret[0].total).in_delta(3.2, 0.0001)
            ok (ret[0].real ).in_delta(3.3, 0.0001)
            #
            _results = self.runner.reporter._results
            ok (_results[0].name) == 'print_header'
            ok (_results[0].args) == ('Remove min & max', )
            ok (self.runner.reporter.out.getvalue()) == """
SOS                               1.3000        #4    5.3000        #5
"""[1:]


    def test__print_results(self):
        results = [
            Result("Haruhi", 1.0, 2.0, 3.0, 4.0),
            Result("Mikuru", 1.1, 2.1, 3.1, 4.1),
            Result("Yuki",   1.2, 2.2, 3.2, 4.2),
        ]
        reporter = Reporter(out=StringIO())
        runner = Runner()
        runner.reporter = reporter
        with spec("print results."):
            runner._print_results(results, "SOS")
            ok (runner.reporter.out.getvalue()) == """
## SOS                              user       sys     total      real
Haruhi                            1.0000    2.0000    3.0000    4.0000
Mikuru                            1.1000    2.1000    3.1000    4.1000
Yuki                              1.2000    2.2000    3.2000    4.2000
"""[1:]



    def test_repeat(self):
        reporter = Reporter(out=StringIO(), vout=StringIO())
        runner = Runner()
        runner.reporter = reporter
        i = 0
        for b in runner.repeat(5, extra=1, key='real'):
            i += 1
            with spec("yield Benchmark object."):
                ok (b).is_a(Benchmark)
            with b.empty():
                pass
            with b('1+1'):
                x = 1 + 1
            with b('2+2'):
                x = 2 + 2
        with spec("repeat n + 2*extra times."):
            ok (i) == 5 + 2*1
            serr = reporter.vout.getvalue().replace('-0.', ' 0.')
            serr = re.sub(r'    #\d', '    #9', serr)
            serr = re.sub(r'0\.00\d\d', '0.0000', serr)
            s = """
## Benchmark #%s                     user       sys     total      real
(Empty)                           0.0000    0.0000    0.0000    0.0000
1+1                               0.0000    0.0000    0.0000    0.0000
2+2                               0.0000    0.0000    0.0000    0.0000

"""[1:]
            expected = ''.join([ s % i for i in xrange(1, 5+2*1+1) ])
            expected += """
## Remove min & max                  min    bench#       max    bench#
1+1                               0.0000        #9    0.0000        #9
2+2                               0.0000        #9    0.0000        #9

"""[1:]
            ok (serr) == expected
        with spec("calculate average."):
            sout = reporter.out.getvalue().replace('-0.', ' 0.')
            ok (sout) == """
## Average of 5 (=7-2*1)            user       sys     total      real
1+1                               0.0000    0.0000    0.0000    0.0000
2+2                               0.0000    0.0000    0.0000    0.0000
"""[1:]


    def test_platform(self):
        lines = self.runner.platform().splitlines(True)
        ok (lines[0].startswith('## benchmarker: '))       == True
        ok (lines[1].startswith('## python platform: '))   == True
        ok (lines[2].startswith('## python version: '))    == True
        ok (lines[3].startswith('## python executable: ')) == True


    def test_compared_matrix(self):
        runner = Benchmarker()
        runner.results = [
            Result("Mikuru", 1.1, 2.1, 3.1, 6.0),
            Result("Haruhi", 1.0, 2.0, 3.0, 4.0),
            Result("Yuki",   1.2, 2.2, 3.2, 5.0),
        ]
        ok (runner.compared_matrix()) == """
## Matrix                           real   [01]   [02]   [03]
[01] Haruhi                       4.0000    0.0   25.0   50.0
[02] Yuki                         5.0000  -20.0    0.0   20.0
[03] Mikuru                       6.0000  -33.3  -16.7    0.0
"""[1:]


    def test_print_compared_matrix(self):
        runner = Benchmarker(out=StringIO())
        runner.results = [
            Result("Mikuru", 1.1, 2.1, 3.1, 6.0),
            Result("Haruhi", 1.0, 2.0, 3.0, 4.0),
            Result("Yuki",   1.2, 2.2, 3.2, 5.0),
        ]
        runner.print_compared_matrix()
        ok (runner.reporter.out.getvalue()) == """
-------------------------------------------------------------------------------
## Matrix                           real   [01]   [02]   [03]
[01] Haruhi                       4.0000    0.0   25.0   50.0
[02] Yuki                         5.0000  -20.0    0.0   20.0
[03] Mikuru                       6.0000  -33.3  -16.7    0.0

"""[1:]



class StatTest(object):


    def before(self):
        self.bm = Benchmarker(out=StringIO())
        self.bm.results = [
            Result("Mikuru", 1.1, 2.1, 3.1, 6.0),
            Result("Haruhi", 1.0, 2.0, 3.0, 4.0),
            Result("Yuki",   1.2, 2.2, 3.2, 5.0),
        ]


    def test_ranking(self):
        ok (self.bm.stat.ranking()) == """
## Ranking                          real  ratio  chart
Haruhi                            4.0000 (100.0) ********************
Yuki                              5.0000 ( 80.0) ****************
Mikuru                            6.0000 ( 66.7) *************
"""[1:]


    def test_matrix(self):
        ok (self.bm.stat.matrix()) == """
## Matrix                           real   [01]   [02]   [03]
[01] Haruhi                       4.0000  100.0  125.0  150.0
[02] Yuki                         5.0000   80.0  100.0  120.0
[03] Mikuru                       6.0000   66.7   83.3  100.0
"""[1:]
        ok (self.bm.stat.matrix(compensate=-100.0)) == """
## Matrix                           real   [01]   [02]   [03]
[01] Haruhi                       4.0000    0.0   25.0   50.0
[02] Yuki                         5.0000  -20.0    0.0   20.0
[03] Mikuru                       6.0000  -33.3  -16.7    0.0
"""[1:]


    def test_all(self):
        ok (self.bm.stat.all()) == """

## Ranking                          real  ratio  chart
Haruhi                            4.0000 (100.0) ********************
Yuki                              5.0000 ( 80.0) ****************
Mikuru                            6.0000 ( 66.7) *************

## Matrix                           real   [01]   [02]   [03]
[01] Haruhi                       4.0000  100.0  125.0  150.0
[02] Yuki                         5.0000   80.0  100.0  120.0
[03] Mikuru                       6.0000   66.7   83.3  100.0
"""[1:]



class BenchmarkerTest(object):


    def test_Benchmarker(self):
        with spec("return Runner object."):
            bm = Benchmarker(25)
            ok (bm).is_a(Runner)
        with spec("create Runner, Reporter, Benchmarker, and Stat objects."):
            ok (bm.reporter).is_a(Reporter)
            ok (bm.benchmark).is_a(Benchmark)
            ok (bm.benchmark.reporter).is_(bm.reporter)
            ok (bm.stat).is_a(Stat)
            ok (bm.stat.runner).is_(bm)
        with spec("add 'width' argument into kwargs."):
            ok (bm.reporter.width) == 25



if __name__ == '__main__':
    run()
