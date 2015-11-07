#!/usr/bin/python2
# -*- coding: utf-8 -*-
"""Script to update nVidia binary drivers only when the resulting ABI breakage
can be immediately resolved by a restart.

Dependencies:
 - A version of apt new enough to have `apt-mark`
 - python-apt 0.9.x (1.0+ support untested)
 - (/bin/rmmod and /bin/modprobe) or /bin/reboot (Ideally, all three)
"""

from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__appname__ = "Controlled nVidia upgrade"
__version__ = "0.1alpha1"
__license__ = "MIT"

import logging, subprocess
from contextlib import contextmanager

from apt.cache import Cache, FetchFailedException, FilteredCache, Filter
from apt.progress.text import OpProgress
from apt_pkg import CURSTATE_INSTALLED  # pylint: disable=no-name-in-module

log = logging.getLogger(__name__)

class NvidiaFilter(Filter):  # pylint: disable=too-few-public-methods
    """Filter for packages with an unstable kernel-userland ABI.

    (Packages that should only be updated when you're willing to reboot)
    """
    def apply(self, pkg):
        if not ('nvidia' in pkg.name and 'restricted' in pkg.section):
            return False

        # Support both pre- and post-1.0 python-apt
        if hasattr(pkg, 'current_state'):
            return pkg.current_state == CURSTATE_INSTALLED
        else:
            return pkg.is_installed

def query_verbosity():
    """Get apt flags and python-apt progress object for current log verbosity.
    """
    if log.isEnabledFor(logging.DEBUG):
        return [], OpProgress()
    else:
        return ['-qq'], None

def logged_call(cmdline, fatal=False):
    """Run a subprocess and log failures. Optionally re-raise the error."""
    try:
        subprocess.check_call(cmdline)
        # Use check_call to fail early if apt-mark is missing
    except subprocess.CalledProcessError:
        log.error("Could not call %r", cmdline)
        if fatal:
            raise

@contextmanager
def unhold(names, cache):
    """Context manager for temporarily un-holding apt packages

    @todo: Stop using apt-mark once I know I can rely on python-apt 1.x being
           available (ie. not Ubuntu Vivid and earlier)."""
    logopts, progress = query_verbosity()

    log.info("Un-holding nVidia drivers...")
    # Use apt-mark until I know I can rely on python-apt 1.x
    # from apt_pkg import SELSTATE_HOLD, SELSTATE_INSTALL
    cache.close()
    logged_call(['/usr/bin/apt-mark', 'unhold'] + logopts + names, fatal=True)
    # Fail early if apt-mark is missing

    try:
        cache.open(progress)
        yield
    finally:
        try:
            cache.close()
        except:  # pylint: disable=bare-except
            pass
        log.info("Re-holding nVidia drivers...")
        logged_call(['/usr/bin/apt-mark', 'hold'] + logopts + names)

def do_update():
    _, progress = query_verbosity()

    log.info("Getting list of eligible packages...")
    cache = Cache(progress)
    f_cache = FilteredCache(cache)
    f_cache.set_filter(NvidiaFilter())
    names = f_cache.keys()

    with unhold(names, cache):
        log.info("Updating package list...")
        try:
            cache.update()
        except FetchFailedException, err:
            log.warn(err)
        cache.open(progress)  # Refresh package list

        old_versions = {name: cache[name].installed for name in names}
        log.info("Updating all packages...")
        for name in names:
            if cache[name].is_upgradable:
                cache[name].mark_upgrade()
        cache.commit(None, None)

        log.info("Refreshing package cache...")
        cache.open(progress)
        new_versions = {name: cache[name].installed for name in names}

        log.info("Checking whether packages were upgraded...")
        for name in old_versions:
            if old_versions[name] != new_versions[name]:
                log.info("Kernel module changed")
                return True
        return False

def main():
    """The main entry point, compatible with setuptools entry points."""
    from argparse import ArgumentParser
    parser = ArgumentParser(usage="%(prog)s [options]",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_argument('--version', action='version',
            version="%%(prog)s v%s" % __version__)
    parser.add_argument('-v', '--verbose', action="count", dest="verbose",
        default=2, help="Increase the verbosity. Use twice for extra effect")
    parser.add_argument('-q', '--quiet', action="count", dest="quiet",
        default=0, help="Decrease the verbosity. Use twice for extra effect")
    # Reminder: %(default)s can be used in help strings.

    args = parser.parse_args()

    # Set up clean logging to stderr
    log_levels = [logging.CRITICAL, logging.ERROR, logging.WARNING,
                  logging.INFO, logging.DEBUG]
    args.verbose = min(args.verbose - args.quiet, len(log_levels) - 1)
    args.verbose = max(args.verbose, 0)
    logging.basicConfig(level=log_levels[args.verbose],
              format='%(levelname)s: %(message)s')

    if do_update():
        log.info("Attempting live kernel module update...")

        # `modprobe -r` returns 0 even on failure so we use rmmod
        if subprocess.call(['/bin/rmmod', 'nvidia']) == 0:
            subprocess.call(['/bin/modprobe', 'nvidia'])
        else:
            log.info("Module removal failed. Triggering reboot.")
            subprocess.call(['/bin/reboot'])

if __name__ == '__main__':
    main()

# vim: set sw=4 sts=4 expandtab :
