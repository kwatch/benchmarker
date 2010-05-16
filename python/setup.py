###
### $Release: 1.0.0 $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

import sys, re, os
arg1 = len(sys.argv) > 1 and sys.argv[1] or None
if arg1 == 'egg_info':
    from ez_setup import use_setuptools
    use_setuptools()
if arg1 == 'bdist_egg':
    from setuptools import setup
else:
    from distutils.core import setup


name     = 'Benchmarker'
version  = '1.0.0'
author   = 'makoto kuwata'
email    = 'kwa@kuwata-lab.com'
maintainer = author
maintainer_email = email
url      = 'http://pypi.python.org/pypi'
desc     = 'a small utility for benchmarking'
detail   = """
Benchmarker is a small utility to benchmark your code.

Example (ex.py)::

    def fib(n):
        return n <= 2 and 1 or fib(n-1) + fib(n-2)
    from benchmarker import Benchmarker
    bm = Benchmarker()  # or Benchmarker(width=30, out=sys.stderr, header=True)
    ## Python 2.5 or later
    with bm('fib(n) (n==34)'):  fib(34)
    with bm('fib(n) (n==35)'):  fib(35)
    ## Python 2.4
    bm('fib(n) (n==34)').run(lambda: fib(34))
    bm('fib(n) (n==35)').run(lambda: fib(35))

Output::

    $ python ex.py
                                       utime      stime      total       real
    fib(n) (n==34)                    4.3700     0.0200     4.3900     4.9449
    fib(n) (n==35)                    7.1500     0.0500     7.2000     8.0643

"""[1:]
license  = 'Public Domain'
platforms = 'any'
#download = 'http://downloads.sourceforge.net/oktest/Benchmarker-%s.tar.gz' % version
download = 'http://pypi.python.org/packages/source/B/Benchmarker/Benchmarker-%s.tar.gz' % version
classifiers = [
    'Development Status :: 5 - Production/Stable',
    'Environment :: Console',
    'Intended Audience :: Developers',
    'License :: Public Domain',
    'Operating System :: OS Independent',
    'Programming Language :: Python',
    'Programming Language :: Python :: 2.3',
    'Programming Language :: Python :: 2.4',
    'Programming Language :: Python :: 2.5',
    'Programming Language :: Python :: 2.6',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.0',
    'Programming Language :: Python :: 3.1',
    'Topic :: Software Development :: Libraries :: Python Modules',
    'Topic :: System :: Benchmark',
]


setup(
    name=name,
    version=version,
    author=author,  author_email=email,
    maintainer=maintainer, maintainer_email=maintainer_email,
    description=desc,  long_description=detail,
    url=url,  download_url=download,  classifiers=classifiers,
    license=license,
    #platforms=platforms,
    #
    py_modules=['benchmarker'],
    #package_dir={'': 'lib'},
    #scripts=['bin/pytenjin'],
    #packages=['tenjin'],
    #zip_safe = False,
)
