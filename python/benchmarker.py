# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###


import sys, os, time, gc
try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO


__all__ = ('Benchmarker', )
__version__ = "$Release: 0.0.0 $".split(' ')[1]


python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3


import __builtin__
if not hasattr(__builtin__, 'xrange'):
    xrange = range



class Reporter(object):


    ## default values
    out     = sys.stdout
    width   = 30
    fmt     = "%9.4f"
    header  = " %9s %9s %9s %9s" % ('user', 'sys', 'total', 'real')
    verbose = True
    vout    = sys.stderr
    sep     = "\n"


    def __init__(self, **kwargs):
        for k in ('out', 'width', 'fmt', 'header','verbose', 'vout'):
            if k in kwargs:
                setattr(self, k, kwargs[k])
        #: if verbose mode is off then use dummy io for verbose output.
        if not self.verbose:
            self.vout = StringIO()
        self.prev_is_separator = None


    def start_verbose_mode(self):
        #: switch output stream for verbose mode.
        self.__out = self.out
        self.out = self.vout


    def stop_verbose_mode(self):
        #: switch back output stream for normal mode.
        self.out = self.__out
        del self.__out


    def write(self, s):
        #: write argument into output stream.
        self.out.write(s)
        #: clear prev_is_separator flag.
        self.prev_is_separator = False
        #: return self.
        return self


    def flush(self):
        #: if output stream can respond to 'flush()' then call it.
        if hasattr(self.out, 'flush'):
            self.out.flush()


    def print_header(self, title, items=None):
        #: print header title and items.
        format = "%%-%ss" % (self.width, )
        header = items and (' %9s' * 4) % items or self.header
        self.write(format % ("## " + title)).write(header).write("\n")


    def print_label(self, label):
        #: print benchmark label.
        format = "%%-%ss" % (self.width, )
        self.write(format % label[0:self.width])
        #: flush output stream.
        self.flush()


    def print_times(self, user, sys, total, real):
        #: print benchmark times.
        for v in (user, sys, total, real):
            self.write(" ").write(self.fmt % v)
        self.write("\n")


    def print_separator(self):
        #: print separator if prev is not separator.
        if not self.prev_is_separator:
            self.write(self.sep)
        #: set prev_is_separator flag.
        self.prev_is_separator = True


REPORTER = Reporter



class Result(object):


    def __init__(self, label, user, sys, total, real):
        self.label, self.user, self.sys, self.total, self.real = label, user, sys, total, real


    def __isub__(self, result):
        #: subtract values.
        self.user  -= result.user
        self.sys   -= result.sys
        self.total -= result.total
        self.real  -= result.real
        return self


    @classmethod
    def average(cls, results):
        #: calculate average of results.
        label = None
        user = sys = total = real = 0.0
        for r in results:
            if label is None: label = r.label
            if label != r.label:
                raise ValueError("%r: label is different from previous one (=%r)" % (r.label, label))
            user  += r.user
            sys   += r.sys
            total += r.total
            real  += r.real
        n = len(results)
        #: return new Result object.
        return cls(label, user/n, sys/n, total/n, real/n)


RESULT = Result



class Task(object):


    def __init__(self, benchmark, label=None):
        self.benchmark = benchmark
        self.label     = label


    def __enter__(self):
        assert self.label
        #: call benchmark._started().
        if self.benchmark:
            self.benchmark._started(self)
        gc.collect()    # start full-GC
        #: start to record times.
        self._start_t = time.time()
        self._t1 = os.times()
        #: return self.
        return self


    def __exit__(self, type, value, tb):
        #: record end times.
        end_t = time.time()
        t2    = os.times()
        user  = t2[0] - self._t1[0]    # user time
        sys   = t2[1] - self._t1[1]    # system time
        total = sum(t2[:4]) - sum(self._t1[:4])  # total time (include child processes' time)
        real  = end_t - self._start_t  # real time
        #: call benchmark._stopped() with Result object.
        result = RESULT(self.label, user, sys, total, real)
        if self.benchmark:
            self.benchmark._stopped(self, result)
        #: return None


    def run(self, func, *args):
        #: if label is not specified then use function name as label.
        if not getattr(self, 'label', None):  # use func name as label
            self.label = getattr(func, 'func_name', None) or getattr(func, '__name__', None)
        #: simulate with-statement.
        try:
            self.__enter__()
            #: return the return value of func.
            return func(*args)
        finally:
            self.__exit__(*sys.exc_info())


    def __iter__(self):
        loop = self.benchmark.loop
        try:
            self.__enter__()
            for i in xrange(loop):
                yield i
        finally:
            self.__exit__(*sys.exc_info())


