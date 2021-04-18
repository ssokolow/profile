#!/bin/sh
# Setup for comfortable use of an old two-button Logitech Marble Mouse
# via a cheap USB-PS/2 adapter.
#
# Resulting functionality:
# 1. Pointer acceleration is tweaked to be usable on a three-monitor spread
# 2. Press and hold left button for 300ms to get right-click
# 3. Right mouse button is remapped to middle mouse button
# 4. Holding the right button turns the trackball into a scroll wheel
#
# Sources:
# - https://help.ubuntu.com/community/Logitech_Marblemouse_USB
# - https://wiki.archlinux.org/index.php/Mouse_acceleration
# - https://leho.kraav.com/blog/combine-xf86-input-evdev-middle-button-wheel-emulation-kensington-orbit-trackball/

dev="Logitech USB Trackball"  # Logitech Marble Mouse for USB

# Workaround for the USB mouse/keyboard adapter using the same name for both
# devices:
dev="$(xinput | grep "$dev\s*.*pointer" | sed -r 's/.*id=(\S+)\s+.*/\1/')"

# Aliases to keep what follows concise
we="Evdev Wheel Emulation"
tbe="Evdev Third Button Emulation"

# Enable acceleration so it's easy to use a 4480x1080px desktop
# (Start moving 10 times faster after we hit 6px per 10ms movement speed)
xset mouse 10 6

# Remap so middle-click is on left small button
# xinput set-button-map "$dev" 1 8 3 4 5 6 7 2 9 10 11 12 13

# Enable Third Button Emulation so Right-Click is press-hold for more than
# 300ms on the left button while moving less than 2px
xinput set-prop "$dev" "$tbe" 1
xinput set-prop "$dev" "$tbe Timeout" 300
xinput set-prop "$dev" "$tbe Button" 2
xinput set-prop "$dev" "$tbe Threshold" 2

# Enable Wheel Emulation on the right button and make it a bit less sensitive
# so it can be comfortably used with things like tab-switching which expect
# detent-by-detent precision
xinput set-prop "$dev" "$we" 1
xinput set-prop "$dev" "$we Button" 3
xinput set-prop "$dev" "$we Inertia" 25
xinput set-prop "$dev" "$we Axes" 6 7 4 5
