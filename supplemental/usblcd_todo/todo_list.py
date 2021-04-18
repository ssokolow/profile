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
from unidecode import unidecode
import pyinotify

BRIGHTNESS = 48
BGCOLOR = BackgroundColours.BLACK
FGCOLOR = TextColours.GREY
log = logging.getLogger(__name__)


class EventHandler(pyinotify.ProcessEvent):
    last_updated = 0

    def __init__(self, path):
        super(EventHandler, self).__init__()
        self.lcd = LCDSysInfo()
        self.lcd.set_brightness(BRIGHTNESS)
        self.lcd.dim_when_idle(False)
        self.lcd.clear_lines(TextLines.ALL, BGCOLOR)
        self.old_lines = [''] * 6
        self.path = path

    @staticmethod
    def fmt_task(task):
        try:
            if task.startswith('+'):
                task = '+ ' + task[1:]
            else:
                task = '- ' + task
            return '____%s' % task
        except AttributeError as err:
            return '- %s' % err

    @staticmethod
    def _parse_todos(path):
        with open(path, 'rU') as fobj:
            yobj = yaml.safe_load_all(fobj)

            # Python 2/3 adapter
            if hasattr(yobj, 'next'):
                yobj_next = yobj.next
            elif hasattr(yobj, '__next__'):
                yobj_next = yobj.__next__
            else:
                raise Exception("Python is broken")

            # Skip header text
            yobj_next()

            return yobj_next() or {}

    def process_IN_MODIFY(self, event):
        # Workaround for race condition when using IN_MODIFY
        # (Because IN_CLOSE_WRITE | IN_MOVED_TO doesn't fire with Leafpad)
        this_stat, waited = os.stat(self.path), 0
        while this_stat.st_size == 0 and waited < 3:
            time.sleep(0.3)
            this_stat = os.stat(self.path)
            waited += 0.3

        # Ensure we fire only once per change
        if self.last_updated == this_stat.st_mtime:
            return

        try:
            data = self._parse_todos(self.path)
        except BaseException as err:
            log.debug("Couldn't parse data from file: %s", self.path)
            lines = ["Error parsing TODO YAML",
                     "%d bytes" % this_stat.st_size,
                     "",
                     str(err)]
            print(err)
        else:
            tasks = data.get('TODO', None)
            if tasks:
                lines = ["TODO:"] + [self.fmt_task(x) for x in tasks]
            else:
                lines = ["No TODOs found"]

        # Waste as little time as possible overwriting lines that haven't
        # changed
        for pos, line in enumerate(lines[:6]):
            if line != self.old_lines[pos]:
                # Work around the ASCII-only-ness of the USBLCD API
                if isinstance(line, bytes):
                    line = line.decode('utf8', 'replace')
                line = unidecode(line)

                self.lcd.display_text_on_line(pos + 1, line, False,
                                         TextAlignment.LEFT, FGCOLOR)
                self.old_lines[pos] = line

        # Only erase lines that used to have something on them
        mask = 0
        for pos in range(len(lines), 6):
            if self.old_lines[pos]:
                mask += 1 << int(pos)
                self.old_lines[pos] = ''
        if mask:
            self.lcd.clear_lines(mask, BGCOLOR)

        # Only update this if we successfuly parsed and applied an update
        self.last_updated = this_stat.st_mtime


def monitor_file(path):
    handler = EventHandler(path)
    handler.process_IN_MODIFY(None)

    wm = pyinotify.WatchManager()
    _ = wm.add_watch(path, pyinotify.IN_MODIFY)
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
