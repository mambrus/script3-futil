# UI part of futil.find.sh
# This is not even a script, stupid and can't exist alone. It is purely
# ment for beeing included.

function print_find_help() {
			cat <<EOF
Usage: $NCHEW_SH_INFO [options] -- pattern filename

Chews up part of a filename

Options:
  -h		This help

  -d d		Direction is from
  	l		  left (default)
	r		  right
	r		  anywhere

  -t t		Pattern is
  	s		  Plain string (default)
	r		  regexp


Example:
  $NCHEW_SH_INFO -dl -ts "$HOME/" 'pwd'
  $NCHEW_SH_INFO -dr -ts 'pwd' "$HOME/"

EOF
}
	while getopts hd:t: OPTION; do
		case $OPTION in
		h)
			print_find_help $0
			exit 0
			;;
		d)
			CHEW_FROM=$OPTARG
			;;
		t)
			PATTERN_TYPE=$OPTARG
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


	CHEW_FROM=${CHEW_FROM-"l"}
	PATTERN_TYPE=${PATTERN_TYPE-"s"}

