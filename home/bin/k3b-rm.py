#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# pylint: disable=invalid-name
"""A simple tool for deleting the files listed in a K3b project after it has
been written to a disc. (Useful in concert with gaff-k3b)

--snip--

@note: This currently explicitly uses C{posixpath} rather than C{os.path}
       since, as a POSIX-only program, K3b is going to be writing project files
       that always use UNIX path separators.

@note: When designing the internals of this tool, I strived to ensure that,
       should a fatal bug be encountered, it would be possible to fix it and
       then re-run the same command to complete the operation.

@todo: For the love of God, make this its own project and split it into
       multiple files!
@todo: Wherever feasible, make mocks actually call what they're supposed to be
       mocking so I can use them purely to determine that the right number of
       calls were made with the right arguments.
       (As is, I'm "testing the mock" too much.)
@todo: Refactor the test suite once I'm no longer burned out on this project.
@todo: Redesign the tests to ensure that Unicode in Python 2.x doesn't cause
       errors with print().
"""

from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__appname__ = "File-Deleting Companion for gaff-k3b"
__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.1"
__license__ = "MIT"

import logging
log = logging.getLogger(__name__)

import os, posixpath, re, shutil, sys
import xml.etree.cElementTree as ET
from zipfile import ZipFile

if sys.version_info.major < 3:  # pragma: nobranch
    from xml.sax.saxutils import escape as xmlescape
    from urllib import (pathname2url as _pathname2url,
                        quote as _urlquote,
                        quote_plus as _urlquote_plus)

    def pathname2url(text):
        """Fixup wrapper to make C{urllib.quote} behave as in Python 3"""
        return _pathname2url(text if isinstance(text, bytes)
                            else text.encode('utf-8'))

    def urlquote(text):
        """Fixup wrapper to make C{urllib.quote} behave as in Python 3"""
        return _urlquote(text if isinstance(text, bytes)
                         else text.encode('utf-8'))

    def urlquote_plus(text, safe=b''):
        """Fixup wrapper to make C{urllib.quote_plus} behave as in Python 3"""
        return _urlquote_plus(text if isinstance(text, bytes)
                              else text.encode('utf-8'), safe)
else:
    from urllib.request import pathname2url       # pylint: disable=E0611,F0401
    from urllib.parse import (quote as urlquote,  # pylint: disable=E0611,F0401
                              quote_plus as urlquote_plus)
    from xml.sax.saxutils import escape as _xmlescape

    def xmlescape(text):
        """Fixup wrapper to make C{xml.sax.saxutils.escape} work with bytes"""
        return (_xmlescape(text.decode('latin1')).encode('latin1')
                if isinstance(text, bytes) else _xmlescape(text))

# ---=== Actual Code ===---

if sys.version_info.major >= 3:  # pragma: nobranch
    basestring = (bytes, str)  # pylint: disable=redefined-builtin
    unicode = str  # pylint: disable=redefined-builtin

