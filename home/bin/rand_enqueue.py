#!/usr/bin/env python

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.2"
__license__ = "GNU GPL 2 or later"

music_root = '/srv/fservroot/music'
BLACKLISTED_EXTS = ['.txt', '.m3u', '.pls', '.xspf', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.html', '.htm', '.war', '.sid', '.mid', '.midi', '.rmi']
# Note: SID is blacklisted for two reasons:
#  1. I have the entire HVSC and I don't want that to weight the randomization in favor of SIDs.
#  2. All the SIDs I've encountered loop infinitely and I want my playlist to stop after a predictable interval.
# MIDI is blacklisted because the timidity plugin is broken and I don't feel like it anyway.

import optparse, os, random, subprocess

if __name__ == '__main__':
	op = optparse.OptionParser(usage="%prog [options] [music root] ...")
	op.add_option("-q", "--enqueue", action="store_true", dest="enqueue", default=False,
			help="Don't start the song playing after enqueueing it.")
	op.add_option("-n", "--song-count", action="store", type=int, dest="wanted_count", default=1,
			metavar="NUM", help="Request that NUM randomly-chosen songs be picked rather than just one.")

	(opts, args) = op.parse_args()

	if not args:
		args.append(music_root)

	_j, _se = os.path.join, os.path.splitext
	choices = []
	for root in args:
		for fldr, dirs, files in os.walk(root):
			choices.extend(_j(fldr, x) for x in files if not _se(x)[1].lower() in BLACKLISTED_EXTS)

	chosen = []
	for i in range(0,opts.wanted_count):
		chosen.append(random.choice(choices))

	command = os.path.expanduser("~/bin/" + (opts.enqueue and 'aq' or 'ap'))
	subprocess.call([command] + chosen)
