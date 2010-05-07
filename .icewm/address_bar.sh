#!/bin/bash

#TODO: Rewrite this so that $1 gets split according to shell quoting rules before testing.
if which $1; then
	exec "$@"
elif [ -e "$1" ]; then
	exec pcmanfm "$@"
elif [[ "$1" == http** ]]; then
	exec firefox "$@"
else
	# This won't be necessary once the above TODO is implemented.
	exec "$@"
fi
