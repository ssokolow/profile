#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""A command-line analogue to the 'merge/overwrite' behaviour for copy-pasting
directories in GUI file managers.

(Unlike rsync-based solutions, does not force a copy when moving within the
same partition)
"""

from __future__ import (absolute_import, division, print_function,
                        with_statement)

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__appname__ = "MergeMove"
__version__ = "0.0pre0"
__license__ = "MIT"

import logging
log = logging.getLogger(__name__)

import os, re, shutil, sys, tempfile, urllib

def _move(src, dest, overwrite=False, dry_run=False):
    """Wrapper for C{shutil.move} which handles overwrite control and
       supports dry_run=True.

        @return: List of paths not moved for use by L{rewrite}
    """
    if os.path.exists(dest) and not overwrite:
        log.warn("Target exists. Skipping: %s", dest)
    else:
        log.info("%r -> %r", src, dest)
        if not dry_run:
            shutil.move(src, dest)
            return []
    return [src]

def mergemove(src, dest, overwrite=False, dry_run=False):
    """Move a file or folder, resursively merging it if the target exists.

    @type src: C{str}
    @param dest: The exact path which C{src} should be moved to
                 (not the parent directory)

    @return: List of paths not moved for use by L{rewrite}
    """
    src = os.path.abspath(src)
    dest = os.path.abspath(dest)

    if not os.path.exists(src):
        log.error("Source path does not exist: %r", src)
    elif os.path.isfile(src):
        if not _move(src, dest, overwrite, dry_run):
            return [src]

    not_moved = []
    for path, dirs, files in os.walk(src):
        relpath = os.path.relpath(path, src)
        destpath = os.path.normpath(os.path.join(dest, relpath))

        # If no merging is necessary, don't descend further
        if not os.path.exists(destpath):
            not_moved.extend(_move(path, destpath, overwrite, dry_run))
            dirs[:] = []
            continue

        # If we got this far, move over the files and let `for ... os.walk()`
        # handle the subdirectories.
        for fname in files:
            not_moved.extend(_move(os.path.join(path, fname),
                                   os.path.join(destpath, fname),
                                   overwrite, dry_run))

    # Skip the second traversal when a dry run would make the results
    # inaccurate and the traversal potentially expensive.
    if not dry_run:
        # TODO: Redesign os.walk() so I can do this on the first traversal
        for path, dirs, files in os.walk(src, topdown=False):
            if dirs or files:
                log.warn("Could not remove non-empty directory: %r", path)
            else:
                log.info("Removing directory: %r", path)
                os.rmdir(path)
    return not_moved

def rewrite(fpath, mappings, exceptions=None):
    """Rewrite paths within a given file."""
    # Transparently support both paths and URL components
    # (Not perfect since not all programs escape the same set of characters as
    #  urllib.quote() but a good start for a naive tool)
    mappings = mappings.copy()
    mappings.update({urllib.pathname2url(x): urllib.pathname2url(y)
                     for x, y in mappings.items()})

    rex = re.compile('(%s)' % '|'.join(re.escape(x) for x in mappings.keys()))
    exceptions = exceptions or []

    # Optimize lookups for exceptions
    exceptions_dict = dict((x, []) for x in mappings.keys())
    for path in exceptions:
        for ancestor in exceptions_dict:
            url_path = urllib.pathname2url(path)

            # Again, transparently support both paths and URL components
            if path.startswith(ancestor):
                exceptions_dict[ancestor].append((path, len(path)))
            elif url_path.startswith(ancestor):
                exceptions_dict[ancestor].append((url_path, len(path)))

    with open(fpath, 'rb') as fobj:
        content = fobj.read()

    def matcher(match):
        """re.sub callback"""
        src = match.group(0)

        for exc_path, exc_len in exceptions_dict[src]:
            start = match.start()
            if exc_path == content[start:start + exc_len]:
                return src
        log.debug("Rewrite in %r: %r -> %r", fpath, src, mappings[src])
        return mappings[src]

    # Replace atomically
    # TODO: I think Windows required an explicit delete first
    with tempfile.NamedTemporaryFile(delete=False,
                                     dir=os.path.split(fpath)[0]) as fobj:
        fobj.write(rex.sub(matcher, content))
        tempsrc = fobj.name
    os.rename(tempsrc, fpath)

def main():
    """The main entry point, compatible with setuptools entry points."""
    # pylint: disable=bad-continuation
    from optparse import OptionParser
    parser = OptionParser(version="%%prog v%s" % __version__,
            usage="%prog [options] <src_path> [...] <dest_path>",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_option('-v', '--verbose', action="count", dest="verbose",
        default=2, help="Increase the verbosity. Use twice for extra effect")
    parser.add_option('-q', '--quiet', action="count", dest="quiet",
        default=0, help="Decrease the verbosity. Use twice for extra effect")
    parser.add_option('-o', '--overwrite', action="store_true",
                      dest="overwrite", default=False,
                      help="Overwrite when file paths collide.")
    parser.add_option('-n', '--dry-run', action="store_true",
                      dest="dry_run", default=False,
                      help="Don't actually do anything")
    parser.add_option('--rewrite', action="append", metavar="PATH",
                      dest="rewrite", default=[],
                      help="Update all moved paths in the given file")

    # Allow pre-formatted descriptions
    parser.formatter.format_description = lambda description: description

    opts, args = parser.parse_args()

    # Set up clean logging to stderr
    log_levels = [logging.CRITICAL, logging.ERROR, logging.WARNING,
                  logging.INFO, logging.DEBUG]
    opts.verbose = min(opts.verbose - opts.quiet, len(log_levels) - 1)
    opts.verbose = max(opts.verbose, 0)
    logging.basicConfig(level=log_levels[opts.verbose],
                        format='%(levelname)s: %(message)s')

    # Implement the same semantics as mv/cp
    move_pairs = {}
    if len(args) < 2:
        parser.print_usage()
        sys.exit(1)
    elif len(args) == 2 and not os.path.isdir(args[1]):
        mergemove(args[0], args[1], opts.overwrite, opts.dry_run)
    else:
        dest = os.path.abspath(args.pop())
        for src in args:
            srcpath = os.path.abspath(src)
            srcname = os.path.split(srcpath)[1]
            destpath = os.path.join(dest, srcname)

            move_pairs[srcpath] = destpath
            exceptions = mergemove(src, destpath,
                                   opts.overwrite, opts.dry_run)

    if opts.rewrite:
        for path in opts.rewrite:
            rewrite(path, move_pairs, exceptions)

if __name__ == '__main__':
    main()
