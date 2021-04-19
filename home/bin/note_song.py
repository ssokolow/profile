#!/usr/bin/env python3

import os
from subprocess import check_output  # nosec

import gi  # type: ignore
gi.require_version('Notify', '0.7')

from gi.repository import Notify  # type: ignore
Notify.init(__file__)
notification = Notify.Notification.new

# Get list of already-noted songs
note_file = os.path.expanduser("~/noted_songs.txt")
if os.path.exists(note_file):
    with open(note_file, 'rb') as fh:
        noted_songs = [x.strip() for x in fh.read().strip().split(b'\n')]
else:
    noted_songs = []

songPath = check_output(['audtool', 'current-song-filename'])  # nosec
songTitle = check_output(['audtool', 'current-song']).decode('utf8')  # nosec

if songPath.strip() not in noted_songs:
    with open(os.path.expanduser("~/noted_songs.txt"), 'ab') as fh:
        fh.write(songPath + b'\n')
    msgTitle = "Song Noted"
else:
    msgTitle = "Already Noted Song"

notification(songTitle, msgTitle, 'dialog-information').show()
