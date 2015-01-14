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
__version__ = "0.1"
__license__ = "MIT"

import logging
log = logging.getLogger(__name__)

import os, posixpath, shutil, sys
import xml.etree.cElementTree as ET
from zipfile import ZipFile

# ---=== Actual Code ===---

class FSWrapper(object):
    """Centralized overwrite/dry-run control and log-as-fail wrapper."""

    overwrite = False
    dry_run = True  # Fail safe if the connection to --dry-run is broken

    def __init__(self, overwrite=overwrite, dry_run=dry_run):
        self.overwrite = overwrite
        self.dry_run = dry_run

    def move(self, src, dest):
        """See L{shutil.move}.

        @return: C{True} if the move was successful or failed because the
            source doesn't exist and the destination already does.
            (Used by the code for rewriting paths within other files)
        @rtype: C{bool}
        """
        dest_exists = os.path.exists(dest)
        if not os.path.exists(src):
            log.warn("Cannot move nonexistant path: %s", src)
            return dest_exists
        elif dest_exists and not self.overwrite:
            log.warn("Target exists. Skipping: %s", dest)
            return False

        log.info("%r -> %r", src, dest)
        if not self.dry_run:
            shutil.move(src, dest)
            # TODO: Log and continue in case of exception here
        return True

    def remove(self, path):
        """See L{os.unlink} or L{shutil.rmtree} as appropriate.

        @return: C{True} on success
        """
        if not os.path.exists(path):
            log.warn("Cannot remove nonexistant path: %s", path)
            return False

        log.info("Removing: %s", path)
        if not self.dry_run:
            if os.path.isdir(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
            # TODO: Log and continue in case of exception here
        return True

def _print(*args, **kwargs):
    """Wrapper for C{print} to allow mocking"""
    print(*args, **kwargs)

def main():
    """setuptools-compatible entry point"""
    import argparse
    parser = argparse.ArgumentParser(
        description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_argument('--version', action='version',
        version="%%(prog)s v%s" % __version__)
    parser.set_defaults(overwrite=False, dry_run=False,
                        verbose=False, quiet=False)

    subparsers = parser.add_subparsers(title='available subcommands')

    def new_subcommand(*args, **kwargs):
        """C{subparsers.add_parser} wrapper which adds common arguments."""
        parser = subparsers.add_parser(*args, **kwargs)
        parser.add_argument('-v', '--verbose', action="count", dest="verbose",
            default=3,
            help="Increase the verbosity. Use twice for extra effect")
        parser.add_argument('-q', '--quiet', action="count", dest="quiet",
            default=0,
            help="Decrease the verbosity. Use twice for extra effect")
        parser.add_argument('-n', '--dry-run', action="store_true",
            dest="dry_run",
            help="Don't actually modify the filesystem. Just simulate.")
        parser.add_argument('paths', metavar='project_file', nargs='+',
            help="K3b project file to read from")
        return parser

    new_subcommand('rm', help='Remove the given files'
                   ).set_defaults(remove_leftovers=True, mode='rm')

    mv_parser = new_subcommand('mv', help='Move the files to the given path')
    mv_parser.add_argument('--overwrite', action="store_true",
        dest="overwrite",
        help="Allow %(prog)s to overwrite files at the target location.")
    mv_parser.add_argument('target', metavar='target_dir',
        help="Directory to move files into")
    mv_parser.set_defaults(remove_leftovers=True, mode='mv')

    new_subcommand('ls', help='List paths retrieved'
                   ).set_defaults(remove_leftovers=False, mode='ls')

    args = parser.parse_args()

    # Set up clean logging to stderr
    log_levels = [logging.CRITICAL, logging.ERROR, logging.WARNING,
                  logging.INFO, logging.DEBUG]
    args.verbose = min(args.verbose - args.quiet, len(log_levels) - 1)
    args.verbose = max(args.verbose, 0)
    logging.basicConfig(level=log_levels[args.verbose],
                        format='%(levelname)s: %(message)s')

    if args.mode == 'mv' and not os.path.isdir(args.target):
        log.critical("Target path is not a directory: %s", args.target)
        return 2

    # TODO: Test that --overwrite and --dry-run always get passed through
    filesystem = FSWrapper(overwrite=args.overwrite, dry_run=args.dry_run)

    for path in args.paths:
        files = parse_k3b_proj(path)
        # TODO: Log and continue in case of exception here

        if args.mode == 'mv':
            # TODO: Replace this with a looped call to filesystem.move,
            # adjust the tests, and delete move_batch.
            move_batch(files, args.target, overwrite=args.overwrite)
        else:
            for src_path, _ in sorted(files.items()):
                if args.mode == 'rm':
                    filesystem.remove(src_path)
                elif args.mode == 'ls':
                    _print(src_path)

    if args.remove_leftovers:
        remove_emptied_dirs(files)

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
            log.warning("Doesn't exist (Already handled?): %s", src_path)
            continue

        dest_path = mounty_join(dest_dir, dest_rel)

        if os.path.exists(dest_path) and not overwrite:
            log.warning("Skipping (target already exists): %r -> %r",
                  src_path, dest_path)
        else:
            log.info("%r -> %r", src_path, dest_path)
            shutil.move(src_path, dest_path)
            # TODO: Log and continue in case of exception here

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

    while file_paths:
        diminished = set()

        #  Sort in reverse order to appromixate os.walk(topdown=False) for
        #  improved efficiency.
        for path in sorted(file_paths, reverse=True):
            parent = os.path.normpath(os.path.dirname(path))
            try:  # We do this for atomic test/act behaviour
                os.rmdir(parent)
            except OSError as err:
                if err.errno != errno.ENOTEMPTY:
                    log.warning("Could not remove: %s (%s)", parent,
                                errno.errorcode[err.errno])
            else:
                diminished.add(parent)

        # Iteratively walk up until we run out of emptied ancestors
        file_paths = diminished

# ---=== Test Suite ===---

if sys.argv[0].rstrip('3').endswith('nosetests'):  # pragma: nobranch
    import errno, tempfile, unittest

    if sys.version_info.major < 3:
        from cStringIO import StringIO
        BytesIO = StringIO
        open_path = '__builtin__.open'
    else:  # pragma: nocover
        from io import StringIO, BytesIO
        open_path = 'builtins.open'

    try:
        from unittest.mock import (     # pylint: disable=E0611,F0401
            patch, call, ANY, DEFAULT, mock_open)
    except ImportError:
        from mock import patch, call, ANY, DEFAULT, mock_open

    def _file_exists(src, *_):
        """Used with C{side_effect} to make filesystem mocks stricter"""
        if os.path.exists(src):
            return DEFAULT
        else:
            raise IOError(errno.ENOENT, '%s: %r' %
                          (os.strerror(errno.ENOENT), src))

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

            cls.expected_tmpl = cls._add_files([], files, depth=2)
            cls.xmldata_tmpl = BytesIO()
            test_tree = ET.ElementTree(test_dom)
            test_tree.write(cls.xmldata_tmpl,
                            encoding="UTF-8",
                            xml_declaration=True)

        @classmethod
        def _make_file_node(cls, dom_parent, fpath):
            """Add a file/url node stack as a child of the given parent"""
            fnode = ET.SubElement(dom_parent, "file",
                                  name=posixpath.basename(fpath))
            unode = ET.SubElement(fnode, "url")
            unode.text = mounty_join(cls.root_placeholder, fpath)

        @classmethod
        def _add_files(cls, ancestors, dom_parent, depth=0):
            """Generate a list of expected test files and populate test XML"""
            expect, parent = {}, os.sep + os.sep.join(ancestors)

            for x in list(u'12ñの') + ['dir']:
                fpath = posixpath.join(parent, '_'.join(ancestors + [x]))
                cls._make_file_node(dom_parent, fpath)
                expect[mounty_join(cls.root_placeholder, fpath)] = fpath

            # For robustness-testing
            ET.SubElement(dom_parent, "garbage")

            if depth:
                for x in u'45ðあ':
                    expect.update(cls._add_files(ancestors + [x],
                        ET.SubElement(dom_parent, "directory", name=x),
                        depth - 1))
            return expect

    class TestFSWrapper(unittest.TestCase):  # pylint: disable=R0904
        """Tests for L{FSWrapper}

        @todo: Consider using unittest2 so I can get access to the Python 3.4
            self.subTest context manager for things like "for dry_run in ..."
        """

        def setUp(self):  # NOQA
            self.testroot = tempfile.mkdtemp(prefix='k3b-rm_test-')
            self.addCleanup(self.cleanup)

            def set_mock(patcher):  # pylint: disable=C0111
                patcher.start()
                self.addCleanup(patcher.stop)

            for mpath in ("os.remove", "os.unlink", "shutil.rmtree",
                          "os.rename", "shutil.move"):
                set_mock(patch(mpath, side_effect=_file_exists, autospec=True))
            for meth in ('warn', 'info'):
                set_mock(patch.object(log, meth, autospec=True))

        def tearDown(self):  # NOQA
            #  Simplify tests by expecting reset_mock() on used mocks.
            for mock in (os.remove, os.unlink, shutil.rmtree,
                         log.info, log.warn):
                self.assertFalse(mock.called,  # pylint: disable=E1103
                                "Shouldn't have been called: %s" % mock)

        def cleanup(self):
            """Stuff which should be called after other cleanups, regardless"""
            # Make sure we call this after the mocks are deactivated
            assert getattr(shutil.rmtree, 'called', None) is None
            shutil.rmtree(self.testroot)

        def _do_move_tsts(self, wrapper, src, dest):
            """The actual subTest code for test_move"""
            should_succeed = wrapper.overwrite or not os.path.exists(dest)

            for m in (os.rename, shutil.move):
                self.assertFalse(m.called)  # pylint: disable=E1101

            self.assertEqual(should_succeed, wrapper.move(src, dest),
                   "Must return True on successful removal")
            if wrapper.dry_run or not should_succeed:
                for m in (os.rename, shutil.move):
                    self.assertFalse(m.called)  # pylint: disable=E1101
            else:
                m = shutil.move
                m.assert_called_once_with(      # pylint: disable=E1101
                                          src, dest)
                m.reset_mock()                  # pylint: disable=E1101

            if should_succeed:
                log.info.assert_called_once_with(ANY, src, dest)
                log.info.reset_mock()
            else:
                log.warn.assert_called_once_with(ANY, dest)
                log.warn.reset_mock()

        def test_init_members(self):
            """FSWrapper.__init__: public members are set properly"""
            wrapper = FSWrapper()
            self.assertFalse(wrapper.overwrite, "overwrite=False not default!")
            self.assertTrue(wrapper.dry_run, "dry_run=True not default!")

            for overwrite in (True, False):
                for dry_run in (True, False):
                    wrapper = FSWrapper(overwrite, dry_run)
                    self.assertEqual(overwrite, wrapper.overwrite)
                    self.assertEqual(dry_run, wrapper.dry_run)

        def test_move(self):
            """FSWrapper.move: normal operation"""

            paths = []
            for _ in range(2):
                fd, fpath = tempfile.mkstemp(dir=self.testroot)
                dpath = tempfile.mkdtemp(dir=self.testroot)
                os.close(fd)
                paths.extend([fpath, dpath])

            for dry_run in (True, False):
                for owrite in (True, False):
                    wrapper = FSWrapper(dry_run=dry_run, overwrite=owrite)

                    for src_idx in (0, 1):
                        self._do_move_tsts(wrapper, paths[src_idx],
                                           paths[src_idx] + '_a')

                        # Test overwrite behaviour for both files and folders
                        # as both source and destination
                        for dest_idx in (2, 3):
                            self._do_move_tsts(wrapper, paths[src_idx],
                                               paths[dest_idx])

        def test_move_bad_paths(self):
            """FSWrapper.move: failures due to bad source/destination"""
            test_src = tempfile.mktemp()
            test_dest = tempfile.mktemp()

            for dry_run in (True, False):
                wrapper = FSWrapper(dry_run=dry_run)

                # Note: While it's less portable, I use POSIX command paths
                #       to avoid the overhead of setting up and tearing down
                #       test files when existence should be the only check.
                for src, dest, expected in (
                        (test_src, test_dest, False),
                        (test_src, '/', True),
                        ('/bin/sh', '/bin/echo', False)):
                    self.assertEqual(wrapper.move(src, dest), expected,
                                     "Must return %s for %s -> %s" %
                                     (expected, src, dest))
                    log.warn.assert_called_once_with(ANY,
                                    dest if os.path.exists(src) else src)
                    log.warn.reset_mock()

        def test_remove(self):
            """FSWrapper.remove: normal operation"""
            for dry_run in (True, False):
                wrapper = FSWrapper(dry_run=dry_run)

                test_fd, test_path = tempfile.mkstemp(dir=self.testroot)
                os.close(test_fd)

                for mock, path in ((os.remove, test_path),
                                   (shutil.rmtree, self.testroot)):
                    self.assertFalse(mock.called)      # pylint: disable=E1101
                    self.assertTrue(wrapper.remove(path),
                                   "Must return True on successful removal")
                    if dry_run:
                        self.assertFalse(mock.called)  # pylint: disable=E1101
                    else:
                        mock.assert_called_once_with(  # pylint: disable=E1101
                                                     path)
                        mock.reset_mock()              # pylint: disable=E1101
                    log.info.assert_called_once_with(ANY, path)
                    log.info.reset_mock()

        def test_remove_nonexistant(self):
            """FSWrapper.remove: nonexistant targets"""
            test_path = tempfile.mktemp()

            for dry_run in (True, False):
                wrapper = FSWrapper(dry_run=dry_run)
                self.assertFalse(wrapper.remove(test_path),
                                 "Must return False if file doesn't exist")

                log.warn.assert_called_once_with(ANY, test_path)
                log.warn.reset_mock()

    class TestK3bRmLightweight(unittest.TestCase, MockDataMixin
                               ):  # pylint: disable=R0904
        """Tests for k3b-rm which require no test tree on the filesystem."""

        @classmethod
        def setUpClass(cls):  # NOQA
            MockDataMixin.setUpClass()

        def test__file_exists(self):
            """L: _file_exists helper for @patch: normal function"""
            self.assertEqual(_file_exists('/'), DEFAULT)
            self.assertRaises(IOError, _file_exists, tempfile.mktemp())

        @patch.object(sys, 'argv',
                      [__file__, 'mv', tempfile.mktemp(), tempfile.mktemp()])
        def test_main_bad_destdir(self):
            """L: main: calls sys.exit(2) for a bad mv target"""
            self.assertEqual(main(), 2, "Must exit with status 2 on bad mv "
                                        "target")

        def test_mounty_join(self):
            """L: mounty_join: proper behaviour"""
            for path_a in ('/foo', '/foo/'):
                for path_b in ('baz', '/baz', '//baz', '///baz'):
                    self.assertEqual(mounty_join(path_a, path_b),
                                     '/foo/baz', "%s + %s" % (path_a, path_b))

        @staticmethod
        @patch.object(log, 'warning', autospec=True)
        def test_move_batch_missing(mock):
            """L: move_batch: missing input"""
            missing_path = tempfile.mktemp()
            move_batch({missing_path: '/foo'}, '/tmp')
            mock.assert_called_once_with(ANY, missing_path)

        @staticmethod
        @patch.object(log, 'warning', autospec=True)
        def test_remove_emptied_dirs_exceptional(mock):
            """L: remove_emptied_dirs: exceptional input"""

            # Test that an empty options list doesn't cause errors
            remove_emptied_dirs([])

            # Test that a failure to normalize input doesn't cause EINVAL
            remove_emptied_dirs(['/.' + os.path.join(
                tempfile.mktemp(dir='/'))])
            mock.assert_called_once_with(ANY, '/', 'EBUSY')
            mock.reset_mock()

            # Separately test response to EBUSY by trying to rmdir('/')
            remove_emptied_dirs(['/bin'])
            mock.assert_called_once_with(ANY, '/', 'EBUSY')

        @staticmethod
        @patch("os.makedirs", autospec=True)
        @patch(open_path, mock_open(), create=True)
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
            self.addCleanup(self.cleanup)

            tmp = self.xmldata_tmpl.getvalue().decode('UTF-8').replace(
                self.root_placeholder, self.root)
            if sys.version_info.major < 3:  # pragma: nobranch
                tmp = tmp.encode('UTF-8')

            xmldata = StringIO(tmp)
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

        def cleanup(self):  # NOQA
            """Stuff which should be called after other cleanups, regardless"""
            for x in ('dest', 'root'):
                path = getattr(self, x, None)
                if path is not None:
                    try:
                        # Make sure we call this after mocks are deactivated
                        assert getattr(shutil.rmtree, 'called', None) is None

                        shutil.rmtree(path)
                    except OSError:
                        pass
                    delattr(self, x)

            del self.project
            del self.expected

        # TODO: Decide how to address this
        # @staticmethod
        # def test_main_argparse_hole() :
        #    """Hole in argparse isn't triggered"""
        #    with patch.object(sys, 'argv', [__file__]):
        #        main()

        @patch.object(sys.modules[__name__], "_print")
        def test_main_ls(self, mock):
            """H: main: ls subcommand function"""
            with patch.object(sys, 'argv',
                              [__file__, 'ls', self.project.name]):
                main()
                self.assertListEqual(
                    sorted(mock.call_args_list), sorted(
                        [call(x) for x in self.expected.keys()]))

        @patch.object(sys.modules[__name__], "remove_emptied_dirs",
                      autospec=True)
        @patch.object(sys.modules[__name__], "move_batch", autospec=True)
        def test_main_move(self, mvbatch, remdirs):
            """H: main: mv triggers move_batch but only with args"""
            with patch.object(sys, 'argv',
                              [__file__, 'mv', self.project.name, '/']):
                main()
                mvbatch.assert_called_once_with(self.expected, '/',
                                           overwrite=False)
                remdirs.assert_called_once_with(self.expected)

            mvbatch.reset_mock()
            remdirs.reset_mock()
            with patch.object(sys, 'argv', [__file__, 'mv', self.project.name,
                                            '/', '--overwrite']):
                main()
                mvbatch.assert_called_once_with(self.expected, '/',
                                           overwrite=True)
                remdirs.assert_called_once_with(self.expected)

        @patch.object(sys.modules[__name__], "remove_emptied_dirs")
        @patch.object(FSWrapper, "move", autospec=True)
        @patch.object(FSWrapper, "remove", autospec=True)
        def test_main_remove(self, remove, move, remdirs):
            """H: main: rm subcommand calls remove() but only properly"""
            with patch.object(sys, 'argv',
                              [__file__, 'rm', self.project.name]):
                main()
                self.assertFalse(move.called)
                remdirs.assert_called_once(self.expected)

                results = [x[0][1] for x in remove.call_args_list]
                self.assertListEqual(sorted(self.expected), sorted(results))

            # TODO: I'll want a test analogous to the old
            #       test_rm_batch_nonexistant

        @patch("shutil.move", side_effect=_file_exists, autospec=True)
        def test_move_batch(self, move):
            """H: move_batch: puts files in the right places"""
            for overwrite, needed in ((0, 0), (0, 1), (1, 0), (1, 1)):
                omitted = None
                if needed:
                    omitted = list(self.expected.values())[0]
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

        def test_remove_emptied_dirs(self):
            """H: remove_emptied_dirs: basic function"""
            dir_names = u'56ðあ'  # Make sure this is at least 3 entries long
            targets, keepers = [], set()

            def make_children(parent, depth=3):
                """Recursive helper for generating a test tree"""
                targets.append(os.path.join(parent, 'dummy'))
                fpath = os.path.join(parent, u'keepœr')
                idx = dir_names.find(os.path.basename(parent))
                if idx == 1:
                    touch_with_parents(fpath)
                    keepers.add(fpath)
                elif idx == 2:
                    os.makedirs(fpath)
                    keepers.add(fpath)

                if depth:
                    for x in dir_names:
                        make_children(os.path.join(parent, x), depth - 1)
            make_children(self.dest)

            remove_emptied_dirs(targets)
            for path, dirs, files in os.walk(self.dest):
                if path.endswith(u'keepœr'):
                    continue
                self.assertNotEqual(dirs + files, [], "Must remove all emptied"
                                    "dirs")
            for path in keepers:
                self.assertTrue(os.path.exists(path),
                                "Must not remove files or sub-target dirs")

if __name__ == '__main__':  # pragma: nocover
    sys.exit(main())
