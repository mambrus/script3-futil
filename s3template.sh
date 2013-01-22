#!/bin/bash
# Author: Michael Ambrus (ambrmi09@gmail.com)
# 2013-01-22
# Create a new s3 command from any current s3 command as template

if [ -z $S3TEMPLATE_SH ]; then

S3TEMPLATE_SH="s3template.sh"

function s3template() {
	mkdir -p ${OUTDIR}/ui

	local FROM_STR=$(basename ${1} | sed -e 's/\..*$//' )
	local   TO_STR=$(basename ${2} | sed -e 's/\..*$//' )
	local STARTDIR=$(pwd)
	local FROM_DIR=$(basename $(pwd))
	local   TO_DIR=$(basename $(cd ${OUTDIR}; pwd))

	(
		cd $(dirname $1)
		cp $(basename $1) ${STARTDIR}/${OUTDIR}/${2}
		cp ui/.$(basename $1) ${STARTDIR}/${OUTDIR}/ui/.${2}
	)

	(
		cd ${OUTDIR}

		futil.onfile.sh \
			-f ${2} -- \
"sed '/#.*[[:digit:]]\{4\}-[[:digit:]]\{2\}-[[:digit:]]\{2\}[[:space:]]*$/"\
"s/.*/'\"# $(date +%Y-%m-%d)\"'/'"

		futil.onfile.sh \
			-f ${2} -- \
			sed -e 's/'"${FROM_STR}"'/'"${TO_STR}"'/g'
		futil.onfile.sh \
			-f ${2} -- \
			sed -e 's/'"${FROM_STR^^}"'/'"${TO_STR^^}"'/g'
		futil.onfile.sh \
			-f ${2} -- \
			sed -e 's/'"${FROM_DIR}"'/'"${TO_DIR}"'/g'
	)
	(
		cd ${OUTDIR}/ui

		futil.onfile.sh \
			-f ".${2}" -- \
			sed -e 's/'"${FROM_STR}"'/'"${TO_STR}"'/g'
		futil.onfile.sh \
			-f ".${2}" -- \
			sed -e 's/'"${FROM_STR^^}"'/'"${TO_STR^^}"'/g'
		futil.onfile.sh \
			-f ".${2}" -- \
			sed -e 's/'"${FROM_DIR}"'/'"${TO_DIR}"'/g'
	)
	(
		cd ${OUTDIR}
		echo "Template creation done. Updating files.s3..."
		s3.install_all.sh
	)
}

source s3.ebasename.sh
if [ "$S3TEMPLATE_SH" == $( ebasename $0 ) ]; then
	#Not sourced, do something with this.

	S3TEMPLATE_SH_INFO=${S3TEMPLATE_SH}

	source .futil.ui..s3template.sh

	tty -s; ATTY="$?"
	ISATTY="$ATTY -eq 0"

	set -e
	#set -u


	s3template "$@"

	RC=$?

	exit $RC
fi

fi

