# {{{ Quick Reference:
#
# cd +/-n            Change to a different directory in the pushd/popd stack
#
# Ctrl-<Left/Right>  Move word-by-word
# Ctrl-<Up/Down>     Cycle history entries matching typed prefix
# Ctrl-<BkSpc/Del>   Delete word-by-word (path components count)
# Alt-<BkSpc/Del>    Alternate binding for word-by-word delete
#
# History:
#  Ctrl-S  Incremental history search (forward)
#  Ctrl-R  Incremental history search (backward)
#
# Kill Buffer:
#  Ctrl-W  Cut previous word
#  Ctrl-Y  Paste
#
# Useful expansions:
#  !!       Previous line
#    !!:0          Command from the previous line
#    !!:1          First argument on the previous line
#    !!$           Last  argument on the previous line
#    !!:s/foo/bar  Previous command with all "foo" turned into "bar"
#  !#       Current line
#    !#$           Last word on the current line
#  --------------------------------------------
#  mv SomeReallyLongFilename !#$:s/Really/Quite
#
# }}}

# Source all environment settings common to both zsh and bash and don't let
# /etc/zsh/zprofile override env (Don't run it twice like `. .zshenv` would be)
# See: https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
source ~/.common_sh_init/env

# zsh-internal equivalent to "export SHELL=`which zsh`"
# So things like 'exec zsh' work as I intend.
export SHELL==zsh

# Not sure if I need this, but it can't hurt. Fix for rcp and scp.
# See the copy in .bashrc for a full explanation of its purpose
if [[ $- != *i* ]]; then
	return
fi

# {{{ fortune command

# I prefer to have a fortune from any new shell, not just login ones.
# (And displaying it this early helps to hide time spent waiting on the disk
#  to build the complietion cache)
if command -v fortune >/dev/null; then
    fortune
fi

#}}}

# Set up the on-action arrays for use
typeset -ga preexec_functions
typeset -ga precmd_functions
typeset -ga chpwd_functions

autoload -U zrecompile # Generate and cache compiled versions of initscripts
autoload -U run-help   # Enable Meta-H (Alt/Esc-h/H) to read the manpage for the current partially typed command

# {{{ Load Definitions Shared With Bash:

# Pull in the stuff common to both bash and zsh
source ~/.common_sh_init/aliases
source ~/.common_sh_init/misc

# Make sure there are no duplicate entries in PATH or PYTHONPATH
typeset -U PATH PYTHONPATH

# }}}
# {{{ Completion:
# Note: Must come after common_sh_init defines LS_COLORS

# Resolve any symlinks in ~/.zsh/functions and prepend the result to fpath
fpath=(~/.zsh/functions(:A) $fpath)
#TODO: Figure out why this isn't causing my _wine completion to load

# Enable completion (case-insensitive, colorized, and tricked-out)
# TODO: Figure out how to get manual completion dumps to get along with a
#       custom fpath and then use `compinit -C` to shave off some startup time
autoload -U compinit promptinit
compinit
promptinit
source ~/.zshrc.d/prompt_gentoo_setup
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Match lowercase letters case-insensitively but not uppercase ones

# Speed up completions by reducing the fuzziness of the matching
zstyle ':completion:*' accept-exact '*(N)'
# TODO: Forget fuzziness. It's too much hassle and too slow sometimes.

# Colorize completions (Note: Must come after common_sh_init defines LS_COLORS)
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Show arrow-navigable completions and, for "kill", do it even when unambiguous
# (https://bbs.archlinux.org/viewtopic.php?pid=987587#p987587)
zstyle ':completion:*' menu yes select
# TODO: Figure out how to get insert-unambiguous on the first keypress and menu
# on the second.
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' verbose yes
# TODO: Use accept-and-menu-complete (or, if that doesn't work, try
#       accept-and-infer-next-history) to set up a keybind for accepting the
#       selected completion and then triggering more completion (like "descend
#       into directory" in vim's wildmenu)

# Group completions by different object types for big result sets (eg. rsync)
zstyle ':completion:*:descriptions' format '%B%F{green}%d%f%b'
zstyle ':completion:*' group-name ''

# Set up some comfy completion exemptions
zstyle ':completion:*:functions' ignored-patterns '_*'                     # hide completion functions from the completer
zstyle ':completion:*:cd:*' ignored-patterns '(*/)#lost+found'             # hide the lost+found directory from cd
zstyle ':completion:*:(cp|mv|rm|kill|diff|scp):*' ignore-line yes          # commands like rm don't want the same completion multiple times
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~' # don't complete backup files as executables

# Exclude bytecode and temporary files from filename completion.
zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?.pyc' '*?.pyo' '*?.class' '*?~' '*?.bak'
# TODO: Make this work
# Exclude bytecode and temporary files from completion for everything except rm.
#zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.pyc' '*?.pyo' '*?~' '*?.bak'

