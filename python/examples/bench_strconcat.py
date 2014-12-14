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



with Benchmarker(loop=10000, cycle=5, extra=1) as bench:

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
