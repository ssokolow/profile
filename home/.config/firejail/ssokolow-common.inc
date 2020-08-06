# Stuff common to the vast majority of thing I want to run in Firejail
blacklist ${HOME}/.lastpass
blacklist ${HOME}/.keepassx
blacklist ${HOME}/.password-store
blacklist ${HOME}/.wine

caps.drop all
nogroups
noroot
protocol unix,inet,inet6,netlink

# Omitted from the common subset:
# - seccomp (prevents Chromium from starting)
# - netfilter (prevents multiplayer game hosting)
# - private-tmp (prevents SDL games from starting)
# - blacklist ${HOME}/.pki/nssdb (probably needed by browsers)
# - protocol omitting netlink (needed by at least Unity)

# Common case, so `noblacklist` can be easily used to fall back to more
# granular blacklisting

# If I were running a Firejail newer than what comes with a 2016 Kubuntu LTS,
# I should be able to use whitelist more thoroughly.
#
# NOTE: `blacklist` lines for /srv and /mnt are hierarchically redundant so
#       that `noblacklist` in application profiles can be used in a manner
#       analogous to `whitelist`.
blacklist /srv
blacklist /srv/backups
blacklist /srv/Burned
blacklist /srv/Burned_todo
blacklist /srv/DVD-bound
blacklist /srv/fservroot
blacklist /srv/inbound
blacklist /srv/lost+found
blacklist /cdrom
blacklist /lost+found
blacklist /media
blacklist /mnt
blacklist /mnt/buffalo_ext
blacklist /mnt/floppy
blacklist /mnt/incoming
blacklist /mnt/red6
blacklist /mnt/red6/backups
blacklist /mnt/red6/buffalo_ext
blacklist /mnt/red6/games
blacklist /mnt/red6/games_todo
blacklist /mnt/red6/home_ssokolow
blacklist /mnt/red6/incoming
blacklist /mnt/red6/incoming_new
blacklist /mnt/red6/lost+found
blacklist /mnt/red6/srv
blacklist /mnt/red6/stuff_to_prune
blacklist /mnt/red6/stuff_to_read
blacklist /mnt/red6/stuff_to_watch
blacklist /mnt/red6/user_opt
blacklist /mnt/red6/VirtualBox
blacklist /mnt/tmp
blacklist /opt
blacklist /root
blacklist /snap
blacklist /user_opt
blacklist /var/backups
blacklist /var/crash
blacklist /var/games
blacklist /var/mail
blacklist /var/metrics
blacklist /var/snap
blacklist /var/www

blacklist /initrd.img
blacklist /initrd.img.old
blacklist /vmlinuz
blacklist /vmlinuz.old

# vim: set ft=conf :
