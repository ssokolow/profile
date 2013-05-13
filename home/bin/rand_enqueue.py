#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""A simple script for randomly selecting a bunch of media files and then
enqueueing or playing them.
"""

__appname__ = "rand_enqueue.py"
__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.3"
__license__ = "GNU GPL 2 or later"

BLACKLISTED_EXTS = [
    '.m3u', '.pls', '.xspf'     # Playlists (just enqueue directly)
    '.jpg', '.jpeg', '.png', '.gif', '.bmp',  # Images (eg. Cover Art)
    '.txt', '.html', '.htm',    # Not media
    '.sid',                     # Capable of looping infinitely
    '.mid', '.midi', '.rmi',    # Require the keyboard to be turned on manually
]
# Note: SID is actually blacklisted for two reasons:
#  1. I have the entire HVSC and I don't want that to weight the randomization
#     in favor of SIDs.
#  2. All the SIDs I've encountered loop infinitely and I want my playlist to
#     stop after a predictable interval.

import logging, os, random, subprocess
log = logging.getLogger(__name__)

#TODO: Try to merge this with lap more
def gather(roots):
    choices = []
    for root in roots:
        for fldr, dirs, files in os.walk(root):
            choices.extend(os.path.join(fldr, x) for x in files
                    if not os.path.splitext(x)[1].lower() in BLACKLISTED_EXTS)

    chosen = []
    for i in range(0, opts.wanted_count):
        # We don't want duplicates
        chosen.append(choices.pop(random.randrange(0, len(choices))))

    return chosen

if __name__ == '__main__':
    from optparse import OptionParser
    op = OptionParser(version="%%prog v%s" % __version__,
            usage="%prog [options] <argument> ...",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])

    op.add_option('-v', '--verbose', action="count", dest="verbose",
        default=2, help="Increase the verbosity. Use twice for extra effect")
    op.add_option('-q', '--quiet', action="count", dest="quiet",
        default=0, help="Decrease the verbosity. Use twice for extra effect")
    op.add_option("-e", "--exec", action="store", dest="exe_cmd", default=None,
        help="Use this command to enqueue/play rather than the default.")
    op.add_option("-Q", "--enqueue", action="store_true", dest="enqueue",
        default=False, help="Don't start song(s) playing after enqueueing it.")
    op.add_option("-n", "--song-count", action="store", type=int,
        dest="wanted_count", default=1, metavar="NUM",
        help="Request that NUM randomly-chosen songs be picked rather than "
        "just one.")

    # Allow pre-formatted descriptions
    op.formatter.format_description = lambda description: description

    (opts, args) = op.parse_args()

    # Set up clean logging to stderr
    log_levels = [logging.CRITICAL, logging.ERROR, logging.WARNING,
                  logging.INFO, logging.DEBUG]
    opts.verbose = min(opts.verbose - opts.quiet, len(log_levels) - 1)
    opts.verbose = max(opts.verbose, 0)
    logging.basicConfig(level=log_levels[opts.verbose],
                        format='%(levelname)s: %(message)s')

    if not args:
        args.append(subprocess.check_output(['xdg-user-dir', 'MUSIC']).strip())

    if opts.exe_cmd:
        cmd = opts.exe_cmd
    else:
        #TODO: Figure out a way to make this more configurable without the
        #      xdg-open limitation of one file per call.
        cmd = 'aq' if opts.enqueue else 'ap'

    subprocess.call([cmd] + gather(args))
