# !/bin/sh
# Simple replacement for the Ubuntu update notifier because I'm stubborn and
# refuse to bow to removal of configuration keys
#
# Copyright (C) 2014 Stephan Sokolow (deitarion/SSokolow)
#
# License: MIT (http://opensource.org/licenses/MIT)

APT_COMMAND="/usr/bin/apt-get dist-upgrade"
ICON_PATH=~/.local/share/icons/elementary/apps/16/update-notifier.svg

# Used so this script can execute its second half within urxvt
if [ "$1" = "--run-apt" ]; then
    # shellcheck disable=SC2086
    if ! sudo $APT_COMMAND; then
        echo "Exited with non-success!"
        read
    fi
    exit
fi

UPGRADES=$($APT_COMMAND -s -q -y --allow-unauthenticated | \
    /bin/grep '^Inst' | \
    /bin/sed 's@Inst \(\S*\) \(\[\(\S*\)\]\)\?[ ]\?(\(\S*\) .*@"\1" "\3" "\4"@g'  | \
    /usr/bin/sort)

if [ -z "$UPGRADES" ]; then
    exit
fi

if ! echo "$UPGRADES" | xargs zenity --list \
        --title="Updated packages available" \
        --window-icon="$ICON_PATH" \
        --text="The following packages have updates available:" \
        --column "Name" \
        --column "Current" \
        --column "Available" \
        --cancel-label="Remind Me Later" \
        --ok-label="Upgrade Now"; then
    exit
fi

exec urxvt -e "$0" --run-apt
