#!/bin/bash
# Author: Michael Ambrus (michael.ambrus@sonyericsson.com)
# 2011-05-27
# Wraps sed's printing of lines by numbers or regexps

if [ -z $PLINE ]; then

PLINE="pline.sh"

#One address version
function pline_1() {
	cat $1 | sed -ne "${2}P"
}

#Two address version
function pline_2() {
	cat $1 | sed -ne "${2},${3}P"
}
source s3.ebasename.sh
if [ "$PLINE" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.
	
	PLINE_SH_INFO=${PLINE_SH}
	source .futil.ui..pline.sh
	
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
			echo "Syntax error: $PLINE [FILE] start [stop]" >&2
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
		pline_1 "$FILENAME" "${START}"
	else
		pline_2 "$FILENAME" "${START}" "${END}"
	fi

	exit $?
fi

fi

