# UI part of futil.tmpname.sh
# This is not even a script, stupid and can't exist alone. It is purely
# ment for beeing included.

function print_tmpname_help() {
			cat <<EOF
Usage: $TMPNAME_SH_INFO [options]

This script figures out a unique filename based on username, process name and
time. It's supposed to be used as included only as it uses the time of
inclusion as one of it's parts.

The reson for making a whole script for such a seeminly simple task as choosing
a suitable name for a tempfile is:

1) We want tempfiles to be unique in a multi-process, multi-user environment
2) But we still want a simple way to examine these filenames for debugging
purposes. I.e. we need a rule-based way of determining where they're stored.

Normally you would not use any options, just include this script. Then you
would use the function tmpname to get a useful tempname. It's only argument
(optional) is a suffix in case your script needs more temp-files than one.

Options:
  -a			Autoinit. Create tempdirs on beforehand if needed.
  -t <timestamp>	Used in special cases to force a different timestamp.
			Format is optional exept that is may not contain
			whitespaces. Prefered format is same same as:
			date +%y%m%d_%H%M%S.%N (i.e. [$(date +%y%m%d_%H%M%S.%N)])
  -p <proc>		Used in special cases to force a different process
			name.
  -u <name>		Used in special cases to use a different username
  -D <directory>	Set a main-directory to be prefixed. Default is
			/tmp/\$0. One useful alternative is "/tmp". Note:
			filename itself is unique enough.
  -d <directory>	Set sub-directory to be prefixed. Default is your
			username [$(whoami)]. One useful alternative is "../"
			which puts all your tempfiles in the main directory (
			see -D option). Note: filename itself is unique enough.
  -h			This help

Example:
  #In a script:

  include $TMPNAME_SH_INFO -fmyproc
  #initializes $TMPNAME_SH_INFO

  TMPF1=\$(tmpfname 1)
  TMPF2=\$(tmpfname 2)
  #Creates variables for easier use (optional)

  echo "Hello " > \$TMPF1
  echo "world" > \$TMPF2
  echo "\$(cat \$TMPF1) \$(cat \$TMPF2)"
  #Do suff with you temp-files

  tmpfname_cleanup
  #Clean-up filenames (special function)

EOF

}

# Note that since ui part will be included even in non-interactive mode,
# variables must be made certain to be uniquie, i.e. their names are themselves
# variables (i.e. indirect variable usage). This is quite nifty, but should not
# need be used as common practice in s3.

VAR_TS="VAR_${$}_TS"
VAR_AUTOINIT="VAR_${$}_AUTOINIT"
VAR_PROC="VAR_${$}_PROC"
VAR_USER="VAR_${$}_USER"
VAR_MAINDIR="VAR_${$}_MAINDIR"
VAR_SUBDIR="VAR_${$}_SUBDIR"
VAR_TMPDIR="VAR_${$}_TMPDIR"
VAR_FULL_TMPNAME_BASE="VAR_${$}_FULL_TMPNAME_BASE"

#This function is used to avoid using bash2 syntax. I.e. ${!VAR_TS}
function getvar() {
	#Coresponding bash syntax:
	#eval echo \$$VAR_TS

	#Needs to be broken down in two stages...
	local THE_VAR=$(eval echo \$"${1}")
	eval echo \$$THE_VAR
}

#Sets a variable if never assigned before
function set_default() {
	local THE_VAR=$(eval echo \$"${1}")
	if [ "X$(eval echo \$$THE_VAR)" == "X" ]; then
		export ${THE_VAR}="${2}"
	fi
}

	while getopts at:p:u:d:D:h OPTION; do
		case $OPTION in
		h)
			clear
			print_tmpname_help $0
			exit 0
			;;
		a)
			export $VAR_AUTOINIT="yes"
			;;
		t)
			export $VAR_TS=$OPTARG
			;;
		p)
			export $VAR_PROC=$OPTARG
			;;
		u)
			export $VAR_USER=$OPTARG
			;;
		d)
			export $VAR_SUBDIR=$OPTARG
			;;
		D)
			export $VAR_MAINDIR=$OPTARG
			;;
		?)
			echo "Syntax error:" 1>&2
			print_tmpname_help $0 1>&2
			exit 2
			;;

		esac
	done
	#Don't not adjust positional parameter scanning if sourced
	#Do that when we know we're not sourced
	#shift $(($OPTIND - 1))

	#export ${VAR_TS}=${!VAR_TS - "$(date +%y%m%d_%H%M%S.%N)" }
	#export ${VAR_TS}=$(date +%y%m%d_%H%M%S.%N)
	set_default VAR_AUTOINIT	"no"
	set_default VAR_TS		$(date +%y%m%d_%H%M%S.%N)
	set_default VAR_PROC		$(basename $0)
	set_default VAR_USER		$(whoami)
	set_default VAR_MAINDIR		/tmp
	set_default VAR_SUBDIR		$(getvar VAR_USER)


	export ${VAR_FULL_TMPNAME_BASE}="$(getvar VAR_PROC)_$(getvar VAR_USER)_$(getvar VAR_TS)"

	#echo ${$(echo ${VAR_TS})}
	#echo ${!VAR_TS}
	#eval echo \$$VAR_TS

	#echo $(getvar VAR_TS)


