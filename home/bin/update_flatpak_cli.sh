#!/bin/sh
# Flatpak CLI Shortcut Proof of Concept
# Copyright 2021 Stephan Sokolow (deitarion/SSokolow)
#
# License: MIT
#
# Known shortcomings in this quick and dirty PoC:
# * In order to support non-local URL arguments to Flatpak'd browsers, use of
#   --file-forwarding assumes all installed programs will accept file:// URLs.
#   (A proper solution would parse the .desktop files to identify what kinds of
#   arguments the commands want.)
# * Assumes command name collisions will never happen
#   (A proper implementation would need to prompt the user to resolve conflicts
#   if encountered.)
# * Just uses `grep command= | cut -d= -f2` to "parse" the INI-style output
#   of `flatpak info -m`
#   (A proper implementation needs to make sure it's from the right section of
#   the file to ensure there's no risk of multiple lines matching.)
# * Uses the sledgehammer approach of just removing all non-folders from the
#   target directory before generating new launchers to clear out stale entries.
#   (A proper solution would keep track of which ones it created)
# * No means of overriding Flatseal's decision to use
#   "com.github.tchx84.Flatseal" as its internal binary name rather than
#   "flatseal"
# * Doesn't solve the problem of flatpaks still not installing manpages

# Add this to the end of your $PATH
BIN_DIR=~/.local/bin/flatpak

# Remove any stale launch scripts
rm -f "$BIN_DIR"/*
mkdir -p "$BIN_DIR"

for X in $(flatpak list --columns=ref); do
    echo "Updating $X..."
    app_command="$(flatpak info -m "$X" | grep command= | cut -d= -f2)"
    cmd_path="$BIN_DIR"/"$app_command"

    if [ -n "$app_command" ]; then
        # Unset LD_PRELOAD to silence gtk-nocsd errors and support file
        # forwarding so you can sandbox browsers and still open local files
        printf '#!/bin/sh\nunset LD_PRELOAD\nexec flatpak run --file-forwarding "%s" @@u "$@" @@' "$X" >"$cmd_path"
        chmod +x "$cmd_path"
    fi
done
