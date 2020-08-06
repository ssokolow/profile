# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Source my common environment here for zsh-like behaviour.
. ~/.common_sh_init/env

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi

# Protect against anything which thinks its being clever by appending to
# profile files that `sudo -s`, rcp, and scp might source.
if [ "$(id -u)" -eq 0 ] ; then
    return
fi

# TODO: Figure out if this works better than my solution
#[ -x /usr/bin/screen-launcher ] && /usr/bin/screen-launcher

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
