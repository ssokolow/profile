# Unity games need unix and netfilter access or they'll fail to start
# (Observed with Race The Sun and Tumblestone)
protocol unix,inet,inet6,netlink

# Turn on the standard set of protections I use for all games
include ${HOME}/.config/firejail/game-common.inc

# vim: set ft=conf :
