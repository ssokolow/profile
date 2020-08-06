# ssokolow's .zshrc
#
# {{{ Quick Reference:
#
# cd +/-n            Change to a different directory in the pushd/popd stack
#
# Ctrl-<Left/Right>  Move word-by-word
# Ctrl-<Up/Down>     Cycle history entries matching typed prefix
# Ctrl-<BkSpc/Del>   Delete word-by-word (path components count)
# Alt-<BkSpc/Del>    Alternate binding for word-by-word delete
# Alt-H              Display help for the command just typed
#
# History:
#  Ctrl-S  Incremental history search (forward)
#  Ctrl-R  Incremental history search (backward)
#
# Kill Buffer:
#  Ctrl-W  Cut previous word
#  Ctrl-Y  Paste
#
# Process Substitution:
#   <(command args)     Redirect stdin into an FD pointing at `command args`
#   >(command args)     Redirect stout into an FD pointing at `command args`
#                       (NOTE: Shell will not block like with | redirection)
#   =(command args)     Pipe the output of `command args` to a temporary file
#                       and then insert the path to it where =(...) was used
#                       (Useful for commands which don't like stdin FDs)
#   $(<path)            Pass the contents of `path` as a literal argument value
#
# History Expansion:
#   Syntax:
#    !<event>[:word][:modifier][...]
#
#   Event Designators:
#     #                 Current command
#     ! or -1           Previous command
#     -<n>              <n>th most recent command
#     <str>             Most recent command beginning with <str>
#     ?<str>[?]         Most recent command containing <str>
#                       (Trailing ? required if anything follows)
#
#   Word Designators:
#     0                 Command
#     ^                 First argument
#     $                 Last argument
#     <n>               <n>th argument
#     <n>*              Arguments from <n> through the last
#     <n>-              Arguments from <n> to (but not including) the last
#     <x>-<y>           Arguments <x> through <y>
#     *                 All Arguments
#
#     The : separator may be omitted if <word> begins with for ^, $, *, or -
#     (eg. `!#$`)
#
#   Modifiers:
#     a                 Make path absolute
#     A                 ...and resolve symlinks
#     c                 Find command's absolute path in `PATH`
#     e                 Strip down to just the extension (minus period)
#     h                 Remove path head like `dirname`
#     l                 Convert to lowercase
#     q                 Quote to prevent further substitutions
#     Q                 Remove one level of quoting
#     r                 Remove extension, leaving filename root
#     s/foo/bar[/...]   Replace first occurrence of `foo` with `bar`
#     s/foo/bar/:G      Replace ALL occurrences of `foo` with `bar`
#     gs/foo/bar           "     "       "       "   "     "    "
#     &   or   g&       Shorthand for repeating previous substitution
#     t                 Remove path tail like `basename`
#     u                 Convert to uppercase
#     x                 Like `q` but split at whitespace
#
#     NOTES:
#     - & in the right-hand side of s/.../... will be replaced with the
#       contents of the left-hand side.
#     - ^foo^bar is allowed as shorthand for !!:s^foo^bar
#
#   Other:
#     !{...}            Disambiguate adjacent characters
#     !"                Disable history expansion for this line
#
#   Examples:
#     !vim
#     vim !#$
#     ^vim^emacs
#     mv SomeReallyLongFilename !#$:s/Really/Quite
#
# }}}
# {{{ TODO:
# - Decide how to alias Cd to cd to work around "finger race conditions"
#   ...ideally, in a way which corrects the command I typed and waits for
#   me to press Enter again so I notice and learn from it (but it has to
#   work for `(cd ...;dl ...)` which is the main place it happens.)
# - Improve completions on the comfort front
#   - Look into customizing completion order for /us<Tab> and the like
#     https://stackoverflow.com/questions/15140396/zsh-completion-order
# - Adapt keybinds to use ${terminfo[...]/N
# - Only rebuild the .zcompdump if it's actually necessary.
#   https://gist.github.com/ctechols/ca1035271ad134841284#gistcomment-3002667
# - Try to remove as many of the results of this command as possible:
#   rg '\$\((|eval' ~/.zshrc ~/.zsh/functions ~/.zsh/zshrc.d ~/.common_sh_init
#       ~/.zprofile ~/.zshenv ~/.bash_profile ~/.bashrc
#   (https://htr3n.github.io/2018/07/faster-zsh/#avoiding-creating-subprocesses)
# - Look into ways to performance-optimize my completions further.
#   They're about 90% of the time taken in zsh startup now
# - Consider running romkatv/gitstatus in an async RPS1:
#   - https://github.com/romkatv/gitstatus
#   - https://www.anishathalye.com/2015/02/07/an-asynchronous-shell-prompt/
# - https://github.com/joepvd/zsh-hints
# - https://linuxhandbook.com/linux-shortcuts/
#
# NOTE: Try not to re-introduce any of the following sub-optimalities
# - https://htr3n.github.io/2018/07/faster-zsh/
# - https://www.topbug.net/blog/2016/10/11/speed-test-check-the-existence-of-a-command-in-bash-and-zsh/
# - Using `print` or `echo` instead of `printf` in situations where tests show
#   `printf` is both faster *and* more readable.
# - Once I've got an RGB terminal, try `zsh/nearcolor` as a fallback as
#   described at  https://wiki.archlinux.org/index.php/Zsh#Colors
# }}}