class FSWrapper(object):
    """Centralized overwrite/dry-run control and log-as-fail wrapper."""

    overwrite = False
    dry_run = True  # Fail safe if the connection to --dry-run is broken

    def __init__(self, overwrite=overwrite, dry_run=dry_run):
        self.overwrite = overwrite
        self.dry_run = dry_run

    def mergemove(self, src, dest):
        """Move a file or folder, recursively merging it if the target exists.

        @param dest: The B{exact} (not parent) path to which to move C{src}.
        @return: Dict mapping old paths to new ones.
        """
        moved = {}
        if os.path.isdir(src) and os.path.exists(dest):
            for fname in os.listdir(src):
                moved.update(self.mergemove(os.path.join(src, fname),
                                            os.path.join(dest, fname)))
        elif self.move(src, dest):
            moved[src] = dest
            self.remove_emptied_dirs(src)
        return moved

    # TODO: What if the parent of dest doesn't exist?
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

    def remove_emptied_dirs(self, paths):
        """Recursively remove empty directories.
        (eg. Clean up directory structures after removing a bunch of files.)
        """
        while paths:
            diminished = set()

            #  Sort reversed to mimic os.walk(topdown=False) for efficiency
            for path in sorted(paths, reverse=True):
                parent = os.path.normpath(os.path.dirname(path))
                try:  # Use os.rmdir as final "do we do?" for atomic operation
                    if not (os.path.isdir(path) and not os.listdir(path)):
                        if not os.path.exists(path):
                            diminished.add(parent)
                        continue

                    log.info("Removing empty directory: %s", path)
                    if not self.dry_run:
                        os.rmdir(path)  # TODO: More dry_run-friendly approach
                        diminished.add(parent)
                except OSError as err:
                    if err.errno == errno.ENOTEMPTY:
                        return  # TODO: Test this short-circuit optimization
                    log.warning(err)

            # Iteratively walk up until we run out of emptied ancestors
            paths = diminished


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
            default=2,
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

    # TODO: How do I prevent set_defaults from clobbering add_argument stuff?
    if args.verbose is False:
        args.verbose = 2

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

        for src_path, dest_rel in sorted(files.items()):
            if args.mode == 'mv':
                dest_path = mounty_join(args.target, dest_rel)
                filesystem.mergemove(src_path, dest_path)
            elif args.mode == 'rm':
                filesystem.remove(src_path)
            else:  # args.mode == 'ls'
                _print(src_path)

    if args.remove_leftovers:
        filesystem.remove_emptied_dirs(files)

def fgrep_to_re_str(patterns):
    """Escape a list of strings and return a regex string to match any of them.

    @type patterns: C{[unicode]} or C{[bytes]}
    @warning: Providing a C{patterns} which contains both unicode and \
              bytestrings is undefined behaviour. It's your own fault if your
              Python 3.x program blows up because of it.

    @note: Does not C{re.compile} for you in case you want to incorporate it
           into a larger regular expression.
    """
    if not patterns:
        return b''  # FIXME: I know this is going to have unexpected results.

    if isinstance(patterns, basestring):
        patterns = [patterns]

    patterns = [re.escape(x) for x in patterns]
    return (b'(' + b'|'.join(patterns) + b')'
            if isinstance(patterns[0], bytes)
            else u'(%s)' % u'|'.join(patterns))

re_percent_escape_u = re.compile(u"%[0-9a-fA-F]{2}")
re_percent_escape_b = re.compile(re_percent_escape_u.pattern.encode('ascii'))
def lower_percent_escapes(escaped_str):
    """Lowercase the %3C-style escapes in a string."""
    rex = re_percent_escape_u
    if isinstance(escaped_str, bytes):
        rex = re_percent_escape_b
    return rex.sub(lambda x: x.group(0).lower(), escaped_str)

def mounty_join(a, b):
    """Join paths C{a} and C{b} while ignoring leading separators on C{b}"""
    b = b.lstrip(os.sep).lstrip(os.altsep or os.sep)
    return posixpath.join(a, b)

# TODO: Decide on an exception-handling policy here
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

