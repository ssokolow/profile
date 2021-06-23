#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""General information display using  LCDSysInfo device"""

# Prevent Python 2.x PyLint from complaining if run on this
from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__appname__ = "[application name here]"
__version__ = "0.0pre0"
__license__ = "GNU GPL 3.0 or later"

import logging, os
from datetime import datetime

#import yaml
from pylcdsysinfo import (BackgroundColours, LCDSysInfo, TextAlignment,
                          TextColours, TextLines)
from unidecode import unidecode
#import pyinotify

import xcffib, xcffib.xproto
import xcffib.screensaver

BRIGHTNESS = 48
BGCOLOR = BackgroundColours.BLACK
FGCOLOR = TextColours.GREY

log = logging.getLogger(__name__)

conn = xcffib.connect()
setup = conn.get_setup()
ss_conn = conn(xcffib.screensaver.key)


def get_idle_secs():
    """Query how long since user input was seen from X11.

    NOTE: Many applications suppress the screensaver by faking user input
    """
    try:
        # (Don't use "while True" in case the xcb "NULL when no more"
        #  behaviour occasionally happens)
        while conn.poll_for_event():
            pass
    except IOError:
        # In testing, IOError is raised when no events are available.
        pass

    idle_query = ss_conn.QueryInfo(setup.roots[0].root)
    idle_secs = idle_query.reply().ms_since_user_input / 1000.0
    return idle_secs


def pformat_idle(secs):
    secs = int(abs(secs))

    if secs >= 60:
        increments = (
            (60 * 60 * 24, 'day'),
            (60 * 60, 'hour'),
            (60, 'minute'),
        )
        for increment, label in increments:
            value = secs // increment
            if value > 1:
                return "Idle for {} {}s".format(value, label)
            elif value == 1:
                return "Idle for {} {}".format(value, label)

    return "Inhibited or Not Idle"


lcd = LCDSysInfo()
lcd.set_brightness(BRIGHTNESS)
lcd.dim_when_idle(False)
lcd.clear_lines(TextLines.ALL, BGCOLOR)
lcd.display_icon(0, 13)

# icon = 3
# for x in range(11, 48):
#    if icon == 13:
#        icon += 1
#    lcd.display_icon(x + 5, icon)
#    icon += 1

import time
last_time = datetime.fromtimestamp(0)
while True:
    this_time = datetime.now()
    if 8 <= this_time.hour <= 18:
        color = FGCOLOR
    elif 18 <= this_time.hour < 21 or 4 <= this_time.hour < 7:
        color = TextColours.YELLOW
    else:
        color = TextColours.RED

    if this_time != last_time:
        lcd.display_text_on_line(1, this_time.strftime('|%Y-%m-%d|%H:%M'),
            True, TextAlignment.LEFT, color)
        lcd.display_text_on_line(2, time.strftime('|%a, %b %d|%Y'),
            True, TextAlignment.LEFT, FGCOLOR)
        last_time = this_time

    lcd.display_text_on_line(3,
        '|{}'.format(pformat_idle(get_idle_secs())),
        True, TextAlignment.LEFT, FGCOLOR)
    time.sleep(1)

# TODO: Consider parsing https://weather.gc.ca/rss/city/on-13_e.xml
#       and displaying the current temperature and icons for the 7-day forecast


def main():
    """The main entry point, compatible with setuptools entry points."""
    from argparse import ArgumentParser, RawDescriptionHelpFormatter
    parser = ArgumentParser(formatter_class=RawDescriptionHelpFormatter,
        description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_argument('--version', action='version',
        version="%%(prog)s v%s" % __version__)
    parser.add_argument('-v', '--verbose', action="count",
        default=2, help="Increase the verbosity. Use twice for extra effect.")
    parser.add_argument('-q', '--quiet', action="count",
        default=0, help="Decrease the verbosity. Use twice for extra effect.")
    parser.add_argument('path', action="store",
        help="Path to operate on")
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


if __name__ == '__main__':  # pragma: nocover
    main()

# vim: set sw=4 sts=4 expandtab :
