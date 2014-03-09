# UI part of futil.pscp.sh
# This is not even a script, stupid and can't exist alone. It is purely
# meant for being included.

source .s3..fonts.sh
source .s3..uifuncs.sh

DEF_PORT=1447

function print_pscp_help() {
	local CMD_STR="$(basename ${0})"

cat <<EOF
$(print_man_header)

$(echo -e ${FONT_BOLD}NAME${FONT_NONE})
        $CMD_STR - $(echo -e \
            "Fast, compressed (remote) copy between SRC and DST.")

$(echo -e ${FONT_BOLD}SYNOPSIS${FONT_NONE})
        $(echo -e ${FONT_BOLD}${CMD_STR}${FONT_NONE} [OPTIONS] SRC DST)
        $(echo -e ${FONT_BOLD}${CMD_STR}${FONT_NONE} [OPTIONS] \
        [[user@]host:]name[/] [[user@]host:]dir/)
        $(echo -e ${FONT_BOLD}${CMD_STR}${FONT_NONE} [OPTIONS] \
        [[user@]host:]name1[/] [[user@]host:]name2)

$(echo -e ${FONT_BOLD}OPTIONS${FONT_NONE})

  -h    This help
  -x    Inhibit progress info (can help terminfo issues)
  -p    Use port (defaut is $DEF_PORT)
  -r    Reversed mode. DST is made a sevice instead of SRC. This makes it
        possible to send from SRC to DST when SRC is behind a firewall
        without proxying or port FW.
  -v N  Be verbose. N is a number 0-3, where 0 is silent and 3 is extra
        verbose and includes debug information.

$(echo -e ${FONT_BOLD}DESCRIPTION${FONT_NONE})
        Copy files between SRC and DSC, where either or both SRC and DST can
        be on remote mashines. It does what scp does but much faster and in
        clear-text. An estimate of 300% speed improvement over scp, even
        with ssh CompressionLevel 6 (-C6). Without compression it's much
        worse even on a very fast network:
        scp:  1m50.851s
        pscp: 0m13.036s
        ==> 836% speed increase

$(echo -e ${FONT_BOLD}EXAMPLES${FONT_NONE})
        $(echo -e "${FONT_BOLD}${CMD_STR} user@host:/absolute/path "\
"relative/path ${FONT_NONE}")

           Copies file or directory from user@host with apsolute path to
           destination on local-host which is relative to \$HOME.

$(echo -e ${FONT_BOLD}OVERVIEW${FONT_NONE})
        This script utilizes pigz (parallel gzip) to copy mainly large
        amounts of files over slow or slowish networks. Exact use-case where
        this plays role vary, but if both ends of a copy are two strong
        machines the compression overhead are negligible. Speed improvement
        can idealy be up to 10xN, where N is the sending sides number of
        CPU:s, provided A) network even with the compressed stream and B)
        disks can keep up.

        An estimate of 300% speed improvement over scp on average, ssh
        CompressionLevel 6 (-C6). Most people forget compression for scp
        and it's somewhat awkward to set up as it's enableability can be set
        at several places. Without ssh compression, a test on a ~1GB
        directory with various types of files on a very fast network showed
        the following:

        scp:  1m50.851s
        pscp: 0m13.036s
        ==> 836% speed increase

        In many cases the increase doen't mean much, but if your transfer
        takes 1hr with scp, there's definitly a difference as pscp will save
        you a full day. $(echo -e ${FONT_UNDERLINE}Note however:${FONT_NONE}) \
