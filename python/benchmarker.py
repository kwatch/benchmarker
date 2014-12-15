# -*- coding: utf-8 -*-
###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

r"""
benchmarker.py -- benchmark utility for Python

ex:

    from benchmarker import Benchmarker

    with Benchmarker(1000*1000, width=20, cycle=5, extra=1) as bench:

        s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"

        @bench(None)
        def _(bm):
            for _ in bm:
                pass

        @bench("'+' op")
        def _(bm):
            for _ in bm:
                s = s1 + s2 + s3 + s4 + s5

        @bench("join()")
        def _(bm):
            for _ in bm:
                s = "".join((s1, s2, s3, s4, s5))

        @bench("'%' op")
        def _(bm):
            for _ in bm:
                s = "%s%s%s%s%s" % (s1, s2, s3, s4, s5)

        @bench("format()")
        def _(bm):
            for _ in bm:
                s = "{0}{1}{2}{3}{4}".format(s1, s2, s3, s4, s5)
"""

from __future__ import with_statement


__all__ = ('Benchmarker', 'Skip',)
__version__ = '$Release: 0.0.0 $'.split()[1]

import sys, os, re
from os import times as _os_times
from time import time as _time_time

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

if python3:
    xrange = range


class Benchmarker(object):

    def __init__(self, loop=1, width=35, cycle=1, extra=0, filter=None,
                 outfile=None, argv=None, reporter=None):
        self.loop    = loop
        self.width   = width
        self.cycle   = cycle
        self.extra   = extra
        self.filter  = filter
        self.outfile = outfile
        self.argv    = argv
        self.benchmarks = []
        self.results = None
        self.reporter = reporter or Reporter(width)
        self.properties = {}    # user-defined key-values, specified by '--key=val'

    def __enter__(self):
        argv = self.argv
        if argv is None or argv is True:
            argv = sys.argv
        if argv is not False:
            _main(self, argv)
        return self

    def __exit__(self, *args):
        raised = args and args[0]
        if not raised:
            self.run()

    def __call__(self, name, **tags):
        return self._new_benchmark(name, **tags)

    def _new_benchmark(self, name, **tags):
        bm = Benchmark(name, self.loop, **tags)
        self.benchmarks.append(bm)
        return bm

    def _filter_benchmarks(self, benchmarks, filter_opt):
        m = _parse_filter(filter_opt)
        assert m, "** %r: invalid filter" % (filter_opt,)
        key, op, expected = m.groups()
        if op == '=':
            op = '=='
        def is_empty(bm):
            return bm.name is None
        def judge(bm, fn, key=key, expected=expected):
            v = (bm.name   if key == 'name' else
                 bm.tags.get(key))
            if isinstance(v, (list, tuple, set)):
                return any( fn(expected, x) for x in v )
            else:
                return fn(expected, v)
        def fn_eq(expeced, val):
            return expected == val
        def fn_mc(expected, val):
            return (False   if val is None else
                    bool(re.search(expected, str(val))))
        if   op == '==':  fn, flag = fn_eq, True
        elif op == '!=':  fn, flag = fn_eq, False
        elif op == '=~':  fn, flag = fn_mc, True
        elif op == '!~':  fn, flag = fn_mc, False
        else:
            assert False, "** op=%r" % (op,)
        filtered = [ bm for bm in benchmarks if is_empty(bm) or judge(bm, fn) is flag ]
        #only_empty = len(filtered) == 1 and is_empty(filtered[0])
        #if not filtered or only_empty:
        #    raise ValueError("-f %s: no benchmark matched" % filter_opt)
        return filtered

    def _write(self, msg):
        sys.stdout.write(msg)
        sys.stdout.flush()

    def _ntimes(self):
        return (self.cycle or 1) + 2 * (self.extra or 0)

    def run(self):
        self._setup()
        self._run_body()
        self._teardown()

    def _setup(self):
        rep = self.reporter
        self._write(rep.report_begin())
        self._write(rep.report_environment(self))

    def _run_body(self):
        ntimes = self._ntimes()
        write = self._write
        rep = self.reporter
        benchmarks = self.benchmarks
        if self.filter:
            benchmarks = self._filter_benchmarks(benchmarks, self.filter)
            self.benchmarks = benchmarks
        write(rep.report_bench_begin())
        for cycle in xrange(1, ntimes+1):
            write(rep.report_bench_header(None if ntimes == 1 else cycle))
            empty_bench_elapsed = None
            for i, bm in enumerate(benchmarks):
                is_empty_bench = bm.name is None
                if is_empty_bench:
                    if i != 0:
                        raise BenchmarkerError("Empty benchmark should be the first of all.")
                write(rep.report_bench_name(bm.name or "(Empty)"))
                elapsed, skipped = bm.run(empty_bench_elapsed)
                if skipped:
                    if is_empty_bench:
                        raise BenchmarkerError("Empty benchmark should not be skipped.")
                    write(rep.report_bench_skipped(skipped))
                else:
                    write(rep.report_bench_elapsed(elapsed))
                if is_empty_bench and not skipped:
                    empty_bench_elapsed = elapsed
            write(rep.report_bench_footer())
        if self.extra:
            for benchmark in self.benchmarks:
                benchmark._exclude_min_max(self.extra)
        write(rep.report_bench_end())

    def _teardown(self):
        benchmarks = [ bm for bm in self.benchmarks
                           if not bm.skipped and bm.name is not None ]
        rep = self.reporter
        write = self._write
        write(rep.report_results(benchmarks))
        if self.extra:
            write(rep.report_ignores(benchmarks))
        if self._ntimes() > 1:
            write(rep.report_averages(benchmarks, self.cycle, self.extra))
        write(rep.report_ranking(benchmarks))
        write(rep.report_matrix(benchmarks))
        write(rep.report_end())
        if self.outfile:
            self._write_outfile(self.outfile, rep.json_data)

    def _write_outfile(self, outfile, json_data):
        import json
        s = json.dumps(json_data, ensure_ascii=False, indent=2)
        with open(outfile, 'w') as f:
            f.write(s)


