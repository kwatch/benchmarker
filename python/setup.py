###
### $Release: $
### $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved $
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
version  = '4.0.0'
author   = 'makoto kuwata'
email    = 'kwa@kuwata-lab.com'
maintainer = author
maintainer_email = email
url      = 'https://pythonhosted.org/Benchmarker/'
desc     = 'small but awesome utility for benchmarking'
detail   = r'''
Benchmarker.py is an awesome utility for benchmarking.

Document: https://pythonhosted.org/Benchmarker/

Example code (example.py)::

    from benchmarker import Benchmarker

    ## specify number of loop
    with Benchmarker(1000*1000, width=20) as bench:
        s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"

        @bench(None)                ## empty loop
        def _(bm):
            for i in bm:
                pass

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

    $ python example.py -h
    $ python example.py -o result.json
    ## benchmarker:         release 4.0.0 (for python)
    ## python version:      3.4.2
    ## python compiler:     GCC 4.8.2
    ## python platform:     Linux-3.13.0-36-generic-x86_64-with-debian-jessie-sid
    ## python executable:   /opt/vs/python/3.4.2/bin/python
    ## cpu model:           Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz  # 2494.050 MHz
    ## parameters:          loop=1000000, cycle=1, extra=0

    ##                        real    (total    = user    + sys)
    (Empty)                 0.0236    0.0200    0.0200    0.0000
    join                    0.2779    0.2800    0.2800    0.0000
    concat                  0.3792    0.3800    0.3800    0.0000
    format                  0.4233    0.4300    0.4300    0.0000

    ## Ranking                real
    join                    0.2779  (100.0) ********************
    concat                  0.3792  ( 73.3) ***************
    format                  0.4233  ( 65.6) *************

    ## Matrix                 real    [01]    [02]    [03]
    [01] join               0.2779   100.0   136.5   152.3
    [02] concat             0.3792    73.3   100.0   111.6
    [03] format             0.4233    65.6    89.6   100.0

See ``python example.py -h`` for details.
'''
license  = "Public Domain"
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
    'Programming Language :: Python :: 2.5',
    'Programming Language :: Python :: 2.6',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.0',
    'Programming Language :: Python :: 3.1',
    'Programming Language :: Python :: 3.2',
    'Programming Language :: Python :: 3.3',
    'Programming Language :: Python :: 3.4',
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