TASK = Task



class Benchmark(object):


    def __init__(self, reporter, title="Benchmark", loop=1, **kwargs):
        self.reporter = reporter
        self.title    = title
        self.loop     = loop
        self.results  = []
        self._benchmark_started = False
        self._empty_task = None
        self._empty_result = None


    def bench(self, label=None):
        #: return new Task object.
        return TASK(self, label=label)


    __call__ = bench


    def empty(self, label="(Empty)"):
        #: create new Task object and keep it.
        self._empty_task = task = TASK(self, label=label)
        #: return Task object.
        return task


    def run(self, func, *args):
        #: same as self.bench(None).run(func, *args).
        return self.bench(None).run(func, *args)


    def _started(self, task):
        #: print header only once.
        if not self._benchmark_started:
            self._benchmark_started = True
            self.reporter.print_header(self.title)
        #: print label.
        self.reporter.print_label(task.label)


    def _stopped(self, task, result):
        #: if task is for empty loop then keep it.
        if task is self._empty_task:
            self._empty_result = result
        #: if task is for normal benchmark...
        else:
            #: if empty loop result exists then substitute it from current result.
            if self._empty_result:
                result -= self._empty_result
            #: keep result.
            self.results.append(result)
        #: print benchmark result.
        r = result
        self.reporter.print_times(r.user, r.sys, r.total, r.real)


BENCHMARK = Benchmark