class BenchmarkerError(Exception):
    pass


class DeprecatedUsageError(Exception):

    MESSAGE = ("Benchmarker ver.4 is not compatible with older version. "
               "See https://pypi.python.org/pypi/Benchmarker/ for new usage.")

    def __init__(self, message=None):
        Exception.__init__(self, message or self.MESSAGE)


class Benchmark(object):

    def __init__(self, name, loop, **tags):
        self.name        = name
        self._loop       = loop
        self.tags        = tags
        self.results     = []
        self.skipped     = None
        self._extra_mins = []
        self._extra_maxs = []
        self._average    = None
        self._start_at   = self._end_at = None
        self._not_yet    = True

    def __call__(self, func):   # decorator
        self.func = func
        return self   # not func

    def __iter__(self):
        if self._not_yet:
            raise DeprecatedUsageError()
        return iter(xrange(self._loop))

    def __enter__(self):
        if self._not_yet:
            raise DeprecatedUsageError()
        self._start_at = (_os_times(), _time_time())
        return self

    def __exit__(self, *args):
        self._end_at = (_os_times(), _time_time())
        if self._not_yet:
            elapsed = self._calc_elapsed(self._start_at, self._end_at)
            self._start_at = self._end_at = None
            self.results.append(elapsed)

    def run(self, empty_bench_elapsed=None):
        self._not_yet = False
        self._start_at = self._end_at = None
        try:
            start_at = (_os_times(), _time_time())
            self.func(self)
            end_at = (_os_times(), _time_time())
        except Skip:
            skipped = sys.exc_info()[1]
            self.skipped = skipped
            elapsed = None
        else:
            skipped = None
            if self._start_at and self._end_at:
                start_at, end_at = self._start_at, self._end_at
            elapsed = self._calc_elapsed(start_at, end_at, empty_bench_elapsed)
            self.results.append(elapsed)
        self._start_at = self._end_at = None
        return elapsed, skipped

    def _calc_elapsed(self, start_at, end_at, empty_bench_elapsed):
        user_time = end_at[0][0] - start_at[0][0]
        sys_time  = end_at[0][1] - start_at[0][1]
        real_time = end_at[1]    - start_at[1]
        if empty_bench_elapsed:
            user_time -= empty_bench_elapsed.user_time
            sys_time  -= empty_bench_elapsed.sys_time
            real_time -= empty_bench_elapsed.real_time
        return Elapsed(real_time, user_time, sys_time, user_time+sys_time)

    def _exclude_min_max(self, extra):
        if not extra:
            return
        if self.skipped:
            return
        if self.name is None:
            return
        pairs = [ (cycle, elapsed.real_time)
                      for cycle, elapsed in enumerate(self.results, 1) ]
        pairs.sort(key=lambda t: t[1])
        self._extra_mins = pairs[:extra]
        self._extra_maxs = pairs[-extra:]
        self._extra_maxs.reverse()

    @property
    def average(self):
        if self._average is None:
            elapseds = self.results[:]
            if self._extra_mins and self._extra_maxs:
                indeces = set([ cycle for cycle, _ in self._extra_mins + self._extra_maxs ])
                elapseds = [ el for cycle, el in enumerate(elapseds, 1)
                                 if cycle not in indeces ]
            num = float(len(elapseds))
            self._average = Elapsed(
                sum( el.real_time  for el in elapseds ) / num,
                sum( el.user_time  for el in elapseds ) / num,
                sum( el.sys_time   for el in elapseds ) / num,
                sum( el.total_time for el in elapseds ) / num,
            )
        return self._average


