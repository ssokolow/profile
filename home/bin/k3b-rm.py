#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""A simple tool for deleting the files listed in a K3b project after it has
been written to a disc. (Useful in concert with gaff-k3b)"""

__appname__ = "File-Deleting Companion for gaff-k3b"
__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.0pre0"
__license__ = "MIT"

import os, posixpath, shutil, sys
import xml.etree.cElementTree as ET
from zipfile import ZipFile

def parse_k3b_proj(path):
    """Parse a K3b project file into a list of paths"""
    with ZipFile(path) as zfh:
        xml = zfh.read('maindata.xml')

    root = ET.fromstring(xml)
    del xml

    return [x.text for x in root.findall('./files//file/url')]

def test_parse_k3b_proj():
    test_root = '/tmp/k3b-rm_test/'  # TODO: Make this dynamic

    def add_files(parent, parent_names=None, depth=0):
        """Generate the list of expected test files"""
        expect, parent_names = [], parent_names or []
        for x in range(1, 7):
            expect.append(posixpath.join(parent,
                                         '_'.join(parent_names + [str(x)])))
        if depth:
            for x in 'abcdef':
                expect.extend(add_files(posixpath.join(parent, x),
                                        parent_names + [x],
                                        depth - 1))
        return expect

    expected = add_files(test_root, depth=2)
    got = parse_k3b_proj(os.path.join(
        os.path.dirname(__file__), "k3b-rm_test.k3b"))

    for x in expected:
        assert x in got, x
    for x in got:
        assert x in expected, x

if __name__ == '__main__':
    # pylint: disable=bad-continuation
    from optparse import OptionParser
    parser = OptionParser(version="%%prog v%s" % __version__,
            usage="%prog [options] <K3b Project File> ...",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_option('-m', '--move', action="store", dest="target",
        default=None, help="Move the files to the provided path.")
    parser.add_option('--remove', action="store_true", dest="remove",
        default=False, help="Actually remove the files found.")

    # Allow pre-formatted descriptions
    parser.formatter.format_description = lambda description: description

    opts, args = parser.parse_args()

    if opts.target and not os.path.isdir(opts.target):
        print "Target path is not a directory: %s" % opts.target
        sys.exit(2)

    DRY_RUN = False
    for path in args:
        files = parse_k3b_proj(path)

        for fpath in files:
            if not os.path.exists(fpath):
                print "Doesn't exist (Already handled?): %s" % fpath
            elif opts.target:
                # XXX: How should I handle potential overwriting?
                print "%r -> %r" % (fpath, opts.target)
                shutil.move(fpath, opts.target)
            elif opts.remove:
                print "REMOVING: %s" % fpath
                if os.path.isdir(fpath):
                    shutil.rmtree(fpath)
                else:
                    os.remove(fpath)
            else:
                DRY_RUN = True
                print fpath
    if DRY_RUN:
        print ("\nRe-run this command with the --remove option to actually "
               "remove these files.")
