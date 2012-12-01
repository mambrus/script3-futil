# UI part of futil.onfile.sh
# This is not even a script, stupid and can't exist alone. It is purely
# ment for beeing included.

function print_onfile_help() {
			cat <<EOF
Usage: $ONFILE_SH_INFO [options] -- <any_command> [<cmd_args>]

Use any command on a file. Typical usage would be for example a sed
operation which needs to be fed back to the same file. Normaly you can't do
that (not with any cammand i.e.). If you try for example this the file "afile"
will end up empty:
sed -e 's/string1/string2/g' < afile > afile

Note: <any_command> must be able to take it's input from stdin for
$ONFILE_SH_INFO to work.

Options:
  -f <filename>		Read input from this file instead of from stdin. Can
			be given several time, or separated with "," if several
			files are to be named. If filenames come from stdin,
			this flag is not considered.
  -x                    Dry-run. Don't write back to file, write to stdout.
			Note that content will come from tempfile and it's
			possible to pipe back to original file this way.
  -h			This help

Example:
  $ONFILE_SH_INFO -f file "sed 's/string1/string2/g'"
  #replace "string1" with "string2" in file "file"

  find . -name "*.c" | \
    $ONFILE_SH_INFO "sed 's/string1/string2/g' | sed 's/string3/string4/g'"
  #In each c-file, replace "string1" with "string2" and "string3" with "string4"

EOF
}
#echo "X OPTIND: $OPTIND"
	while getopts f:hx OPTION; do
		case $OPTION in
		h)
			clear
			print_onfile_help $0
			exit 0
			;;
		f)
#echo "file"
			FILENAMES="${FILENAMES},$OPTARG"
			;;
		x)
#echo "apa"
			DRYRUN='yes'
			;;
		?)
			echo "Syntax error:" 1>&2
			print_onfile_help $0 1>&2
			exit 2
			;;

		esac
#echo "OPTIND: $OPTIND"
	done
##echo "OPTIND: $OPTIND"
	shift $(($OPTIND - 1))

	FILENAMES=${FILENAMES-""}
	DRYRUN=${DRYRUN-"no"}


