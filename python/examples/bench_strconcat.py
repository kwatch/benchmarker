# -*- coding: utf-8 -*-

##
## Benchmarks for string concatenation
##
## - list.append() + join()
## - list.extend() + join()
## - list.extend() + join()  (bound method)
## - list slice + join()
## - StringIO
## - mmap
## - generator + join()
##
## Requires Benchmarker 3.0
##   http://pypi.python.org/pypi/Benchmarker/
##

from __future__ import with_statement

import sys, mmap
python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

if python2:
    from cStringIO import StringIO
if python3:
    xrange = range
    from io import StringIO


from benchmarker import Benchmarker, cmdopt
cmdopt.parse()


##
## dummy data
##

class User(object):
    def __init__(self, name, email):
        self.name  = name
        self.email = email

nusers = 100
users = []
for i in xrange(nusers):
    name = "user%03d" % i
    email = name + "@example.com"
    users.append(User(name, email))


##
## benchmark functions
##

benchmark_functions = []
def bench(func):
    benchmark_functions.append(func)
    return func


@bench
def bench_append(users):
    """append()"""
    _buf = []
    _buf.append('''<table>\n''')
    for user in users:
        _buf.append(''' <tr>
  <td>'''); _buf.append(user.name); _buf.append('''</td>
  <td><a href="mailto:'''); _buf.append(user.email); _buf.append('''">'''); _buf.append(user.email); _buf.append('''</a></td>
 </tr>\n''')
    #endfor
    _buf.append('''</table>\n''')
    return "".join(_buf)


@bench
def bench_extend(users):
    """extend()"""
    _buf = []
    _buf.extend(('''<table>\n''', ))
    for user in users:
        _buf.extend((''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', ))
    #endfor
    _buf.extend(('''</table>\n''', ))
    return "".join(_buf)


@bench
def bench_extend_bound(users):
    """extend() (bound)"""
    _buf = []; _extend = _buf.extend
    _extend(('''<table>\n''', ))
    for user in users:
        _extend((''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', ))
    #endfor
    _extend(('''</table>\n''', ))
    return "".join(_buf)


@bench
def bench_slice(users):
    """slice[-1:]"""
    _buf = ['']
    _buf[-1:] = ('''<table>\n''', '')
    for user in users:
        _buf[-1:] = (''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', '')
    #endfor
    _buf[-1:] = ('''</table>\n''', '')
    return "".join(_buf)


@bench
def bench_slice2(users):
    """slice[99999:]"""
    _buf = ['']
    _buf[99999:] = ('''<table>\n''', )
    for user in users:
        _buf[99999:] = (''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', )
    #endfor
    _buf[99999:] = ('''</table>\n''', )
    return "".join(_buf)


@bench
def bench_stringio(user):
    """StringIO"""
    _buf = StringIO()
    _buf.write('''<table>\n''')
    for user in users:
        _buf.write(''' <tr>
  <td>'''); _buf.write(user.name); _buf.write('''</td>
  <td><a href="mailto:'''); _buf.write(user.email); _buf.write('''">'''); _buf.write(user.email); _buf.write('''</a></td>
 </tr>\n''');
    #endfor
    _buf.write('''</table>\n''')
    return _buf.getvalue()


MM = mmap.mmap(-1, 2*1024*1024)

@bench
def bench_mmap(user):
    """mmap"""
    #_buf = mmap.mmap(-1, 2*1024*1024)
    _buf = MM
    _buf.write('''<table>\n''')
    for user in users:
        _buf.write(''' <tr>
  <td>'''); _buf.write(user.name); _buf.write('''</td>
  <td><a href="mailto:'''); _buf.write(user.email); _buf.write('''">'''); _buf.write(user.email); _buf.write('''</a></td>
 </tr>\n''');
    #endfor
    _buf.write('''</table>\n''')
    length = _buf.tell()
    _buf.seek(0)
    output = _buf.read(length)
    _buf.seek(0)
    return output


@bench
def bench_generator(user):
    """generator"""
    return ''.join(_generate_template(users))

def _generate_template(users):
    yield '''<table>\n'''
    for user in users:
        yield ''' <tr>
  <td>'''; yield (user.name); yield '''</td>
  <td><a href="mailto:'''; yield (user.email); yield '''">'''; yield (user.email); yield '''</a></td>
 </tr>\n''';
    #endfor
    yield '''</table>\n'''


##
## mmap module of Python 3 doesn't support str
##
for func in benchmark_functions:
    func._skip_msg = False
if python3:
    bench_mmap._skip_msg = '   (skipped in Python3)'


##
## check outputs of each benchmark
##
expected = benchmark_functions[0](users)
for func in benchmark_functions:
    if not func._skip_msg:
        assert func(users) == expected


##
## do benchmarks
##
for bm in Benchmarker(loop=10000, cycle=5, extra=1):
    for func in benchmark_functions:
        if func._skip_msg:
            bm.skip(func, func._skip_msg)
        else:
            bm.run(func, users)



##
## output example
##
# $ python bench_strconcat.py -q -n 10000
# ## benchmarker:       release 3.0.0 (for python)
# ## python platform:   darwin [GCC 4.2.1 (Apple Inc. build 5659)]
# ## python version:    2.5.5
# ## python executable: /usr/local/python/2.5.5/bin/python
#
# ## Average of 5 (=7-2*1)           user       sys     total      real
# append()                         1.8840    0.0040    1.8880    1.8900
# extend()                         1.0680    0.0000    1.0680    1.0707
# extend() (bound)                 0.9840    0.0000    0.9840    0.9853
# slice[-1:]                       1.0160    0.0020    1.0180    1.0169
# slice[99999:]                    1.0040    0.0000    1.0040    1.0077
# StringIO                         2.4940    0.0020    2.4960    2.4962
# mmap                             2.1840    0.0000    2.1840    2.1872
# generator                        1.3520    0.0020    1.3540    1.3518
#
# ## Ranking                         real
# extend() (bound)                 0.9853 (100.0%) *************************
# slice[99999:]                    1.0077 ( 97.8%) ************************
# slice[-1:]                       1.0169 ( 96.9%) ************************
# extend()                         1.0707 ( 92.0%) ***********************
# generator                        1.3518 ( 72.9%) ******************
# append()                         1.8900 ( 52.1%) *************
# mmap                             2.1872 ( 45.0%) ***********
# StringIO                         2.4962 ( 39.5%) **********
#
# ## Ratio Matrix                    real    [01]    [02]    [03]    [04]    [05]    [06]    [07]    [08]
# [01] extend() (bound)            0.9853  100.0%  102.3%  103.2%  108.7%  137.2%  191.8%  222.0%  253.3%
# [02] slice[99999:]               1.0077   97.8%  100.0%  100.9%  106.3%  134.1%  187.6%  217.1%  247.7%
# [03] slice[-1:]                  1.0169   96.9%   99.1%  100.0%  105.3%  132.9%  185.9%  215.1%  245.5%
# [04] extend()                    1.0707   92.0%   94.1%   95.0%  100.0%  126.3%  176.5%  204.3%  233.1%
# [05] generator                   1.3518   72.9%   74.5%   75.2%   79.2%  100.0%  139.8%  161.8%  184.7%
# [06] append()                    1.8900   52.1%   53.3%   53.8%   56.6%   71.5%  100.0%  115.7%  132.1%
# [07] mmap                        2.1872   45.0%   46.1%   46.5%   49.0%   61.8%   86.4%  100.0%  114.1%
# [08] StringIO                    2.4962   39.5%   40.4%   40.7%   42.9%   54.2%   75.7%   87.6%  100.0%
