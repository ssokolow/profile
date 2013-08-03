#!/bin/sh
# Source: http://cemerick.com/2009/09/28/working-with-git-submodules-recursively/

case "$1" in
        "init") CMD="submodule update --init" ;;
        *) CMD="$*" ;;
esac

git $CMD
git submodule foreach "$0" $CMD
