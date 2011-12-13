# If this isn't an interactive shell, silently connect to any existing global
# ssh-agent and gpg-agent sessions now
if [[ $- != *i* ]]; then
	GA_PID=${GPG_AGENT_INFO#*:}
	GA_PID=${GA_PID%:*}

	(`kill -0 "$SSH_AGENT_PID"` && kill -0 "$GA_PID") &> /dev/null ||
		eval `/usr/bin/keychain --eval --quick --noask --quiet 2> /dev/null`

	unset GA_PID
fi

## Load up screen if it's not already present
## DISABLED: I'll just let Yakuake/yeahconsole/Tilda/etc. do this so I can have
##           a reliable non-screen shell for embedded terminals
#if [[ $STY = '' ]] && [ "$NO_SCREEN" = "" ]; then
#    screen -RR
#	read -t 5 "?Press Enter to continue without GNU Screen" || exit
#	clear
#fi
