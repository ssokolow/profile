#!/bin/sh

# Edit and kill the program to change bedtime
while true; do
    # Ensure we get the Xfce notification daemon under KDE
    DBUS_SESSION_BUS_ADDRESS='' ~/bin/remind_bedtime
    sleep 1
done
