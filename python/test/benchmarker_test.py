# -*- coding: utf-8 -*-

import sys, os, re
python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3
import unittest
try:
    import json
except LoadError:
    json = None

from oktest import ok, test, subject, situation, skip, at_end
from oktest.dummy import dummy_file, dummy_io

from benchmarker import Benchmarker, Benchmark


def retrieve_sample_code_from_module_doc():
    import benchmarker
    doc = benchmarker.__doc__
    m = re.compile(r'^ *from benchmarker', re.M).search(doc)
    assert m is not None
    sample_code = doc[m.start(0):]
    sample_code = re.compile(r'^    ', re.M).sub('', sample_code)
    sample_code = sample_code.replace(r"1000*1000", "1000")
    return sample_code

def escape_rexp(pattern):
    return re.sub(r'([\+\.\*\?\^\$\|\(\)\{\}\[\]])', r'\\\1', pattern)

def run_command(command, input=None):
    from subprocess import Popen, PIPE
    p = Popen(command, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE, close_fds=True)
    stdin, stdout, stderr = p.stdin, p.stdout, p.stderr
    try:
        if input:
            stdin.write(input)
        stdin.close()
        sout = stdout.read()
        serr = stderr.read()
        if python2:
            assert isinstance(sout, str)
            assert isinstance(serr, str)
        if python3:
            assert isinstance(sout, bytes)
            assert isinstance(serr, bytes)
            sout = sout.decode('utf-8')
            serr = serr.decode('utf-8')
        return sout, serr
    finally:
        stdout.close()
        stderr.close()

EXPECTED_OUTPUT = r"""
## benchmarker:         release D.D.D (for python)
## python version:      D.D.D
## python compiler:     STRING
## python platform:     STRING
## python executable:   STRING
## cpu model:           STRING
## parameters:          loop=1000, cycle=5, extra=1

## (#1)                   real    (total    = user    + sys)
(Empty)                 D.DDDD    D.DDDD    D.DDDD    D.DDDD
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## (#2)                   real    (total    = user    + sys)
(Empty)                 D.DDDD    D.DDDD    D.DDDD    D.DDDD
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## (#3)                   real    (total    = user    + sys)
(Empty)                 D.DDDD    D.DDDD    D.DDDD    D.DDDD
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## (#4)                   real    (total    = user    + sys)
(Empty)                 D.DDDD    D.DDDD    D.DDDD    D.DDDD
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## (#5)                   real    (total    = user    + sys)
(Empty)                 D.DDDD    D.DDDD    D.DDDD    D.DDDD
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## (#6)                   real    (total    = user    + sys)
(Empty)                 D.DDDD    D.DDDD    D.DDDD    D.DDDD
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## (#7)                   real    (total    = user    + sys)
(Empty)                 D.DDDD    D.DDDD    D.DDDD    D.DDDD
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ignore min & max        min     cycle       max     cycle
'+' op                  D.DDDD      (#D)    D.DDDD      (#D)
join()                  D.DDDD      (#D)    D.DDDD      (#D)
'%' op                  D.DDDD      (#D)    D.DDDD      (#D)
format()                D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
DESCRIPT                D.DDDD  (100.0) ********************
DESCRIPT                D.DDDD  ( DD.D) BAR
DESCRIPT                D.DDDD  ( DD.D) BAR
DESCRIPT                D.DDDD  ( DD.D) BAR

## Matrix                 real    [01]    [02]    [03]    [04]
[01] DESCRIPT           D.DDDD   100.0   DDD.D   DDD.D   DDD.D
[02] DESCRIPT           D.DDDD    DD.D   100.0   DDD.D   DDD.D
[03] DESCRIPT           D.DDDD    DD.D    DD.D   100.0   DDD.D
[04] DESCRIPT           D.DDDD    DD.D    DD.D    DD.D   100.0

"""[1:]

def output2pattern(expected_output):
    expected_pattern = (
        '^' +
        escape_rexp(expected_output)
          .replace('STRING', r'\S.*')
          .replace('BAR', r'\*{1,20}')
          .replace('DESCRIPT', r"('\+' op  |join\(\)  |'\%' op  |format\(\))")
          .replace('D', r'\d')
        #+ '$'
    )
    return expected_pattern

EXPECTED_OUTPUT_PATTERN = output2pattern(EXPECTED_OUTPUT)

