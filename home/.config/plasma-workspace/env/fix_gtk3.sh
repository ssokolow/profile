#!/bin/sh
# Workaround for GTK+ 3.x bug
# Source:
#   https://bugs.launchpad.net/ubuntu/+source/gtk+3.0/+bug/1240957
#   https://bugs.kde.org/show_bug.cgi?id=348270
export GDK_CORE_DEVICE_EVENTS=1

# Yes, I'm very sure that I want gtk3-nocsd to take effect
export GTK_CSD=0

# No overlay scrolling, please. Having a scroll handle just float over content
# looks tacky and ugly without going full swipe-to-scroll Android/iOS UI.
export GTK_OVERLAY_SCROLLING=0

# Ask for non-Flatpak'd GTK apps to also use featureful file choosers, please
export GTK_USE_PORTAL=1
