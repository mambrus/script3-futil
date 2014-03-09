#!/bin/bash
# Author: Michael Ambrus (michael.ambrus@sonymobile.com)
# 2014-02-11

if [ -z $PSCP_SH ]; then

PSCP_SH="pscp.sh"

#- Forward version of the remote scripts --------------------------------------
#Echo the sending script
#Function takes one argument, the path
function echo_send_script() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

SRC_DIR=$(echo ${1} | sed -e 's/\/$//')
echo "cd \$SRC_DIR/.."
cd "\$SRC_DIR/.."

SRC=\$(echo \$SRC_DIR | sed -e 's/.*\///')

echo "Running PIGZ transfer..."
echo "tar -c \${SRC} | pigz -\${NP} | nc -l ${PORT}"

tar -c \${SRC} | pigz -\${NP} | nc -l ${PORT}

EOF
}

#Echo the receiving script, simple version
#Function takes the following arguments
#1 The path
#2 Host to receive data from
function echo_receive_script_simple() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

TRGT_DIR=$(echo ${1} | sed -e 's/\/$//')
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
function echo_receive_script_ETA() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

TRGT_DIR=$(echo ${1} | sed -e 's/\/$//')
mkdir -p \$TRGT_DIR
cd \$TRGT_DIR
time nc ${2} ${PORT} | \
	pigz -\${NP} -d | \
	pv -f --size ${3} | \
	tar xf -

EOF
}

#- Reversed versions of the remote scripts ------------------------------------
#Echo the sending script
function echo_send_script_simple_bd() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

SRC_DIR=$(echo ${1} | sed -e 's/\/$//')
echo "cd \$SRC_DIR/.."
cd "\$SRC_DIR/.."

SRC=\$(echo \$SRC_DIR | sed -e 's/.*\///')

echo "Running PIGZ transfer..."
echo "tar -c \${SRC} | pigz -\${NP} | nc ${2} ${PORT}"

time tar -c \${SRC} | pigz -\${NP} | nc ${2} ${PORT}

EOF
}

#Echo the sending script
function echo_send_script_ETA_bd() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

SRC_DIR=$(echo ${1} | sed -e 's/\/$//')
echo "cd \$SRC_DIR/.."
cd "\$SRC_DIR/.."

SRC=\$(echo \$SRC_DIR | sed -e 's/.*\///')

echo "Running PIGZ transfer..."
echo "tar -c \${SRC} | pv -f --size ${3} | pigz -\${NP} | nc ${2} ${PORT}"

time tar -c \${SRC} | 
	pv -f --size ${3} | \
	pigz -\${NP} | \
	nc ${2} ${PORT}

EOF
}

#Echo the receiving script
function echo_receive_script_bd() {
cat <<EOF
#!/bin/bash
set -e

#Determine number of CPU:s on this host
NP=\$(cat /proc/cpuinfo | grep processor | wc -l)

TRGT_DIR=$(echo ${1} | sed -e 's/\/$//')
mkdir -p \$TRGT_DIR
cd \$TRGT_DIR
nc ${2} -l ${PORT} | pigz -\${NP} -d | tar xvf -

EOF
}

#- Init/Fini remote scripts ---------------------------------------------------
# Initializes and checks prerequisites on remote machine
function echo_remote_init() {
cat <<EOF
#!/bin/bash

# Verbosely execute args (i.e. print and execute)
# Returns: the error-code of the command if any.
function pexec () {
	echo "\${@}"
	"\${@}"
	return \$?
}

# On which-error, try run to get system to output more info
# Returns: Nothing. Exits if invoked
function try_run() {
	bash -ic \${@} || exit \$?
	exit 666
}

# Tests if binary is installed (in \$PATH), and if not
# run it anyway to get more system leads of what to do
# Returns:
function texec() {
	pexec which \${1} || try_run \${1}
}

#Either of the below should abort execution on failure
echo "which bash"
which bash || (echo "Bash is required"; exit 69)
texec screen
texec pigz
texec host
texec nc
texec pv

set -e
echo "nc -v 2>&1 | head -n1 | grep 'netcat-openbsd'"
nc -v 2>&1 | head -n1 | grep 'netcat-openbsd'
pexec mkdir -p /tmp/\$USER

EOF
}