class Elapsed(object):

    def __init__(self, real_time, user_time, sys_time, total_time):
        self.real_time  = real_time
        self.user_time  = user_time
        self.sys_time   = sys_time
        self.total_time = total_time

    def __iter__(self):
        return iter((self.real_time, self.total_time, self.user_time, self.sys_time))


class Skip(Exception):
    pass


class Float(float):
    """
    ex:
       >>> json.dumps([3.3])
       '[3.2999999999999998]'
       >>> json.dumps([Float('3.3')])
       '[3.3]'
    """
    def __init__(self, string):
        self._value = string
    def __str__(self):
        return self._value
    def __repr__(self):
        return self._value


class Reporter(object):

    def __init__(self, width):
        self.width = width
        self._header_format = "%-" + str(self.width) + "s"
        self.json_data = {}

    def report_begin(self):
        return ''

    def report_end(self):
        return ''

    def report_bench_begin(self):
        return ''

    def report_bench_end(self):
        return ''

    def report_bench_header(self, cycle):
        if cycle is None:
            s = self._header_format % "##"
        else:
            s = self._header_format % ("## (#%s)" % cycle)
        return s + "      real    (total    = user    + sys)\n"

    def report_bench_name(self, name):
        return self._header_format % name

    def report_bench_elapsed(self, elapsed):
        return " %9.4f %9.4f %9.4f %9.4f\n" % tuple(elapsed)

    def report_bench_skipped(self, skipped):
        return "    ## %s\n" % (skipped,)

    def report_bench_footer(self):
        return "\n"

    def report_environment(self, benchmarker):
        b = benchmarker
        import platform
        items = [
            ("benchmarker"      , "release %s (for python)" % __version__),
            ("python version"   , platform.python_version()),
            ("python compiler"  , platform.python_compiler()),
            ("python platform"  , platform.platform()),
            ("python executable", sys.executable),
            ("cpu model"        , _get_cpu_model() or "-"),
            ("parameters"       , dict(loop=b.loop, cycle=b.cycle, extra=b.extra)),
        ]
        self.json_data["Environment"] = dict(items)
        #
        buf = []; add = buf.append
        for k, v in items:
            if k == "parameters":
                v = "loop=%s, cycle=%s, extra=%s" % (v['loop'], v['cycle'], v['extra'])
            add("## %-20s %s\n" % (k+":", v))
        add("\n")
        return "".join(buf)

    def report_results(self, benchmarks):
        items = []
        for bm in benchmarks:
            if bm.skipped:
                continue
            elapseds = bm.results
            items.append({
                "name" : bm.name,
                "real" : [ Float('%.4f' % el.real_time)  for el in elapseds ],
                "total": [ Float('%.4f' % el.total_time) for el in elapseds ],
                "user" : [ Float('%.4f' % el.user_time)  for el in elapseds ],
                "sys"  : [ Float('%.4f' % el.sys_time)   for el in elapseds ],
            })
        self.json_data["Result"] = items
        #
        return ""

    def report_ignores(self, benchmarks):
        items = []
        for bm in benchmarks:
            if bm.skipped:
                continue
            mins = [ {"real": Float("%.4f" % real_time), "cycle": cycle}
                         for cycle, real_time in bm._extra_mins ]
            maxs = [ {"real": Float("%.4f" % real_time), "cycle": cycle}
                         for cycle, real_time in bm._extra_maxs ]
            items.append({
                "name": bm.name,
                "min":  mins,
                "max":  maxs,
            })
        self.json_data["Ignore"] = items
        #
        buf = []; add = buf.append
        s = "## Ignore min & max"
        if len(s) > self.width:
            s = "## Ignore"
        add(self._header_format % s)
        add("       min     cycle       max     cycle\n")
        fmt = " %9.4f %9s"
        for d in items:
            name = d['name']
            for min_d, max_d in zip(d['min'], d['max']):
                add(self._header_format % name)
                add(fmt % (min_d['real'], "(#%s)" % min_d['cycle']))
                add(fmt % (max_d['real'], "(#%s)" % max_d['cycle']))
                add("\n")
                name = ""
        add("\n")
        return "".join(buf)

    def report_averages(self, benchmarks, cycle, extra):
        items = []
        for bm in benchmarks:
            if bm.skipped:
                continue
            avg = bm.average
            items.append({
                "name":  bm.name,
                "real":  Float('%.4f' % avg.real_time),
                "total": Float('%.4f' % avg.total_time),
                "user":  Float('%.4f' % avg.user_time),
                "sys":   Float('%.4f' % avg.sys_time),
            })
        self.json_data["Average"] = items
        #
        buf = []; add = buf.append
        s = "## Average of %s (=%s-2*%s)" % (cycle, cycle + 2 * extra, extra)
        if self.width < 20:
            s = "## Average of %s" % (cycle,)
        if len(s) <= self.width:
            add(self._header_format % s)
            add("      real    (total    = user    + sys)\n")
        else:
            n = self.width + 10 - max(self.width, len(s)) - len(" real")
            add(s); add(" " * max(n, 0)); add (" real")
            add("    (total    = user    + sys)\n")
        for d in items:
            add(self._header_format % d['name'])
            add(" %9s %9s %9s %9s\n" % (d['real'], d['total'], d['user'], d['sys']))
        add("\n")
        return "".join(buf)

    def report_ranking(self, benchmarks):
        pairs = [ (bm.name, bm.average.real_time)
                      for bm in benchmarks if not bm.skipped ]
        pairs.sort(key=lambda t: t[1])
        base_time = pairs[0][1] if pairs else None
        items = []
        for name, real_time in pairs:
            ratio = base_time / real_time
            items.append({
                "name":  name,
                "real":  Float("%.4f" % real_time),
                "ratio": Float("%.1f" % (ratio * 100.0)),
                "bar":   "*" * int(round(ratio * 20.0)),
            })
        self.json_data["Ranking"] = items
        #
        buf = []; add = buf.append
        add(self._header_format % "## Ranking")
        add("      real\n")
        for d in items:
            add(self._header_format % d['name'])
            add(" %9s  (%5s) %s\n" % (d['real'], d['ratio'], d['bar']))
        add("\n")
        return "".join(buf)

    def report_matrix(self, benchmarks):
        items = []
        pairs = [ (bm.name, bm.average.real_time)
                      for bm in benchmarks if not bm.skipped ]
        pairs.sort(key=lambda t: t[1])
        for name, real_time in pairs:
            base_time = real_time
            cols = [ Float('%.1f' % (100.0 * r_time / base_time))
                         for _, r_time in pairs ]
            items.append({
                "name": name,
                "real": Float("%.4f" % real_time),
                "cols": cols,
            })
        self.json_data["Matrix"] = items
        #
        buf = []; add = buf.append
        add(self._header_format % "## Matrix")
        add("      real")
        for i in xrange(1, len(benchmarks)+1):
            add("%8s" % ("[%02d]" % i))
        add("\n")
        i = 0
        for d in items:
            i += 1
            add(self._header_format % ("[%02d] %s" % (i, d['name'])))
            add(" %9s" % d['real'])
            for col in d['cols']:
                add(" %7s" % col)
            add("\n")
        add("\n")
        return "".join(buf)


