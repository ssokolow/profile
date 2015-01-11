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
