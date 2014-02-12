#!/bin/bash
# Author: Michael Ambrus (michael.ambrus@sonymobile.com)
# 2014-02-11

if [ -z $PSCP_SH ]; then

PSCP_SH="pscp.sh"

#Echo the sending script
#Function takes one argument, the path
function print_send_script() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

echo "Running PIGZ transfer..."
echo "tar -c $1 | pigz -\${NP} | nc -l ${PORT}"

tar -c $1 | pigz -\${NP} | nc -l ${PORT}

EOF
}

#Echo the receiving script, simple version
#Function takes the following arguments
#1 The path
#2 Host to receive data from
function print_receive_script_simple() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

#Determine if path ends with a '/', i.e. is a directory.
EC=\$(echo "${1}" | sed -E 's/(.*)(.)$/\2/')

if [ "X\$EC" != "X/" ]; then
	TRGT_DIR=$(dirname ${1})
else
	TRGT_DIR=${1}
fi
mkdir -p \$TRGT_DIR
cd \$TRGT_DIR
time nc ${2} ${PORT} | pigz -\${NP} -d | tar xvf -

EOF
}

#Echo the receiving script, ETA version
#Function takes the following arguments
#1 The path
#2 Host to receive data from
#3 Total size to be received
function print_receive_script_ETA() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

#Determine if path ends with a '/', i.e. is a directory.
EC=\$(echo "${1}" | sed -E 's/(.*)(.)$/\2/')

if [ "X\$EC" != "X/" ]; then
	TRGT_DIR=$(dirname ${1})
else
	TRGT_DIR=${1}
fi
mkdir -p \$TRGT_DIR
cd \$TRGT_DIR
time nc ${2} ${PORT} | \
	pigz -\${NP} -d | \
	pv -f --size ${3} | \
	tar xf -

EOF
}

# Functions below get host, user, path parts out from scp syntax. I.e from
# user@hostr:path respective part is extracted, with sane fall-backs if any
# part is missing.
# ------------------------------------------------------------------------

# Returns user if any, else $USER
function get_user() {
	local LUSER=$(expr match "${1}" '\(.*@\)' | sed -E 's/@$//')
	if [ "X${LUSER}" == "X" ]; then
		local LUSER=$USER
	fi
	echo $LUSER
}

# Returns host part, or "localhost" if none is given
function get_host() {
	local HOST=$(
		expr match "${1}" '\(.*:\)' | \
		sed -E 's/.*@//' | sed -E 's/:$//')

	if [ "X${HOST}" == "X" ]; then
		local HOST="localhost"
	fi
	echo $HOST
}

# Returns PATH part, or "." if none is given
function get_path() {
	local PATH=$(echo "${1}" | cut -f2 -d":")
	if [ "X${PATH}" == "X" ]; then
		echo "Warning: Path can't be determined. Assigning default: \".\"" 1>&2
		local PATH="."
	fi
	echo $PATH
}

function info() {
	if [ "X${VERBOSE}" != "X0" ]; then
		echo "$(date '+%D %T') " "${@}"
	fi
}

source s3.ebasename.sh
if [ "$PSCP_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	PSCP_SH_INFO=${PSCP_SH}
	source .futil.ui..pscp.sh
	source futil.tmpname.sh
	SENDSCRIPT=$(tmpname send.sh)
	SENDSCREEN=$(tmpname sending | sed -E 's/^.*\///')
	RECSCRIPT=$(tmpname rec.sh)

	set -e
	set -u

	SUSER=$(get_user $1)
	SHOST=$(get_host $1)
	SPATH=$(get_path $1)
	RUSER=$(get_user $2)
	RHOST=$(get_host $2)
	RPATH=$(get_path $2)

	if [ $SHOW_PROGRESS == "yes" ]; then
		echo "Copy from ${SUSER}@${SHOST}:${SPATH}"\
			"to: ${RUSER}@${RHOST}:${RPATH}"
	fi

	info "Initializing $SUSER@$SHOST" ...
	ssh ${SUSER}@${SHOST} mkdir -p /tmp/$USER
	SSIZE=$(ssh ${SUSER}@${SHOST} du -sb $SPATH | awk '{print $1}')

	info "Initializing $RUSER@$RHOST" ...
	ssh ${RUSER}@${RHOST} mkdir -p /tmp/$USER

	info "Transferring send-script $SUSER@$SHOST"...
	info "  ($SENDSCRIPT)"
	print_send_script $SPATH  | \
		ssh ${SUSER}@${SHOST} "cat -- > ${SENDSCRIPT}"
	ssh ${SUSER}@${SHOST} "chmod a+x ${SENDSCRIPT}"

	info "Transferring receive-script to $RUSER@$RHOST"...
	info "  ($RECSCRIPT)"
	if [ $SHOW_PROGRESS == "yes" ]; then
		print_receive_script_ETA $RPATH $SHOST $SSIZE| \
			ssh ${RUSER}@${RHOST} "cat -- > ${RECSCRIPT}"
	else
		print_receive_script_simple $RPATH $SHOST | \
			ssh ${RUSER}@${RHOST} "cat -- > ${RECSCRIPT}"
	fi
	ssh ${RUSER}@${RHOST} "chmod a+x ${RECSCRIPT}"

	info "Starting send-script $SUSER@$SHOST"...
	info "  screen -rd $SENDSCREEN"
	screen -dmS $SENDSCREEN ssh ${SUSER}@${SHOST} ${SENDSCRIPT}

	info "Starting receive-script $RUSER@$RHOST"...
	ssh ${RUSER}@${RHOST} "export TERM=$TERM; ${RECSCRIPT}"

	info "Tidying up send-script $SUSER@$SHOST"...
	info "  ($SENDSCRIPT)"
	ssh ${SUSER}@${SHOST} "rm ${SENDSCRIPT}"
	info "Tidying up receive-script $RUSER@$RHOST"...
	info "  ($RECSCRIPT)"
	info ${RUSER}@${RHOST} "rm ${RECSCRIPT}"

	exit $?
fi

fi

