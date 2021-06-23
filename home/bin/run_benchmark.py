#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A simple helper to set up and then tear down benchmarking conditions
for a specified command.

Currently, it...

1. Sets the CPU governor to `performance`
2. Clears disk caches on multiple levels
3. Runs the given command
4. Resets the CPU governor to `ondemand`
5. Plays a PC Speaker tune to signal success or failure

NOTE: This will invoke `sudo` for changes requiring root privileges.
"""

# Prevent Python 2.x PyLint from complaining if run on this
from __future__ import (absolute_import, division, print_function,
                        with_statement, unicode_literals)

__author__ = "Stephan Sokolow (deitarion/SSokolow)"
__appname__ = "Benchmark Wrapper"
__version__ = "0.1"
__license__ = "MIT"

BENCHMARK_DRIVE = '/dev/sda'
USUAL_CPU_GOVERNOR = 'ondemand'

import sys
from subprocess import call, check_call, CalledProcessError, DEVNULL

def play_tune(tones, length=200):
    for tone in tones:
        call(['beep', '-f', str(tone), '-l', str(length)])

# TODO: Figure out the best way to gather information on cronjobs and the like
#       which may have run in the background during a benchmark run.

try:
    # Enable a CPU governor that should safely maximize frequency stability
    check_call(['sudo', 'cpupower', 'frequency-set', '-g', 'performance'],
        stdout=DEVNULL)

    # Flush the disk caches as thoroughly as reliably possible
    check_call(['sync'])
    check_call(['sudo', 'sysctl', 'vm.drop_caches=3', '-q'])
    check_call(['sudo', 'blockdev', '--flushbufs', BENCHMARK_DRIVE])
    check_call(['sudo', 'hdparm', '-qF', BENCHMARK_DRIVE])
    # TODO: Also read enough unrelated data to evict any caches that don't obey

    # Run the command given as arguments
    check_call(sys.argv[1:])
except CalledProcessError:
    # Play first measure of Dies Irae to signal failure, then re-raise error
    play_tune([175, 165, 175, 147, 165, 131, 147, 147], length=600)
    raise
else:
    # Play a rising sequence to signal success
    play_tune([440, 550, 660, 880])
    play_tune([440, 550, 660, 880] * 4, length=20)
finally:
    # Set the CPU governor back to `ondemand` on completion
    check_call(['sudo', 'cpupower', 'frequency-set', '-g', USUAL_CPU_GOVERNOR],
    stdout=DEVNULL)



# vim: set sw=4 sts=4 expandtab :