def _get_cpu_model():
    import platform
    system = platform.system()
    #
    if system == "Linux":
        with open("/proc/cpuinfo") as f:
            content = f.read()
        #if python3:
        #    content = content.decode('us-ascii')
        m = re.search(r'\nmodel name\s*:(.*)', content)
        if m:
            model_name = re.sub(r'\s+', ' ', m.group(1).strip())
            m = re.search(r'\ncpu MHz\s*:(.*)', content)
            if m:
                model_name += "  # %s MHz" % m.group(1).strip()
            return model_name
        return None
    #
    if system == "Darwin":
        from subprocess import Popen, PIPE
        command = ["/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string"]
        p = Popen(command, stdout=PIPE, stderr=PIPE)
        output, error = p.communicate()  # or p.communicate("input string")
        if python3:
            output = output.decode('us-ascii')
        return re.sub(r'\s+', ' ', output)
    #
    if os.path.exists("/usr/sbin/sysctl"):
        from subprocess import Popen, PIPE
        if system == "Darwin":
            command = ["/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string"]
        else:
            command = ["/usr/sbin/sysctl", "-n", "hw.model"]
        p = Popen(command, stdout=PIPE, stderr=PIPE)
        output, error = p.communicate()  # or p.communicate("input string")
        if python3:
            output = output.decode('us-ascii')
        return re.sub(r'\s+', ' ', output)
    #
    if system == "Windows":
        return platform.processor()
    #
    return None


