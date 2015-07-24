#!/bin/sh

if [ "$1" = "-1" ]; then
    if [ "$(qdbus org.kde.KWin /KWin org.kde.KWin.currentDesktop)" = 1 ]; then
        qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 4
    else
        qdbus org.kde.KWin /KWin org.kde.KWin.previousDesktop
    fi
elif [ "$1" = "+1" ]; then
    if [ "$(qdbus org.kde.KWin /KWin org.kde.KWin.currentDesktop)" = 4 ]; then
        qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop 1
    else
        qdbus org.kde.KWin /KWin org.kde.KWin.nextDesktop
    fi
else
    qdbus org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop "$1"
fi
