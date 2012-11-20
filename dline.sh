#!/bin/bash
# Author: Michael Ambrus (michael.ambrus@sonyericsson.com)
# 2012-11-20
# Wraps sed's deletion of lines by numbers or regexps

if [ -z $DLINE_SH ]; then

DLINE_SH="dline.sh"

#One address version
function dline_1() {
	cat $1 | sed -e "${2}d"
}

#Two address version
function dline_2() {
	cat $1 | sed -e "${2},${3}d"
}
source s3.ebasename.sh
if [ "$DLINE_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	DLINE_SH_INFO=${DLINE_SH}
	source .futil.ui..dline.sh

	tty -s; ATTY="$?"
	ISATTY="$ATTY -eq 0"

	if [ ! $ISATTY ]; then
		#This is an piped input
		FILENAME="--"
		START="${1}"
		END="${2}"
	else
		if [ $# -ne 0 ]; then
			FILENAME="${1}"
			START="${2}"
			END="${3}"
		else
			echo "Syntax error: $DLINE_SH [FILE] start [stop]" >&2
			exit 1
		fi
		if [ ! -f $FILENAME ]; then
			echo "Error: file not found [$FILENAME]" >&2
			exit 1
		fi

	fi

	set -e
	set -u
	if [ "X${START}" == "X" ]; then
		echo "Error: file not found [$FILENAME]" >&2
		exit 1
	fi

	if [ "X${END}" == "X" ]; then
		dline_1 "$FILENAME" "${START}"
	else
		dline_2 "$FILENAME" "${START}" "${END}"
	fi

	exit $?
fi

fi

