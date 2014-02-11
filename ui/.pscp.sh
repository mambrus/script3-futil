# UI part of futil.pscp.sh
# This is not even a script, stupid and can't exist alone. It is purely
# meant for being included.

DEF_PORT=1447

function print_pscp_help() {
			cat <<EOF
Usage: $PSCP_SH_INFO [options] source destination

 This script utilizes pigz (parallel gzip) to copy mainly large amounts of
 files over slow or slowish networks. Exact use-case where this plays role
 vary, but if both ends of a copy are two strong machines the compression
 overhead are negligible. Speed improvement can ideally be up to roughly
 10xN, where N is the sending sides number of CPU:s.

 Note that this script does not use encryption. Besides from being
 compressed, files are sent in clear-text. ssh is used to transfer
 remote-side end of script. I.e. you need accounts and preferably keys
 exchanged on both ends (see s3.ssh_keypair.sh for a nice way to do this).

Options:
  -h                This help
  -p                Show progress info
  -P                Use port (defaut is $DEF_PORT)

Example:
  $PSCP_SH_INFO user@host:/absolute/path relative/path


EOF
}
	while getopts ph OPTION; do
		case $OPTION in
		h)
			clear
			print_pscp_help $0
			exit 0
			;;
		p)
			SHOW_PROGRESS='yes'
			;;
		p)
			PORT=$OPTARG
			;;
		?)
			echo "Syntax error:" 1>&2
			print_pscp_help $0 1>&2
			exit 2
			;;

		esac
	done
	shift $(($OPTIND - 1))

	if [ $# != 2 ]; then
		echo "Syntax error: Exactly two arguments required" 1>&2
		echo "" 1>&2
		print_pscp_help $0 1>&2
		exit 2
	fi

	SHOW_PROGRESS=${SHOW_PROGRESS-"no"}
	PORT=${PORT-"$DEF_PORT"}