# Clean-up on remote machine
function echo_remote_fini() {
cat <<EOF
#!/bin/bash
set -e

EOF
}

function info() {
	local DEBUG_LVL="${1}"
	if [ $# -eq 2 ]; then
		shift
		local OUTS="${@}"
	elif [ $# -eq 1 ]; then
		while read LINE; do
			info "${DEBUG_LVL}" "${LINE-nil}"
		done
		return 0
	else
		echo "FATAL: Snytax error in function info" 1>&2
		return -1
	fi

	if [ $DEBUG_LVL == "-1" ]; then
		echo ">>>>: $(date '+%D %T') " "${OUTS}"
	elif [ $DEBUG_LVL == "0" ]; then
		local PRFX="ERR"
	elif [ $DEBUG_LVL == "1" ]; then
		local PRFX="WARN"
	elif [ $DEBUG_LVL == "2" ]; then
		local PRFX="INFO"
	elif [ $DEBUG_LVL == "3" ]; then
		local PRFX="DBG"
	elif [ $DEBUG_LVL == "4" ]; then
		local PRFX="REMO"
		local DEBUG_LVL="2"
	else
		local PRFX="UNKN"
	fi

	if [ $(( VERBOSE >= DEBUG_LVL )) -eq 1 ]; then
		echo "$(date '+%y-%m-%d %T.%N') ${PRFX}:" "${OUTS}"
	fi
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
		local HOST="127.0.0.1"
	fi
	echo $HOST
}

# Returns PATH part, or "." if none is given
function get_path() {
	local LPATH=$(echo "${1}" | cut -f2 -d":")
	if [ "X${LPATH}" == "X" ]; then
		info 1 "Path can't be determined. Assigning default: \".\"" 1>&2
		local LPATH="."
	fi
	echo $LPATH
}

function forward_transfer() {
	info 2 "Transferring send-script $SUSER@$SHOST"...
	info 2 "  ($SENDSCRIPT)"
	info 3 "  Local copy: ${SENDSCRIPT}.local"
	echo_send_script $SPATH  | \
		ssh ${SUSER}@${SHOST} "cat -- > ${SENDSCRIPT}; chmod a+x ${SENDSCRIPT}"
	echo_send_script $SPATH > ${SENDSCRIPT}.local

	info 2 "Starting send-script $SUSER@$SHOST"...
	info 2 "  screen -rd $SENDSCREEN"
	rm -f screenlog.[0-9]
	screen -dmLS $SENDSCREEN ssh ${SUSER}@${SHOST} ${SENDSCRIPT}

	info 2 "Transferring receive-script to $RUSER@$RHOST"...
	info 2 "  ($RECSCRIPT)"
	info 3 "  Local copy: ${RECSCRIPT}.local"

	SSHOST=$SHOST;
	if [ "X${SSHOST}" == "X127.0.0.1" ]; then
		info 2 "Localhost IP cant be used for server name"
		info 2 "  Trying to deduct FQDN..."
		SSHOST=$(host hornet | cut -f1 -d" ");
		info 2 "FQDN-\$SHOST=$SSHOST"
	fi
	if [ $SHOW_PROGRESS == "yes" ]; then
		echo_receive_script_ETA $RPATH $SSHOST $SSIZE| \
			ssh ${RUSER}@${RHOST} "cat -- > ${RECSCRIPT}; chmod a+x ${RECSCRIPT}"
		echo_receive_script_ETA $RPATH $SSHOST $SSIZE > ${RECSCRIPT}.local
	else
		echo_receive_script_simple $RPATH $SSHOST | \
			ssh ${RUSER}@${RHOST} "cat -- > ${RECSCRIPT}; chmod a+x ${RECSCRIPT}"
		echo_receive_script_simple $RPATH $SSHOST > ${RECSCRIPT}.local
	fi

	info 3 "Before start receiving, confirm send-script is up and running"
	if [ "X$(screen -ls | grep $SENDSCREEN)" == "X" ]; then
		info 0 "Sending encountered error"
		cat screenlog.[0-9] | while read LINE; do
			info 0 "$LINE"
		done
		exit 1
	fi
	info 2 "Starting receive-script $RUSER@$RHOST"...
	ssh ${RUSER}@${RHOST} "export TERM=$TERM; ${RECSCRIPT}"
}

function backdoor_transfer() {
	info 2 "Transferring receive-script to $RUSER@$RHOST"...
	info 2 "  ($RECSCRIPT)"
	info 3 "  Local copy: ${RECSCRIPT}.local"

	echo_receive_script_bd $RPATH | \
		ssh ${RUSER}@${RHOST} "cat -- > ${RECSCRIPT}; chmod a+x ${RECSCRIPT}"
	echo_receive_script_bd $RPATH > ${RECSCRIPT}.local
	
	info 2 "Starting recieve-script $SUSER@$SHOST"
	info 2 "  screen -rd $RECSCREEN"
	rm -f screenlog.[0-9]
	screen -dmLS $RECSCREEN ssh ${RUSER}@${RHOST} ${RECSCRIPT}
	
	info 2 "Transferring send-script $SUSER@$SHOST"...
	info 2 "  ($SENDSCRIPT)"
	info 3 "  Local copy: ${SENDSCRIPT}.local"
	
	if [ $SHOW_PROGRESS == "yes" ]; then
		echo_send_script_ETA_bd $RPATH $SSHOST $SSIZE| \
			ssh ${RUSER}@${RHOST} "cat -- > ${SENDSCRIPT}; chmod a+x ${SENDSCRIPT}"
		echo_send_script_ETA_bd $RPATH $SSHOST $SSIZE > ${SENDSCRIPT}.local
	else
		echo_send_script_simple_bd $RPATH $SSHOST | \
			ssh ${RUSER}@${RHOST} "cat -- > ${SENDSCRIPT}; chmod a+x ${SENDSCRIPT}"
		echo_send_script_simple_bd $RPATH $SSHOST > ${SENDSCRIPT}.local
	fi

	info 3 "Before start rending, confirm receive-script is up and running"
	if [ "X$(screen -ls | grep $RECSCREEN)" == "X" ]; then
		info 0 "Sending encountered error"
		cat screenlog.[0-9] | while read LINE; do
			info 0 "$LINE"
		done
		exit 1
	fi
	info 2 "Starting send-script $SUSER@$SHOST"...
	ssh ${SUSER}@${SHOST} "export TERM=$TERM; ${SENDSCRIPT}"
}

source s3.ebasename.sh
if [ "$PSCP_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	PSCP_SH_INFO=${PSCP_SH}
	source .futil.ui..pscp.sh
	source futil.tmpname.sh
	SENDSCRIPT=$(tmpname send.sh)
	SENDSCREEN=$(tmpname sending | sed -E 's/^.*\///')
	RECSCREEN=$(tmpname receiving | sed -E 's/^.*\///')
	RECSCRIPT=$(tmpname rec.sh)
	INITSCRIPT=$(tmpname init.sh)
	FINISCRIPT=$(tmpname fini.sh)

	set -e
	set -u
	set -o pipefail

	SUSER=$(get_user $1)
	SHOST=$(get_host $1)
	SPATH=$(get_path $1)
	RUSER=$(get_user $2)
	RHOST=$(get_host $2)
	RPATH=$(get_path $2)

	info 3 "Initial meaning of parsed SRC/DST"
	info 3 "SRC-USER: $SUSER"
	info 3 "SRC-HOST: $SHOST"
	info 3 "SRC-PATH: $SPATH"
	info 3 "DST-USER: $RUSER"
	info 3 "DST-HOST: $RHOST"
	info 3 "DST-PATH: $RPATH"

	THIS_PATH=$(pwd)
	CHEWED_PATH=$(futil.nchew.sh -dl -ts $HOME $THIS_PATH)
	if [ "X${THIS_PATH}" != "X${CHEWED_PATH}" ]; then
		# Invokers path is relative his $HOME, fix it a little
		info 3 "(A)"
		STAND_PATH=$(echo "${CHEWED_PATH}" | sed -E 's/^\///')
	else
		info 3 "(B)"
		STAND_PATH="${CHEWED_PATH}"
	fi
	info 3 "THIS_PATH: $THIS_PATH"
	info 3 "STAND_PATH: $STAND_PATH"

	# If not absolute paths and not explicit relative "~",Prepend STAND_PATH
	# to them, except if in $HOME itself.
	if [ $(expr index "${SPATH}" "/") != "1" -a $(expr index "${SPATH}" "~") != "1" ]; then
		if [ "X${STAND_PATH}" != "X" ]; then
			SPATH="${STAND_PATH}/${SPATH}"
		fi
	fi
	if [ $(expr index "${RPATH}" "/") != "1" -a $(expr index "${RPATH}" "~") != "1" ]; then
		if [ "X${STAND_PATH}" != "X" ]; then
			RPATH="${STAND_PATH}/${RPATH}"
		fi
	fi

	if [ $SHOW_PROGRESS == "yes" ]; then
		info 2 "Copy from ${SUSER}@${SHOST}:${SPATH} to: ${RUSER}@${RHOST}:${RPATH}"
	fi
	info 3 "Final meaning of parsed SRC/DST"
	info 3 "  SRC:${SUSER}@${SHOST}:${SPATH}"
	info 3 "  DST:${RUSER}@${RHOST}:${RPATH}"

	#Initialization and perquisites check stage
	echo_remote_init > ${INITSCRIPT}.local
	info 2 "Initializing and testing SRC: $SUSER@$SHOST with:"
	info 2 "  ${INITSCRIPT}.local"
	if ! cat ${INITSCRIPT}.local | ssh ${SUSER}@${SHOST} | info 4 ; then
		RC=${PIPESTATUS[1]}
		info 0 "Prerequisites check on SRC-mashine [${SHOST}] failed: ${RC}"
		exit ${RC}
	fi
	SSIZE=$(ssh ${SUSER}@${SHOST} du -sb $SPATH | awk '{print $1}')
	info 2 "Initializing and testing DST: $RUSER@$RHOST with:"
	info 2 "  ${INITSCRIPT}.local"
	if ! cat ${INITSCRIPT}.local | ssh ${RUSER}@${RHOST} | info 4 ; then
		RC=${PIPESTATUS[1]}
		info 0 "Prerequisites check on DST-mashine [${RHOST}] failed: ${RC}"
		exit ${RC}
	fi
	ssh ${RUSER}@${RHOST} mkdir -p /tmp/$USER

	if [ "X${REVERSED}" == "Xno" ]; then
		forward_transfer
	else
		backdoor_transfer
	fi

	rm -f ${RECSCRIPT}.local
	rm -f ${SENDSCRIPT}.local
	rm -f ${INITSCRIPT}.local
	rm -f ${FINISCRIPT}.local
	info 2 "Tidying up send-script $SUSER@$SHOST"...
	info "  ($SENDSCRIPT)"
	ssh ${SUSER}@${SHOST} "rm ${SENDSCRIPT}"
	info 2 "Tidying up receive-script $RUSER@$RHOST"...
	info 2 "  ($RECSCRIPT)"
	info 2 ${RUSER}@${RHOST} "rm ${RECSCRIPT}"

	exit $?
fi

fi

