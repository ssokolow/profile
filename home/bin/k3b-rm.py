#!/usr/bin/env python
# -*- coding: utf-8 -*-
# pylint: disable=invalid-name
"""A simple tool for deleting the files listed in a K3b project after it has
been written to a disc. (Useful in concert with gaff-k3b)"""

__appname__ = "File-Deleting Companion for gaff-k3b"
__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.0pre0"
__license__ = "MIT"

import os, shutil, sys
import xml.etree.cElementTree as ET
from zipfile import ZipFile

# ---=== Actual Code ===---

def parse_proj_directory(parent_path, node):
    """Recursive helper for traversing k3b project XML"""
    results = {}
    for item in node:
        path = os.path.join(parent_path, item.get("name", ''))
        if item.tag == 'file':
            results[item.find('.//url').text] = path
        elif item.tag == 'directory':
            results.update(parse_proj_directory(path, item))
    return results

def parse_k3b_proj(path):
    """Parse a K3b project file into a list of paths"""
    with ZipFile(path) as zfh:
        xml = zfh.read('maindata.xml')

    root = ET.fromstring(xml)
    del xml

    return parse_proj_directory('/', root.find('./files'))

def main():
    """setuptools-compatible entry point"""
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

    dry_run = False
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
                dry_run = True
                print fpath
    if dry_run:
        print ("\nRe-run this command with the --remove option to actually "
               "remove these files.")

# ---=== Test Suite ===---

import unittest

class TestK3bRm(unittest.TestCase):  # pylint: disable=too-many-public-methods
    """Test suite for k3b-rm to be run via C{nosetests}."""
    def setUp(self):  # NOQA
        """Generate all data necessary for a test run"""
        # Avoid importing these in non-test operation
        import tempfile, zipfile
        from cStringIO import StringIO

        test_root = tempfile.mkdtemp(prefix='k3b-rm_test-')
        test_projfile = tempfile.NamedTemporaryFile(prefix='k3b-rm_test-',
                                                    suffix='.k3b')

        test_dom = ET.Element("k3b_data_project")
        files = ET.SubElement(test_dom, "files")

        expected = self._add_files(test_root, files, depth=2)
        test_tree = ET.ElementTree(test_dom)
        xmldata = StringIO()
        test_tree.write(xmldata, encoding="UTF-8", xml_declaration=True)

        with zipfile.ZipFile(test_projfile, 'w') as zobj:
            zobj.writestr("maindata.xml", xmldata.getvalue())

        self.project = test_projfile
        self.root = test_root
        self.expected = expected

    def tearDown(self):  # NOQA
        del self.project
        shutil.rmtree(self.root)

    def _add_files(self, parent, dom_parent, parent_names=None, depth=0):
        """Generate the list of expected test files and populate test XML"""
        # Avoid importing this in non-test operation
        import posixpath

        expect, parent_names = [], parent_names or []
        for x in range(1, 7):
            fname = '_'.join(parent_names + [str(x)])
            fpath = posixpath.join(parent, fname)

            # `touch $fpath`
            open(fpath, 'w').close()

            fnode = ET.SubElement(dom_parent, "file")
            fnode.set("name", fname)
            unode = ET.SubElement(fnode, "url")
            unode.text = fpath

            expect.append(fpath)
        if depth:
            for x in 'abcdef':
                path = posixpath.join(parent, x)

                # XXX: Is it worth it to ensure this runs on non-POSIX OSes?
                os.makedirs(path)

                subdir = ET.SubElement(dom_parent, "directory")
                subdir.set("name", x)

                expect.extend(self._add_files(path,
                                              subdir,
                                              parent_names + [x],
                                              depth - 1))
        return expect

    def test_parse_k3b_proj(self):
        """Test basic parsing of .k3b files"""
        got = parse_k3b_proj(self.project.name)

        for x in self.expected:
            self.assertIn(x, got)
        for x in got:
            self.assertIn(x, self.expected)


if __name__ == '__main__':
    main()
