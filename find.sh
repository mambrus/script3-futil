#!/bin/bash
# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2011-03-21

# Finds file /like find), but upwards in FS

if [ -z $FIND_SH ]; then

FIND_SH="find.sh"

# Find a file from where you stand and upwards. When found, print full path or
# nothing if no file is found.
function up_find() {
	local LAST_PATH=`pwd`
	let ROOT_REACHED=0
	while
		ls -a | egrep "${1}" 1>/dev/null
		(( FOUND = !$? ))
		if [ $(pwd) == "/" ]; then
			ROOT_REACHED=1;
		fi
		[[ $FOUND = 0 && $ROOT_REACHED = 0 ]]
	do
		(( depth++ ))
		cd ..
	done
	if [[ $FOUND = 1 ]]; then
		pwd
	fi
	cd ${LAST_PATH}
}

source s3.ebasename.sh
if [ "$FIND_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	FIND_SH_INFO=${FIND_SH}
	source futil.ui.find.sh

	LAST_PATH=`pwd`

	cd ${START_DIR}

	up_find "$@"
	RC=$?

	cd ${LAST_PATH}

	exit ${RC}
fi

fi
