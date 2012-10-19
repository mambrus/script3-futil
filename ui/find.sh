# UI part of futil.find.sh
# This is not even a script, stupid and can't exist alone. It is purely
# ment for beeing included.

function print_find_help() {
			cat <<EOF
Usage: $FIND_SH_INFO [options] -- regexp_pattern

Find a filename fitting the regex_pattern upwards in file-system.

Options:
  -d		Start directory
  -t c          Target is of type c
  	d		directory

	f		regular file (default)

Example:
  $FIND_SH_INFO -D /lib/modules/2.6.32-36-generic/ -t d udev

EOF
}
	while getopts hd:t: OPTION; do
		case $OPTION in
		h)
			print_find_help $0
			exit 0
			;;
		d)
			START_DIR=$OPTARG
			;;
		t)
			TYPE=$OPTARG
			;;
		?)
			echo "Syntax error:" 1>&2
			print_find_help $0 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	if [ $# = 0 ]; then
		echo "Syntax error: regexp_pattern is mandatory" 1>&2
		print_find_help $0 1>&2
		exit 2
	fi
	
	if [ "X${START_DIR}" == "X" ]; then
		START_DIR=$(pwd)
	fi
	
	if [ "X${TYPE}" == "X" ]; then
		TYPE="f"
	fi

