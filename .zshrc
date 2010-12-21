# Don't let /etc/zsh/zprofile override my ~/.zshenv
source ${ZDOTDIR:-~}/.zshenv

# So things like 'exec zsh' work as I intend.
export SHELL=`which zsh`

# Not sure if I need this, but it can't hurt. Fix for rcp and scp.
# See the copy in .bashrc for a full explanation of its purpose
if [[ $- != *i* ]]; then
	return
fi

# Set up the on-action arrays for use
typeset -ga preexec_functions
typeset -ga precmd_functions
typeset -ga chpwd_functions

#################
# Misc. Modules #
#################

autoload -U zrecompile # Generate and cache compiled versions of initscripts
autoload -U run-help   # Enable Meta-H (Alt/Esc-h/H) to read the manpage for the current partially typed command

##############
# Completion #
##############

fpath=(~/.zsh/functions $fpath)

# Enable completion (case-insensitive, colorized, and tricked-out)
autoload -U compinit promptinit
compinit -C
promptinit
source ~/.zshrc.d/prompt_gentoo_setup
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:processes' command 'ps x'

# Speed up completions by reducing the fuzziness of the matching
zstyle ':completion:*' accept-exact '*(N)'

# Set up some comfy completion exemptions
zstyle ':completion:*:functions' ignored-patterns '_*'                     # hide completion functions from the completer
zstyle ':completion:*:cd:*' ignored-patterns '(*/)#lost+found'             # hide the lost+found directory from cd
zstyle ':completion:*:(rm|kill|diff|scp):*' ignore-line yes          # commands like rm don't want the same completion multiple times
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~' # don't complete backup files as executables
zstyle ':completion:*:*:*:users' ignored-patterns \
    adm apache bin daemon games gdm halt ident junkbust lp mail mailnull \
    named news nfsnobody nobody nscd ntp operator pcap postgres radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs backup bind  \
    dictd gnats identd irc man messagebus postfix proxy sys www-data \
    avahi clamav ddclient festival freenet haldaemon ldap mysql partimag \
    postmaster sockd timidity asterisk avahi-autoipd buildbot cron firebird \
    hsqldb mythtv nut paludisbuild portage pulse smmsp tor

zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?.pyc' '*?.pyo' '*?~' '*?.bak'
# TODO: Make this work
#zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.pyc' '*?.pyo' '*?~' '*?.bak'

# Recognize completions even if I mistype one character
#zstyle ':completion:*' completer _complete _match _approximate
#zstyle ':completion:*:approximate:*' max-errors 1 numeric
# TODO: Find a way to allow _approximate to add or transpose but not delete

# Set up some pretty verbose formatting for completion
#zstyle ':completion:*:descriptions' format '%B%d%b'
#zstyle ':completion:*' group-name ''
#zstyle ':completion:*' verbose yes
#zstyle ':completion:*:messages' format '%d'
#zstyle ':completion:*:warnings' format 'No matches for: %d'

##########
# Common #
##########

# Pull in the stuff common to both bash and zsh
source ~/.common_sh_init/aliases
source ~/.common_sh_init/misc

# Colorize completions (Has to come after common_sh_init defines LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Make sure there are no duplicate entries in PATH or PYTHONPATH
typeset -U PATH PYTHONPATH

###############
# Keybindings #
###############

# Use EMACS-style keybindings despite my having EDITOR set to vim
bindkey -e

# Make Home/End/Ins/Del work
bindkey '\e[1~'   beginning-of-line  # Linux console, PuTTY
bindkey '\e[H'    beginning-of-line  # xterm
bindkey '\eOH'    beginning-of-line  # gnome-terminal
bindkey '\e[2~'   overwrite-mode     # Linux console, xterm, gnome-terminal
bindkey '\e[3~'   delete-char        # Linux console, xterm, gnome-terminal
bindkey '\e[4~'   end-of-line        # Linux console, PuTTY
bindkey '\e[F'    end-of-line        # xterm
bindkey '\eOF'    end-of-line        # gnome-terminal
bindkey '\eOw'    end-of-line        # PuTTy in rxvt mode

# Make word-by-word movement work for Ctrl+Left/Right
bindkey "\e[1;5C" forward-word
bindkey "\e[1;5D" backward-word

# Rebind Up/Down arrows to get what I like about bash's cmdhist option
# (ensure that 3 keypresses will move 3 commands up/down the history)
bindkey "^[OA" up-history
bindkey "^[OB" down-history
bindkey "^[[A" up-history
bindkey "^[[B" down-history

# The rest of the stuff from my .inputrc
bindkey "\e[1;5A" history-beginning-search-backward
bindkey "\e[1;5B" history-beginning-search-forward
bindkey "\e[3~"   delete-char
bindkey '^r'      history-incremental-search-backward
bindkey ' '       magic-space

###########
# History #
###########

# Make history work
setopt HIST_FCNTL_LOCK 2>/dev/null
setopt HIST_ALLOW_CLOBBER
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt APPEND_HISTORY # Default, but let's be sure
setopt INC_APPEND_HISTORY SHARE_HISTORY

HISTFILE=$HOME/.zhistory
HISTSIZE=1000
SAVEHIST=1000

#################
# Shell Options #
#################

# Set shopts which bash doesn't support
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

# Set up "you know what I mean" handling of raw paths
setopt AUTO_CD
alias -s {pdf,PDF,ps,chm,CHM,djvu,DjVu}=okular
alias -s {php,css,js,htm,html}="$EDITOR"
alias -s {jpeg,jpg,JPEG,JPG,png,gif,xpm}="$IMAGE_VIEWER"
alias -s {avi,AVI,Avi,divx,DivX,mkv,mpg,mpeg,wmv,WMV,mov,rm,flv,ogm,ogv,mp4}=mplayer
alias -s {aac,ape,au,hsc,flac,gbs,gym,it,lds,ogg,m4a,mod,mp2,mp3,MP3,Mp3,mpc,nsf,nsfe,psf,sid,spc,stm,s3m,vgm,vgz,wav,wma,wv,xm}="$MUSIC_PLAYER"
# TODO: Find a way to make these suffix aliases case-insensitive.

##############
# HardStatus #
##############

# Set up a hardstatus line like I had in bash
function title {
	if [[ $TERM == "screen" ]]; then
		# Use these two for GNU Screen:
		print -nR $'\033k'$1$'\033'\\

		print -nR $'\033]0;'$2$'\a'
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

# I prefer to have a fortune from any new shell, not just login ones.
if command -v fortune >/dev/null; then
    fortune
fi
