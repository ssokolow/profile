#!/usr/bin/env python3

import os, subprocess, sys
from difflib import diff_bytes, unified_diff

STORED_PATH = os.path.join(
    os.path.dirname(__file__), os.pardir, 'supplemental', 'crontab_backup')

current = subprocess.check_output(['crontab', '-l']).strip().decode('utf8')
with open(STORED_PATH) as fobj:
    stored = fobj.read().strip()

diff = unified_diff(
    stored.split('\n'),
    current.split('\n'),
    'stored',
    'current')
for line in diff:
    print(line)
