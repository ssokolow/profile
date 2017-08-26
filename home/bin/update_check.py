#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""Simple notify2-based apt-get update notifier

Requires:
- dbus-python (A.K.A. python-dbus)
- notify2
- python-gobject (for Python 2.x)

(Though it shouldn't be too difficult to adapt to Python 3.x since
 python-gobject is the only dependency with a changed API.)
"""

from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.1"
__license__ = "MIT"

import os, re, subprocess, sys
import gobject
import notify2 as notify

from dbus.mainloop.glib import DBusGMainLoop
DBusGMainLoop(set_as_default=True)

TERM_CMD = ['urxvt', '-e']
TIMEOUT = 1000 * 3600 * 23  # 23 hours
ICON_PATH = os.path.expanduser(
    "~/.local/share/icons/elementary/apps/16/update-notifier.svg")

def die(title, msg):
    """Send an error message via libnotify and exit"""
    notification = notify.Notification(title, msg, ICON_PATH)
    notification.set_timeout(notify.EXPIRES_NEVER)
    notification.show()
    sys.exit(1)

def enwindow():
    """Ensure that we are running in a terminal window"""
    argv = TERM_CMD + sys.argv + ['--no-prompt']
    try:
        os.execvp(argv[0], argv)
    except OSError:
        die("Failed to launch terminal!",
            "Could not run command:\n{}".format(
                repr(argv)))

class AptWrapper(object):
    """API abstraction to make it easy to swap in `python-apt` later"""
    _apt_command = ["/usr/bin/apt-get", "dist-upgrade"]
    _re_apt_line = re.compile(r"""^Inst[ ]
        (?P<name>\S+)[ ]
        \[(?P<oldver>[^\]]*)\][ ]
        \((?P<newver>\S+)[ ]
        (?P<source>.+)[ ]
        \[(?P<arch>[^\]]+)\].*\)
    """, re.VERBOSE | re.MULTILINE)

    def apply_updates(self):
        """Request that pending updates be applied"""
        argv = ['sudo'] + self._apt_command
        try:
            subprocess.check_call(argv)
        except (OSError, subprocess.CalledProcessError):
            die("apt-get Failure!",
                "Attempting to call the following command returned failure:\n"
                "{}".format(repr(argv)))

    def get_updates(self):
        """Retrieve a list of pending package updates"""
        argv = (self._apt_command +
                ['-s', '-q', '-y', '--allow-unauthenticated'])

        try:
            pkgs = self._re_apt_line.findall(subprocess.check_output(argv))
        except (OSError, subprocess.CalledProcessError):
            die("apt-get Failure!",
                "Attempting to call the following command returned failure:\n"
                "{}".format(repr(argv)))

        pkgs = [{'name': x[0], 'old_ver': x[1], 'new_ver': x[2]} for x in pkgs]
        pkgs.sort()
        return pkgs

class NotificationPrompt(object):
    """API wrapper for using a libnotify popup as a prompt"""
    def __init__(self, mainloop, userdata=None, timeout=TIMEOUT):
        self.loop = mainloop
        self.timeout = timeout
        self.userdata = userdata

    def cb_cancel(self, userdata):
        """Callback to quit the program when the notification is closed"""
        self.loop.quit()

    def prompt(self, title, msg, cb_ok, cb_ok_title='OK'):
        notification = notify.Notification(title, msg, ICON_PATH)
        notification.set_timeout(self.timeout)
        notification.set_hint('resident', False)
        notification.connect('closed', self.cb_cancel)
        notification.add_action('ok', cb_ok_title, cb_ok, self.userdata)
        notification.show()

def cb_update_requested(notification=None, action_key=None):
    """Callback to pop up an apt-get terminal if the button is clicked"""
    if notification:
        notification.close()
        enwindow()

    AptWrapper().apply_updates()
    sys.exit()


def main():
    """The main entry point, compatible with setuptools entry points."""
    # If we're running on Python 2, take responsibility for preventing
    # output from causing UnicodeEncodeErrors. (Done here so it should only
    # happen when not being imported by some other program.)
    if sys.version_info.major < 3:
        reload(sys)
        sys.setdefaultencoding('utf-8')  # pylint: disable=no-member

    from argparse import ArgumentParser, RawTextHelpFormatter
    parser = ArgumentParser(formatter_class=RawTextHelpFormatter,
        description=__doc__.replace('\r\n', '\n').split('\n--snip--\n')[0])
    parser.add_argument('--version', action='version',
        version="%%(prog)s v%s" % __version__)
    parser.add_argument('--no-prompt', default=False, action='store_true',
        help="Jump straight to applying updates")

    args = parser.parse_args()
    loop = gobject.MainLoop()

    notify.init("update_notifier")
    apt = AptWrapper()

    if args.no_prompt:
        cb_update_requested()
    elif apt.get_updates():
        if 'actions' in notify.get_server_caps():
            prompt = NotificationPrompt(loop)
            prompt.prompt("Updates Available",
                "Packages updates are available via apt-get",
                cb_update_requested, 'Update')
        else:
            raise NotImplementedError("TODO: Fall back to Zenity")
    else:
        sys.exit()

    gobject.timeout_add(TIMEOUT, loop.quit)
    loop.run()

if __name__ == '__main__':
    main()

# vim: set sw=4 sts=4 expandtab :
