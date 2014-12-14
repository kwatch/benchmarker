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
## Requires Benchmarker 4.0
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


from benchmarker import Benchmarker


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



with Benchmarker(loop=10000, width=30, cycle=5, extra=1) as bench:

    @bench(None)
    def _(bm):
        for _ in bm:
            pass

    @bench("append()")
    def _(bm):
        for _ in bm:
            _buf = []
            _buf.append('''<table>\n''')
            for user in users:
                _buf.append(''' <tr>
  <td>'''); _buf.append(user.name); _buf.append('''</td>
  <td><a href="mailto:'''); _buf.append(user.email); _buf.append('''">'''); _buf.append(user.email); _buf.append('''</a></td>
 </tr>\n''')
            #endfor
            _buf.append('''</table>\n''')
            output = "".join(_buf)

    @bench("extend()")
    def _(bm):
        for _ in bm:
            _buf = []
            _buf.extend(('''<table>\n''', ))
            for user in users:
                _buf.extend((''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', ))
            #endfor
            _buf.extend(('''</table>\n''', ))
            output = "".join(_buf)

    @bench("extend() (bound)")
    def _(bm):
        for _ in bm:
            _buf = []; _extend = _buf.extend
            _extend(('''<table>\n''', ))
            for user in users:
                _extend((''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', ))
            #endfor
            _extend(('''</table>\n''', ))
            output = "".join(_buf)

    @bench("slice[-1:]")
    def _(bm):
        for _ in bm:
            _buf = ['']
            _buf[-1:] = ('''<table>\n''', '')
            for user in users:
                _buf[-1:] = (''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', '')
            #endfor
            _buf[-1:] = ('''</table>\n''', '')
            output = "".join(_buf)

    @bench("slice[99999:]")
    def _(bm):
        for _ in bm:
            _buf = ['']
            _buf[99999:] = ('''<table>\n''', )
            for user in users:
                _buf[99999:] = (''' <tr>
  <td>''', (user.name), '''</td>
  <td><a href="mailto:''', (user.email), '''">''', (user.email), '''</a></td>
 </tr>\n''', )
            #endfor
            _buf[99999:] = ('''</table>\n''', )
            output = "".join(_buf)

    @bench("StringIO")
    def _(bm):
        for _ in bm:
            _buf = StringIO()
            _buf.write('''<table>\n''')
            for user in users:
                _buf.write(''' <tr>
  <td>'''); _buf.write(user.name); _buf.write('''</td>
  <td><a href="mailto:'''); _buf.write(user.email); _buf.write('''">'''); _buf.write(user.email); _buf.write('''</a></td>
 </tr>\n''');
            #endfor
            _buf.write('''</table>\n''')
            output = _buf.getvalue()

    MM = mmap.mmap(-1, 2*1024*1024)

    @bench("mmap")
    def _(bm):
        if python3:
            return "mmap() doesn't handle string"
        for _ in bm:
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

    @bench("generator")
    def _(bm):
        def _generate_template(users):
            yield '''<table>\n'''
            for user in users:
                yield ''' <tr>
  <td>'''; yield (user.name); yield '''</td>
  <td><a href="mailto:'''; yield (user.email); yield '''">'''; yield (user.email); yield '''</a></td>
 </tr>\n''';
            #endfor
            yield '''</table>\n'''
        for _ in bm:
            g = _generate_template(users)
            output = ''.join(g)



##
## output example
##
r"""
## benchmarker:         release 4.0.0 (for python)
## python version:      2.7.7
## python compiler:     GCC 4.2.1 Compatible Apple LLVM 6.0 (clang-600.0.51)
## python platform:     Darwin-14.0.0-x86_64-i386-64bit
## python executable:   /opt/vs/python/2.7.7/bin/python
## cpu model:           Intel(R) Core(TM) i7-4650U CPU @ 1.70GHz
## parameters:          loop=10000, cycle=5, extra=1

## (#1)                             real    (total    = user    + sys)
(Empty)                           0.0005    0.0000    0.0000    0.0000
append()                          0.7153    0.7200    0.7200    0.0000
extend()                          0.3861    0.3800    0.3800    0.0000
extend() (bound)                  0.3369    0.3300    0.3300    0.0000
slice[-1:]                        0.3908    0.3900    0.3900    0.0000
slice[99999:]                     0.4030    0.4000    0.4000    0.0000
StringIO                          2.4666    2.4600    2.4500    0.0100
mmap                              1.4611    1.4600    1.4600    0.0000
generator                         0.5140    0.5100    0.5100    0.0000

## (#2)                             real    (total    = user    + sys)
(Empty)                           0.0002    0.0000    0.0000    0.0000
append()                          0.6909    0.7000    0.6900    0.0100
extend()                          0.3935    0.3900    0.3900    0.0000
extend() (bound)                  0.3581    0.3500    0.3500    0.0000
slice[-1:]                        0.4100    0.4100    0.4100    0.0000
slice[99999:]                     0.4016    0.3900    0.3900    0.0000
StringIO                          2.4102    2.4100    2.4000    0.0100
mmap                              1.4816    1.4700    1.4700    0.0000
generator                         0.5087    0.5100    0.5100    0.0000

## (#3)                             real    (total    = user    + sys)
(Empty)                           0.0004    0.0000    0.0000    0.0000
append()                          0.7572    0.7500    0.7500    0.0000
extend()                          0.3768    0.3800    0.3800    0.0000
extend() (bound)                  0.3383    0.3300    0.3300    0.0000
slice[-1:]                        0.3738    0.3800    0.3700    0.0100
slice[99999:]                     0.3805    0.3800    0.3800    0.0000
StringIO                          2.3405    2.3300    2.3300    0.0000
mmap                              1.4765    1.4700    1.4700    0.0000
generator                         0.5503    0.5500    0.5500    0.0000

## (#4)                             real    (total    = user    + sys)
(Empty)                           0.0002    0.0000    0.0000    0.0000
append()                          0.7138    0.7100    0.7000    0.0100
extend()                          0.3774    0.3800    0.3800    0.0000
extend() (bound)                  0.3391    0.3400    0.3400    0.0000
slice[-1:]                        0.3735    0.3700    0.3700    0.0000
slice[99999:]                     0.3889    0.3800    0.3800    0.0000
StringIO                          2.4867    2.4900    2.4800    0.0100
mmap                              1.4597    1.4500    1.4500    0.0000
generator                         0.5276    0.5200    0.5200    0.0000

## (#5)                             real    (total    = user    + sys)
(Empty)                           0.0002    0.0000    0.0000    0.0000
append()                          0.6967    0.7000    0.7000    0.0000
extend()                          0.3814    0.3700    0.3700    0.0000
extend() (bound)                  0.3519    0.3500    0.3500    0.0000
slice[-1:]                        0.3744    0.3800    0.3800    0.0000
slice[99999:]                     0.3942    0.4000    0.3900    0.0100
StringIO                          2.4396    2.4300    2.4300    0.0000
mmap                              1.4419    1.4300    1.4300    0.0000
generator                         0.5468    0.5400    0.5400    0.0000

## (#6)                             real    (total    = user    + sys)
(Empty)                           0.0002    0.0000    0.0000    0.0000
append()                          0.6803    0.6900    0.6800    0.0100
extend()                          0.3814    0.3800    0.3800    0.0000
extend() (bound)                  0.3513    0.3500    0.3500    0.0000
slice[-1:]                        0.3635    0.3600    0.3600    0.0000
slice[99999:]                     0.3757    0.3700    0.3700    0.0000
StringIO                          2.3613    2.3600    2.3500    0.0100
mmap                              1.4690    1.4600    1.4600    0.0000
generator                         0.5224    0.5200    0.5200    0.0000

## (#7)                             real    (total    = user    + sys)
(Empty)                           0.0002    0.0000    0.0000    0.0000
append()                          0.6871    0.6800    0.6800    0.0000
extend()                          0.3752    0.3800    0.3800    0.0000
extend() (bound)                  0.3327    0.3300    0.3300    0.0000
slice[-1:]                        0.4074    0.4000    0.4000    0.0000
slice[99999:]                     0.3805    0.3900    0.3800    0.0100
StringIO                          2.4293    2.4200    2.4200    0.0000
mmap                              1.4762    1.4700    1.4700    0.0000
generator                         0.5025    0.5000    0.5000    0.0000

## Ignore min & max                  min     cycle       max     cycle
append()                          0.6803      (#6)    0.7572      (#3)
extend()                          0.3752      (#7)    0.3935      (#2)
extend() (bound)                  0.3327      (#7)    0.3581      (#2)
slice[-1:]                        0.3635      (#6)    0.4100      (#2)
slice[99999:]                     0.3757      (#6)    0.4030      (#1)
StringIO                          2.3405      (#3)    2.4867      (#4)
mmap                              1.4419      (#5)    1.4816      (#2)
generator                         0.5025      (#7)    0.5503      (#3)

## Average of 5 (=7-2*1)            real    (total    = user    + sys)
append()                          0.7008    0.7020    0.6980    0.0040
extend()                          0.3806    0.3780    0.3780    0.0000
extend() (bound)                  0.3435    0.3400    0.3400    0.0000
slice[-1:]                        0.3840    0.3840    0.3820    0.0020
slice[99999:]                     0.3892    0.3880    0.3840    0.0040
StringIO                          2.4214    2.4160    2.4100    0.0060
mmap                              1.4685    1.4620    1.4620    0.0000
generator                         0.5239    0.5200    0.5200    0.0000

## Ranking                          real
extend() (bound)                  0.3435  (100.0) ********************
extend()                          0.3806  ( 90.3) ******************
slice[-1:]                        0.3840  ( 89.5) ******************
slice[99999:]                     0.3892  ( 88.3) ******************
generator                         0.5239  ( 65.6) *************
append()                          0.7008  ( 49.0) **********
mmap                              1.4685  ( 23.4) *****
StringIO                          2.4214  ( 14.2) ***

## Matrix                           real    [01]    [02]    [03]    [04]    [05]    [06]    [07]    [08]
[01] extend() (bound)             0.3435   100.0   110.8   111.8   113.3   152.5   204.0   427.5   704.9
[02] extend()                     0.3806    90.3   100.0   100.9   102.2   137.7   184.1   385.8   636.2
[03] slice[-1:]                   0.3840    89.5    99.1   100.0   101.3   136.4   182.5   382.4   630.6
[04] slice[99999:]                0.3892    88.3    97.8    98.7   100.0   134.6   180.1   377.4   622.2
[05] generator                    0.5239    65.6    72.6    73.3    74.3   100.0   133.8   280.3   462.2
[06] append()                     0.7008    49.0    54.3    54.8    55.5    74.8   100.0   209.6   345.5
[07] mmap                         1.4685    23.4    25.9    26.1    26.5    35.7    47.7   100.0   164.9
[08] StringIO                     2.4214    14.2    15.7    15.9    16.1    21.6    28.9    60.6   100.0
"""