###


class CommandOptionError(Exception):
    pass


def _main(benchmarker, argv=None):
    if argv is None:
        argv = sys.argv
    try:
        script, short_opts, long_opts, args = _parse_cmdopts(argv)
    except CommandOptionError as ex:
        sys.stderr.write(str(ex))
        sys.stderr.write("\n")
        sys.exit(1)
    if 'h' in short_opts:
        sys.stdout.write(_usage(script, benchmarker))
        sys.exit(0)
    if 'v' in short_opts:
        sys.stdout.write(__version__)
        sys.stdout.write("\n")
        sys.exit(0)
    if 'n' in short_opts:
        benchmarker.loop = int(short_opts['n'])
    if 'c' in short_opts:
        benchmarker.cycle = int(short_opts['c'])
    if 'x' in short_opts:
        benchmarker.extra = int(short_opts['x'])
    if 'o' in short_opts:
        benchmarker.outfile = short_opts['o']
    if 'f' in short_opts:
        benchmarker.filter = short_opts['f']
    benchmarker.properties = long_opts


def _usage(script, benchmarker):
    loop  = benchmarker.loop
    cycle = benchmarker.cycle
    extra = benchmarker.extra
    return r"""
Usage: python %(script)s [options]
  -h             : help
  -v             : print Benchmarker version
  -n N           : loop N times in each benchmark (N=%(loop)s)
  -c N           : cycle benchmarks N times (N=%(cycle)s)
  -x N           : ignore worst N results and best N results (N=%(extra)s)
  -o result.json : output file in JSON format
  -f name=...    : filter by benchmark name   (op: '==', '!=', '=~', '!~')
  -f tag=...     : filter by user-defined tag (op: '==', '!=', '=~', '!~')
  --key[=value]  : user-defined properties

Tips:
  * Filtering benchmarks by name
      $ python test1.py -f 'name==...'   # filter by name ('==' or '!=')
      $ python test1.py -f 'name=~...'   # filter by regexp ('=~' or '!~')
  * Filtering benchmarks by user-defined tag
      with Benchmarker() as bench:
          @bench("example1", tag="A", label="x") # user-defined tag
          def _(bm):
              ...
          @bench("example2", tag=["A","B","C"])  # user-defined tag
          def _(bm):
              ...
      $ python test1.py -f 'tag==A'      # filter by tag name
      $ python test1.py -f 'tag=~^A$'    # filter by regexp
  * Default filter
      with Benchmarker(filter="tag!=heavy"):   # default filter
          @bench("takes too long", tag="heavy"):
          def _(bm):
              ...
      $ python test1.py                  # ignores heavy benchmarks
      $ python test1.py -f 'tag=~.'      # runs all, including heavy ones
"""[1:] % {'script': script, 'loop': loop, 'cycle': cycle, 'extra': extra}


def _parse_cmdopts(argv=None):
    if argv is None:
        argv = sys.argv
    argv = argv[:]
    short_opts = {}
    long_opts = {}
    script = os.path.basename(argv[0])
    args = sys.argv[1:]
    while args and args[0].startswith("-"):
        arg = args.pop(0)
        if arg == "--":
            break
        if arg.startswith("--"):
            m = re.match(r'^(\w[-\w]*)(?:=(.*))?', arg[2:])
            if not m:
                raise CommandOptionError("%s: invalid option." % arg)
            key, val = m.groups()
            if val is None:
                val = True
            long_opts[key] = val
        else:
            for i in xrange(1, len(arg)):
                ch = arg[i]
                if ch in "hv":
                    short_opts[ch] = True
                elif ch in "ncxof":
                    optarg = arg[i+1:]
                    if not optarg:
                        if not args:
                            raise CommandOptionError("-%s: argument required." % ch)
                        optarg = args.pop(0)
                    if ch in "ncx" and not optarg.isdigit():
                        raise CommandOptionError("-%s %s: integer expected." % (ch, optarg))
                    if ch == "f" and not _parse_filter(optarg):
                        raise CommandOptionError("-%s %s: invalid argument." % (ch, optarg))
                    short_opts[ch] = optarg
                    break
                else:
                    raise CommandOptionError("-%s: unknown option." % ch)
    #
    return script, short_opts, long_opts, args


def _parse_filter(filter_opt):
    return re.match(r'^(\w+)(=[=~]?|![=~])(.+)$', filter_opt)
