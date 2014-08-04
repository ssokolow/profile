#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Simple unattended script for linking my roaming profile into a new $HOME.

@todo:
- Run ` ~/bin/git-submodule-recur.sh submodule update --init` on completion.
- Should recurse if not --overwrite and os.path.isdir()
- Consider including an option to install my base set of packages on apt-based
  distros and chsh to zsh.
- Need some generic mechanism for running commands like these after:
    xrdb -merge ~/.Xresources
"""

__appname__ = "ssokolow/profile symlink setup script"
__author__  = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.1"
__license__ = "GNU GPL 2.0 or later"

import logging, os, shutil
log = logging.getLogger(__name__)

# TODO: Make this support paths to be exploded for clean and specific syntax.
RECURSE = [
    'applications',
    'bin',
    '.virtualenvs',
    '.config',
    'geeqie',
    'lxpanel',
    'lxsession',
    'LXDE',
    'openbox',
    'parcellite',
    '.local',
    '.trinity',
    'share'
]

# TODO: Hook this in
def relpath(path, start=os.curdir):
    """Return a relative version of a path
    Borrowed from Python 2.7's posixpath.py for compatibility with Slax.
    """

    if not path:
        raise ValueError("no path specified")

    start_list = [x for x in os.path.abspath(start).split(os.sep) if x]
    path_list = [x for x in os.path.abspath(path).split(os.sep) if x]

    # Work out how much of the filepath is shared by start and path.
    i = len(os.path.commonprefix([start_list, path_list]))

    rel_list = [os.pardir] * (len(start_list) - i) + path_list[i:]
    if not rel_list:
        return os.curdir
    return os.path.join(*rel_list)

def symlink_path(source, target, dry_run=False, overwrite=False):
    tgt_dir = os.path.dirname(target)

    if os.path.exists(target) or os.path.islink(target):
        if overwrite:
            log.info("Replace with Symlink: %s -> %s", source, target)
            if not dry_run:
                if os.path.isdir(target) and not os.path.islink(target):
                    shutil.rmtree(target)
                else:
                    os.unlink(target)
        else:
            log.warning("Skipping already existing target: %s", target)
            return False
    elif os.path.exists(tgt_dir) and not os.path.isdir(tgt_dir):
        log.error("Target 'parent directory' not a directory: %s", tgt_dir)
        return False
    else:
        log.info("Symlink: %s -> %s", source, target)

    if not dry_run:
        if not os.path.exists(tgt_dir):
            os.makedirs(tgt_dir)

        linkpath = relpath(source, tgt_dir)
        os.symlink(linkpath, target)
    return True


def symlink_profile(root, home_root, dry_run=False, overwrite=False):
    """
    @param home_root: Target equivalent to C{root} used for recusive calling.
    """
    root = os.path.normpath(root)
    home = os.path.normpath(home_root)

    for name in sorted(os.listdir(root)):
        src = os.path.join(root, name)
        tgt = os.path.join(home, name)

        if os.path.islink(tgt):
            tgt_link = os.path.normpath(os.path.join(home, os.readlink(tgt)))
        else:
            tgt_link = None

        if tgt_link == src:
            log.debug("Skipping already-linked path: %s", tgt)
        elif os.path.isdir(src) and name in RECURSE:
            log.debug("Recursing: %s", src)
            symlink_profile(src, tgt, dry_run, overwrite)
        else:
            symlink_path(src, tgt, dry_run, overwrite)

if __name__ == '__main__':
    from optparse import OptionParser
    parser = OptionParser(version="%%prog v%s" % __version__,
            usage="%prog [options]",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_option('-n', '--dry-run', action="store_true", dest="dry_run",
        default=False, help="Don't make changes. (Best used with -v)")
    parser.add_option('-v', '--verbose', action="count", dest="verbose",
        default=3, help="Increase the verbosity.")
    parser.add_option('-q', '--quiet', action="count", dest="quiet",
        default=0, help="Decrease the verbosity. Repeat for extra effect.")
    parser.add_option('--overwrite', action="store_true", dest="overwrite",
        default=False, help="Overwrite existing files if necessary.")
    parser.add_option('--prefix', action="store", dest="home",
        default=os.environ['HOME'],
        help="Specify a location other than %default to install to.")

    opts, args  = parser.parse_args()

    # Set up clean logging to stderr
    log_levels = [logging.CRITICAL, logging.ERROR, logging.WARNING,
                  logging.INFO, logging.DEBUG]
    opts.verbose = min(opts.verbose - opts.quiet, len(log_levels) - 1)
    opts.verbose = max(opts.verbose, 0)
    logging.basicConfig(level=log_levels[opts.verbose],
                        format='%(levelname)s: %(message)s')

    root = os.path.dirname(os.path.abspath(__file__))
    if not os.path.isdir(os.path.join(root, '.git')):
        log.warning("You aren't running me on a valid git repository!")

    symlink_profile(os.path.join(root, 'home'), opts.home,
        dry_run=opts.dry_run,
        overwrite=opts.overwrite)

# vim: sw=4 sts=4 expandtab