class Runner(object):


    ## default value
    loop = 1


    def __init__(self, **kwargs):
        for k in ('loop', ):
            if k in kwargs:
                setattr(self, k, kwargs[k])
        self.kwargs    = kwargs
        self.reporter  = None # REPORTER(**kwargs)
        self.benchmark = None # BENCHMARK(self.reporter, **kwargs)
        self.stat      = None # STAT(self, **kwargs)
        self.results   = None


    def _get_benchmark(self):
        #: if self.results is None then set self.benchmark.results to it.
        if self.results is None:
            self.results = self.benchmark.results
        #: return self.benchmark.
        return self.benchmark


    def bench(self, label=None):
        #: same as self.benchmark.bench(label).
        return self._get_benchmark().bench(label)


    __call__ = bench


    def empty(self, label="(Empty)"):
        #: same as self.benchmark.empty(label).
        return self._get_benchmark().empty(label)


    def run(self, func, *args):
        #: same as self.benchmark.run(func, *args).
        return self._get_benchmark().run(func, *args)


    def _minmax_values_and_indecies(self, results, key, extra):
        #: search min and max values and indecies.
        sorted_results = sorted(results, key=lambda ent: getattr(ent, key))
        arr = []
        for i in xrange(extra):
            min_r   = sorted_results[i]
            max_r   = sorted_results[-i-1]
            min_idx = results.index(min_r)
            max_idx = results.index(max_r)
            min_val = getattr(min_r, key)
            max_val = getattr(max_r, key)
            arr.append((min_val, min_idx, max_val, max_idx))
        return arr


    def _delete_minmax_from(self, results, key, extra, fmt, label_fmt):
        #: print min an max benchmarks.
        arr = self._minmax_values_and_indecies(results, key, extra)
        label = results[0].label
        for min_val, min_idx, max_val, max_idx in arr:
            max_pos = "#%s" % (max_idx + 1)
            min_pos = "#%s" % (min_idx + 1)
            self.reporter.write(label_fmt % label) \
                         .write(fmt % min_val).write(" %9s" % min_pos) \
                         .write(fmt % max_val).write(" %9s" % max_pos).write("\n")
            label = ''
            results[min_idx] = results[max_idx] = None
        #: return results without min and max results.
        return [ r for r in results if r ]


    def _average_results(self, all_results, key, extra):
        #: calculate average of results.
        avg_results = []
        if extra > 0:
            fmt = " " + self.reporter.fmt
            label_fmt = "%-" + str(self.reporter.width) + "s"
            self.reporter.print_header("Remove min & max", items=('min', 'bench#', 'max', 'bench#'))
            for results in all_results:
                results = self._delete_minmax_from(results, key, extra, fmt, label_fmt)
                avg_results.append(RESULT.average(results))
        else:
            for results in all_results:
                avg_results.append(RESULT.average(results))
        return avg_results


    def _print_results(self, results, title):
        #: print results.
        self.reporter.print_header(title)
        for r in results:
            self.reporter.print_label(r.label)
            self.reporter.print_times(r.user, r.sys, r.total, r.real)


    def repeat(self, n, extra=0, key='real'):
        self.reporter.start_verbose_mode()
        results_list = []
        #: repeat n + 2*extra times.
        for i in xrange(n + 2 * extra):
            bm = BENCHMARK(self.reporter, title="Benchmark #%s" % (i+1), loop=self.loop)
            self.benchmark = bm
            #: yield Benchmark object.
            yield bm
            results_list.append(bm.results)
            self.reporter.print_separator()
        #: calculate average.
        num_results = len(results_list[0])
        all_results = [ [] for j in xrange(num_results) ]
        for results in results_list:
            for j, result in enumerate(results):
                all_results[j].append(result)
        self.all_results = all_results
        self.results = self._average_results(all_results, key=key, extra=extra)
        self.reporter.print_separator()
        self.reporter.stop_verbose_mode()
        title = "Average of %s" % n
        enough_width = 24
        if extra > 0 and self.reporter.width >= enough_width:
            title += " (=%s-2*%s)" % (n + 2 * extra, extra)
        self._print_results(self.results, title)


    def platform(self):
        buf = []
        a = buf.append
        a("## benchmarker:       release %s (for python)\n" % (__version__, ))
        a("## python platform:   %s %s\n" % (sys.platform, sys.version.splitlines()[1]))
        a("## python version:    %s\n"    % (sys.version.split(' ')[0], ))
        a("## python executable: %s\n"    % (sys.executable))
        return ''.join(buf)


    #def stats(self):
    #    return "\n" + self.stat.all()


    def compared_matrix(self, **kwargs):
        """obsolete. use self.stat.matrix(compensate=-100.0) instead."""
        return self.stat.matrix(compensate=-100.0, **kwargs)


    def print_compared_matrix(self, **kwargs):
        """obsolete. use print self.stat.matrix(compensate=-100.0) instead."""
        self.reporter.write("-" * 79).write("\n")
        self.reporter.write(self.stat.matrix(compensate=-100.0, **kwargs)).write("\n")


RUNNER = Runner



