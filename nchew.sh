#!/bin/bash
# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2011-03-21

# When basename or pathname isn't enough, nchew is your script.
# It "chews" a part of a string up from the left based on the string given as
# argument. It can be used on any strings, in such case sed is probably more
# useful, but is especially usefull on strings like paths which contains
# characters that needs to be escaped.

if [ -z $NCHEW_SH ]; then

NCHEW_SH="nchew.sh"


function nchew_sed_pattern() {
	local NCHEW_SED_PATTERN=$(echo $1 | sed -e 's/\//\\\//g')
	echo "$NCHEW_SED_PATTERN"
}

function nchew_from_left() {
	local P=$(nchew_sed_pattern ${1})
	echo ${2} | sed -e "s/^${P}//"
}

function nchew_from_right() {
	local P=$(nchew_sed_pattern ${1})
	echo ${2} | sed -e "s/${P}$//"
}

function nchew_from_all() {
	local P=$(nchew_sed_pattern ${1})
	echo ${2} | sed -e "s/${P}//"
}

source s3.ebasename.sh
if [ "$NCHEW_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	NCHEW_SH_INFO=${NCHEW_SH}
	source .futil.ui..nchew.sh

	if [[ $CHEW_FROM = l ]]; then
		nchew_from_left "$@"
	elif [[ $CHEW_FROM = r ]]; then
		nchew_from_right "$@"
	elif [[ $CHEW_FROM = a ]]; then
		nchew_from_all "$@"
	else
		echo "Syntax error: unknown direction" 1>&2
		print_nchew_help $0 1>&2
	fi

	exit ${?}
fi

fi
