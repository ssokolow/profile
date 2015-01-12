#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# pylint: disable=invalid-name
"""A simple tool for deleting the files listed in a K3b project after it has
been written to a disc. (Useful in concert with gaff-k3b)

--snip--

@note: This currently explicitly uses C{posixpath} rather than C{os.path}
       since, as a POSIX-only program, K3b is going to be writing project files
       that always use UNIX path separators.

@todo: Need test directory and filenames containing unicode characters.
"""

from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__appname__ = "File-Deleting Companion for gaff-k3b"
__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.0pre0"
__license__ = "MIT"

import os, posixpath, shutil, sys
import xml.etree.cElementTree as ET
from zipfile import ZipFile

# ---=== Actual Code ===---

def parse_proj_directory(parent_path, node):
    """Recursive helper for traversing k3b project XML"""
    results = {}
    for item in node:
        path = posixpath.join(parent_path, item.get("name", ''))
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

def list_batch(src_pairs):
    """Given the output of L{parse_k3b_proj}, list all files"""
    for src_path, _ in sorted(src_pairs.items()):
        print(src_path)

def mounty_join(a, b):
    """Join paths C{a} and C{b} while ignoring leading separators on C{b}"""
    b = b.lstrip(os.sep).lstrip(os.altsep or os.sep)
    return os.path.join(a, b)

def move_batch(src_pairs, dest_dir):
    """Given output from L{parse_k3b_proj}, move all files and preserve paths
       relative to the project root.
    """
    for src_path, dest_rel in sorted(src_pairs.items()):
        if not os.path.exists(src_path):
            print("Doesn't exist (Already handled?): %s" % src_path)
            continue

        dest_path = mounty_join(dest_dir, dest_rel)

        # XXX: How should I handle potential overwriting?
        print("%r -> %r" % (src_path, dest_path))
        shutil.move(src_path, dest_path)

def rm_batch(src_pairs):
    """Given the output of L{parse_k3b_proj}, remove all files"""
    for src_path, _ in sorted(src_pairs.items()):
        if not os.path.exists(src_path):
            print("Doesn't exist (Already handled?): %s" % src_path)
            continue

        print("REMOVING: %s" % src_path)
        if os.path.isdir(src_path):
            shutil.rmtree(src_path)
        else:
            os.remove(src_path)

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

    opts, args = parser.parse_args()

    if opts.target and not os.path.isdir(opts.target):
        print("Target path is not a directory: %s" % opts.target)
        sys.exit(2)

    for path in args:
        files = parse_k3b_proj(path)

        if opts.target:
            move_batch(files, opts.target)
        elif opts.remove:
            rm_batch(files)
        else:
            list_batch(files)
            print("\nRe-run this command with the --remove option to "
                  "actually remove these files.")

# ---=== Test Suite ===---

