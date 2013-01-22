# UI part of futil.onfile.sh
# This is not even a script, stupid and can't exist alone. It is purely
# ment for beeing included.

function print_onfile_help() {
			cat <<EOF
Usage:
   $ONFILE_SH_INFO [options] [--] <cmd> [<cmd_args>]
   $ONFILE_SH_INFO [options] [--] "<cmd> [<cmd_args>] [ | <cmd> [<cmd_args>] ]"

Use any command on a file. Typical usage would be for example a sed
operation which needs to be fed back to the same file. Normaly you can't do
that (not with any command i.e.). If you try for example this the file "afile"
will end up empty:
sed -e 's/string1/string2/g' < afile > afile


Note: <cmd> must be able to take it's input from stdin for
$ONFILE_SH_INFO to work.

Note: If you need to pipe the operation on the file, you need to quote the
complete chain of commands or the pipe will be a command terminator and result
not what you intend.

Options:
  -f <filename> Operate on this file-name instead of name(s) passed via stdin.
                Can be given several times, or separated with "," if several
                files are to be managed. If filenames come from stdin, this
                flag is not considered.
  -v            Verbose. Show each command on each file as it's processed.
  -x            Dry-run. Don't write back to file, write to stdout.
                Note that content will come from tempfile and it's
                possible to pipe back to original file this way.
  -h            This help

Examples:
  $ONFILE_SH_INFO -f file "sed 's/string1/string2/g'"
  #Replace "string1" with "string2" in file "file"

  find . -name "*.c" | \\
    $ONFILE_SH_INFO "sed 's/string1/string2/g' | sed 's/string3/string4/g'"
  #In each c-file, replace "string1" with "string2" and "string3" with "string4"

  src.shgrep.sh '[[:space:]]+$' | cut -f1 -d":" | sort -u \\
    futil.onfile.sh -v "sed -e 's/[[:space:]]+$//'"
  #Notice why this is useful as regexp are slighly different. -v flag shows what
  #is being done.

EOF
}
	while getopts f:hvx OPTION; do
		case $OPTION in
		h)
			clear
			print_onfile_help $0
			exit 0
			;;
		f)
			FILENAMES="${FILENAMES},$OPTARG"
			;;
		v)
			VERBOSE='yes'
			;;
		x)
			DRYRUN='yes'
			;;
		?)
			echo "Syntax error:" 1>&2
			print_onfile_help $0 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	FILENAMES=${FILENAMES-""}
	DRYRUN=${DRYRUN-"no"}
	VERBOSE=${VERBOSE-"no"}


