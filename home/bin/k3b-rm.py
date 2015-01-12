#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# pylint: disable=invalid-name
"""A simple tool for deleting the files listed in a K3b project after it has
been written to a disc. (Useful in concert with gaff-k3b)

--snip--

@note: This currently explicitly uses C{posixpath} rather than C{os.path}
       since, as a POSIX-only program, K3b is going to be writing project files
       that always use UNIX path separators.
"""

from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__appname__ = "File-Deleting Companion for gaff-k3b"
__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.0pre0"
__license__ = "MIT"

import logging
log = logging.getLogger(__name__)

import os, posixpath, shutil, sys
import xml.etree.cElementTree as ET
from zipfile import ZipFile

# ---=== Actual Code ===---

def list_batch(src_pairs):
    """Given the output of L{parse_k3b_proj}, list all files"""
    for src_path in sorted(src_pairs.keys()):
        log.info(src_path)

def main():
    """setuptools-compatible entry point"""
    from optparse import OptionParser
    parser = OptionParser(version="%%prog v%s" % __version__,
            usage="%prog [options] <K3b Project File> ...",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_option('-v', '--verbose', action="count", dest="verbose",
        default=3, help="Increase the verbosity. Use twice for extra effect")
    parser.add_option('-q', '--quiet', action="count", dest="quiet",
        default=0, help="Decrease the verbosity. Use twice for extra effect")
    parser.add_option('-m', '--move', action="store", dest="target",
        default=None, help="Move the files to the provided path.")
    parser.add_option('--overwrite', action="store_true", dest="overwrite",
        default=False, help="Allow --move to overwrite files at the target.")
    parser.add_option('--remove', action="store_true", dest="remove",
        default=False, help="Actually remove the files found.")

    opts, args = parser.parse_args()

    # Set up clean logging to stderr
    log_levels = [logging.CRITICAL, logging.ERROR, logging.WARNING,
                  logging.INFO, logging.DEBUG]
    opts.verbose = min(opts.verbose - opts.quiet, len(log_levels) - 1)
    opts.verbose = max(opts.verbose, 0)
    logging.basicConfig(level=log_levels[opts.verbose],
                        format='%(levelname)s: %(message)s')

    if opts.target and not os.path.isdir(opts.target):
        log.critical("Target path is not a directory: %s", opts.target)
        sys.exit(2)

    for path in args:
        files = parse_k3b_proj(path)

        if opts.target:
            move_batch(files, opts.target, overwrite=opts.overwrite)
            remove_emptied_dirs(files)
        elif opts.remove:
            rm_batch(files)
            remove_emptied_dirs(files)
        else:
            list_batch(files)
            log.info("Re-run this command with the --remove option to actually"
                     " remove these files.")

def mounty_join(a, b):
    """Join paths C{a} and C{b} while ignoring leading separators on C{b}"""
    b = b.lstrip(os.sep).lstrip(os.altsep or os.sep)
    return posixpath.join(a, b)

def move_batch(src_pairs, dest_dir, overwrite=False):
    """Given output from L{parse_k3b_proj}, move all files and preserve paths
       relative to the project root.
    """
    for src_path, dest_rel in sorted(src_pairs.items()):
        if not os.path.exists(src_path):
            log.warn("Doesn't exist (Already handled?): %s", src_path)
            continue

        dest_path = mounty_join(dest_dir, dest_rel)

        if os.path.exists(dest_path) and not overwrite:
            log.warn("Skipping (target already exists): %r -> %r",
                  src_path, dest_path)
        else:
            log.info("%r -> %r", src_path, dest_path)
            shutil.move(src_path, dest_path)

def parse_k3b_proj(path):
    """Parse a K3b project file into a list of paths"""
    with ZipFile(path) as zfh:
        xml = zfh.read('maindata.xml')

    root = ET.fromstring(xml)
    del xml

    return parse_proj_directory('/', root.find('./files'))

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

def remove_emptied_dirs(file_paths):
    """Remove folders which have been emptied by removing the given files"""

    # TODO: Proper test suite for this
    while file_paths:
        diminished = set()

        #  Sort in reverse order to appromixate os.walk(topdown=False) for
        #  improved efficiency.
        for path in sorted(file_paths, reverse=True):
            parent = os.path.dirname(path)
            try:  # We do this for atomic test/act behaviour
                os.rmdir(parent)
            except OSError, err:
                if err.errno in (errno.ENOENT, errno.EACCES, errno.ENOTEMPTY):
                    pass
                else:
                    raise
            else:
                diminished.add(parent)

        # Iteratively walk up until we run out of emptied ancestors
        file_paths = diminished

def rm_batch(src_pairs):
    """Given the output of L{parse_k3b_proj}, remove all files"""
    for src_path, _ in sorted(src_pairs.items()):
        if not os.path.exists(src_path):
            log.warn("Doesn't exist (Already handled?): %s", src_path)
            continue

        log.info("REMOVING: %s", src_path)
        if os.path.isdir(src_path):
            shutil.rmtree(src_path)
        else:
            os.remove(src_path)

# ---=== Test Suite ===---

if sys.argv[0].endswith('nosetests'):  # pragma: nobranch
    import errno, tempfile, unittest
    from cStringIO import StringIO

    try:
        from unittest.mock import patch, DEFAULT  # pylint: disable=E0611,F0401
        from unittest.mock import mock_open  # pylint: disable=E0611,F0401
    except ImportError:
        from mock import patch, DEFAULT, mock_open

    def _file_exists(src, *_):
        """Used with C{side_effect} to make filesystem mocks stricter"""
        if os.path.exists(src):
            return DEFAULT
        else:
            raise IOError(errno.ENOENT, '%s: %r' %
                          (os.strerror(errno.ENOENT), src))

    def _make_file_node(dom_parent, fpath):
        """Add a file/url node stack as a child of the given parent"""
        fnode = ET.SubElement(dom_parent, "file")
        fnode.set("name", posixpath.basename(fpath))
        unode = ET.SubElement(fnode, "url")
        unode.text = fpath

    def touch_with_parents(path):
        """Touch a file into existence, including parents if needed"""
        parent = posixpath.dirname(path)
        if not os.path.exists(parent):
            os.makedirs(parent)

        # `touch $fpath`
        open(path, 'a').close()

    class MockDataMixin(object):  # pylint: disable=R0903
        """Code common to both light and heavy tests"""

        maxDiff = None
        longMessage = True
        root_placeholder = u'~ROOT~'

        @classmethod
        def setUpClass(cls):  # NOQA
            """Profiling showed over 25% of test time spent on ElementTree.

            This cuts that in half.
            """
            test_dom = ET.Element("k3b_data_project")
            files = ET.SubElement(test_dom, "files")

            cls.expected_tmpl = cls._add_files(cls.root_placeholder,
                                               files, depth=2)
            cls.xmldata_tmpl = StringIO()
            test_tree = ET.ElementTree(test_dom)
            test_tree.write(cls.xmldata_tmpl,
                            encoding="UTF-8",
                            xml_declaration=True)

        @classmethod
        def _add_files(cls, parent, dom_parent, parent_names=None, depth=0):
            """Generate a list of expected test files and populate test XML"""
            expect, parent_names = {}, parent_names or []
            for x in '123ïøµñ':
                fpath = posixpath.join(parent,
                                       '_'.join(parent_names + [x]))

                _make_file_node(dom_parent, fpath)
                expect[fpath] = fpath[len(cls.root_placeholder):]

            # For robustness-testing
            ET.SubElement(dom_parent, "garbage")

            # To test a purely hypothetical case
            dpath = posixpath.join(parent, '_'.join(parent_names + ['dir']))
            _make_file_node(dom_parent, dpath)
            expect[dpath] = dpath[len(cls.root_placeholder):]

            if depth:
                for x in 'æßçð€f':
                    path = posixpath.join(parent, x)

                    subdir = ET.SubElement(dom_parent, "directory")
                    subdir.set("name", x)

                    expect.update(cls._add_files(path,
                                                 subdir,
                                                 parent_names + [x],
                                                 depth - 1))
            return expect

    class TestK3bRmLightweight(unittest.TestCase, MockDataMixin
                               ):  # pylint: disable=R0904
        """Tests k3b-rm which require no test tree on the filesystem."""

        @classmethod
        def setUpClass(cls):  # NOQA
            MockDataMixin.setUpClass()

        def test__file_exists(self):
            """L: _file_exists helper for @patch: normal function"""
            self.assertEquals(_file_exists('/'), DEFAULT)
            self.assertRaises(IOError, _file_exists, tempfile.mktemp())

        def test_list_batch(self):
            """L: list_batch: doesn't raise exception when called"""
            list_batch(self.expected_tmpl)

        @staticmethod
        @patch("sys.exit", autospec=True)
        @patch.object(sys, 'argv', [__file__, '-m', tempfile.mktemp()])
        def test_main_bad_destdir(sysexit):
            """L: main: calls sys.exit(2) for a bad -m path"""
            main()
            sysexit.assert_called_once_with(2)

        def test_mounty_join(self):
            """L: mounty_join: proper behaviour"""
            for path_a in ('/foo', '/foo/'):
                for path_b in ('baz', '/baz', '//baz', '///baz'):
                    self.assertEqual(mounty_join(path_a, path_b),
                                     '/foo/baz', "%s + %s" % (path_a, path_b))

        @staticmethod
        @patch("os.makedirs", autospec=True)
        @patch("__builtin__.open", mock_open(), create=True)
        def test_touch_with_parents(makedirs):
            """L: touch_with_parents: basic operation"""
            touch_with_parents('/bar/foo')
            makedirs.assert_called_once_with('/bar')

            # pylint: disable=E1101
            open.assert_called_once_with('/bar/foo', 'a')

    class TestK3bRm(unittest.TestCase, MockDataMixin):  # pylint: disable=R0904
        """Test suite for k3b-rm to be run via C{nosetests}."""

        @classmethod
        def setUpClass(cls):  # NOQA
            MockDataMixin.setUpClass()

        def setUp(self):  # NOQA
            """Generate all data necessary for a test run"""
            self.dest = tempfile.mkdtemp(prefix='k3b-rm_test-dest-')
            self.root = tempfile.mkdtemp(prefix='k3b-rm_test-src-')
            self.project = tempfile.NamedTemporaryFile(prefix='k3b-rm_test-',
                                                       suffix='.k3b')

            xmldata = StringIO(
                self.xmldata_tmpl.getvalue().decode('UTF-8').replace(
                    self.root_placeholder, self.root).encode('UTF-8'))
            with ZipFile(self.project, 'w') as zobj:
                zobj.writestr("maindata.xml", xmldata.getvalue())

            self.expected = {}
            for key, value in self.expected_tmpl.items():
                path = key.replace(self.root_placeholder, self.root)

                self.expected[path] = value
                if path.endswith('dir'):
                    os.makedirs(path)
                else:
                    touch_with_parents(path)

        def tearDown(self):  # NOQA
            for x in ('dest', 'root'):
                try:
                    shutil.rmtree(getattr(self, x))
                except OSError:
                    pass
                delattr(self, x)

            del self.project
            del self.expected

        @patch.object(sys.modules[__name__], "list_batch", autospec=True)
        def test_main_list(self, lsbatch):
            """H: main: list_batch is default but only with args"""
            with patch.object(sys, 'argv', [__file__]):
                main()
                self.assertFalse(lsbatch.called,
                                 "Nothing should happen if no args provided")

            with patch.object(sys, 'argv', [__file__, self.project.name]):
                # Avoid polluting output
                with patch.object(log, 'info', autospec=True):
                    main()
                    lsbatch.assert_called_once_with(self.expected)

        @patch.object(sys.modules[__name__], "remove_emptied_dirs",
                      autospec=True)
        @patch.object(sys.modules[__name__], "move_batch", autospec=True)
        def test_main_move(self, mvbatch, remdirs):
            """H: main: --move triggers move_batch but only with args"""
            with patch.object(sys, 'argv', [__file__, '--move', '/']):
                main()
                self.assertFalse(mvbatch.called,
                                 "--move shouldn't be called without args")
                self.assertFalse(remdirs.called)

            with patch.object(sys, 'argv',
                              [__file__, '--move', '/', self.project.name]):
                main()
                mvbatch.assert_called_once_with(self.expected, '/',
                                           overwrite=False)
                remdirs.assert_called_once_with(self.expected)

            mvbatch.reset_mock()
            remdirs.reset_mock()
            with patch.object(sys, 'argv', [__file__, '--move', '/',
                                            self.project.name, '--overwrite']):
                main()
                mvbatch.assert_called_once_with(self.expected, '/',
                                           overwrite=True)
                remdirs.assert_called_once_with(self.expected)

        @patch.object(sys.modules[__name__], "remove_emptied_dirs")
        @patch.object(sys.modules[__name__], "rm_batch", autospec=True)
        def test_main_remove(self, rmbatch, remdirs):
            """H: main: --remove triggers rm_batch but only with args"""
            with patch.object(sys, 'argv', [__file__, '--remove']):
                main()
                self.assertFalse(rmbatch.called,
                                 "--remove shouldn't be called without args")
                self.assertFalse(remdirs.called)

            with patch.object(sys, 'argv',
                              [__file__, '--remove', self.project.name]):
                main()
                rmbatch.assert_called_once_with(self.expected)
                remdirs.assert_called_once(self.expected)

        @patch("shutil.move", side_effect=_file_exists, autospec=True)
        def test_move_batch(self, move):
            """H: move_batch: puts files in the right places"""
            for overwrite, needed in ((0, 0), (0, 1), (1, 0), (1, 1)):
                omitted = None
                if needed:
                    omitted = self.expected.values()[0]
                    touch_with_parents(mounty_join(self.dest, omitted))

                move_batch(self.expected, self.dest, overwrite)

                results = {x[0][0]: x[0][1] for x in move.call_args_list}
                for src, dest_rel in self.expected.items():
                    if dest_rel == omitted and not overwrite:
                        self.assertNotIn(src, results,
                                         "Overwrote when not allowed")
                    else:
                        self.assertIn(src, results, "Failed to move file")
                        self.assertEqual(mounty_join(self.dest, dest_rel),
                                         results[src],
                                         "Moved to wrong location")
                        del results[src]
                self.assertDictEqual(results, {}, "Spurious extra move(s)")
                move.reset_mock()

        def test_parse_k3b_proj(self):
            """H: parse_k3b_proj: basic functionality"""
            got = parse_k3b_proj(self.project.name)
            self.assertDictEqual(self.expected, got)

        @patch("os.remove", side_effect=_file_exists, autospec=True)
        @patch("os.unlink", side_effect=_file_exists, autospec=True)
        @patch("shutil.rmtree", side_effect=_file_exists, autospec=True)
        def test_rm_batch(self, *mocks):
            """H: rm_batch: deletes exactly the right files"""
            rm_batch(self.expected)
            results = [y[0][0] for x in mocks for y in x.call_args_list]
            self.assertListEqual(sorted(self.expected), sorted(results))

        def test_rm_batch_nonexistant(self):
            """H: rm_batch: handles missing files gracefully"""
            omitted = self.expected.keys()[3]
            if os.path.isdir(omitted):
                shutil.rmtree(omitted)
            else:
                os.unlink(self.expected.keys()[3])

            rm_batch(self.expected)
            rm_batch(self.expected)
            for x in self.expected:
                self.assertFalse(os.path.exists(x))

            remove_emptied_dirs(x.replace(self.root_placeholder, self.root)
                                for x in self.expected.keys())
            self.assertFalse(os.path.exists(self.root))

if __name__ == '__main__':  # pragma: nocover
    main()