if sys.argv[0].endswith('nosetests'):  # pragma: nobranch
    import tempfile, unittest
    try:
        from unittest.mock import patch  # pylint: disable=E0611,F0401
    except ImportError:
        from mock import patch

    class TestK3bRm(unittest.TestCase):  # pylint: disable=R0904
        """Test suite for k3b-rm to be run via C{nosetests}."""
        def setUp(self):  # NOQA
            """Generate all data necessary for a test run"""
            # Avoid importing these in non-test operation
            import zipfile
            from cStringIO import StringIO

            self.dest = tempfile.mkdtemp(prefix='k3b-rm_test-dest-')
            self.root = tempfile.mkdtemp(prefix='k3b-rm_test-src-')
            self.project = tempfile.NamedTemporaryFile(prefix='k3b-rm_test-',
                                                       suffix='.k3b')

            test_dom = ET.Element("k3b_data_project")
            files = ET.SubElement(test_dom, "files")

            self.expected = self._add_files(self.root, files, depth=2)
            test_tree = ET.ElementTree(test_dom)
            xmldata = StringIO()
            test_tree.write(xmldata, encoding="UTF-8", xml_declaration=True)

            with zipfile.ZipFile(self.project, 'w') as zobj:
                zobj.writestr("maindata.xml", xmldata.getvalue())

        def tearDown(self):  # NOQA
            shutil.rmtree(self.root)
            shutil.rmtree(self.dest)
            del self.root
            del self.dest
            del self.project
            del self.expected

        def _make_file_node(self, dom_parent, fpath):  # pylint: disable=R0201
            """Add a file/url node stack as a child of the given parent"""
            fnode = ET.SubElement(dom_parent, "file")
            fnode.set("name", posixpath.basename(fpath))
            unode = ET.SubElement(fnode, "url")
            unode.text = fpath

        def _add_files(self, parent, dom_parent, parent_names=None, depth=0):
            """Generate a list of expected test files and populate test XML"""
            # Avoid importing this in non-test operation

            expect, parent_names = {}, parent_names or []
            for x in range(1, 7):
                fpath = posixpath.join(parent,
                                       '_'.join(parent_names + [str(x)]))

                # `touch $fpath`
                open(fpath, 'w').close()
                self._make_file_node(dom_parent, fpath)

                expect[fpath] = fpath[len(self.root):]

            # For robustness-testing
            ET.SubElement(dom_parent, "garbage")

            # To test a purely hypothetical case
            dpath = posixpath.join(parent, '_'.join(parent_names + ['dir']))
            os.makedirs(dpath)
            self._make_file_node(dom_parent, dpath)
            expect[dpath] = dpath[len(self.root):]

            if depth:
                for x in 'abcdef':
                    path = posixpath.join(parent, x)

                    os.makedirs(path)

                    subdir = ET.SubElement(dom_parent, "directory")
                    subdir.set("name", x)

                    expect.update(self._add_files(path,
                                                  subdir,
                                                  parent_names + [x],
                                                  depth - 1))
            return expect

        def test_parse_k3b_proj(self):
            """parse_k3b_proj: basic functionality"""
            got = parse_k3b_proj(self.project.name)
            self.assertDictEqual(self.expected, got)

        @patch("os.remove")
        @patch("os.unlink")
        @patch("shutil.rmtree")
        def test_rm_batch(self, *mocks):
            """rm_batch: deletes exactly the right files"""
            rm_batch(self.expected)
            results = [y[0][0] for x in mocks for y in x.call_args_list]
            self.assertListEqual(sorted(self.expected), sorted(results))

        def test_rm_batch_nonexistant(self):
            """rm_batch: handles missing files gracefully"""
            os.unlink(posixpath.join(self.root, 'b', 'b_3'))
            rm_batch(self.expected)
            rm_batch(self.expected)
            for x in self.expected:
                self.assertFalse(os.path.exists(x))

            # TODO: This requires the directory-clearing code
            # self.assertListEqual(os.listdir(self.root), [])

        def test_mounty_join(self):
            """mounty_join: proper behaviour"""
            for path_a in ('/foo', '/foo/'):
                for path_b in ('baz', '/baz', '//baz', '///baz'):
                    self.assertEqual(mounty_join(path_a, path_b),
                                     '/foo/baz', "%s + %s" % (path_a, path_b))

        @patch("shutil.move")
        def test_move_batch(self, move):
            """move_batch: puts files in the right places"""
            move_batch(self.expected, self.dest)

            results = {x[0][0]: x[0][1] for x in move.call_args_list}
            for src, dest_rel in self.expected.items():
                self.assertIn(src, results)
                self.assertEqual(mounty_join(self.dest, dest_rel),
                                 results[src])
                del results[src]
            self.assertDictEqual(results, {})

        def test_list_batch(self):
            """list_batch: doesn't raise exception when called"""
            list_batch(self.expected)

        @patch("sys.exit")
        @patch.object(sys, 'argv', [__file__, '-m', tempfile.mktemp()])
        def test_main_bad_destdir(self, sysexit):
            """main: calls sys.exit(2) for a bad -m path"""
            main()
            self.assertIsNotNone(sysexit.call_args)
            self.assertEqual(sysexit.call_args[0][0], 2)

        @patch.object(sys.modules[__name__], "list_batch")
        def test_main_list(self, lsbatch):
            """main: list_batch is default but only with args"""
            with patch.object(sys, 'argv', [__file__]):
                main()
                self.assertFalse(lsbatch.called)

            with patch.object(sys, 'argv',
                              [__file__, self.project.name]):
                main()
                self.assertTrue(lsbatch.called)

        @patch.object(sys.modules[__name__], "rm_batch")
        def test_main_remove(self, rmbatch):
            """main: --remove triggers rm_batch but only with args"""
            with patch.object(sys, 'argv', [__file__, '--remove']):
                main()
                self.assertFalse(rmbatch.called)

            with patch.object(sys, 'argv',
                              [__file__, '--remove', self.project.name]):
                main()
                self.assertTrue(rmbatch.called)

        @patch.object(sys.modules[__name__], "move_batch")
        def test_main_move(self, mvbatch):
            """main: --move triggers move_batch but only with args"""
            with patch.object(sys, 'argv', [__file__, '--move', '/']):
                main()
                self.assertFalse(mvbatch.called)

            with patch.object(sys, 'argv',
                              [__file__, '--move', '/', self.project.name]):
                main()
                self.assertTrue(mvbatch.called)

if __name__ == '__main__':
    main()