def _dummy_namespace():


    class Statistics(object):


        ## default values
        key        = 'real'
        width      = Reporter.width
        fmt        = Reporter.fmt
        sort       = True


        def __init__(self, **kwargs):
            for k in ('key', 'width', 'fmt', 'sort'):
                if k in kwargs:
                    setattr(self, k, kwargs[k])


        def aggregate(self, results):
            raise NotImplemenetedError("%s.aggregate(): not implemented yet." % self.__class__.__name__)


        def renderer(self):
            return self


        def render_text(self, results):
            raise NotImplemenetedError("%s.render_text(): not implemented yet." % self.__class__.__name__)


        def process(self, results, format='text'):
            data = self.aggregate(results)
            if format == 'text':
                return self.renderer().render_text(data)
            if format == 'raw':
                return data
            return



    class Ranking(Statistics):


        def aggregate(self, results):
            key = self.key
            data = {'title': 'Ranking', 'key': key}
            data['results'] = []
            append = data['results'].append
            base = None
            results = results[:]
            results.sort(key=lambda r: getattr(r, key))
            for result in results:
                val = getattr(result, key)
                if base is None:
                    base = 100.0 * val
                ratio = base / val
                chart = '*' * int(ratio / 5.0)
                d = {'label': result.label, 'value': val, 'ratio': ratio, 'chart': chart}
                append(d)
            return data


        def render_text(self, data):
            width, fmt = self.width, self.fmt
            buf = []; a = buf.append
            format = "%-" + str(width) + "s %9s  %5s  %s\n"
            a(format % ('## ' + data['title'], data['key'], 'ratio', 'chart'))
            format = "%-" + str(width) + "s " + fmt + " (%5.1f) %s\n"
            for d in data['results']:
                a(format % (d['label'][0:width], d['value'], d['ratio'], d['chart']))
            return ''.join(buf)



    class Matrix(Statistics):


        ## default values
        compensate = 0.0


        def __init__(self, **kwargs):
            Statistics.__init__(self, **kwargs)
            for k in ('compensate', ):
                if k in kwargs:
                    setattr(self, k, kwargs[k])


        def aggregate(self, results, formula=None):
            key, sort, compensate = self.key, self.sort, self.compensate
            if not formula:
                formula = lambda val, other: 100.0 * other / val
            if sort:
                results = results[:]
                results.sort(key=lambda r: getattr(r, key))
            values = [ getattr(result, key) for result in results ]
            data = {'title': 'Matrix', 'key': key, 'compensate': compensate}
            data['results'] = []
            append = data['results'].append
            for i, val in enumerate(values):
                ratios = [ formula(val, other) + compensate for other in values ]
                append({'label': results[i].label, 'value': val, 'ratios': ratios})
            return data


        def render_text(self, data):
            width, fmt = (self.width, self.fmt)
            buf = []; a = buf.append
            format = "%-" + str(width) + "s %9s"
            a(format % ("## " + data['title'], data['key']))
            width -= len("[00] ")
            for n in xrange(1, len(data['results']) + 1):
                a("   [%02d]" % n)
            a("\n")
            format = "[%02d] %-" + str(width) + "s " + fmt
            for i, d in enumerate(data['results']):
                a(format % (i+1, d['label'][0:width], d['value']))
                for ratio in d['ratios']:
                    a(" %6.1f" % ratio)
                a("\n")
            return "".join(buf)


    RANKING = Ranking
    MATRIX = Matrix


    return locals()


statistics = type(sys)('benchmarker.statistics')
statistics.__dict__.update(_dummy_namespace())
sys.modules['benchmarker.statistics'] = statistics



class Stat(object):


    def __init__(self, runner, **kwargs):
        self.runner = runner
        if 'width' not in kwargs:
            kwargs['width'] = self.runner.reporter.width
        self.kwargs = kwargs


    @staticmethod
    def _merge(dict1, dict2):
        d = dict2.copy()
        d.update(dict1)
        return d


    def ranking(self, **kwargs):
        kwargs = self._merge(kwargs, self.kwargs)
        return statistics.Ranking(**kwargs).process(self.runner.results)


    def matrix(self, **kwargs):
        kwargs = self._merge(kwargs, self.kwargs)
        return statistics.Matrix(**kwargs).process(self.runner.results)


    def all(self, almost=True, sep="\n", **kwargs):
        buf = ['']
        buf.append(self.ranking(**kwargs))
        buf.append(self.matrix(**kwargs))
        return sep.join(buf)


STAT = Stat



def Benchmarker(width=None, **kwargs):
    #: add 'width' argument into kwargs.
    if width is not None:
        kwargs['width'] = width
    #: create Runner, Reporter, Benchmarker, and Stat objects.
    runner = RUNNER(**kwargs)
    runner.reporter  = REPORTER(**kwargs)
    runner.benchmark = BENCHMARK(runner.reporter, **kwargs)
    if 'width' not in kwargs:
        kwargs = kwargs.copy()
        kwargs['width'] = runner.reporter.width
    runner.stat = STAT(runner, **kwargs)
    #: return Runner object.
    return runner
