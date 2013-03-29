#!/usr/bin/env python

import os, sys
from xml.sax.saxutils import escape

#TODO: Support using GDBus
import dbus
bus = dbus.Bus(dbus.Bus.TYPE_SESSION)

try:
    import pynotify
    pynotify.init(__file__)
    notification = pynotify.Notification
except ImportError:
    from gi.repository import Notify
    Notify.init(__file__)
    notification = Notify.Notification.new

try:
    aud = bus.get_object('org.atheme.audacious', '/org/atheme/audacious')
except dbus.DBusException:
    sys.exit("Either Audacious is not running or you have something wrong with"
             " your D-Bus setup.")

# Get list of already-noted songs
note_file = os.path.expanduser("~/noted_songs.txt")
if os.path.exists(note_file):
    with file(note_file, 'r') as fh:
        noted_songs = [x.strip() for x in fh.read().strip().split('\n')]
else:
    noted_songs = []

songURL = aud.SongFilename(aud.Position()).encode("utf8")
songTitle = escape(aud.SongTitle(aud.Position()).strip())
if songURL.strip() not in noted_songs:
    with open(os.path.expanduser("~/noted_songs.txt"), 'a') as fh:
        fh.write(aud.SongFilename(aud.Position()).encode("utf8") + '\n')
    msgTitle = "Song Noted"
else:
    msgTitle = "Already Noted Song"

notification(songTitle, msgTitle, 'dialog-information').show()
