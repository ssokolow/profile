# Unity games need unix and netfilter access or they'll fail to start
# (Observed with Race The Sun and Tumblestone)
protocol unix,netlink

# Turn on the standard set of protections I use for all games
include ${HOME}/.config/firejail/game-common.inc

# Deny network access to single-player games
net none

# vim: set ft=conf :
