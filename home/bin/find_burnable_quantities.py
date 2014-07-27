#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""A simple little script to walk a filesystem subtree from the leaves upwards
and draw a tree of of folders large enough to be backed up to DVD+R."""

from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__appname__ = "Find Burnable Quantities"
__version__ = "0.0pre0"
__license__ = "MIT"

MIN_SIZE = 4480 * (1024 ** 2)  # 4480MiB
OMITTED_NAMES = ['VIDEO_TS']  # Only show DVD-Video dumps as whole entries

# Avoid thrashing the disk by descending into directories with tons of tiny
# files that we're unlikely to want to size for burning anyway.
TRAVERSAL_EXCLUSIONS = [
    '.backups',
    '.git', '.hg', '.bzr', '.svn',
    'incomplete'
]

import logging
log = logging.getLogger(__name__)

import itertools, math, os, re

def walk(top, topdown=True, onerror=None, followlinks=False,
         traversal_filter_cb=None):
    """Python 2.7.3's os.walk(), modified to allow directory exclusion when
    using topdown=True.

    If a function is passed in via the traversal_filter_cb argument, call it
    with the same arguments that will be yielded before descending.

    Users may then mutate `dirs` to control traversal order or skip folders.
    """

    islink, join, isdir = os.path.islink, os.path.join, os.path.isdir

    # We may not have read permission for top, in which case we can't
    # get a list of the files the directory contains.  os.path.walk
    # always suppressed the exception then, rather than blow up for a
    # minor reason when (say) a thousand readable directories are still
    # left to visit.  That logic is copied here.
    try:
        names = os.listdir(top)
    except os.error, err:
        if onerror is not None:
            onerror(err)
        return

    dirs, nondirs = [], []
    for name in names:
        if isdir(join(top, name)):
            dirs.append(name)
        else:
            nondirs.append(name)

    if traversal_filter_cb:
        traversal_filter_cb(top, dirs, nondirs)
    if topdown:
        yield top, dirs, nondirs
    for name in dirs:
        new_path = join(top, name)
        if followlinks or not islink(new_path):
            for x in walk(new_path, topdown, onerror, followlinks):
                yield x
    if not topdown:
        yield top, dirs, nondirs

def humansort_key(strng):
    """Human/natural sort key-gathering function for sorted()
    Source: http://stackoverflow.com/a/1940105
    """
    if isinstance(strng, tuple):
        strng = strng[0]
    return [w.isdigit() and int(w) or w.lower()
            for w in re.split(r'(\d+)', strng)]

def format_file_size(size, unit='', precision=0):
    """Take a size in bits or bytes and return it all prettied
    up and rounded to whichever unit gives the smallest number.

    A fixed unit can be specified. Possible units are B, KiB,
    MiB, GiB, TiB, and PiB so far. Case-insensitive.

    Works on both negative and positive numbers. In the event
    that the given value is in bits, the user will have to
    use result = result[:-1] + 'b' to make it appear correct.

    Will calculate using integers unless precision is != 0.
    Will display using integers unless precision is > 0.
    """
    # Each unit's position in the list is crucial.
    # units[2] = 'MiB' and size / 1024**2 = size in MiB
    # units[3] = 'GiB' and size / 1024**3 = size in GiB
    units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB']
    increment = 1024.0  # Must be float in Python 2.x to avoid floor division

    # Did the calling function specify a valid unit of measurement?
    if unit and unit.upper() in [x.upper() for x in units]:
        unit_idx = units.index(unit)
    else:
        unit_idx = min(int(math.log(abs(size), increment)), len(units) - 1)

    size /= increment ** unit_idx

    return '%.*f%s' % (precision, size, units[unit_idx])

class StatGatherer(object):
    """Gathers size-filtered disk usage stats"""

    def __init__(self, omitted_names=None, traversal_exclusions=None):
        """
        param omitted_names: Names to be omitted from the listing for clarity
            (eg. VIDEO_TS)
        param traversal_exclusions: Directories to be skipped when descending
            for efficiency (eg. .git)
        """
        self.size_cache = {}
        self.count_cache = {}
        self.omitted_names = omitted_names or []
        self.traversal_exclusions = traversal_exclusions or []

    def _exclusion_cb(self, top, dirs, nondirs):
        """Used with my custom os.walk() to implement traversal exclusions
           when using topdown=False
        """
        for name in self.traversal_exclusions:
            while name in dirs:
                dirs.remove(name)

    def examine(self, root, min_size=MIN_SIZE):
        """Generator to walk a filesystem from the leaves in and print a tree
        of folders larger than C{min_size} bytes."""

        for path, dirs, files in walk(root, topdown=False,
                                      traversal_filter_cb=self._exclusion_cb):
            path = os.path.normpath(os.path.normcase(path))

            # Recursively sum file sizes
            size, fcount = 0, len(files)
            for fname in files:
                try:
                    size += os.path.getsize(os.path.join(path, fname))
                except OSError:
                    pass
            for dname in dirs:
                dpath = os.path.join(path, dname)
                if dpath in self.size_cache:
                    size += self.size_cache[dpath]
                if dpath in self.count_cache:
                    fcount += self.count_cache[dpath]

            self.size_cache[path] = size
            self.count_cache[path] = fcount
            if size >= min_size and (
                    os.path.split(path)[1] not in self.omitted_names):
                yield (path, size, fcount)

    # pylint: disable=no-self-use
    def render(self, results):
        """Generator to render a list of (path, size, count) tuples as a
            treeview using indents."""
        # Commented out to allow efficient generator stream processing
        # results.sort(key=humansort_key)

        for (path, size, files) in results:
            # print(path, size)
            yield '%s%s (%s in %s files)' % (
                ' ' * (path.count(os.sep)),
                os.path.split(path)[1], format_file_size(size, precision=2),
                files)

def main():
    """The main entry point, compatible with setuptools entry points."""
    # pylint: disable=bad-continuation
    from optparse import OptionParser
    parser = OptionParser(version="%%prog v%s" % __version__,
            usage="%prog [options] <path> ...",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_option('-v', '--verbose', action="count", dest="verbose",
        default=2, help="Increase the verbosity. Use twice for extra effect")
    parser.add_option('-q', '--quiet', action="count", dest="quiet",
        default=0, help="Decrease the verbosity. Use twice for extra effect")
    parser.add_option('-r', '--reverse', action="store_true", dest="reverse",
        default=0, help="Show results as they are gathered (in reverse order)")

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

    statter = StatGatherer(
        omitted_names=OMITTED_NAMES,
        traversal_exclusions=TRAVERSAL_EXCLUSIONS)

    results = itertools.chain(*[statter.render(statter.examine(x))
                                for x in args])

    if not opts.reverse:
        results = reversed(list(results))
    for line in results:
        print(line)

if __name__ == '__main__':
    main()