def vary_escaped(path):
    """Generate all known encodings of a path that a regex may need to expect.

    Seen In the wild:
        - Completely unescaped (.pls, .gqv)
        - urllib.pathname2url()ed file:/// URLs with upcase %-encoding (.audpl)
        - xml.sax.saxutils.escape()ed unicode (XSPF)

    @note: For most versatile matching, the file:// portion is omitted from
        the generated output in order to also match file://<host>/...

    @note: Output ordering is guaranteed to remain consistent between runs
        within the same process lifetime so that C{zip()} can be used to
        generate before/after pairs.

    @warning: This only addresses common encodings used to encapsulate a URI
        or path within a structured data file. It is still your responsibility
        to ensure that you provide a path in the correct character coding.

        This also makes no attempt to hack around XML entity encodings. If you
        want to C{sed} paths in an XML file, combine this with a SAX-based
        stream filter so you can operate on Unicode codepoints without fear
        of rendering the XML invalid or tripping over an entity reference.

    @warning: This makes no attempt to work around badly normalized paths or
        mixed-case percent-encoding. Attempting to do so would result in a
        combinatorial explosion. If you want to deal with messy data, you need
        to actually parse and then re-serialize the format.

    @todo: Does .audpl perform path separator conversion like pathname2url()
           or does it just escape blindly like quote()?

    @todo: Do a survey of file formats to determine what else I should do.
        Potential examples:
            - urllib.quote()ed (pathname2url with no os.sep conversion)
            - urllib.quote_plus()ed file:/// URLs with uppercase %-encoding
            - urllib.quote_plus()ed file:/// URLs with lowercase %-encoding
    """

    # NOTE TO MAINTAINERS: This must return a consistently-ordered result
    #           but there is currently no way to reliably unit test that.
    p2url = pathname2url(path)
    return [
        path,                          # literal (.pls, .gqv)
        p2url,                         # url escaped (.audpl)
        lower_percent_escapes(p2url),
        xmlescape(path),               # xml-escaped (XSPF)
    ]

# ---=== Test Suite ===---

