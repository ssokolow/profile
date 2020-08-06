# Use something a game could conceivably want to put us in whitelist mode
whitelist ~/.asoundrc
read-only ~/.asoundrc

# turn on the standard set of protections like "noroot", "seccomp",
# and "caps.drop all"
seccomp
blacklist ${HOME}/.pki/nssdb

# If I were running a Firejail newer than what comes with a 2016 Kubuntu LTS,
# I should be able to just whitelist the game install directory like I
# did the save directory rather than having to trim away my non-standard,
# non-read-only additions outside $HOME
noblacklist /mnt
noblacklist /mnt/red6
noblacklist /mnt/red6/games

include ${HOME}/.config/firejail/ssokolow-common.inc

# vim: set ft=conf :
