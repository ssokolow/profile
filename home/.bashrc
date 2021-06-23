# This file originated in the Gentoo /etc/skel version but has been heavily
# modified.

# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.

# Test for an interactive or root shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases. (And I guard against sudo -s being too
# clever for its own good)
if [[ $- != *i* ]] || [ "$(id -u)" -eq 0 ]; then
    # Shell is non-interactive.  Be done now
    return
fi

# -- A copy of how Ubuntu does the above... just in case I need it. --
# If not running interactively, don't do anything
#[ -z "$PS1" ] && return

# Support for figuring out how my .bashrc ran
function do_debug() { export BASHRC_DEBUG="$BASHRC_DEBUG"$'\n'"${BASHRC_DEBUG_INDENT}$@"; }

## Let's make use of screen for increased efficiency.
## DISABLED: I'll just let Yakuake/yeahconsole/Tilda/etc. do this so I can have
##           a reliable non-screen shell for embedded terminals
#if [[ "$STY" == "" ]] && [ "$NO_SCREEN" == "" ]; then
#	do_debug "	    -- Calling screen subshell --"
#	export BASHRC_DEBUG_INDENT="		"
#		read -t 1 -p "Calling screen... (Press enter to cancel)" || exec screen -RR
#	unset BASHRC_DEBUG_INDENT
#else
#	do_debug "	    -- Already running inside screen --"
#fi

# --== Begin Ubuntu stuff not yet integrated ==--
# TODO: Finish integrating this.

# set variable identifying the chroot you work in (used in the prompt below)
#if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
#    debian_chroot=$(cat /etc/debian_chroot)
#fi

# set a fancy prompt (non-color, unless we know we "want" color)
#case "$TERM" in
#xterm-color)
#    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#    ;;
#*)
#    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
#    ;;
#esac

# Comment in the above and uncomment this below for a color prompt
#PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# --== End Ubuntu stuff not yet integrated ==--

# Change the window title of X terminals (Customized from the Gentoo version)
case $TERM in
    xterm* | rxvt | Eterm | eterm)
        PROMPT_COMMAND='echo -ne "\033]0;bash: ${PWD/$HOME/~}\007"'
        ;;
    screen)
        PROMPT_COMMAND='echo -ne "\033k"bash$"\033"\\; echo -ne "\033_${PWD/$HOME/~}\033\\"'
        #PROMPT_COMMAND='echo -ne "\033_bash: ${PWD/$HOME/~} - Window: $WINDOW\033\\"'
        ;;
esac

# uncomment the following to activate bash-completion:
#[ -f /etc/profile.d/bash-completion ] && source /etc/profile.d/bash-completion
# (Too slow-loading for me)
source ~/.bash_completion

# Configure the shell the way I like it
shopt -s cdspell      # Enable typo correction for the cd command.
shopt -s checkwinsize # Make sure bash keeps the LINES and COLUMNS current as the term resizes.
shopt -s extglob      # Enable more regex-like shell glob support
set -b                # Make status messages about terminated background jobs appear immediately

# Set up comfortable history management.
export CDPATH=".:~"
export HISTFILESIZE=1000                              # Default is 500 lines
export HISTIGNORE="&"                                 # Example: export HISTIGNORE="&:ls:ls *:mutt:[bf]g:exit"
export HISTCONTROL="ignoredups:ignorespace:erasedups" # Make sure a command only appears in the list once.
export PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"
shopt -s cmdhist    # Ensure multi-line commands are single-line history entries
shopt -s histappend # Append command history, don't overwrite

# Pull in the stuff common to both bash and zsh
source ~/.common_sh_init/env
source ~/.common_sh_init/aliases
source ~/.common_sh_init/misc

# Run fortune for maximum wittiness
if command -v fortune >/dev/null; then
    fortune
fi

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

bash_virtualenv_prompt() {
    # If not in a virtualenv, print nothing
    [[ "$VIRTUAL_ENV" == "" ]] && return

    # Support both ~/.virtualenvs/<name> and <name>/venv
    local venv_name="${VIRTUAL_ENV##*/}"
    if [[ "$venv_name" == "venv" ]]; then
        venv_name=${VIRTUAL_ENV%/*}
        venv_name=${venv_name##*/}
    fi

    # Distinguish between the shell where the virtualenv was activated and its
    # children
    if typeset -f deactivate >/dev/null; then
        echo "[${venv_name}] "
    else
        echo "<${venv_name}> "
    fi
}

# Display a "we are in a virtualenv" indicator that works in child shells too
export VIRTUAL_ENV_DISABLE_PROMPT=1
PS1='$(bash_virtualenv_prompt)'"$PS1"
