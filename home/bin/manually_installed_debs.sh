#!/bin/sh

if type aptitude 1>/dev/null 2>&1; then
    echo "Packages with no repository source (eg. manually-installed .debs):"
    aptitude search ~o
else
    echo "ERROR: This script requires aptitude to be installed."
fi
