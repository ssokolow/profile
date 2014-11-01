#!/bin/bash
# PrintScr-to-file confirmation wrapper for urxvt
# Copyright 2014, Stephan Sokolow (deitarion/SSokolow)
#
# Released under the MIT license
# http://opensource.org/licenses/MIT

if zenity --question --title "URxvt PrintScr"; then
    TGT="$(TMPDIR=$HOME mktemp urxvt.XXXXXX.txt)";
    cat > "$TGT";
    xdg-open "$TGT"
fi