This is for transfers where the content
        either doesn't matter much, or the network is end-to-end trusted.
        The latter would be the case if you transfer large amount of data
        between two computers on for example a LAN.

        Actually, what was limiting in comparison above were the disks as
        the network (1Gbps) wasent nearly saturated. 85.8MB/s, thats faster
        that the disks can copy files when borth SRC and DST is on the same
        physical disc. As the network wasnt loaded much, compression alone
        can't explain the difference.

        Note that this script does not use encryption. Besides from being
        compressed, files are sent in clear-text. ssh is used to transfer
        remote-side end of script only. I.e. you need accounts and
        preferably keys exchanged on both ends (see s3.ssh_keypair.sh for a
        nice way to do this).

        Also note the syntax on SRC and DST differ slightly from scp. In
        absolute path form they are close to identical, except that you don't
        need to be explicit about is SRC is a directory or not. Both SRC and
        DST has the following full syntax:

        [[user@]host:]file-or-dir

        user can be omitted and is then deducted to local \$USER (or to any
        remapping in \$HOME/.ssh/configure

        FILE OR DIRECTORY:
            "file" can be either a directory or a file, whichever is
            determined by the last letter, if it's a '/' or not. But the
            meaning differ depending on if it's on SRC or DST.

            SRC:
              Ending with '/' for file in SRC does not affect what's done.
              If it's a directory, a recursive directory copy will occur
              regardless if '/' is given or not, if it's a file, a single
              file copy will occur.

            DST:
              Ending with '/' for file in DST $(echo -e ${FONT_UNDERLINE}does \
matter${FONT_NONE}).
              If SRC was a directory and if DST ends with
              '/', the whole given path will be regarded as a sub-path. If
              it doesn't end with '/', the destination will be named verbatim
              as given on command-line.

        RELATIVE PATH DEDUCTION:
            $CMD_STR will try to figure out what you bean based on a few
            rules. If any "file" resides within \$HOME $(echo -e ${FONT_UNDERLINE}when you
            invoke the script${FONT_NONE}), it will be
            transformed into corresponding \$HOME relative path on either
            remote.

            However, if relative paths are given when you stand outside
            \$HOME in which case path will be expanded/translated to
            localhost:s corresponding meaning.

            $(echo -e ${FONT_UNDERLINE}NOTE:${FONT_NONE})
              When using relative paths, especially ouside \$HOME, be very
              careful to check that the corresponding path is valid on the
              remote.

            One thing that differs greatly is how destination path is
            deducted for relative paths. Besides form user user@host: part,
            pscp has a behavior more similar to cp than to scp. I.e,
            DST= user@host:. does $(echo -e ${FONT_UNDERLINE}NOT${FONT_NONE}) \
mean the same thing.
            In pscp it means relatively from where you stand on the mashine
            you invoked pscp from, whereas in scp the same thing means from
            where the ssh login shell drops you (usually \$HOME). To be more
            explicit about where you want your DST to go use the \
$(echo -e ${FONT_BOLD}~${FONT_NONE} character).
            Furthermore '~' means the same in both scp and pscp,
            user@host:~/whatever is relative \$HOME (whatever that turns out
            to be) in both cases.

$(echo -e ${FONT_BOLD}DEFAULTS${FONT_NONE})
        This program figures out certain defaults dynamically. Most notably
        are the implicit user and final-path deductions for SRC and DST.

        The full source directory is based on where you currently stand. It
        tries to do deduct relative paths in an intelligent way, I.e. a
        SRC given relatively is first evaluated against the PID:s \$HOME. If
        it lays within that, and if DST does not start with '/', then final
        destination path will be constructed against the DST users \$HOME.
        If you're uncertain how the expansion works, use -v2 for INF output
        and look for the two lines under the string: $(echo -e ${FONT_UNDERLINE}"Final \
meaning of parsed
        SRC/DST".${FONT_NONE})

$(echo -e ${FONT_BOLD}AUTHOR${FONT_NONE})
        Written by Michael Ambrus.

$(echo -e ${FONT_BOLD}CAVEATS AND QUIRKS${FONT_NONE})
        ${CMD_STR} launches two processes when it operates, either of which
        can fail and worst case hang the daemonized process that owns it. If
        this happens and the cause is systemic (it's always (TM) initially)
        you need to enter either side manually and invoke 'screen -ls' then
        screen -rd SESSION to see what's keeping the transfer from working.

        ${CMD_STR} depends on a few sub-commands/sub-tools but it will make
        a check for these on both SRC and DST before staring to operate and
        try to evaluate existence and valid versions/variants.
        Note that ${CMD_STR} is very picky on ${FONT_UNDERLINE}which netcat\
        ${FONT_NONE} is used.
        It's only the BSD version that operates the way ${CMD_STR} want's it
        too.

$(echo -e ${FONT_BOLD}REPORTING BUGS${FONT_NONE})
        Report $CMD_STR bugs to bug-script3@gnu.org
        GNU coreutils home page: <http://www.gnu.org/software/script3/>
        General help using GNU software: <http://www.gnu.org/gethelp/>
        Report $CMD_STR translation bugs to <http://translationproject.org/team/>

$(echo -e ${FONT_BOLD}COPYRIGHT${FONT_NONE})
        Copyright 2014 Free Software Foundation, Inc. License GPLv3+: GNU GPL version 3 or
        later <http://gnu.org/licenses/gpl.html>.
        This is free software: you are free to change and redistribute it.\
$(echo -e ${FONT_BOLD}There  is  NO  WARRANTY,${FONT_NONE}\\n"\
        "to the extent permitted by law.)

$(echo -e ${FONT_BOLD}SEE ALSO${FONT_NONE})
        The  full  documentation  for $CMD_STR is maintained as a Texinfo
        manual. If the info and $CMD_STR programs are properly installed at
        your site, the command

              info script3 '$CMD_STR invocation'

       should give you access to the complete manual.

GNU script3 16.7.121-032bb              Mars 2014                \
$(echo $CMD_STR | tr '[:lower:]' '[:upper:]')(7)
EOF
}
	while getopts xrp:v:h OPTION; do
		case $OPTION in
		h)
		if [ -t 1 ]; then
			print_pscp_help $0 | less -R
		else
			print_pscp_help $0
		fi
			exit 0
			;;
		x)
			SHOW_PROGRESS='no'
			;;
		p)
			PORT=$OPTARG
			;;
		r)
			REVERSED="yes"
			;;
		v)
			VERBOSE=$OPTARG
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

	SHOW_PROGRESS=${SHOW_PROGRESS-"yes"}
	REVERSED=${REVERSED-"no"}
	PORT=${PORT-"$DEF_PORT"}
	VERBOSE=${VERBOSE-"0"}


