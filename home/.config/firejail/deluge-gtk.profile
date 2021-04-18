# deluge profile
blacklist ${HOME}/.pki/nssdb
seccomp

# Deluge has no need for netlink
protocol unix,inet,inet6

whitelist ${HOME}/.config/deluge

# Deluge is written in Python
noblacklist /usr/bin/python*

# Allow access to the places I may want to save downloads to
whitelist ${HOME}/Documents/4570376/Unsaved
noblacklist /mnt
noblacklist /mnt/incoming
noblacklist /mnt/red6
noblacklist /mnt/red6/incoming_new

netfilter
include /etc/firejail/whitelist-common.inc
include /home/ssokolow/.config/firejail/ssokolow-common.inc
