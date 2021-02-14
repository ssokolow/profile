#!/bin/sh
# Workaround for GTK+ 3.x bug
# Source:
#   https://bugs.launchpad.net/ubuntu/+source/gtk+3.0/+bug/1240957
#   https://bugs.kde.org/show_bug.cgi?id=348270
export GDK_CORE_DEVICE_EVENTS=1
