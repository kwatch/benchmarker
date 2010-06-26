# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

##
# cookbook for Benchmarker -- you must install pykook at first.
## pykook is a build tool like Rake. you can define your task in Python.
## http://pypi.python.org/pypi/Kook/
## http://www.kuwata-lab.com/kook/pykook-users-guide.html
##

from __future__ import with_statement

import os, re
from glob import glob
from kook.utils import read_file, write_file
kook_default_product = 'test'

release   = prop('release', '1.0.0')
package   = prop('package', 'Benchmarker')
copyright = prop('copyright', "copyright(c) 2010 kuwata-lab.com all rights reserved")
license   = "Public Domain"
#kook_default_product = 'test'

python = prop('python', 'python')


@recipe
def task_test(c):
    for fname in glob('test/test_*.py'):
        system(c%"$(python) $(fname)")


@recipe
def task_clean(c):
    rm_rf('*.pyc', '*/*.pyc', 'dist')


@recipe
def task_edit(c):
    def replacer(s):
        s = re.sub(r'\$Release:[^%]*?\$',    '$Release: %s $'   % release,   s)
        s = re.sub(r'\$Copyright:[^%]*?\$',  '$Copyright: %s $' % copyright, s)
        s = re.sub(r'\$License:[^%]*?\$',    '$License: %s $'   % license,   s)
        return s
    filenames = read_file('MANIFEST').splitlines()
    filenames.remove('Kookbook.py')
    edit(filenames, by=replacer)


@recipe
@spices('-a: create all egg packages for 2.4~2.7')
def task_package(c, *args, **kwargs):
    """create package"""
    ## remove files
    pattern = c%"dist/$(package)-$(release)*"
    if glob(pattern):
        rm_rf(pattern)
    ## edit files
    repl = (
        (r'\$Release\$',   release),
        (r'\$Copyright\$', copyright),
        (r'\$License\$',   license),
        (r'\$Package\$',   package),
        (r'\$Release:[^%]*?\$',   '$Release: %s $'   % release),
        (r'\$Copyright:[^%]*?\$', '$Copyright: %s $' % copyright),
        (r'\$License:[^%]*?\$',   '$License: %s $'   % license),
        (r'X\.X\.X',  release)
    )
    ## setup
    system(c%'$(python) setup.py sdist')
    #system(c%'$(python) setup.py sdist --keep-temp')
    with chdir('dist') as d:
        #pkgs = kook.util.glob2(c%"$(package)-$(release).tar.gz");
        #pkg = pkgs[0]
        pkg = c%"$(package)-$(release).tar.gz"
        echo(c%"pkg=$(pkg)")
        #tar_xzf(pkg)
        system(c%"tar xzf $(pkg)")
        dir = re.sub(r'\.tar\.gz$', '', pkg)
        #echo("*** debug: pkg=%s, dir=%s" % (pkg, dir))
        edit(c%"$(dir)/**/*", by=repl, exclude='*/oktest.py')
        #with chdir(dir):
        #    system(c%"$(python) setup.py egg_info --egg-base .")
        #    rm("*.pyc")
        mv(pkg, c%"$(pkg).bkup")
        #tar_czf(c%"$(dir).tar.gz", dir)
        system(c%"tar -cf $(dir).tar $(dir)")
        system(c%"gzip -f9 $(dir).tar")
        ## create *.egg file
        opt_a = kwargs.get('a')
        with chdir(dir):
            if opt_a:
                pythons = [
                    '/opt/local/bin/python2.7',
                    '/opt/local/bin/python2.6',
                    '/opt/local/bin/python2.5',
                    '/opt/local/bin/python2.4',
                ]
            else:
                pythons = [ python ]
            for py in pythons:
                system(c%'$(py) setup.py bdist_egg')
                mv("dist/*.egg", "..")
                rm_rf("build", "dist")
