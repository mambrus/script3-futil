# UI part of futil.s3template.sh
# This is not even a script, stupid and can't exist alone. It is purely
# ment for beeing included.

function print_s3template_help() {
			cat <<EOF
Usage:
   $S3TEMPLATE_SH_INFO [options] <s3cmd> <new_cmd>

Use any s3cmd as a template to create a new command including it's ui part


Options:
  -d <dir>      Output directory
  -h            This help

Examples:
  cd futil
  $S3TEMPLATE_SH_INFO -d ../util $ONFILE_SH_INFO test.sh

EOF
}
	while getopts d:f OPTION; do
		case $OPTION in
		h)
			clear
			print_s3template_help $0
			exit 0
			;;
		d)
			OUTDIR="$OPTARG"
			;;
		?)
			echo "Syntax error:" 1>&2
			print_s3template_help $0 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	OUTDIR=${OUTDIR-"./"}
	if [ ! $# -eq 2 ]; then
		echo "Syntax error: $(basename $0) require"\
		     "exactly two arguments" 1>&2
		echo 1>&2
		print_s3template_help 1>&2
		exit 1
	fi

