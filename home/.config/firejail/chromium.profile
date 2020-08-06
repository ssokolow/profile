noblacklist ${HOME}/.config/chromium
whitelist ${HOME}/.config/chromium
whitelist ${HOME}/.cache/chromium

# chromium is distributed with a perl script on Arch
noblacklist /usr/bin/perl
noblacklist /usr/bin/cpan*
noblacklist /usr/share/perl*
noblacklist /usr/lib/perl*

# Allow access to the places I may want to save downloads to
whitelist ${HOME}/Documents/Fanfiction
whitelist ${HOME}/Documents/4570376/Unsaved
noblacklist /srv
noblacklist /srv/DVD-bound
noblacklist /mnt
noblacklist /mnt/red6
noblacklist /mnt/red6/incoming_new

netfilter
include /etc/firejail/whitelist-common.inc
include /home/ssokolow/.config/firejail/ssokolow-common.inc