if sys.argv[0].rstrip('3').endswith('nosetests'):  # pragma: nobranch
    import errno, tempfile, unittest
    from itertools import product

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

    def test_pathname2url():
        """pathname2url: UTF-8 and Unicode input produce same output"""
        assert pathname2url(b'abc/def ghi') == pathname2url(u'abc/def ghi')

    def test_urlquote():
        """urlquote: UTF-8 and Unicode input produce same output"""
        assert urlquote(b'abc/def ghi') == urlquote(u'abc/def ghi')

    def test_urlquote_plus():
        """urlquote_plus: UTF-8 and Unicode input produce same output"""
        assert urlquote_plus(b'abc/def ghi') == urlquote_plus(u'abc/def ghi')

    def test_xmlescape():
        """xmlescape: both bytes and unicode are supported"""
        assert xmlescape(u'<abc & def>') == u'&lt;abc &amp; def&gt;'
        assert xmlescape(b'<abc & def>') == b'&lt;abc &amp; def&gt;'

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

        @todo: Come up with a clean, robust way to either mock or generate
               filesystem structures and then test postconditions.
               My test suite is currently a mess.

        @todo: Consider using unittest2 so I can get access to the Python 3.4
            self.subTest context manager for things like "for dry_run in ..."
        """

        def setUp(self):  # NOQA
            self.testroot = tempfile.mkdtemp(prefix='k3b-rm_test-')
            self.destroot = tempfile.mkdtemp(prefix='k3b-rm_test-')
            self.addCleanup(self.cleanup)

            def set_mock(patcher):  # pylint: disable=C0111
                patcher.start()
                self.addCleanup(patcher.stop)

            self._rmd = os.rmdir
            for mpath in ("os.remove", "os.unlink", "os.rmdir", "os.rename",
                          "shutil.rmtree", "shutil.move"):
                set_mock(patch(mpath, side_effect=_file_exists, autospec=True))
            for meth in ('warn', 'info'):
                set_mock(patch.object(log, meth, autospec=True))

        def tearDown(self):  # NOQA
            #  Simplify tests by expecting reset_mock() on used mocks.
            for mock in (os.remove, os.unlink, os.rmdir, os.rename,
                         shutil.rmtree, shutil.move,
                         log.info, log.warn):
                self.assertFalse(mock.called,  # pylint: disable=E1103
                                "Shouldn't have been called: %s" % mock)

        def cleanup(self):
            """Stuff which should be called after other cleanups, regardless"""
            # Make sure we call this after the mocks are deactivated
            assert getattr(shutil.rmtree, 'called', None) is None
            shutil.rmtree(self.testroot)
            shutil.rmtree(self.destroot)

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

        def _make_children(self, parent, targets, keepers, depth=3):
            """Recursive helper for generating a test tree"""
            dir_names = u'56ðあ'  # Keep this at least 3 entries long

            dpath = os.path.join(parent, 'target')
            os.makedirs(dpath)
            targets.append(dpath)

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
                    self._make_children(os.path.join(parent, x),
                                  targets, keepers, depth - 1)

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

        @patch.object(FSWrapper, "move", autospec=True)
        @patch.object(FSWrapper, "remove_emptied_dirs", autospec=True)
        def test_mergemove(self, remdirs, move):
            """FSWrapper.mergemove: normal operation"""
            # dry_run=False to catch stuff which should be within the mocks.
            wrapper = FSWrapper(dry_run=False)
            mergemove = wrapper.mergemove

            with patch.object(FSWrapper, 'mergemove', autospec=True) as mmove:
                targets, keepers = [], set()
                self._make_children(self.testroot, targets, keepers)
                new_dest = os.path.join(self.destroot, 'new_dest')
                afile = os.path.join(self.testroot, 'afile')
                touch_with_parents(afile)

                # Directory that doesn't exist at dest
                self.assertDictEqual(mergemove(self.testroot, new_dest),
                                     {self.testroot: new_dest})
                move.assert_called_once_with(ANY, self.testroot, new_dest)
                move.reset_mock()
                remdirs.assert_called_once_with(ANY, self.testroot)
                remdirs.reset_mock()

                # File that doesn't exist at dest
                self.assertDictEqual(mergemove(afile, new_dest),
                                     {afile: new_dest})
                move.assert_called_once_with(ANY, afile, new_dest)
                move.reset_mock()
                remdirs.assert_called_once_with(ANY, afile)
                remdirs.reset_mock()

                # Directory that exists at dest
                self.assertFalse(mmove.called)
                mmove.return_value = {'FROM': 'TO'}
                self.assertDictEqual(mergemove(self.testroot, self.destroot),
                                     {'FROM': 'TO'})
                self.assertListEqual(
                    sorted(mmove.call_args_list), sorted(
                        [call(ANY, os.path.join(self.testroot, x),
                              os.path.join(self.destroot, x))
                         for x in os.listdir(self.testroot)]))
                mmove.reset_mock()

                # Reaction to a failed self.move call in mergemove
                move.return_value = False
                self.assertDictEqual(mergemove(self.testroot, new_dest), {})
                self.assertFalse(mmove.called)
                move.assert_called_once_with(ANY, self.testroot, new_dest)

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

        def test_remove_emptied_dirs(self):
            """FSWrapper.remove_emptied_dirs: basic function"""
            targets, keepers = [], set()
            self._make_children(self.testroot, targets, keepers)

            # Test the handling of nonexistant paths too
            targets.append(tempfile.mktemp())
            # TODO: Test files and nonexistant children of otherwise empty dirs

            for dry_run in (True, False):
                if not dry_run:
                    os.rmdir.side_effect = (
                        lambda x: self._rmd(x))  # pylint: disable=E1101,W0108

                wrapper = FSWrapper(dry_run=dry_run)
                wrapper.remove_emptied_dirs(targets)

                # TODO: Assert that log.info was called *in a way that gives
                # dry-running meaning*.
                self.assertTrue(log.info.called)
                log.info.reset_mock()

                self.assertEqual(
                    os.rmdir.called, not dry_run)  # pylint: disable=E1101
                if dry_run:
                    continue

            # Test actual os.rmdir use when not dry-running
            try:
                for path in targets:
                    if not os.path.exists(path):
                        continue
                    self.assertIn(call(path),
                        os.rmdir.call_args_list)  # pylint: disable=E1101

                    # Rough test for parent traversal
                    parent = os.path.dirname(path)
                    if len(os.listdir(parent)) > 1:
                        continue
                    self.assertIn(call(parent),
                        os.rmdir.call_args_list)  # pylint: disable=E1101
            finally:
                os.rmdir.reset_mock()  # pylint: disable=E1101

            # Verify that the only remaining things are ancestors of stuff we
            # wanted to keep.
            for path, _, files in os.walk(self.testroot):
                if path.endswith(u'keepœr'):
                    continue
                self.assertIn(files, [[], [u'keepœr']],
                    "Must remove all emptied dirs")
            for path in keepers:
                self.assertTrue(os.path.exists(path),
                                "Must not remove files or sub-target dirs")

            # Prevent tearDown from complaining about an expected mock call
            os.rmdir.reset_mock()  # pylint: disable=E1101

        @patch.object(log, 'warning', autospec=True)
        def test_remove_emptied_dirs_exceptional(self, mock):
            """FSWrapper.remove_emptied_dirs: exceptional input"""

            wrapper = FSWrapper(dry_run=False)  # TODO: Test dry_run=True

            # Test that an empty options list doesn't cause errors or call
            # os.rmdir unnecessarily
            wrapper.remove_emptied_dirs([])
            self.assertFalse(os.rmdir.called)  # pylint: disable=E1101

            # Test that a failure to normalize input doesn't raise exceptions
            # TODO: Redesign this so we can actually verify results
            wrapper.remove_emptied_dirs(['/.' + os.path.join(
                tempfile.mktemp(dir='/'))])
            mock.reset_mock()

            # Separately test response to EBUSY by trying to rmdir('/')
            os.rmdir.side_effect = OSError(errno.EBUSY, "FOO")
            wrapper.remove_emptied_dirs(['/bin'])

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
        @patch("os.makedirs", autospec=True)
        @patch(open_path, mock_open(), create=True)
        def test_touch_with_parents(makedirs):
            """L: touch_with_parents: basic operation"""
            touch_with_parents('/bar/foo')
            makedirs.assert_called_once_with('/bar')

            # pylint: disable=E1101
            open.assert_called_once_with('/bar/foo', 'a')

        def test_fgrep_to_re_str(self):
            """L: fgrep_to_re_str: basic operation

            @todo: Consider using unittest2 so I can get access to the
            Python 3.4 self.subTest context manager to simplify this.
            """

            # Test support for unicode input
            self.assertEqual(fgrep_to_re_str([u"abc"]), u"(abc)")
            self.assertEqual(fgrep_to_re_str([u"abc", u"def"]), u"(abc|def)")
            self.assertEqual(fgrep_to_re_str([br"\n[1]".decode('utf8'), u"|"]),
                             br"(\\n\[1\]|\|)".decode('utf8'),
                             "Must escape input strings")

            # Test support for bytes input
            self.assertEqual(fgrep_to_re_str([b"abc"]), b"(abc)")
            self.assertEqual(fgrep_to_re_str([b"abc", b"def"]), b"(abc|def)")
            self.assertEqual(fgrep_to_re_str([br"\n[1]", br"|"]),
                             br"(\\n\[1\]|\|)", "Must escape input strings")

            # Test convenience support for passing a bare string as input
            self.assertEqual(fgrep_to_re_str(u"abc"), u"(abc)")
            self.assertEqual(fgrep_to_re_str(b"abc"), b"(abc)")

            # Test that an empty list doesn't break things
            self.assertIn(fgrep_to_re_str([]), (b'', u'', b'()', u'()'))

            # Verify that escaping isn't being reinvented
            with patch("re.escape") as resc:
                resc.return_value = ""  # Needed to prevent an exception
                fgrep_to_re_str("abc")
                resc.assert_called_once_with("abc")

        def test_lower_percent_escapes(self):
            """L: lower_percent_escapes: basic operation"""
            for before, after in (
                    (u"ABCabc", u"ABCabc"),                     # Percent-free
                    (u"%AFfoo%B0bar%0C", u"%affoo%b0bar%0c"),   # start/mid/end
                    (u"%Affoo%Babar%EC", u"%affoo%babar%ec"),   # mixed case
                    (u"%affoo%b0bar%0c", u"%affoo%b0bar%0c"),   # already lower
                    (u"%02foo%35bar%22", u"%02foo%35bar%22"),   # digit-only
                    (u"%ZaZ%KaZ", u"%ZaZ%KaZ")):                # No-hex triple

                # Verify that it works on both unicode and bytes
                self.assertEqual(lower_percent_escapes(before), after)
                self.assertEqual(lower_percent_escapes(before.encode('utf8')),
                                 after.encode('utf8'))

        def test_vary_escaped(self):
            """L: vary_escaped: basic operation"""
            # Manually-generated test strings (do not automate)
            test_str = u"/01/fœ & bar/<Båz>"
            expected = [u"/01/fœ & bar/<Båz>",
                        u'/01/f%C5%93%20%26%20bar/%3CB%C3%A5z%3E',
                        u'/01/f%c5%93%20%26%20bar/%3cB%c3%a5z%3e',
                        u'/01/fœ &amp; bar/&lt;Båz&gt;']

            result = vary_escaped(test_str)
            self.assertIsInstance(result, (tuple, list),
                                  "Result must have a consistent ordering")
            self.assertListEqual(result, expected)

            # ...and bytestrings to ensure type(input) = type(output)
            test_str = b"/01/foo & bar/<Baz>"
            expected = [b"/01/foo & bar/<Baz>",
                        # TODO: Is this Py3 bytes->str conversion desirable?
                        '/01/foo%20%26%20bar/%3CBaz%3E',
                        '/01/foo%20%26%20bar/%3cBaz%3e',
                        b'/01/foo &amp; bar/&lt;Baz&gt;']

            result = vary_escaped(test_str)
            self.assertIsInstance(result, (tuple, list),
                                  "Result must have a consistent ordering")
            self.assertListEqual(result, expected)

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
        @patch.object(sys.modules[__name__], "FSWrapper", autospec=True)
        def test_main_ls(self, fswrapper, mock):
            """H: main: ls subcommand function"""
            # Allow FSWrapper to be initialized but don't allow method calls
            fswrapper.return_value = None

            with patch.object(sys, 'argv',
                              [__file__, 'ls', self.project.name]):
                main()
                self.assertListEqual(
                    sorted(mock.call_args_list), sorted(
                        [call(x) for x in self.expected.keys()]))

        @patch.object(FSWrapper, "mergemove", autospec=True)
        @patch.object(FSWrapper, "remove_emptied_dirs", autospec=True)
        def test_main_move(self, remdirs, mmv):
            """H: main: mv triggers move_batch but only with args"""
            for args in [[], ['--overwrite']]:
                with patch.object(sys, 'argv',
                        [__file__, 'mv', self.project.name, '/'] + args):
                    main()
                    results = [x[0][1:] for x in mmv.call_args_list]
                    self.assertListEqual(sorted(results),
                        sorted([(x, mounty_join('/', self.expected[x]))
                                for x in self.expected]))
                    remdirs.assert_called_once_with(ANY, self.expected)

                    mmv.reset_mock()
                    remdirs.reset_mock()

        @patch.object(FSWrapper, "move", autospec=True)
        @patch.object(FSWrapper, "remove", autospec=True)
        @patch.object(FSWrapper, "remove_emptied_dirs", autospec=True)
        def test_main_remove(self, remdirs, remove, move):
            """H: main: rm subcommand calls remove() but only properly"""
            with patch.object(sys, 'argv',
                              [__file__, 'rm', self.project.name]):
                main()
                self.assertFalse(move.called)
                remdirs.assert_called_once_with(ANY, self.expected)

                results = [x[0][1] for x in remove.call_args_list]
                self.assertListEqual(sorted(self.expected), sorted(results))

            # TODO: I'll want a test analogous to the old
            #       test_rm_batch_nonexistant

        def test_parse_k3b_proj(self):
            """H: parse_k3b_proj: basic functionality"""
            got = parse_k3b_proj(self.project.name)
            self.assertDictEqual(self.expected, got)

if __name__ == '__main__':  # pragma: nocover
    sys.exit(main())
