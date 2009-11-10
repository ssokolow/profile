# This file originated in the Gentoo /etc/skel version but is simple enough to
# have been something I could have easily come up with on my own.

# If this isn't an interactive shell, connect to any existing global ssh-agent and gpg-agent sessions now
if [[ $- != *i* ]]; then
	eval `/usr/bin/keychain --eval --quick --noask 2> /dev/null`
fi

#This file is sourced by bash when you log in interactively.
[ -f ~/.bashrc ] && . ~/.bashrc
