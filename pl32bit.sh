#!/bin/bash
# Author: Michael Ambrus (michael.ambrus@sonyericsson.com)
# 2011-05-27
# Print only lines that have hexdata that seems like 32bit

if [ -z $PL32BIT ]; then

PL32BIT="pl32bit.sh"

function pl32bit() {
	cat "${1}" | egrep '0x[[:xdigit:]]{8}($|[^[:xdigit:]])'
}

source s3.ebasename.sh
if [ "$PL32BIT" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.
	tty -s; ATTY="$?"
	ISATTY="$ATTY -eq 0"

	set -e
	set -u

	if [ ! $ISATTY ]; then
		#This is an piped input
		FILENAME="--"
	else
		if [ $# -ne 0 ]; then
			FILENAME="${1}"
		else
			echo "Syntax error: $PL32BIT [FILE] start [stop]" >&2
			exit 1
		fi
		if [ ! -f $FILENAME ]; then
			echo "Error: file not found [$FILENAME]" >&2
			exit 1
		fi

	fi

	pl32bit "$FILENAME" "$@"
	exit $?
fi

fi

