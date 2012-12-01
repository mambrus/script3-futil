#!/bin/bash
# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2012-12-01
# Use cmd on file, write back to same file

if [ -z $ONFILE_SH ]; then

ONFILE_SH="onfile.sh"

#From the env-var FILENAME, deploy arguments and write back to FILENAME
function onfile() {
	#echo "cmd: $@"
	if [ "X$TMPNAME_SH" == "X" ]; then
		source futil.tmpname.sh -a
	fi
	
	#echo "cmd: $@"
	#echo "$FILENAME"
	cat $FILENAME | \
	while read LINE; do
		cat $LINE | bash -c "$@" > $(tmpname res)
#echo "${DRYRUN}"
		if [ "X${DRYRUN}" == "Xno" ]; then
			cat $(tmpname res) > $LINE
		else
			cat $(tmpname res)
		fi
	done
}

source s3.ebasename.sh
#source futil.tmpname.sh -a
##shift $#
#shift 4

if [ "$ONFILE_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	ONFILE_SH_INFO=${ONFILE_SH}
	#source futil.tmpname.sh -a
	source .futil.ui..onfile.sh

	tty -s; ATTY="$?"
	ISATTY="$ATTY -eq 0"

	set -e
	#set -u
	
	source futil.tmpname.sh -a

	FILENAME="-"
	if [ "X$FILENAMES" != "X" ]; then
		echo $FILENAMES | \
			sed -e 's/,/\n/g' | \
			sed -e '/^[[:space:]]*$/d' > \
			$(tmpname files)
		FILENAME=$(tmpname files)
	fi
#exit 0
	if [ ! $ISATTY ]; then
		#This is an piped input
		FILENAME="-"
	fi
	#shift 0
	#echo "cmd: $@"
	onfile "$@"

	RC=$?

	if [ $RC -eq 0 ]; then
		tmpname_cleanup
	fi

	exit $RC
fi

fi

