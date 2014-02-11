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

TRGT_DIR=$(dirname ${1})
mkdir -p \$TRGT_DIR
cd \$TRGT_DIR
time nc ${2} ${PORT} | pigz -\${NP} -d | tar xvf -
#time nc ${2} ${PORT} | gunzip | tar xvf -

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

TRGT_DIR=$(dirname ${1})
mkdir -p \$TRGT_DIR
cd \$TRGT_DIR
time nc remote_ip ${PORT} | pigz -d | tar xvf -

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
	local PATH=$(expr "${1}" : '.*:\(.*\)')
	if [ "X${PATH}" == "X" ]; then
		local PATH="."
	fi
	echo $PATH
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

	echo "Initializing $SUSER@$SHOST" ...
	ssh ${SUSER}@${SHOST} mkdir -p /tmp/$USER
	SSIZE=$(ssh ${SUSER}@${SHOST} du -sb $SPATH | awk '{print $1}')
	
	echo "Initializing $RUSER@$RHOST" ...
	ssh ${RUSER}@${RHOST} mkdir -p /tmp/$USER

	echo "Transferring send-script $SUSER@$SHOST"...
	echo "  ($SENDSCRIPT)"
	print_send_script $SPATH  | \
		ssh ${SUSER}@${SHOST} "cat -- > ${SENDSCRIPT}"
	ssh ${SUSER}@${SHOST} "chmod a+x ${SENDSCRIPT}"
	
	echo "Transferring receive-script to $RUSER@$RHOST"...
	echo "  ($RECSCRIPT)"
	if [ $SHOW_PROGRESS == "yes" ]; then
		print_receive_script_ETA $RPATH $SHOST $SSIZE| \
			ssh ${RUSER}@${RHOST} "cat -- > ${RECSCRIPT}"
	else
		print_receive_script_simple $RPATH $SHOST | \
			ssh ${RUSER}@${RHOST} "cat -- > ${RECSCRIPT}"
	fi
	ssh ${RUSER}@${RHOST} "chmod a+x ${RECSCRIPT}"


	echo "Starting send-script $SUSER@$SHOST"...
	echo "  screen -rd $SENDSCREEN"
	screen -dmS $SENDSCREEN ssh ${SUSER}@${SHOST} ${SENDSCRIPT}
	
	echo "Starting receive-script $RUSER@$RHOST"...
	ssh ${RUSER}@${RHOST} ${RECSCRIPT}

	#tmpname_cleanup

	exit $?
fi

fi

