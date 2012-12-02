#!/bin/bash
# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2012-12-01
# Use cmd on file, write back to same file

if [ -z $ONFILE_SH ]; then

ONFILE_SH="onfile.sh"

#From the env-var FILENAME, deploy arguments and write back to FILENAME
function onfile() {
	if [ "X$TMPNAME_SH" == "X" ]; then
		source futil.tmpname.sh
		tmpname_flags_init "-a"
	fi

	cat $FILENAME | \
	while read LINE; do
		if [ "X${VERBOSE}" == "Xyes" ]; then
			echo "$0 -f $LINE \"$@\""
		fi
		cat $LINE | bash -c "$@" > $(tmpname res)
		if [ "X${DRYRUN}" == "Xno" ]; then
			cat $(tmpname res) > $LINE
		else
			cat $(tmpname res)
		fi
	done
}

source s3.ebasename.sh
if [ "$ONFILE_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	ONFILE_SH_INFO=${ONFILE_SH}
	source futil.tmpname.sh -a

	source .futil.ui..onfile.sh

	tty -s; ATTY="$?"
	ISATTY="$ATTY -eq 0"

	set -e
	#set -u

	FILENAME="-"
	if [ "X$FILENAMES" != "X" ]; then
		echo $FILENAMES | \
			sed -e 's/,/\n/g' | \
			sed -e '/^[[:space:]]*$/d' > \
			$(tmpname files)
		FILENAME=$(tmpname files)
	fi
	if [ ! $ISATTY ]; then
		#This is an piped input
		FILENAME="-"
	fi
	if [ "X${@}" == "X" ]; then
		echo "$0 Syntax error: Command is mandatory" 1>&2
		sleep 3
		print_onfile_help
		exit 1
	fi

	onfile "$@"

	RC=$?

	if [ $RC -eq 0 ]; then
		tmpname_cleanup
	fi

	exit $RC
fi

fi

