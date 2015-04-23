#!/bin/bash
POL_BASH_PATH="/usr/share/playonlinux/playonlinux-bash"

# Allow shellcheck to see a recognizable shebang
if [ -e "$POL_BASH_PATH" ]; then
    if [ -z "$PLAYONLINUX" ]; then # Prevent infinite loop
        exec "$POL_BASH_PATH" "$0" "$@"
    fi
else
    echo "Could not find $POL_BASH_PATH"
    exit 1
fi

source "$PLAYONLINUX/lib/sources"

POL_Config_Write NO_DESKTOP_ICON "TRUE"
