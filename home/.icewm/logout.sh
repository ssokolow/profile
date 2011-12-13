#!/bin/sh

cat ~/.icewm/synergy_ssh.pid | xargs kill
killall icewm-session
