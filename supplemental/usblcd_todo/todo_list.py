#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""TODO list driver for LCDSysInfo device"""

from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__appname__ = "[application name here]"
__version__ = "0.0pre0"
__license__ = "GNU GPL 3.0 or later"

import logging, os, time

import yaml
from pylcdsysinfo import (BackgroundColours, LCDSysInfo, TextAlignment,
                          TextColours, TextLines)
import pyinotify

BRIGHTNESS = 48
BGCOLOR = BackgroundColours.BLACK
FGCOLOR = TextColours.GREY
log = logging.getLogger(__name__)

def monitor_file(path):
    class EventHandler(pyinotify.ProcessEvent):
        last_updated = 0

        def __init__(self):
            super(EventHandler, self).__init__()
            self.lcd = LCDSysInfo()
            self.lcd.set_brightness(BRIGHTNESS)
            self.lcd.dim_when_idle(False)
            self.lcd.clear_lines(TextLines.ALL, BGCOLOR)
            self.old_lines = [''] * 6

        @staticmethod
        def fmt_task(task):
            if task.startswith('+'):
                task = '+ ' + task[1:]
            else:
                task = '- ' + task
            return '____%s' % task

        def process_IN_MODIFY(self, event):
            # TODO: There's a race condition on how we use inotify. See if we
            #       there's a proper solution beyond "only update last_updated
            #       on successful parse."

            # Ensure we fire only once per change
            this_mtime = os.stat(path).st_mtime
            if self.last_updated == this_mtime:
                return

            try:
                with open(path, 'rU') as fobj:
                    yobj = yaml.safe_load_all(fobj)
                    yobj.next()  # Skip header text
                    data = yobj.next()
            except StopIteration:
                log.debug("Couldn't parse data from file: %s", path)
                return  # Don't die on a bad file

            tasks = data.get('TODO')
            if not tasks:
                return


            # Waste as little time as possible overwriting lines that haven't
            # changed
            lines = ["TODO:"] + [self.fmt_task(x) for x in tasks]
            for pos, line in enumerate(lines[:6]):
                if line != self.old_lines[pos]:
                    self.lcd.display_text_on_line(pos + 1, line, False,
                                             TextAlignment.LEFT, FGCOLOR)
                    self.old_lines[pos] = line

            # Only erase lines that used to have something on them
            mask, linecount = 0, len(lines)
            for pos in range(len(lines), 6):
                if self.old_lines[pos]:
                    mask += 1 << int(pos)
                    self.old_lines[pos] = ''
            if mask:
                self.lcd.clear_lines(mask, BGCOLOR)

            # Only update this if we successfuly parsed and applied an update
            self.last_updated = this_mtime

    handler = EventHandler()
    handler.process_IN_MODIFY(None)

    wm = pyinotify.WatchManager()
    wdd = wm.add_watch(path, pyinotify.IN_MODIFY)
    notifier = pyinotify.Notifier(wm, handler)
    notifier.loop()

def main():
    """The main entry point, compatible with setuptools entry points."""
    from argparse import ArgumentParser
    parser = ArgumentParser(usage="%(prog)s [options] <argument> ...",
            description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_argument('--version', action='version',
            version="%%(prog)s v%s" % __version__)
    parser.add_argument('-v', '--verbose', action="count", dest="verbose",
        default=2, help="Increase the verbosity. Use twice for extra effect")
    parser.add_argument('-q', '--quiet', action="count", dest="quiet",
        default=0, help="Decrease the verbosity. Use twice for extra effect")
    parser.add_argument('path', action="store")
    # Reminder: %(default)s can be used in help strings.

    args = parser.parse_args()

    # Set up clean logging to stderr
    log_levels = [logging.CRITICAL, logging.ERROR, logging.WARNING,
                  logging.INFO, logging.DEBUG]
    args.verbose = min(args.verbose - args.quiet, len(log_levels) - 1)
    args.verbose = max(args.verbose, 0)
    logging.basicConfig(level=log_levels[args.verbose],
                        format='%(levelname)s: %(message)s')

    monitor_file(args.path)

if __name__ == '__main__':
    main()

# vim: set sw=4 sts=4 expandtab :