# Complete PIDs and process names to any process owned by my user
# (Use "cut" as a workaround for kdeinit4 argv[0])
zstyle ':completion:*:processes' command 'ps x'     # Complete PIDs any process owned by my user
zstyle ':completion:*:processes-names' command 'ps x -o command | cut -d: -f1'

# Opt ssh and rsync out of /etc/hosts so my ad-blocking doesn't flood out
# useful completions (https://gist.github.com/4000350)
local _hosts
_hosts=(${${${(M)${(f)"$(<~/.ssh/config)"}:#Host*}#Host }:#*\**})
zstyle ':completion:*' hosts $_hosts

# Only complete users to non-system accounts (https://gist.github.com/4000615)
# Note: Only gives "root" on OSX because "getent passwd" returns an empty list
#       (Need to parse 'dscacheutil -q user' there, which has another format)
local _users
_users=(root)
getent passwd | while IFS=: read name passwd uid rest; do
    if [[ $uid = <1000-> ]]; then
        _users=($_users $name)
    fi
done
zstyle ':completion:*' users $_users

#TODO: Identify which "Shell Options" control completion and belong here instead
#TODO: Can I set up a keybind which means "If we're not already in an {a,b,c}
#      group, then move back to the nearest /, insert {, return, and add a ','"?
#TODO: Maybe I should further subdivide this section.

# }}}
# {{{ Keybindings:

# Use EMACS-style keybindings despite my having EDITOR set to vim
bindkey -e

# Make Home/End/Ins/Del work explicitly
bindkey '\e[1~'   beginning-of-line  # Linux console, PuTTY
bindkey '\e[7'    beginning-of-line  # urxvt
bindkey '\e[H'    beginning-of-line  # xterm
bindkey '\eOH'    beginning-of-line  # gnome-terminal
bindkey '\e[2~'   overwrite-mode     # Linux console, xterm, gnome-terminal, urxvt
bindkey '\e[3~'   delete-char        # Linux console, xterm, gnome-terminal, urxvt
bindkey '\e[4~'   end-of-line        # Linux console, PuTTY
bindkey '\e[8'    end-of-line        # urxvt
bindkey '\e[F'    end-of-line        # xterm
bindkey '\eOF'    end-of-line        # gnome-terminal
bindkey '\eOw'    end-of-line        # PuTTy in rxvt mode

# Make word-by-word movement work for Ctrl+Left/Right/Backspace/Delete/Tab
# TODO: Look into making an argument-by-argument delete
bindkey "\eOc"    forward-word  # urxvt
bindkey "\e[1;5C" forward-word  # everything else
bindkey "\eOd"    backward-word # urxvt
bindkey "\e[1;5D" backward-word # everything else
bindkey "\e[3\^"  kill-word # urxvt
bindkey "\e[3;5~" kill-word # everything else
bindkey "\e[Z"    reverse-menu-complete # urxvt
bindkey "\er"     reverse-menu-complete # everything else


# Set up Alt-Del to match Alt-Backspace if I'm ever stuck on VTE.
bindkey "\e[3;3~" kill-word

# Adjust WORDCHARS so word-by-word basically means "until a space or slash"
WORDCHARS='*?+_-.[]~=&;!#$%^(){}<>:@,\\'

# Rebind Up/Down arrows to get what I like about bash's cmdhist option
# (ensure that 3 keypresses will move 3 commands up/down the history)
bindkey "^[OA" up-history
bindkey "^[OB" down-history
bindkey "^[[A" up-history
bindkey "^[[B" down-history

# The rest of the stuff from my .inputrc
bindkey "\eOa"   history-beginning-search-backward  # urxvt
bindkey "\e[1;5A" history-beginning-search-backward # everything else
bindkey "\eOb"   history-beginning-search-forward   # urxvt
bindkey "\e[1;5B" history-beginning-search-forward  # everything else
bindkey "\e[3~"   delete-char
bindkey '^r'      history-incremental-search-backward
bindkey ' '       magic-space

# }}}
# {{{ History:

# Make history work
setopt HIST_FCNTL_LOCK 2>/dev/null
setopt HIST_ALLOW_CLOBBER
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE # Easy way to omit things from history
setopt APPEND_HISTORY # Default, but let's be sure
setopt INC_APPEND_HISTORY SHARE_HISTORY

HISTFILE=$HOME/.zhistory
HISTSIZE=1100
SAVEHIST=1000

# }}}
# {{{ Shell Options: (TODO: Split out into more appropriate places)

# Set shopts which bash doesn't support
setopt MULTIBYTE
setopt AUTO_PUSHD
setopt PUSHD_SILENT
setopt NUMERIC_GLOB_SORT
setopt LIST_PACKED
setopt SHORT_LOOPS
setopt AUTO_RESUME

# Set shopts equivalent to stuff in my .bashrc
setopt nolistambiguous autolist
setopt NOTIFY # Default, but just in case
setopt INTERACTIVE_COMMENTS
setopt NO_BG_NICE
setopt NOHUP
setopt AUTO_CONTINUE
setopt NO_NOMATCH

# }}}
# {{{ File Extension Associations
# Note: Must be after common_sh_init for EDITOR, IMAGE_MANAGER, and MUSIC_PLAYER

setopt AUTO_CD
alias -s {chm,CHM}=xdg-open
alias -s {pdf,PDF,ps,djvu,DjVu}=xdg-open
alias -s {pdf,PDF,ps,djvu,DjVu}=xdg-open
alias -s {rar,Rar,RAR,zip,Zip,ZIP}=xdg-open
alias -s {php,css,js,htm,html}="$EDITOR"
alias -s {jpeg,jpg,JPEG,JPG,png,gif,xpm}="$IMAGE_VIEWER"
alias -s {avi,AVI,Avi,divx,DivX,mkv,mpg,mpeg,wmv,WMV,mov,rm,flv,ogm,ogv,mp4}=mplayer
alias -s {aac,ape,au,hsc,flac,gbs,gym,it,lds,ogg,m4a,mod,mp2,mp3,MP3,Mp3,mpc,nsf,nsfe,psf,sid,spc,stm,s3m,vgm,vgz,wav,wma,wv,xm}="$MUSIC_PLAYER"
# TODO: Is there any way to set up xdg-open as a default?
# TODO: Find a way to make these suffix aliases case-insensitive.

# }}}
# {{{ HardStatus

# Set up a hardstatus line like I had in bash
function title {
	if [[ $TERM == "screen" ]]; then
		# Use these two for GNU Screen:
		if [[ "$1" == "zsh" ]]; then
			if [[ "$PWD" == "$HOME" ]]; then
				print -nR $'\033k'~/$'\033'\\
			else
				print -nR $'\033k'${PWD##*/}/$'\033'\\
			fi
		else
			print -nR $'\033k'$1$'\033'\\
		fi

		print -nR $'\033]0;'$1: $2$'\a'
	elif [[ $TERM == "xterm" || $TERM == "rxvt" ]]; then
		# Use this one instead for XTerms:
		print -nR $'\033]0;'$*$'\a'
	fi
}

function zsh_hardstatus_precmd {
	title zsh "$PWD"
}
precmd_functions+='zsh_hardstatus_precmd'

function zsh_hardstatus_preexec {
	emulate -L zsh
	local -a cmd; cmd=(${(z)1})

	# Construct a command that will output the desired job number.
	case $cmd[1] in
		fg)
			if (( $#cmd == 1 )); then
				# No arguments, must find the current job
				cmd=(builtin jobs -l %+)
			else
				# Replace the command name, ignore extra args.
				cmd=(builtin jobs -l ${(Q)cmd[2]})
			fi;;
		%*) cmd=(builtin jobs -l ${(Q)cmd[1]});; # Same as "else" above
		exec) shift cmd;& # If the command is 'exec', drop that, because
			# we'd rather just see the command that is being
			# exec'd. Note the ;& to fall through.
		*)  title $cmd[1]:t "$cmd[2,-1]:Q"    # Not resuming a job,
			return;;                        # so we're all done
			# Modified from http://zshwiki.org/home/examples/hardstatus so it
			# displays more naturally for humans. (strips escaping)
	esac

	local -A jt; jt=(${(kv)jobtexts})       # Copy jobtexts for subshell

	# Run the command, read its output, and look up the jobtext.
	# Could parse $rest here, but $jobtexts (via $jt) is easier.
	$cmd >>(read num rest
	        cmd=(${(z)${(e):-\$jt$num}})
	        title $cmd[1]:t "$cmd[2,-1]") 2>/dev/null
}
preexec_functions+='zsh_hardstatus_preexec'

# TODO: Look into offloading this into a different file with autoload.
# Set up a nice little function to encourage use of sudoedit
function sudo() {
	case "${1##*/}" in
		(${EDITOR##*/}|vim|emacs|nano|pico)
			shift
			print -z sudoedit "$@"
			;;
		(*)
			command sudo "$@"
		;;
	esac
}

# }}}
#{{{ url-encode
# Source:
# http://stackoverflow.com/questions/171563/whats-in-your-zshrc/187853#187853

# URL encode something and print it.
function url-encode; {
    setopt extendedglob
    echo "${${(j: :)@}//(#b)(?)/%$[[##16]##${match[1]}]}"
}

#}}}
#{{{ Deferred heavy stuff

# TODO: See if I can make this lighter without losing cdr<Tab>
setopt hashcmds hashdirs hashlistall

#}}}
# vim:fdm=marker