# {{{ Note the start time to detect slow starts due to disk contention

# (Use a prompt expansion modifier `(%s)` on a defaulting variable substitution
#  `:-` that contains a default but no variable so it can access `strftime`
#  without invoking a subshell to call `print -P`.)
local start_time="${(%):-"%D{%s}"}"

# }}}
# {{{ Options for profiling startup time

# Use zsh's high-level profiler
# (Run `zprof | less` after startup completes)
#zmodload zsh/zprof

# Generate more detailed xtrace script to further investigate startup time
# See https://github.com/raboof/zshprof for KCachegrind adapter
MAKE_XTRACE_DUMP=0
if [ "${MAKE_XTRACE_DUMP:-0}" = 1 ]; then
    local xtrace_path=/tmp/zshstart.$$.log
    PS4=$'\\\011%D{%s%6.}\011%x\011%I\011%N\011%e\011'
    exec 3>&2 2>$xtrace_path
    setopt xtrace prompt_subst
fi

# }}}
# {{{ Source all environment settings common to both zsh and bash
# ...and don't let /etc/zsh/zprofile override env
# (Don't run it twice like `. .zshenv` would be)
# See: https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
source ~/.common_sh_init/env

# zsh-internal equivalent to "export SHELL=`which zsh`"
# So things like 'exec zsh' work as I intend.
export SHELL==zsh

# Not sure if I need this, but it can't hurt. Fix for rcp, scp, and sudo -s.
# See the copy in .bashrc for a full explanation of its purpose
if [[ $- != *i* ]] || [[ "$EUID" -eq 0 ]] ; then
        return
fi
# }}}
# {{{ Load Definitions Shared With Bash:

# Pull in the stuff common to both bash and zsh
source ~/.common_sh_init/aliases
source ~/.common_sh_init/misc

# Make sure there are no duplicate entries in PATH or PYTHONPATH
typeset -U PATH PYTHONPATH

# }}}

# Set up the on-action arrays for use
typeset -ga preexec_functions
typeset -ga precmd_functions
typeset -ga chpwd_functions

autoload -Uz zrecompile # Generate and cache compiled versions of initscripts
autoload -Uz run-help   # Enable Meta-H (Alt/Esc-h/H) to read the manpage for
                        # the current partially typed command

# My own functions
autoload -Uz 457mv audmv setprj sudo url-encode
source ~/.zsh/zshrc.d/help-gnu.zsh
source ~/.zsh/zshrc.d/rg

# {{{ Completion:
# Note: Must come after common_sh_init defines any desired LS_COLORS

# Enable completion (case-insensitive, colorized, and tricked-out)
autoload -Uz compinit

# Only have compinit check the completion cache for staleness once per day
#  https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92
for dump in ~/.zcompdump(N.mh+24); do
  echo "Bringing completions up to date..."
  compinit
  touch "$dump"

  # Compile ~/.zcompdump (Takes compinit from 90% to ~60% of zprof)
  zcompile -U "$dump" &!
  echo "Done."
done

compinit -C

zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Match lowercase letters case-insensitively but not uppercase ones

# Speed up completions by reducing the fuzziness of the matching
zstyle ':completion:*' accept-exact '*(N)'
# TODO: Forget fuzziness. It's too much hassle and too slow sometimes.

# Group completions by different object types for big result sets (eg. rsync)
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%F{green}%d%f%b'

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

# Set up some comfy completion exemptions
zstyle ':completion:*:functions' ignored-patterns '_*'                     # hide completion functions from the completer
zstyle ':completion:*:cd:*' ignored-patterns '(*/)#lost+found'             # hide the lost+found directory from cd
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~' # don't complete backup files as executables