EXPECTED_HELP = r"""
Usage: python %(script)s [options]
  -h             : help
  -v             : print Benchmarker version
  -n N           : loop N times in each benchmark (N=1000)
  -c N           : cycle benchmarks N times (N=5)
  -x N           : ignore worst N results and best N results (N=1)
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
"""[1:]



class Benchmarker_TC(unittest.TestCase):

    def provide_sample_file(self):
        sample_code = retrieve_sample_code_from_module_doc()
        tmp_filename = "_test_sample_bench.py"
        with open(tmp_filename, 'w') as f:
            f.write(sample_code)
        return tmp_filename

    def release_sample_file(self, tmp_filename):
        if os.path.exists(tmp_filename):
            os.unlink(tmp_filename)

    def provide_tagged_sample_file(self, sample_file):
        with open(sample_file) as f: content = f.read()
        content = content.replace("""@bench("'+' op")""", """@bench("'+' op", tag="oper")""")
        content = content.replace("""@bench("'%' op")""", """@bench("'%' op", tag="oper")""")
        content = content.replace("""@bench("join()")""", """@bench("join()", tag=["func","function"])""")
        #content = content.replace("""@bench("format()")""", """@bench("format()", tag="func")""")
        with open(sample_file, 'w') as f: f.write(content)
        return sample_file


    @test("run sample code")
    def _(self, sample_file):
        s = EXPECTED_OUTPUT
        expected_pattern = output2pattern(s)
        sout, serr = run_command("%s %s" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""

    @test("'-h' shows help message")
    def _(self, sample_file):
        expected_help = EXPECTED_HELP % {'script': sample_file}
        sout, serr = run_command("%s %s -h" % (sys.executable, sample_file))
        ok (sout) == expected_help
        ok (serr) == ""

    @test("'-v' print Benchmark version")
    def _(self, sample_file):
        import benchmarker
        expected = "%s\n" % benchmarker.__version__
        sout, serr = run_command("%s %s -v" % (sys.executable, sample_file))
        ok (sout) == expected
        ok (serr) == ""

    @test("'-n' changes number of loop")
    def _(self, sample_file):
        s = EXPECTED_OUTPUT
        s = s.replace(r"loop=1000", r"loop=999")
        expected_pattern = output2pattern(s)
        sout, serr = run_command("%s %s -n 999" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""

    @test("'-c' changes number of cycle")
    def _(self, sample_file):
        s = EXPECTED_OUTPUT
        s = s.replace(r"cycle=5", r"cycle=1")
        s = re.sub(r'(## \(#[4-7]\)(.*\n.*\n.*\n.*\n.*\n.*\n\n))', '', s)
        s = s.replace(r'## Average of 5 (=7-2*1)', r'## Average of 1 (=3-2*1)')
        expected_pattern = output2pattern(s)
        sout, serr = run_command("%s %s -c 1" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""

    @test("'-x' changes number of extra cycle")
    def _(self, sample_file):
        s = EXPECTED_OUTPUT
        s = s.replace(r"## Average of 10 (=14-2*2)", r"## Average of 10 (=12-2*1)")
        expected_pattern = output2pattern(s)
        sout, serr = run_command("%s %s -x 1" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""

    @test("'-o' outputs JSON string")
    @skip.when(json is None, "failed to import json module")
    def _(self, sample_file):
        jsonfile = "_result.json"
        @at_end
        def _(): os.path.exists(jsonfile) and os.unlink(jsonfile)
        s = EXPECTED_OUTPUT
        expected_pattern = output2pattern(s)
        if os.path.exists(jsonfile): os.unlink(jsonfile)
        ok (jsonfile).not_exist()
        sout, serr = run_command("%s %s -o _result.json" % (sys.executable, sample_file))
        ok (jsonfile).exists()
        ok (sout).matches(expected_pattern)
        ok (serr) == ""
        with open(jsonfile) as f:
            content = f.read()
        def fn(): json.loads(content)
        ok (fn).not_raise(Exception)
        d = json.loads(content)
        ok (d).has_key('Environment'); ok (d['Environment']).is_a(dict)
        ok (d).has_key('Result')     ; ok (d['Result']).is_a(list)
        ok (d).has_key('Ignore')     ; ok (d['Ignore']).is_a(list)
        ok (d).has_key('Average')    ; ok (d['Average']).is_a(list)
        ok (d).has_key('Ranking')    ; ok (d['Ranking']).is_a(list)
        ok (d).has_key('Matrix')     ; ok (d['Matrix']).is_a(list)

    @test("'-f name=xxx' selects benchmarks by name")
    def _(self, sample_file):
        s = EXPECTED_OUTPUT
        s = re.compile(r"^('\+' op|'\%' op|format\(\)) .*\n", re.M).sub("", s)
        s = re.compile(r"^## Ignore min \& max .*", re.M|re.S).sub("", s)
        s += r"""
## Ignore min & max        min     cycle       max     cycle
join()                  D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
join()                  D.DDDD  (100.0) ********************

## Matrix                 real    [01]
[01] join()             D.DDDD   100.0

"""[1:]
        expected_pattern = output2pattern(s)
        #
        sout, serr = run_command("%s %s -f name=='join()'" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f name='join()'" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f name=~^join" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""
        #

    @test("'-f name!=xxx' ignores benchmarks by name")
    def _(self, sample_file):
        s = EXPECTED_OUTPUT
        s = re.compile(r"^(join\(\)) .*\n", re.M).sub("", s)
        s = re.compile(r"^## Ignore min \& max .*", re.M|re.S).sub("", s)
        s += r"""
## Ignore min & max        min     cycle       max     cycle
DESCRIPT                D.DDDD      (#D)    D.DDDD      (#D)
DESCRIPT                D.DDDD      (#D)    D.DDDD      (#D)
DESCRIPT                D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
DESCRIPT                D.DDDD    D.DDDD    D.DDDD    D.DDDD
DESCRIPT                D.DDDD    D.DDDD    D.DDDD    D.DDDD
DESCRIPT                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
DESCRIPT                D.DDDD  (100.0) ********************
DESCRIPT                D.DDDD  ( DD.D) BAR
DESCRIPT                D.DDDD  ( DD.D) BAR

## Matrix                 real    [01]    [02]    [03]
[01] DESCRIPT           D.DDDD   100.0   DDD.D   DDD.D
[02] DESCRIPT           D.DDDD    DD.D   100.0   DDD.D
[03] DESCRIPT           D.DDDD    DD.D    DD.D   100.0

"""[1:]
        expected_pattern = output2pattern(s)
        #
        sout, serr = run_command("%s %s -f name!='join()'" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f name!~^join" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""

    @test("'-f tag=xxx' selects benchmarks by tag")
    def _(self, tagged_sample_file):
        sample_file = tagged_sample_file
        #
        s1 = EXPECTED_OUTPUT
        s1 = re.compile(r"^(join\(\)|format\(\)) .*\n", re.M).sub("", s1)
        s1 = re.compile(r"^## Ignore min \& max .*", re.M|re.S).sub("", s1)
        s1 += r"""
## Ignore min & max        min     cycle       max     cycle
DESCRIPT                D.DDDD      (#D)    D.DDDD      (#D)
DESCRIPT                D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
DESCRIPT                D.DDDD    D.DDDD    D.DDDD    D.DDDD
DESCRIPT                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
DESCRIPT                D.DDDD  (100.0) ********************
DESCRIPT                D.DDDD  ( DD.D) BAR

## Matrix                 real    [01]    [02]
[01] DESCRIPT           D.DDDD   100.0   DDD.D
[02] DESCRIPT           D.DDDD    DD.D   100.0

"""[1:]
        expected_pattern1 = output2pattern(s1)
        #
        sout, serr = run_command("%s %s -f tag==oper" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern1)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f tag=oper" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern1)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f tag=~^o" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern1)
        ok (serr) == ""
        #
        s2 = EXPECTED_OUTPUT
        s2 = re.compile(r"^('\+' op|'\%' op|format\(\)) .*\n", re.M).sub("", s2)
        s2 = re.compile(r"^## Ignore min \& max .*", re.M|re.S).sub("", s2)
        s2 += r"""
## Ignore min & max        min     cycle       max     cycle
join()                  D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
join()                  D.DDDD  (100.0) ********************

## Matrix                 real    [01]
[01] join()             D.DDDD   100.0

"""[1:]
        expected_pattern2 = output2pattern(s2)
        #
        sout, serr = run_command("%s %s -f tag==func" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern2)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f tag=func" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern2)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f tag=~^f" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern2)
        ok (serr) == ""

    @test("'-f tag!=xxx' ignores benchmarks by tag")
    def _(self, tagged_sample_file):
        sample_file = tagged_sample_file
        #
        s1 = EXPECTED_OUTPUT
        s1 = re.compile(r"^('\+' op|'\%' op) .*\n", re.M).sub("", s1)
        s1 = re.compile(r"^## Ignore min \& max .*", re.M|re.S).sub("", s1)
        s1 += r"""
## Ignore min & max        min     cycle       max     cycle
join()                  D.DDDD      (#D)    D.DDDD      (#D)
format()                D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
join()                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
DESCRIPT                D.DDDD  (100.0) ********************
DESCRIPT                D.DDDD  ( DD.D) BAR

## Matrix                 real    [01]    [02]
[01] DESCRIPT           D.DDDD   100.0   DDD.D
[02] DESCRIPT           D.DDDD    DD.D   100.0

"""[1:]
        expected_pattern1 = output2pattern(s1)
        #
        sout, serr = run_command("%s %s -f tag!=oper" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern1)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f tag!~^o" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern1)
        ok (serr) == ""
        #
        s2 = EXPECTED_OUTPUT
        s2 = re.compile(r"^(join\(\)) .*\n", re.M).sub("", s2)
        s2 = re.compile(r"^## Ignore min \& max .*", re.M|re.S).sub("", s2)
        s2 += r"""
## Ignore min & max        min     cycle       max     cycle
'+' op                  D.DDDD      (#D)    D.DDDD      (#D)
'%' op                  D.DDDD      (#D)    D.DDDD      (#D)
format()                D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
format()                D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
DESCRIPT                D.DDDD  (100.0) ********************
DESCRIPT                D.DDDD  ( DD.D) BAR
DESCRIPT                D.DDDD  ( DD.D) BAR

## Matrix                 real    [01]    [02]    [03]
[01] DESCRIPT           D.DDDD   100.0   DDD.D   DDD.D
[02] DESCRIPT           D.DDDD    DD.D   100.0   DDD.D
[03] DESCRIPT           D.DDDD    DD.D    DD.D   100.0

"""[1:]
        expected_pattern2 = output2pattern(s2)
        #
        sout, serr = run_command("%s %s -f tag!=func" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern2)
        ok (serr) == ""
        #
        sout, serr = run_command("%s %s -f tag!~^f" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern2)
        ok (serr) == ""

    @test("'raise Skip(..reason..)' skips benchmark.")
    def _(self, sample_file):
        with open(sample_file, 'r+') as f:
            content = f.read()
            content = content.replace("import Benchmarker", "import Benchmarker, Skip")
            rexp = re.compile(r'(@bench\("(join|format)\(\)"\)\n    def _\(bm\):\n)')
            content = rexp.sub(r'\1        raise Skip("cancel")\n', content)
            f.seek(0)
            f.truncate(0)
            f.write(content)
        s = EXPECTED_OUTPUT
        s = re.compile(r'^(join|format)\(\)(\s+)(D\.DDDD)(\s+D.DDDD){3}$', re.M)\
              .sub(r'\1()\2## cancel', s)
        s = re.compile(r"^## Ignore min \& max .*", re.M|re.S).sub("", s)
        s += r"""
## Ignore min & max        min     cycle       max     cycle
'+' op                  D.DDDD      (#D)    D.DDDD      (#D)
'%' op                  D.DDDD      (#D)    D.DDDD      (#D)

## Average of 5 (=7-2*1)  real    (total    = user    + sys)
'+' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD
'%' op                  D.DDDD    D.DDDD    D.DDDD    D.DDDD

## Ranking                real
DESCRIPT                D.DDDD  (100.0) ********************
DESCRIPT                D.DDDD  ( DD.D) BAR

## Matrix                 real    [01]    [02]
[01] DESCRIPT           D.DDDD   100.0   DDD.D
[02] DESCRIPT           D.DDDD    DD.D   100.0

"""[1:]
        expected_pattern = output2pattern(s)
        sout, serr = run_command("%s %s" % (sys.executable, sample_file))
        ok (sout).matches(expected_pattern)
        ok (serr) == ""

    @test("'--name=value' sets benchmarker property.")
    def _(self, sample_file):
        content = r"""
from benchmarker import Benchmarker
from pprint import pprint
with Benchmarker() as bench:
    pprint(bench.properties)
"""[1:]
        with open(sample_file, 'w') as f:
            f.write(content)
        sout, serr = run_command("%s %s --str=foo --flag --num=123" % (sys.executable, sample_file))
        ok (sout).should.startswith("{'flag': True, 'num': '123', 'str': 'foo'}\n")
        ok (serr) == ""



if __name__ == '__main__':
    import oktest
    oktest.main()
