# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

##
## cookbook for Benchmarker -- you must install pykook at first.
## pykook is a build tool like Rake. you can define your task in Python.
## http://pypi.python.org/pypi/Kook/
## http://www.kuwata-lab.com/kook/pykook-users-guide.html
##

from __future__ import with_statement

import os, re
from glob import glob
from kook.utils import read_file, write_file
kook_default_product = 'test'

release   = prop('release', '4.0.1')
package   = prop('package', 'Benchmarker')
copyright = prop('copyright', "copyright(c) 2010-2011 kuwata-lab.com all rights reserved")
license   = "Public Domain"
#kook_default_product = 'test'

python = prop('python', 'python')


python_versions = [
    #('2.4', '/opt/local/bin/python2.4'),
    ('2.5', '/opt/local/bin/python2.5'),
    ('2.6', '/opt/local/bin/python2.6'),
    ('2.7', '/opt/local/bin/python2.7'),
    ('3.0', '/usr/local/python/3.0.1/bin/python'),
    ('3.1', '/usr/local/python/3.1/bin/python'),
    ('3.2', '/usr/local/python/3.2rc1/bin/python'),
]

@recipe
@spices("-a: do test with python from 2.4 to 3.2")
def task_test(c, *args, **kwargs):
    if kwargs.get('a'):
        for ver, bin in python_versions:
            print("#")
            print("# python %s (%s)" % (ver, bin))
            print("#")
            for fname in glob('test/*_test.py'):
                system(c%"$(bin) $(fname)")
    else:
        for fname in glob('test/*_test.py'):
            system(c%"$(python) $(fname)")


@recipe
def task_clean(c):
    rm_rf('*.pyc', '*/*.pyc', 'dist', 'index.html')


@recipe
def task_edit(c):
    def replacer(s):
        #s = re.sub(r'\$Release:[^%]*?\$',    '$Release: %s $'   % release,   s)
        s = re.sub(r'\$Copyright:[^%]*?\$',  '$Copyright: %s $' % copyright, s)
        s = re.sub(r'\$License:[^%]*?\$',    '$License: %s $'   % license,   s)
        return s
    filenames = read_file('MANIFEST').splitlines()
    filenames.remove('Kookbook.py')
    filenames.remove('test/oktest.py')
    edit(filenames, by=replacer)
    replacer = lambda s: re.sub(r'\$Release:[^%]*?\$', '$Release: %s $' % release, s)
    #edit('README.txt', by=replacer)
    pat = re.compile(r'^(version *= *).*?$', re.M)
    replacer = lambda s: pat.sub(r"\1'%s'" % release, s)
    edit('setup.py', by=replacer)

@recipe
@spices('-a: create src dist file')
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
    #
    print(c%"** created: dist/$(package)-$(release).tar.gz")


@recipe
@product('test/oktest.py')
def file_test_oktest_py(c):
    fpath = '../../oktest/python/lib/oktest.py'
    if not os.path.exists(fpath):
        raise Exception("%f: not found." % fpath)
    cp(fpath, c.product)


@recipe
@ingreds('test/oktest.py')
def oktest(c):
    """copy oktest.py to test"""
    pass



@recipe
@product('README.html')
#@ingreds('README.txt')
@ingreds('README.rst')
def file_README_html(c):
    """generate README.html from README.rst"""
    rst2html = 'rst2html-2.7.py'
    #system(c%"$(rst2html) -i utf-8 -o utf-8 -l en --stylesheet-path=style.css $(ingred) > $(product)")
    system(c%"$(rst2html) -i utf-8 -o utf-8 -l en --stylesheet=style.css --link-stylesheet $(ingred) > $(product)")
    #system(c%"$(rst2html) -i utf-8 -o utf-8 -l en $(ingred) > $(product)")
    with open(c.product, 'r+') as f:
        s = f.read()
        s = s.replace('{{*', '<strong>')
        s = s.replace('*}}', '</strong>')
        s = s.replace('&quot;', '"')
        s = s.replace('&#64;', '@')
        meta_charset = '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />'
        meta_viewport = '<meta name="viewport" content="width=device-width; initial-scale=1.0" />'
        s = s.replace(meta_charset, meta_charset + '\n' + meta_viewport)
        f.seek(0)
        f.truncate(0)
        f.write(s)
    #system(c%"perl -pi -e 's/\{\{\*/<strong>/g;s/\*\}\}/<\/strong>/g;' $(product)")
    #system(c%"perl -pi -e 's/\&quot;/\"/g;s/\&#64;/\@/g;' $(product)")
    #system(c%"rst2html.py -i utf-8 -o utf-8 -l en $(ingred) > $(product)")
    #system_f(c%'kwaser -t html-css $(ingred) > $(product)')
    #system_f(c%'tidy -q -m -utf8 -i -w 0 $(product)')


@recipe
@spices('-f README.rst: filename')
def task_examples(c, **kwargs):
    """retrieve example files from README.rst"""
    readme_file = kwargs.get('f') or 'README.rst'
    script_name = None
    lines = None
    for line in open(readme_file):
        import sys
        if script_name:
            m1 = re.match('^    (.*\n)', line)
            m2 = re.match('^\s*$', line)
            if m1:
                lines.append(m1.group(1))
                continue
            elif m2:
                lines.append("\n")
                continue
            else:
                content = ''.join(lines)
                content = re.sub(r'\{\{\*(.*?)\*\}\}', r'\1', content)
                open(script_name, 'w').write(content)
                print("- %s" % script_name)
                script_name = None
                lines = None
                #continue
        m = re.search(r'\((ex\d\.py)\)', line)
        if m:
            script_name = m.group(1)
            lines = []

@recipe
@product('website.zip')
@ingreds('README.html', 'style.css')
def file_website_zip(c):
    """create zip file for https://pythonhosted.org/"""
    cp('README.html', 'index.html')
    replacer = [
        (r'Release: 0\.0\.0', 'Release: %s' % release),
        (r'X\.X\.X', release),
    ]
    edit('index.html', by=replacer)
    system(c%"zip $(product) index.html style.css")