# commands like kill don't want the same completion multiple times
# (Don't add things which take paths to this. It breaks ~/.vim<Tab> → ~/.vim/)
zstyle ':completion:*:(kill|killall|pgrep|pkill):*' ignore-line yes

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

# TODO: Identify which "Shell Options" control completion and move them here
# TODO: Can I set up a keybind which means "If we're not already in an {a,b,c}
#      group, then move back to the nearest /, insert {, return, and add a ','"?
# TODO: Maybe I should further subdivide this section.

# }}}
# {{{ Keybindings:

# Adjust WORDCHARS so word-by-word basically means "until a space, slash,
# period, question mark, semicolon, or ampersand", so wordwise motions in URLs
# and shellscript one-liners is useful.
WORDCHARS='*+_-[]~=!#$%^(){}<>:@,\\'

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
bindkey "\e[3\^"  kill-word # urxvt (old)
bindkey "\e[3;5~" kill-word # everything else
bindkey "\e[Z"    reverse-menu-complete # urxvt
bindkey "\er"     reverse-menu-complete # everything else

# Set up Alt-Del to match Alt-Backspace if I'm ever stuck on VTE.
bindkey "\e[3;3~" kill-word

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
setopt HIST_IGNORE_SPACE # Easy way to omit things from history
setopt APPEND_HISTORY # Default, but let's be sure
setopt HIST_VERIFY # Safety for !<cmd><Tab> and the like
setopt SHARE_HISTORY

# http://www.zsh.org/mla/workers/2013/msg00807.html
setopt NO_HIST_REDUCE_BLANKS # TODO: Keep an eye on when this is fixed

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
alias -s {cbr,Cbr,CBR,cbz,Cbz,CBZ}=xdg-open
alias -s {rar,Rar,RAR,zip,Zip,ZIP}=xdg-open
alias -s {php,css,js,htm,html}="$EDITOR"
alias -s {jpeg,jpg,JPEG,JPG,png,gif,xpm}="$IMAGE_VIEWER"
alias -s {avi,AVI,Avi,divx,DivX,mkv,mpg,mpeg,wmv,WMV,mov,rm,flv,ogm,ogv,mp4}=mplayer
alias -s {aac,ape,au,hsc,flac,gbs,gym,it,lds,ogg,m4a,mod,mp2,mp3,MP3,Mp3,mpc,nsf,nsfe,psf,sid,spc,stm,s3m,vgm,vgz,wav,wma,wv,xm}="$MUSIC_PLAYER"
# TODO: Is there any way to set up xdg-open as a default?
# TODO: Find a way to make these suffix aliases case-insensitive.

# }}}
# {{{ fortune command

# I prefer to have a fortune from any new shell, not just login ones
# ...but I don't want it further bogging down an already slow start.
local end_time="${(%):-"%D{%s}"}"
if [[ $(( end_time - start_time )) < 2 ]]; then
    # Might as well micro-optimize this. $+commands is up to 10x faster
    # (https://www.topbug.net/blog/2016/10/11/speed-test-check-the-existence-of-a-command-in-bash-and-zsh/)
    if (( $+commands[fortune] )); then
        fortune
    fi
else
    echo "Skipping fortune (slow startup)"
fi

#}}}
# {{{ Allow the VENV_TO_ACTIVATE variable to activate virtualenvwrapper
if [ -n "$VENV_TO_ACTIVATE" ]; then
    workon "$VENV_TO_ACTIVATE"
    unset "$VENV_TO_ACTIVATE"

    if [ -n "$RUN_IN_VENV" ]; then
        $RUN_IN_VENV
    fi
fi
unset "$RUN_IN_VENV"
# }}}
# {{{ Set prompt and hardstatus

# Defer these until as late as possible to avoid running them unnecessarily
source ~/.zsh/zshrc.d/prompt_gentoo_setup
source ~/.zsh/zshrc.d/hardstatus

# }}}
# {{{ Finish gathering profiling data (if enabled)
if [[ "$MAKE_XTRACE_DUMP" = 1 ]]; then
    unsetopt xtrace
    exec 2>&3 3>&-
    echo "Profiling data saved to $xtrace_path"
    if [ -e ~/bin/log2callgrind ]; then
        ~/bin/log2callgrind < "$xtrace_path" > "$xtrace_path".callgrind
        echo "KCachegrind data saved to $xtrace_path".callgrind
    fi
fi
# }}}

# TODO: Set ~/.zshrc immutable to keep things like RVM and the travis gem from
#       messing it up.
