# UI part of futil.pline.sh
# This is not even a script, stupid and can't exist alone. It is purely
# ment for beeing included.

function print_pline_help() {
			cat <<EOF
Usage: $PLINE_SH_INFO [options] -- </regexp/><line-num> [</regexp/><line-num>]

Cut out a section of text from a file. It's basically sed, but with a better
UI. Normally section to cut are given as line-numbers, but instead of
linenumbers, text-markers can be given. If so, they have to be given in regexp
form and they have to be surrounded by '/'.

Script can take one or two arguments and can take input either from file or
stdin. Stdin input is ment to be piped.

Options:
  -f <filename>		Read input from this file instead of from stdin
  -h				This help

Example:
  $PLINE_SH_INFO -f text.txt 10 20
  #Return lines 10..20 from file text.txt

  $PLINE_SH_INFO '/<manifest>/' '/\/<manifest>/' < manifest.xml
  #Plint only the manifest content from a repo manifest file

EOF
}
	while getopts f:h OPTION; do
		case $OPTION in
		h)
			print_pline_help $0
			exit 0
			;;
		f)
			FILENAME=$OPTARG
			;;
		?)
			echo "Syntax error:" 1>&2
			print_pline_help $0 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	if [ $# = 0 ]; then
		echo "Syntax error: Marker(s) are mandatory" 1>&2
		print_pline_help $0 1>&2
		exit 2
	fi

	FILENAME=${FILENAME-""}


